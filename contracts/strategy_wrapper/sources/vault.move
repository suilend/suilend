module strategy_wrapper::vault {
    use std::type_name::{Self, TypeName};
    use sui::bag::{Self, Bag};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::event;
    use suilend::lending_market::{Self, LendingMarket};
    use strategy_wrapper::strategy_wrapper::{Self, StrategyOwnerCap};

    // === Errors ===
    const EIncorrectVersion: u64 = 1;
    const ETooSmall: u64 = 2;
    const EInvalidShare: u64 = 3;
    const EUnauthorizedManager: u64 = 4;
    const EInvalidFeeRate: u64 = 5;
    const EInsufficientShares: u64 = 7;

    // === Constants ===
    const CURRENT_VERSION: u64 = 1;
    const MAX_FEE_BPS: u64 = 1000; // 10% max fee
    const MIN_DEPOSIT: u64 = 1000000; // Minimum deposit to prevent dust
    const BASIS_POINTS: u64 = 10000;

    // === Structs ===
    
    /// Main vault that holds the underlying strategy position
    public struct Vault<phantom P> has key, store {
        id: UID,
        version: u64,
        strategy_cap: StrategyOwnerCap<P>,      // Single obligation for entire vault
        total_shares: u64,                      // Total shares issued
        strategy_type: u8,                      // SUI looping, BTC looping, etc
        management_fee_bps: u64,               // Management fee in basis points
        performance_fee_bps: u64,              // Performance fee in basis points
        last_compound_time: u64,               // For fee calculation
        last_total_value: u64,                 // For performance fee calculation
        manager: address,                       // Vault manager address
        additional_fields: Bag,                // For future extensions
    }

    /// User's share of the vault
    public struct VaultShare<phantom P> has key, store {
        id: UID,
        vault_id: ID,
        shares: u64,
    }

    /// Vault management capability
    public struct VaultManagerCap<phantom P> has key, store {
        id: UID,
        vault_id: ID,
    }

    // === Events ===
    public struct VaultCreated has copy, drop {
        vault_id: address,
        strategy_type: u8,
        manager: address,
        management_fee_bps: u64,
        performance_fee_bps: u64,
    }

    public struct Deposited has copy, drop {
        vault_id: address,
        user: address,
        deposit_amount: u64,
        shares_minted: u64,
        total_shares: u64,
        share_price: u64, // Price per share at deposit
    }

    public struct Withdrawn has copy, drop {
        vault_id: address,
        user: address,
        shares_burned: u64,
        withdraw_amount: u64,
        total_shares: u64,
        share_price: u64, // Price per share at withdrawal
    }

    public struct RewardsCompounded has copy, drop {
        vault_id: address,
        reward_token: TypeName,
        reward_amount: u64,
        compounded_amount: u64,
        new_total_value: u64,
    }


    // === Public Functions ===

    /// Create a new vault with underlying strategy
    public fun create_vault<P>(
        lending_market: &mut LendingMarket<P>,
        strategy_type: u8,
        management_fee_bps: u64,
        performance_fee_bps: u64,
        ctx: &mut TxContext
    ): (Vault<P>, VaultManagerCap<P>) {
        assert!(management_fee_bps <= MAX_FEE_BPS, EInvalidFeeRate);
        assert!(performance_fee_bps <= MAX_FEE_BPS, EInvalidFeeRate);

        // Create underlying strategy position
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap(
            lending_market,
            strategy_type,
            ctx
        );

        let vault = Vault {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            strategy_cap,
            total_shares: 0,
            strategy_type,
            management_fee_bps,
            performance_fee_bps,
            last_compound_time: 0,
            last_total_value: 0,
            manager: tx_context::sender(ctx),
            additional_fields: bag::new(ctx),
        };

        let manager_cap = VaultManagerCap {
            id: object::new(ctx),
            vault_id: object::id(&vault),
        };

        event::emit(VaultCreated {
            vault_id: object::id_address(&vault),
            strategy_type,
            manager: tx_context::sender(ctx),
            management_fee_bps,
            performance_fee_bps,
        });

        (vault, manager_cap)
    }

    /// User deposits assets and receives vault shares
    public fun deposit<P, T>(
        vault: &mut Vault<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_index: u64,
        deposit_coins: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): VaultShare<P> {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        let deposit_amount = coin::value(&deposit_coins);
        assert!(deposit_amount >= MIN_DEPOSIT, ETooSmall);

        // Calculate shares to mint
        let shares_to_mint = if (vault.total_shares == 0) {
            // First deposit - 1:1 ratio
            deposit_amount
        } else {
            // Subsequent deposits - proportional to vault value
            let vault_value = calculate_vault_value(vault, lending_market);
            if (vault_value == 0) {
                deposit_amount // Fallback to 1:1 if vault value is 0
            } else {
                ((deposit_amount as u128) * (vault.total_shares as u128) / (vault_value as u128) as u64)
            }
        };

        assert!(shares_to_mint > 0, ETooSmall);

        // Deposit into underlying strategy
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens(
            lending_market,
            reserve_index,
            clock,
            deposit_coins,
            ctx,
        );

        lending_market::deposit_ctokens_into_obligation(
            lending_market,
            reserve_index,
            strategy_wrapper::inner_cap(&vault.strategy_cap),
            clock,
            ctokens,
            ctx,
        );

        // Update vault state
        vault.total_shares = vault.total_shares + shares_to_mint;

        let share = VaultShare {
            id: object::new(ctx),
            vault_id: object::id(vault),
            shares: shares_to_mint,
        };

        event::emit(Deposited {
            vault_id: object::id_address(vault),
            user: tx_context::sender(ctx),
            deposit_amount,
            shares_minted: shares_to_mint,
            total_shares: vault.total_shares,
            share_price: if (vault.total_shares > shares_to_mint) {
                calculate_vault_value(vault, lending_market) * BASIS_POINTS / vault.total_shares
            } else {
                BASIS_POINTS // 1:1 for first deposit
            },
        });

        share
    }

    /// User burns shares and withdraws proportional assets
    public fun withdraw<P, T>(
        vault: &mut Vault<P>,
        share: VaultShare<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_index: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<T> {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(share.vault_id == object::id(vault), EInvalidShare);
        
        let VaultShare { id, vault_id: _, shares } = share;
        object::delete(id);

        assert!(shares > 0, EInsufficientShares);
        assert!(vault.total_shares >= shares, EInsufficientShares);

        // Calculate withdrawal amount based on current vault value
        let vault_value = calculate_vault_value(vault, lending_market);
        let withdraw_amount = ((shares as u128) * (vault_value as u128) / (vault.total_shares as u128) as u64);

        assert!(withdraw_amount > 0, ETooSmall);

        // Withdraw from underlying strategy
        let ctokens = lending_market::withdraw_ctokens(
            lending_market,
            reserve_index,
            strategy_wrapper::inner_cap(&vault.strategy_cap),
            clock,
            withdraw_amount,
            ctx,
        );

        let coins = lending_market::redeem_ctokens_and_withdraw_liquidity(
            lending_market,
            reserve_index,
            clock,
            ctokens,
            option::none(), // No rate limiter exemption
            ctx,
        );

        // Update vault state
        vault.total_shares = vault.total_shares - shares;

        event::emit(Withdrawn {
            vault_id: object::id_address(vault),
            user: tx_context::sender(ctx),
            shares_burned: shares,
            withdraw_amount: coin::value(&coins),
            total_shares: vault.total_shares,
            share_price: if (vault.total_shares > 0) {
                calculate_vault_value(vault, lending_market) * BASIS_POINTS / vault.total_shares
            } else {
                0
            },
        });

        coins
    }

    /// Compound same-token rewards (permissionless)
    public fun compound_same_token_rewards<P, T>(
        vault: &mut Vault<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_index: u64,
        reward_index: u64,
        is_deposit_reward: bool,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        
        let obligation_id = lending_market::obligation_id(
            strategy_wrapper::inner_cap(&vault.strategy_cap)
        );

        // Use permissionless auto-compounding
        lending_market::claim_rewards_and_deposit<P, T>(
            lending_market,
            obligation_id,
            clock,
            reserve_index, // reward reserve
            reward_index,
            is_deposit_reward,
            reserve_index, // deposit reserve (same token)
            ctx,
        );

        vault.last_compound_time = clock::timestamp_ms(clock);

        event::emit(RewardsCompounded {
            vault_id: object::id_address(vault),
            reward_token: type_name::get<T>(),
            reward_amount: 0, // Would need to track this from transaction
            compounded_amount: 0, // Would need to track this from transaction
            new_total_value: calculate_vault_value(vault, lending_market),
        });
    }

    /// Auto-compound cross-token rewards (manager only)
    public fun compound_cross_token_rewards<P, RewardToken>(
        vault: &mut Vault<P>,
        manager_cap: &VaultManagerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reward_reserve_index: u64,
        reward_index: u64,
        is_deposit_reward: bool,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<RewardToken> {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(manager_cap.vault_id == object::id(vault), EUnauthorizedManager);

        // This function returns the claimed rewards
        // The caller must handle the swap and re-deposit externally

        // Get access to obligation cap
        let obligation_cap = strategy_wrapper::inner_cap(&vault.strategy_cap);

        // Claim cross-token rewards
        let rewards = lending_market::claim_rewards<P, RewardToken>(
            lending_market,
            obligation_cap,
            clock,
            reward_reserve_index,
            reward_index,
            is_deposit_reward,
            ctx,
        );

        vault.last_compound_time = clock::timestamp_ms(clock);

        // Return rewards for external swap handling
        rewards
    }

    /// Complete cross-token compounding (after external swap)
    public fun complete_cross_token_compound<P, DepositToken>(
        vault: &mut Vault<P>,
        manager_cap: &VaultManagerCap<P>,
        lending_market: &mut LendingMarket<P>,
        deposit_reserve_index: u64,
        swapped_coins: Coin<DepositToken>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(manager_cap.vault_id == object::id(vault), EUnauthorizedManager);
        
        let deposit_amount = coin::value(&swapped_coins);
        assert!(deposit_amount > 0, ETooSmall);

        // Deposit the swapped tokens back into the strategy
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens(
            lending_market,
            deposit_reserve_index,
            clock,
            swapped_coins,
            ctx,
        );

        lending_market::deposit_ctokens_into_obligation(
            lending_market,
            deposit_reserve_index,
            strategy_wrapper::inner_cap(&vault.strategy_cap),
            clock,
            ctokens,
            ctx,
        );

        event::emit(RewardsCompounded {
            vault_id: object::id_address(vault),
            reward_token: type_name::get<DepositToken>(),
            reward_amount: 0, // Original reward amount would be tracked separately
            compounded_amount: deposit_amount,
            new_total_value: calculate_vault_value(vault, lending_market),
        });
    }

    /// Perform strategy operations (manager only) - borrow, leverage, etc.
    public fun strategy_borrow<P, T>(
        vault: &mut Vault<P>,
        manager_cap: &VaultManagerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_index: u64,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<T> {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(manager_cap.vault_id == object::id(vault), EUnauthorizedManager);

        lending_market::borrow<P, T>(
            lending_market,
            reserve_index,
            strategy_wrapper::inner_cap(&vault.strategy_cap),
            clock,
            amount,
            ctx,
        )
    }

    /// Perform strategy operations (manager only) - repay debt
    public fun strategy_repay<P, T>(
        vault: &mut Vault<P>,
        manager_cap: &VaultManagerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_index: u64,
        repay_coins: &mut Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(manager_cap.vault_id == object::id(vault), EUnauthorizedManager);

        let obligation_id = lending_market::obligation_id(
            strategy_wrapper::inner_cap(&vault.strategy_cap)
        );

        lending_market::repay<P, T>(
            lending_market,
            reserve_index,
            obligation_id,
            clock,
            repay_coins,
            ctx,
        );
    }

    // === View Functions ===

    public fun vault_id<P>(vault: &Vault<P>): ID {
        object::id(vault)
    }

    public fun strategy_type<P>(vault: &Vault<P>): u8 {
        vault.strategy_type
    }

    public fun total_shares<P>(vault: &Vault<P>): u64 {
        vault.total_shares
    }

    public fun manager<P>(vault: &Vault<P>): address {
        vault.manager
    }

    public fun management_fee_bps<P>(vault: &Vault<P>): u64 {
        vault.management_fee_bps
    }

    public fun performance_fee_bps<P>(vault: &Vault<P>): u64 {
        vault.performance_fee_bps
    }

    public fun share_vault_id<P>(share: &VaultShare<P>): ID {
        share.vault_id
    }

    public fun share_amount<P>(share: &VaultShare<P>): u64 {
        share.shares
    }

    public fun calculate_share_value<P>(
        vault: &Vault<P>,
        share: &VaultShare<P>,
        lending_market: &LendingMarket<P>
    ): u64 {
        assert!(share.vault_id == object::id(vault), EInvalidShare);
        
        if (vault.total_shares == 0) {
            return 0
        };

        let vault_value = calculate_vault_value(vault, lending_market);
        ((share.shares as u128) * (vault_value as u128) / (vault.total_shares as u128) as u64)
    }

    // === Private Functions ===

    fun calculate_vault_value<P>(
        _vault: &Vault<P>,
        _lending_market: &LendingMarket<P>
    ): u64 {
        // This would need to calculate the total value of the vault's position
        // including deposits, borrows, and current market values
        // For now, returning a placeholder - this would need to be implemented
        // based on the specific lending market's value calculation functions
        0 // Placeholder
    }

    // === Test Functions ===
    #[test_only]
    public fun destroy_vault_for_testing<P>(vault: Vault<P>) {
        let Vault { 
            id, 
            version: _, 
            strategy_cap, 
            total_shares: _, 
            strategy_type: _, 
            management_fee_bps: _, 
            performance_fee_bps: _, 
            last_compound_time: _, 
            last_total_value: _, 
            manager: _, 
            additional_fields 
        } = vault;
        
        object::delete(id);
        strategy_wrapper::destroy_for_testing(strategy_cap);
        bag::destroy_empty(additional_fields);
    }

    #[test_only]
    public fun destroy_vault_share_for_testing<P>(share: VaultShare<P>) {
        let VaultShare { id, vault_id: _, shares: _ } = share;
        object::delete(id);
    }

    #[test_only]
    public fun destroy_manager_cap_for_testing<P>(cap: VaultManagerCap<P>) {
        let VaultManagerCap { id, vault_id: _ } = cap;
        object::delete(id);
    }
}