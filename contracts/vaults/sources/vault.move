module vaults::vault {
    use pyth::price_info::PriceInfoObject;
    use sui::{
        balance::{Self, Balance},
        clock::{Self, Clock},
        coin::{Self, TreasuryCap, Coin},
        event,
        object_table::{Self, ObjectTable}
    };
    use suilend::{
        decimal,
        lending_market::{Self, ObligationOwnerCap, LendingMarket},
        obligation::{Self, Obligation},
        reserve
    };

    // === Errors ===
    const EIncorrectVersion: u64 = 1;
    const EInvalidManager: u64 = 2;
    const EInvalidDepositFeeBps: u64 = 6;
    const EInvalidWithdrawalFeeBps: u64 = 7;
    const EInvalidPerformanceFeeBps: u64 = 8;
    const EInvalidManagementFeeBps: u64 = 9;
    const EInvalidDeposit: u64 = 10;
    const EInvalidWithdraw: u64 = 11;
    const EInsufficientShares: u64 = 12;

    // === Constants ===
    const CURRENT_VERSION: u64 = 1;
    const MAX_DEPOSIT_FEE_BPS: u64 = 1000; // 10% max deposit fee
    const MAX_WITHDRAWAL_FEE_BPS: u64 = 1000; // 10% max withdrawal fee
    const MAX_PERFORMANCE_FEE_BPS: u64 = 5000; // 50% max performance fee
    const MAX_MANAGEMENT_FEE_BPS: u64 = 1000; // 10% max management fee
    const MIN_DEPOSIT: u64 = 1000000; // Minimum deposit 0.001 SUI to prevent dust
    const BASIS_POINTS: u64 = 10000; // 100%
    const NAV_PRECISION: u64 = 1_000_000_000; // 1e9 for NAV per share calculations
    const MAX_UTILIZATION_RATE_BPS: u64 = 7000; // 70% max utilization

    // === Structs ===
    public struct Vault<phantom P> has key, store {
        id: object::UID,
        version: u64,
        obligations: vector<ObligationOwnerCap<P>>,
        treasury_cap: TreasuryCap<VaultShare<P>>,
        deposit_asset: Balance<P>,
        total_shares: u64,
        users: vector<address>,
        user_entries: ObjectTable<address, UserEntry>,
        fee_receiver: address,
        management_fee_bps: u64,
        performance_fee_bps: u64,
        deposit_fee_bps: u64,
        withdrawal_fee_bps: u64,
        last_update_time_ms: u64,
        utilization_rate_bps: u64, // Current utilization rate in basis points
    }

    public struct VaultShare<phantom P> has drop, store {}

    public struct UserEntry has key, store {
        id: object::UID,
        shares: u64,
        entry_nav_per_share: u64, // NAV per share when user first deposited (scaled by 1e9)
        total_deposited: u64, // Total amount deposited by user
        last_deposit_time_ms: u64,
    }

    public struct VaultManagerCap<phantom P> has key, store {
        id: object::UID,
        vault_id: object::ID,
    }

    // === Events ===
    public struct VaultCreated has copy, drop {
        vault_id: object::ID,
        fee_receiver: address,
        management_fee_bps: u64,
        performance_fee_bps: u64,
        deposit_fee_bps: u64,
        withdrawal_fee_bps: u64,
    }

    public struct Deposit has copy, drop {
        vault_id: object::ID,
        user: address,
        deposit_amount: u64,
        shares_minted: u64,
        timestamp_ms: u64,
    }

    public struct Withdraw has copy, drop {
        vault_id: object::ID,
        user: address,
        amount: u64,
        shares_burned: u64,
        timestamp_ms: u64,
    }

    public struct FeesAccrued has copy, drop {
        vault_id: object::ID,
        fee_type: u64, // 1: deposit fee, 2: withdrawal fee, 3: performance fee, 4: management fee
        fee_amount: u64,
        fee_receiver: address,
        timestamp_ms: u64,
    }

    // === Functions ===
    public fun create_vault<P>(
        fee_receiver: address,
        management_fee_bps: u64,
        performance_fee_bps: u64,
        deposit_fee_bps: u64,
        withdrawal_fee_bps: u64,
        ctx: &mut tx_context::TxContext,
    ): (Vault<P>, VaultManagerCap<P>) {
        assert!(management_fee_bps <= MAX_MANAGEMENT_FEE_BPS, EInvalidManagementFeeBps);
        assert!(performance_fee_bps <= MAX_PERFORMANCE_FEE_BPS, EInvalidPerformanceFeeBps);
        assert!(deposit_fee_bps <= MAX_DEPOSIT_FEE_BPS, EInvalidDepositFeeBps);
        assert!(withdrawal_fee_bps <= MAX_WITHDRAWAL_FEE_BPS, EInvalidWithdrawalFeeBps);

        let share_treasury_cap = coin::create_treasury_cap_for_testing<VaultShare<P>>(ctx);

        // Create vault
        let vault = Vault {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            obligations: vector::empty(),
            treasury_cap: share_treasury_cap,
            deposit_asset: balance::zero<P>(),
            total_shares: 0,
            users: vector::empty(),
            user_entries: object_table::new(ctx),
            fee_receiver,
            management_fee_bps,
            performance_fee_bps,
            deposit_fee_bps,
            withdrawal_fee_bps,
            last_update_time_ms: 0,
            utilization_rate_bps: 0,
        };

        let vault_manager_cap = VaultManagerCap {
            id: object::new(ctx),
            vault_id: object::id(&vault),
        };

        event::emit(VaultCreated {
            vault_id: object::id(&vault),
            fee_receiver,
            management_fee_bps,
            performance_fee_bps,
            deposit_fee_bps,
            withdrawal_fee_bps,
        });

        (vault, vault_manager_cap)
    }

    public fun deposit<P>(
        vault: &mut Vault<P>,
        deposit: Coin<P>,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<VaultShare<P>> {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(coin::value(&deposit) >= MIN_DEPOSIT, EInvalidDeposit);

        let deposit_amount = coin::value(&deposit);
        let current_time = clock::timestamp_ms(clock);
        let user = tx_context::sender(ctx);

        // Calculate deposit fee
        let deposit_fee = (deposit_amount * vault.deposit_fee_bps) / BASIS_POINTS;
        let net_deposit_amount = deposit_amount - deposit_fee;

        // Split out fee
        let mut deposit = deposit;
        let fee_coins = coin::split(&mut deposit, deposit_fee, ctx);

        // Send fee to collector
        sui::transfer::public_transfer(fee_coins, vault.fee_receiver);

        // Add deposited coins to vault's asset balance
        balance::join(&mut vault.deposit_asset, coin::into_balance(deposit));

        // Calculate shares to mint based on current NAV
        let shares_to_mint = if (vault.total_shares == 0) {
            // First deposit - 1:1 ratio with net amount
            net_deposit_amount
        } else {
            let nav_per_share = calculate_nav_per_share(vault, lending_market, clock);
            (net_deposit_amount * NAV_PRECISION) / nav_per_share
        };

        assert!(shares_to_mint > 0, EInvalidDeposit);

        // Update user entry for performance fee tracking
        let current_nav_per_share = if (vault.total_shares == 0) {
            NAV_PRECISION
        } else {
            calculate_nav_per_share(vault, lending_market, clock)
        };

        if (!object_table::contains(&vault.user_entries, user)) {
            // New user
            let user_entry = UserEntry {
                id: object::new(ctx),
                shares: shares_to_mint,
                entry_nav_per_share: current_nav_per_share,
                total_deposited: net_deposit_amount,
                last_deposit_time_ms: current_time,
            };
            object_table::add(&mut vault.user_entries, user, user_entry);
            vector::push_back(&mut vault.users, user);
        } else {
            // Existing user - weighted average entry price
            let user_entry = object_table::borrow_mut(&mut vault.user_entries, user);
            let old_value = (user_entry.shares * user_entry.entry_nav_per_share) / NAV_PRECISION;
            let new_value = net_deposit_amount;
            let total_value = old_value + new_value;
            let total_shares = user_entry.shares + shares_to_mint;

            // Update weighted average entry NAV
            user_entry.entry_nav_per_share = (total_value * NAV_PRECISION) / total_shares;
            user_entry.shares = total_shares;
            user_entry.total_deposited = user_entry.total_deposited + net_deposit_amount;
            user_entry.last_deposit_time_ms = current_time;
        };

        // Mint vault shares to user
        let vault_shares = coin::mint(&mut vault.treasury_cap, shares_to_mint, ctx);
        vault.total_shares = vault.total_shares + shares_to_mint;
        vault.last_update_time_ms = current_time;

        // Emit fee collection event
        if (deposit_fee > 0) {
            event::emit(FeesAccrued {
                vault_id: object::id(vault),
                fee_type: 1, // deposit fee
                fee_amount: deposit_fee,
                fee_receiver: vault.fee_receiver,
                timestamp_ms: current_time,
            });
        };

        // Emit deposit event
        event::emit(Deposit {
            vault_id: object::id(vault),
            user: user,
            deposit_amount: deposit_amount,
            shares_minted: shares_to_mint,
            timestamp_ms: current_time,
        });

        vault_shares
    }

    /// User burns shares and withdraws proportional assets with performance fees on realized gains
    public fun withdraw<P>(
        vault: &mut Vault<P>,
        shares: Coin<VaultShare<P>>,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<P> {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(coin::value(&shares) > 0, EInsufficientShares);

        let shares_amount = coin::value(&shares);
        let user = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);

        assert!(vault.total_shares >= shares_amount, EInsufficientShares);
        assert!(object_table::contains(&vault.user_entries, user), EInsufficientShares);

        let current_nav_per_share = calculate_nav_per_share(vault, lending_market, clock);
        let user_entry = object_table::borrow_mut(&mut vault.user_entries, user);
        assert!(user_entry.shares >= shares_amount, EInsufficientShares);

        let entry_nav_per_share = user_entry.entry_nav_per_share;

        // Calculate withdrawal amount based on current NAV
        let withdraw_amount = (shares_amount * current_nav_per_share) / NAV_PRECISION;

        // Calculate realized gain and performance fee
        let mut performance_fee = 0;
        if (current_nav_per_share > entry_nav_per_share) {
            let gain_per_share = current_nav_per_share - entry_nav_per_share;
            let total_gain = (shares_amount * gain_per_share) / NAV_PRECISION;
            performance_fee = (total_gain * vault.performance_fee_bps) / BASIS_POINTS;
        };

        // Calculate withdrawal fee on the gross amount
        let withdrawal_fee = (withdraw_amount * vault.withdrawal_fee_bps) / BASIS_POINTS;

        // Total fees to deduct
        let total_fees = performance_fee + withdrawal_fee;
        let net_withdraw_amount = withdraw_amount - total_fees;

        // Update user entry
        user_entry.shares = user_entry.shares - shares_amount;
        if (user_entry.shares == 0) {
            // Remove user entry if no shares left
            let UserEntry {
                id,
                shares: _,
                entry_nav_per_share: _,
                total_deposited: _,
                last_deposit_time_ms: _,
            } = object_table::remove(&mut vault.user_entries, user);
            object::delete(id);
        };

        // Burn the shares
        coin::burn(&mut vault.treasury_cap, shares);
        vault.total_shares = vault.total_shares - shares_amount;
        vault.last_update_time_ms = current_time;

        // Withdraw full amount from vault's asset balance
        let mut withdrawn_balance = balance::split(&mut vault.deposit_asset, withdraw_amount);

        // Split out fees
        if (total_fees > 0) {
            let fee_balance = balance::split(&mut withdrawn_balance, total_fees);
            let fee_coins = coin::from_balance(fee_balance, ctx);

            // Send fees to collector
            sui::transfer::public_transfer(fee_coins, vault.fee_receiver);
        };

        // Return net amount to user
        let coins = coin::from_balance(withdrawn_balance, ctx);

        // Emit performance fee event
        if (performance_fee > 0) {
            event::emit(FeesAccrued {
                vault_id: object::id(vault),
                fee_type: 3, // performance fee
                fee_amount: performance_fee,
                fee_receiver: vault.fee_receiver,
                timestamp_ms: current_time,
            });
        };

        // Emit withdrawal fee event
        if (withdrawal_fee > 0) {
            event::emit(FeesAccrued {
                vault_id: object::id(vault),
                fee_type: 2, // withdrawal fee
                fee_amount: withdrawal_fee,
                fee_receiver: vault.fee_receiver,
                timestamp_ms: current_time,
            });
        };

        // Emit withdrawal event
        event::emit(Withdraw {
            vault_id: object::id(vault),
            user: user,
            amount: net_withdraw_amount,
            shares_burned: shares_amount,
            timestamp_ms: current_time,
        });

        coins
    }

    public(package) fun calculate_shares_to_mint<P>(
        vault: &Vault<P>,
        deposit_amount: u64,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
    ): u64 {
        if (vault.total_shares == 0) {
            deposit_amount
        } else {
            let nav_per_share = calculate_nav_per_share(vault, lending_market, clock);
            (deposit_amount * NAV_PRECISION) / nav_per_share
        }
    }

    public(package) fun calculate_shares_to_burn<P>(
        vault: &Vault<P>,
        withdraw_amount: u64,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
    ): u64 {
        if (vault.total_shares == 0) {
            0
        } else {
            let nav_per_share = calculate_nav_per_share(vault, lending_market, clock);
            (withdraw_amount * NAV_PRECISION) / nav_per_share
        }
    }

    public(package) fun calculate_withdraw_amount<P>(
        vault: &Vault<P>,
        shares_amount: u64,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
    ): u64 {
        if (vault.total_shares == 0) {
            0
        } else {
            let nav_per_share = calculate_nav_per_share(vault, lending_market, clock);
            (shares_amount * nav_per_share) / NAV_PRECISION
        }
    }

    public(package) fun calculate_deposit_amount<P>(
        vault: &Vault<P>,
        shares_amount: u64,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
    ): u64 {
        let nav_per_share = calculate_nav_per_share(vault, lending_market, clock);
        (shares_amount * nav_per_share) / NAV_PRECISION
    }

    /// Check if vault can deploy more funds (under 70% utilization)
    public fun can_deploy_funds<P>(
        vault: &Vault<P>,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
        amount: u64,
    ): bool {
        let liquid_value = balance::value(&vault.deposit_asset);

        if (amount > liquid_value) {
            false
        } else {
            let new_liquid_value = liquid_value - amount;
            let total_value = calculate_total_vault_value(vault, lending_market, clock);
            if (total_value == 0) {
                true
            } else {
                let new_deployed = total_value - new_liquid_value;
                let new_utilization = (new_deployed * BASIS_POINTS) / total_value;
                new_utilization <= MAX_UTILIZATION_RATE_BPS
            }
        }
    }

    /// Get user's current position info
    public fun get_user_position<P>(vault: &Vault<P>, user: address): (u64, u64, u64, u64) {
        if (!object_table::contains(&vault.user_entries, user)) {
            (0, 0, 0, 0)
        } else {
            let user_entry = object_table::borrow(&vault.user_entries, user);
            (
                user_entry.shares,
                user_entry.entry_nav_per_share,
                user_entry.total_deposited,
                user_entry.last_deposit_time_ms,
            )
        }
    }

    /// Check current utilization rate
    public fun get_utilization_rate<P>(
        vault: &Vault<P>,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
    ): u64 {
        calculate_utilization_rate(vault, lending_market, clock)
    }

    /// Convert assets to shares
    public fun convert_to_shares<P>(
        vault: &Vault<P>,
        assets: u64,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
    ): u64 {
        if (vault.total_shares == 0) {
            assets
        } else {
            let nav_per_share = calculate_nav_per_share(vault, lending_market, clock);
            (assets * NAV_PRECISION) / nav_per_share
        }
    }

    /// Convert shares to assets
    public fun convert_to_assets<P>(
        vault: &Vault<P>,
        shares: u64,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
    ): u64 {
        if (vault.total_shares == 0) {
            0
        } else {
            let nav_per_share = calculate_nav_per_share(vault, lending_market, clock);
            (shares * nav_per_share) / NAV_PRECISION
        }
    }

    /// Preview deposit (assets → shares, no fees)
    public fun preview_deposit<P>(
        vault: &Vault<P>,
        assets: u64,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
    ): u64 {
        convert_to_shares(vault, assets, lending_market, clock)
    }

    /// Preview redeem (shares → assets, no fees)
    public fun preview_redeem<P>(
        vault: &Vault<P>,
        shares: u64,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
    ): u64 {
        convert_to_assets(vault, shares, lending_market, clock)
    }

    /// Total assets under management
    public fun total_assets<P>(
        vault: &Vault<P>,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
    ): u64 {
        calculate_total_vault_value(vault, lending_market, clock)
    }

    /// Total supply of shares
    public fun total_supply<P>(vault: &Vault<P>): u64 {
        vault.total_shares
    }

    /// Calculate total vault value in asset-native terms
    /// Returns total assets under management in the base asset P
    public fun calculate_total_vault_value<P>(
        vault: &Vault<P>,
        lending_market: &LendingMarket<P>,
        _clock: &Clock,
    ): u64 {
        let mut total_value = balance::value(&vault.deposit_asset);

        // Add value from all lending positions
        let mut i = 0;
        while (i < vector::length(&vault.obligations)) {
            let obligation_cap = vector::borrow(&vault.obligations, i);
            let obligation_id = lending_market::obligation_id(obligation_cap);
            let obligation = lending_market::obligation(lending_market, obligation_id);

            // Get net value from this obligation (deposits - borrows in asset terms)
            let net_value = calculate_obligation_net_value<P>(obligation, lending_market);
            total_value = total_value + net_value;

            i = i + 1;
        };

        total_value
    }

    /// Calculate net value of an obligation in asset-native terms
    /// This converts all positions back to the base asset P
    fun calculate_obligation_net_value<P>(
        obligation: &Obligation<P>,
        lending_market: &LendingMarket<P>,
    ): u64 {
        let mut net_value = 0;

        // Add collateral deposits (converted from cTokens to underlying)
        let deposits = obligation::deposits(obligation);
        let mut i = 0;
        while (i < vector::length(deposits)) {
            let deposit = vector::borrow(deposits, i);
            let reserve_index = deposit.reserve_array_index();
            let reserves = lending_market::reserves(lending_market);
            let reserve = vector::borrow(reserves, reserve_index);

            // Check if this deposit is in our base asset P
            if (reserve::coin_type(reserve) == std::type_name::get<P>()) {
                let ctoken_amount = deposit.deposited_ctoken_amount();
                let ctoken_ratio = reserve::ctoken_ratio(reserve);
                // Convert cTokens to underlying asset amount
                let underlying_amount = decimal::floor(
                    decimal::mul(decimal::from(ctoken_amount), ctoken_ratio),
                );
                net_value = net_value + underlying_amount;
            };

            i = i + 1;
        };

        // Subtract borrowed amounts (if borrowed in base asset P)
        let borrows = obligation::borrows(obligation);
        let mut j = 0;
        while (j < vector::length(borrows)) {
            let borrow = vector::borrow(borrows, j);
            let reserve_index = borrow.reserve_array_index();
            let reserves = lending_market::reserves(lending_market);
            let reserve = vector::borrow(reserves, reserve_index);

            // Check if this borrow is in our base asset P
            if (reserve::coin_type(reserve) == std::type_name::get<P>()) {
                let borrowed_amount = decimal::floor(borrow.borrowed_amount());
                net_value = if (net_value >= borrowed_amount) {
                    net_value - borrowed_amount
                } else {
                    0
                };
            };

            j = j + 1;
        };

        net_value
    }

    /// Calculate NAV per share (scaled by NAV_PRECISION)
    public fun calculate_nav_per_share<P>(
        vault: &Vault<P>,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
    ): u64 {
        if (vault.total_shares == 0) {
            NAV_PRECISION // 1.0 scaled
        } else {
            let total_value = calculate_total_vault_value(vault, lending_market, clock);
            (total_value * NAV_PRECISION) / vault.total_shares
        }
    }

    /// Calculate utilization rate in basis points
    public fun calculate_utilization_rate<P>(
        vault: &Vault<P>,
        lending_market: &LendingMarket<P>,
        clock: &Clock,
    ): u64 {
        let total_value = calculate_total_vault_value(vault, lending_market, clock);
        let liquid_value = balance::value(&vault.deposit_asset);

        if (total_value == 0) {
            0
        } else {
            let deployed_value = total_value - liquid_value;
            (deployed_value * BASIS_POINTS) / total_value
        }
    }

    // === Vault Manager Functions ===

    /// Validate that a manager cap belongs to a specific vault
    public fun validate_manager_cap<P>(vault: &Vault<P>, manager_cap: &VaultManagerCap<P>) {
        assert!(manager_cap.vault_id == object::id(vault), EInvalidManager);
    }

    // deposit assets to lending market
    public fun deposit_to_lending_market<P>(
        vault_manager_cap: &mut VaultManagerCap<P>,
        vault: &mut Vault<P>,
        obligation_cap: &mut ObligationOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        coins_to_deposit: Coin<P>,
        ctx: &mut TxContext,
    ) {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        validate_manager_cap(vault, vault_manager_cap);
        assert!(coin::value(&coins_to_deposit) > 0, EInvalidDeposit);

        // deposit coins to lending market
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens(
            lending_market,
            reserve_array_index,
            clock,
            coins_to_deposit,
            ctx,
        );

        // Then deposit cTokens into obligation using our inner cap
        lending_market::deposit_ctokens_into_obligation(
            lending_market,
            reserve_array_index,
            obligation_cap,
            clock,
            ctokens,
            ctx,
        );
    }

    // withdraw assets from lending market
    public fun withdraw_from_lending_market<P>(
        vault_manager_cap: &mut VaultManagerCap<P>,
        vault: &mut Vault<P>,
        lending_market: &mut LendingMarket<P>,
        obligation_cap: &mut ObligationOwnerCap<P>,
        reserve_array_index: u64,
        ctoken_amount: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<P> {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        validate_manager_cap(vault, vault_manager_cap);
        assert!(ctoken_amount > 0, EInvalidWithdraw);

        // First withdraw cTokens from obligation
        let ctokens = lending_market::withdraw_ctokens(
            lending_market,
            reserve_array_index,
            obligation_cap,
            clock,
            ctoken_amount,
            ctx,
        );

        // Then redeem cTokens for underlying asset
        let withdrawn_coins = lending_market::redeem_ctokens_and_withdraw_liquidity(
            lending_market,
            reserve_array_index,
            clock,
            ctokens,
            option::none(),
            ctx,
        );

        withdrawn_coins
    }

    /// Borrow from the vault's obligation
    public fun borrow_from_lending_market<P, T>(
        vault_manager_cap: &mut VaultManagerCap<P>,
        vault: &mut Vault<P>,
        lending_market: &mut LendingMarket<P>,
        obligation_cap: &mut ObligationOwnerCap<P>,
        reserve_array_index: u64,
        clock: &Clock,
        amount: u64,
        ctx: &mut TxContext,
    ): Coin<T> {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        validate_manager_cap(vault, vault_manager_cap);

        lending_market::borrow<P, T>(
            lending_market,
            reserve_array_index,
            obligation_cap,
            clock,
            amount,
            ctx,
        )
    }

    /// Repay borrowed assets
    public fun repay_to_lending_market<P, T>(
        vault_manager_cap: &mut VaultManagerCap<P>,
        vault: &mut Vault<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        obligation_id: object::ID,
        clock: &Clock,
        max_repay_coins: &mut Coin<T>,
        ctx: &mut TxContext,
    ) {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        validate_manager_cap(vault, vault_manager_cap);

        lending_market::repay<P, T>(
            lending_market,
            reserve_array_index,
            obligation_id,
            clock,
            max_repay_coins,
            ctx,
        )
    }

    /// Refresh reserve price before operations
    public fun refresh_reserve_price<P>(
        vault_manager_cap: &VaultManagerCap<P>,
        vault: &Vault<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        price_info: &PriceInfoObject,
    ) {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        validate_manager_cap(vault, vault_manager_cap);

        lending_market::refresh_reserve_price<P>(
            lending_market,
            reserve_array_index,
            clock,
            price_info,
        )
    }

    /// Compound interest on a reserve
    public fun compound_interest<P>(
        vault_manager_cap: &VaultManagerCap<P>,
        vault: &Vault<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
    ) {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        validate_manager_cap(vault, vault_manager_cap);

        lending_market::compound_interest<P>(
            lending_market,
            reserve_array_index,
            clock,
        )
    }

    /// Claim liquidity mining rewards
    public fun claim_rewards<P, RewardType>(
        vault_manager_cap: &VaultManagerCap<P>,
        vault: &Vault<P>,
        lending_market: &mut LendingMarket<P>,
        obligation_cap: &ObligationOwnerCap<P>,
        clock: &Clock,
        reserve_id: u64,
        reward_index: u64,
        is_deposit_reward: bool,
        ctx: &mut TxContext,
    ): Coin<RewardType> {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        validate_manager_cap(vault, vault_manager_cap);

        lending_market::claim_rewards<P, RewardType>(
            lending_market,
            obligation_cap,
            clock,
            reserve_id,
            reward_index,
            is_deposit_reward,
            ctx,
        )
    }

    /// Create a new obligation for the vault
    public fun create_obligation<P>(
        vault_manager_cap: &VaultManagerCap<P>,
        vault: &mut Vault<P>,
        lending_market: &mut LendingMarket<P>,
        ctx: &mut TxContext,
    ): u64 {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        validate_manager_cap(vault, vault_manager_cap);

        let obligation_cap = lending_market::create_obligation<P>(lending_market, ctx);
        vector::push_back(&mut vault.obligations, obligation_cap);

        // Return the index of the newly created obligation
        vector::length(&vault.obligations) - 1
    }

    /// Get obligation cap at index (read-only)
    public fun get_obligation_cap<P>(vault: &Vault<P>, index: u64): &ObligationOwnerCap<P> {
        vector::borrow(&vault.obligations, index)
    }

    /// Get mutable obligation cap at index (manager only)
    public fun get_obligation_cap_mut<P>(
        vault_manager_cap: &VaultManagerCap<P>,
        vault: &mut Vault<P>,
        index: u64,
    ): &mut ObligationOwnerCap<P> {
        validate_manager_cap(vault, vault_manager_cap);
        vector::borrow_mut(&mut vault.obligations, index)
    }

    /// Get number of obligations in vault
    public fun obligation_count<P>(vault: &Vault<P>): u64 {
        vector::length(&vault.obligations)
    }

    // === Test Functions ===
    #[test_only]
    public fun deposit_for_testing<P>(
        vault: &mut Vault<P>,
        deposit: Coin<P>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<VaultShare<P>> {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(coin::value(&deposit) >= MIN_DEPOSIT, EInvalidDeposit);

        let deposit_amount = coin::value(&deposit);
        let current_time = clock::timestamp_ms(clock);
        let user = tx_context::sender(ctx);

        let deposit_fee = (deposit_amount * vault.deposit_fee_bps) / BASIS_POINTS;
        let net_deposit_amount = deposit_amount - deposit_fee;

        let mut deposit = deposit;
        let fee_coins = coin::split(&mut deposit, deposit_fee, ctx);
        sui::transfer::public_transfer(fee_coins, vault.fee_receiver);

        balance::join(&mut vault.deposit_asset, coin::into_balance(deposit));

        let shares_to_mint = if (vault.total_shares == 0) {
            net_deposit_amount
        } else {
            // Simple proportional calculation for testing
            (net_deposit_amount * vault.total_shares) / balance::value(&vault.deposit_asset)
        };

        let vault_shares = coin::mint(&mut vault.treasury_cap, shares_to_mint, ctx);
        vault.total_shares = vault.total_shares + shares_to_mint;
        vault.last_update_time_ms = current_time;

        vault_shares
    }

    #[test_only]
    public fun withdraw_for_testing<P>(
        vault: &mut Vault<P>,
        shares: Coin<VaultShare<P>>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<P> {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(coin::value(&shares) > 0, EInsufficientShares);

        let shares_amount = coin::value(&shares);
        let current_time = clock::timestamp_ms(clock);

        assert!(vault.total_shares >= shares_amount, EInsufficientShares);
        assert!(vault.total_shares > 0, EInsufficientShares);

        // Calculate withdrawal amount BEFORE burning shares
        let total_assets = balance::value(&vault.deposit_asset);
        let withdraw_amount = (shares_amount * total_assets) / vault.total_shares;

        // Now burn the shares
        coin::burn(&mut vault.treasury_cap, shares);
        vault.total_shares = vault.total_shares - shares_amount;

        let withdrawal_fee = (withdraw_amount * vault.withdrawal_fee_bps) / BASIS_POINTS;
        let mut withdrawn_balance = balance::split(&mut vault.deposit_asset, withdraw_amount);

        if (withdrawal_fee > 0) {
            let fee_balance = balance::split(&mut withdrawn_balance, withdrawal_fee);
            let fee_coins = coin::from_balance(fee_balance, ctx);
            sui::transfer::public_transfer(fee_coins, vault.fee_receiver);
        };

        vault.last_update_time_ms = current_time;
        coin::from_balance(withdrawn_balance, ctx)
    }

    #[test_only]
    public fun create_vault_for_testing<P>(
        fee_receiver: address,
        management_fee_bps: u64,
        performance_fee_bps: u64,
        deposit_fee_bps: u64,
        withdrawal_fee_bps: u64,
        ctx: &mut TxContext,
    ): (Vault<P>, VaultManagerCap<P>) {
        assert!(management_fee_bps <= MAX_MANAGEMENT_FEE_BPS, EInvalidManagementFeeBps);
        assert!(performance_fee_bps <= MAX_PERFORMANCE_FEE_BPS, EInvalidPerformanceFeeBps);
        assert!(deposit_fee_bps <= MAX_DEPOSIT_FEE_BPS, EInvalidDepositFeeBps);
        assert!(withdrawal_fee_bps <= MAX_WITHDRAWAL_FEE_BPS, EInvalidWithdrawalFeeBps);

        // Create treasury cap for testing
        let share_treasury_cap = coin::create_treasury_cap_for_testing<VaultShare<P>>(ctx);

        // Create vault
        let vault = Vault {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            obligations: vector::empty(),
            treasury_cap: share_treasury_cap,
            deposit_asset: balance::zero<P>(),
            total_shares: 0,
            users: vector::empty(),
            user_entries: object_table::new(ctx),
            fee_receiver,
            management_fee_bps,
            performance_fee_bps,
            deposit_fee_bps,
            withdrawal_fee_bps,
            last_update_time_ms: 0,
            utilization_rate_bps: 0,
        };

        let vault_manager_cap = VaultManagerCap {
            id: object::new(ctx),
            vault_id: object::id(&vault),
        };

        event::emit(VaultCreated {
            vault_id: object::id(&vault),
            fee_receiver,
            management_fee_bps,
            performance_fee_bps,
            deposit_fee_bps,
            withdrawal_fee_bps,
        });

        (vault, vault_manager_cap)
    }
}
