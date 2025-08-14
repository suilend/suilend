module vaults::vault {
    use sui::event;
    use suilend::lending_market::{Self, ObligationOwnerCap, LendingMarket};
    use suilend::decimal::Decimal;
    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::balance::{Self, Balance};
    use sui::clock::{Self, Clock};
    use pyth::price_info::PriceInfoObject;
    use sui::object;
    use sui::tx_context;
    use sui::transfer;
    use std::option;
    use std::vector;
    use suilend::decimal;

    
    // === Errors ===
    const EIncorrectVersion: u64 = 1;
    const EInvalidManager: u64 = 2;
    const EInvalidObligation: u64 = 3;
    const EInvalidTreasury: u64 = 4;
    const EInvalidFeeReceiver: u64 = 5;
    const EInvalidDepositFeeBps: u64 = 6;
    const EInvalidWithdrawalFeeBps: u64 = 7;
    const EInvalidPerformanceFeeBps: u64 = 8;
    const EInvalidManagementFeeBps: u64 = 9;
    const EInvalidDeposit: u64 = 10;
    const EInvalidWithdraw: u64 = 11;
    const EInsufficientShares: u64 = 12;
    const ETooSmall: u64 = 13;


    // === Constants ===
    const CURRENT_VERSION: u64 = 1; // Updated for new features
    const MAX_DEPOSIT_FEE_BPS: u64 = 1000; // 10% max deposit fee
    const MAX_WITHDRAWAL_FEE_BPS: u64 = 1000; // 10% max withdrawal fee
    const MAX_PERFORMANCE_FEE_BPS: u64 = 5000; // 50% max performance fee
    const MAX_MANAGEMENT_FEE_BPS: u64 = 1000; // 10% max management fee
    const MIN_DEPOSIT: u64 = 1000000; // Minimum deposit 0.001 SUI to prevent dust
    const SHARE_DECIMALS: u8 = 9; // Share token decimals
    const BASIS_POINTS: u64 = 10000; // 100%

    // === Structs ===
    public struct Vault<phantom P> has key, store {
        id: object::UID,
        version: u64,
        obligations: vector<ObligationOwnerCap<P>>,
        treasury_cap: TreasuryCap<VaultShare<P>>,
        deposit_asset: Balance<P>,
        total_shares: u64,
        users: vector<address>,
        fee_receiver: address,
        management_fee_bps: u64,
        performance_fee_bps: u64,
        deposit_fee_bps: u64,
        withdrawal_fee_bps: u64,
    }

    public struct VaultShare<phantom P> has store, drop {}

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

    public struct VaultManagerUpdated has copy, drop {
        vault_id: object::ID,
        manager: address,
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
        // should we prevent the fee receiver to be the zero address?        

        // Create treasury cap for fungible shares
        let (share_treasury_cap, coin_metadata) = coin::create_currency(
            VaultShare<P> {},
            SHARE_DECIMALS,
            b"VS",
            b"Vault Share",
            b"Suilend Vault Share",
            option::none(),
            ctx
        );

        transfer::public_freeze_object(coin_metadata);

        // Create vault
        let vault = Vault {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            obligations: vector::empty(),
            treasury_cap: share_treasury_cap,
            deposit_asset: balance::zero<P>(),
            total_shares: 0,
            users: vector::empty(),
            fee_receiver,
            management_fee_bps,
            performance_fee_bps,
            deposit_fee_bps,
            withdrawal_fee_bps,
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
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<VaultShare<P>> {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(coin::value(&deposit) >= MIN_DEPOSIT, EInvalidDeposit);

        let deposit_amount = coin::value(&deposit);
        
        let current_time = clock::timestamp_ms(clock);
        
        // Calculate deposit fee
        let deposit_fee = (deposit_amount * vault.deposit_fee_bps) / BASIS_POINTS; // 10% of deposit amount
        let net_deposit_amount = deposit_amount - deposit_fee;
        
        // Split out fee
        let mut deposit = deposit;
        let fee_coins = coin::split(&mut deposit, deposit_fee, ctx);
        
        // Send fee to collector
        sui::transfer::public_transfer(fee_coins, vault.fee_receiver);
        
        // Add deposited coins to vault's asset balance
        balance::join(&mut vault.deposit_asset, coin::into_balance(deposit));
        
        // Calculate current vault NAV
        let vault_nav_usd = decimal::from(0); // PLACEHOLDER: Implement vault NAV calculation
        
        // Calculate shares to mint based on NAV
        let shares_to_mint = if (vault.total_shares == 0) {
            // First deposit - 1:1 ratio with net amount
            net_deposit_amount
        } else {
            // PLACEHOLDER: Implement proper NAV-based share calculation
            // For now, use simple proportional calculation
            (net_deposit_amount * vault.total_shares) / 1000000 // Simple placeholder ratio
        };
        
        assert!(shares_to_mint > 0, EInvalidDeposit);
                
        // Mint vault shares to user
        let vault_shares = coin::mint(&mut vault.treasury_cap, shares_to_mint, ctx);
        vault.total_shares = vault.total_shares + shares_to_mint;
        vector::push_back(&mut vault.users, tx_context::sender(ctx));


        // PLACEHOLDER: Update cached NAV
        // vault.cached_nav = calculate_vault_nav();
        
        // PLACEHOLDER: Calculate share price in USD
        // let share_price_usd = vault_nav_usd / vault.total_shares;
        
        // Emit fee collection event
        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: 1, // deposit fee
            fee_amount: deposit_fee,
            fee_receiver: vault.fee_receiver,
            timestamp_ms: current_time,
        });
        
        // Emit deposit event
        event::emit(Deposit {
            vault_id: object::id(vault),
            user: tx_context::sender(ctx),
            deposit_amount: deposit_amount,
            shares_minted: shares_to_mint,
            timestamp_ms: current_time,
        });
        
        vault_shares
    }

    /// User burns shares and withdraws proportional assets. Assume the deposit coin is USDC or SUI
    public fun withdraw<P>(
        vault: &mut Vault<P>,
        shares: Coin<VaultShare<P>>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<P> {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(coin::value(&shares) > 0, EInsufficientShares);

        let shares_amount = coin::value(&shares); // amount of shares to burn
        assert!(vault.total_shares >= shares_amount, EInsufficientShares); 
        
        let current_time = clock::timestamp_ms(clock);
        
        // Burn the shares
        coin::burn(&mut vault.treasury_cap, shares);
        vault.total_shares = vault.total_shares - shares_amount;

        // calculate the amount of coins to withdraw
        let withdraw_amount = calculate_withdraw_amount(vault, shares_amount);
        
        // Calculate withdrawal fee
        let withdrawal_fee = (withdraw_amount * vault.withdrawal_fee_bps) / BASIS_POINTS;

        // Withdraw full amount from vault's asset balance
        let mut withdrawn_balance = balance::split(&mut vault.deposit_asset, withdraw_amount);
        
        // Split out withdrawal fee
        let fee_balance = balance::split(&mut withdrawn_balance, withdrawal_fee);
        let fee_coins = coin::from_balance(fee_balance, ctx);
        
        // Send fee to collector
        transfer::public_transfer(fee_coins, vault.fee_receiver);
        
        // Return net amount to user
        let coins = coin::from_balance(withdrawn_balance, ctx);
        
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
            user: tx_context::sender(ctx),
            amount: withdraw_amount,
            shares_burned: shares_amount,
            timestamp_ms: current_time,
        });
        
        // Return coins to caller
        coins
    }

    public(package) fun calculate_shares_to_mint<P>(
        vault: &Vault<P>,
        deposit_amount: u64,
    ): u64 {
        // TODO: Implement proper NAV-based share calculation
        // For now, use simple proportional calculation
        (deposit_amount * vault.total_shares) / 1000000 // Simple placeholder ratio
    }

    public(package) fun calculate_shares_to_burn<P>(
        vault: &Vault<P>,
        withdraw_amount: u64,
    ): u64 {
        // TODO: Implement proper NAV-based share calculation
        // For now, use simple proportional calculation
        (withdraw_amount * vault.total_shares) / 1000000 // Simple placeholder ratio
    }

    public(package) fun calculate_withdraw_amount<P>(
        vault: &Vault<P>,
        shares_amount: u64,
    ): u64 {
        // TODO: Implement proper NAV-based share calculation
        // For now, use simple proportional calculation
        (shares_amount * vault.total_shares) / 1000000 // Simple placeholder ratio
    }

    public(package) fun calculate_deposit_amount<P>(
        vault: &Vault<P>,
        shares_amount: u64,
    ): u64 {
        // TODO: Implement proper NAV-based share calculation
        // For now, use simple proportional calculation
        (shares_amount * vault.total_shares) / 1000000 // Simple placeholder ratio
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
}