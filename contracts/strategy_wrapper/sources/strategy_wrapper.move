module strategy_wrapper::strategy_wrapper {
    use sui::event;
    use suilend::lending_market::{Self, ObligationOwnerCap, LendingMarket, RateLimiterExemption};
    use suilend::obligation::Obligation;
    use suilend::reserve::CToken;
    use sui::coin::Coin;
    use sui::clock::Clock;
    use sui::sui::SUI;
    use sui_system::sui_system::SuiSystemState;


    // === Errors ===
    const EIncorrectVersion: u64 = 1;
    const EInvalidStrategyType: u64 = 2;
    const EUnauthorizedRelayer: u64 = 3;
    const EObligationCapAlreadyBorrowed: u64 = 4;
    const EObligationCapNotBorrowed: u64 = 5;

    // === Constants ===
    const CURRENT_VERSION: u64 = 1;

    // === Strategy Type Constants ===
    const STRATEGY_SUI_LOOPING_SSUI: u8 = 1;
    const STRATEGY_SUI_LOOPING_STRATSUI: u8 = 2;
    const STRATEGY_SUI_LOOPING_USDC: u8 = 3;
    const STRATEGY_SUI_LOOPING_AUSD: u8 = 4;
    const STRATEGY_SUI_LOOPING_XBTC: u8 = 100;
    const SLUSH_WBTC_LOOPING_XBTC: u8 = 101;


    // Structs
    public struct StrategyOwnerCap<phantom P> has key, store {
        id: UID,
        version: u64,
        inner_cap: ObligationOwnerCap<P>,
        strategy_type: u8,
    }
    
    /// Shared object that holds the obligation cap for hot potato pattern
    public struct WrappedObligationCap<phantom P> has key, store {
        id: UID,
        version: u64,
        inner_cap: Option<ObligationOwnerCap<P>>, // None when borrowed
        strategy_type: u8,
        relayer_address: address,
    }

    /// Capability for backend to borrow the obligation cap
    public struct RelayerCap<phantom P> has key, store {
        id: UID,
        wrapped_cap_id: ID,
        strategy_type: u8,
    }

    /// Hot potato, must be consumed by return_obligation_cap
    public struct BorrowReceipt<phantom P> {
        wrapped_cap_id: ID,
        borrower: address,
    }

    // Events
    public struct CreatedStrategyOwnerCap has copy, drop {
        cap_id: address,
        obligation_id: address,
        strategy_type: u8,
    }

    #[allow(unused_field)]
    public struct EjectedInnerCap has copy, drop {
        cap_id: address,
        obligation_id: address,
    }

    public struct MigratedStrategyOwnerCap has copy, drop {
        cap_id: address,
        old_version: u64,
        new_version: u64,
    }
    
    public struct ConvertedToWrappedCap has copy, drop {
        strategy_cap_id: address,
        wrapped_cap_id: address,
        relayer_cap_id: address,
        obligation_id: address,
        strategy_type: u8,
        relayer_address: address,
    }

    public struct BorrowedObligationCap has copy, drop {
        wrapped_cap_id: address,
        obligation_id: address,
        borrower: address,
    }

    public struct ReturnedObligationCap has copy, drop {
        wrapped_cap_id: address,
        obligation_id: address,
        borrower: address,
    }

    // === Strategy Type Validation ===
    public fun is_valid_strategy_type(strategy_type: u8): bool {
        strategy_type == STRATEGY_SUI_LOOPING_SSUI ||
        strategy_type == STRATEGY_SUI_LOOPING_STRATSUI ||
        strategy_type == STRATEGY_SUI_LOOPING_USDC ||
        strategy_type == STRATEGY_SUI_LOOPING_AUSD ||
        strategy_type == STRATEGY_SUI_LOOPING_XBTC ||
        strategy_type == SLUSH_WBTC_LOOPING_XBTC ||
        (strategy_type > 0 && strategy_type <= 30)
    }

    // === Public functions ===

    // Create a new strategy owner cap with a new obligation
    public fun create_strategy_owner_cap<P>(
        lending_market: &mut LendingMarket<P>,
        strategy_type: u8,
        ctx: &mut TxContext
    ): StrategyOwnerCap<P> {
        assert!(is_valid_strategy_type(strategy_type), EInvalidStrategyType);
        
        // Create a new obligation in the lending market
        let inner_cap = lending_market::create_obligation(lending_market, ctx);
        let obligation_id = lending_market::obligation_id(&inner_cap);

        let strategy_cap = StrategyOwnerCap {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            inner_cap,
            strategy_type,
        };

        event::emit(CreatedStrategyOwnerCap {
            cap_id: object::id_address(&strategy_cap),
            obligation_id: object::id_to_address(&obligation_id),
            strategy_type: strategy_cap.strategy_type,
        });

        strategy_cap
    }

    // === Hot Potato Pattern Functions ===

    /// Convert a StrategyOwnerCap to a WrappedObligationCap + RelayerCap for hot potato pattern
    public fun convert_to_wrapped_cap<P>(
        mut strategy_cap: StrategyOwnerCap<P>,
        relayer_address: address,
        ctx: &mut TxContext
    ): (WrappedObligationCap<P>, RelayerCap<P>) {
        assert_version_and_upgrade(&mut strategy_cap);
        
        let strategy_cap_id = object::id_address(&strategy_cap);
        let obligation_id = lending_market::obligation_id(&strategy_cap.inner_cap);
        
        let StrategyOwnerCap { 
            id: strategy_id, 
            version: _, 
            inner_cap, 
            strategy_type 
        } = strategy_cap;
        
        object::delete(strategy_id);

        let wrapped_cap = WrappedObligationCap {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            inner_cap: option::some(inner_cap),
            strategy_type,
            relayer_address,
        };

        let relayer_cap = RelayerCap {
            id: object::new(ctx),
            wrapped_cap_id: object::id(&wrapped_cap),
            strategy_type,
        };

        event::emit(ConvertedToWrappedCap {
            strategy_cap_id,
            wrapped_cap_id: object::id_address(&wrapped_cap),
            relayer_cap_id: object::id_address(&relayer_cap),
            obligation_id: object::id_to_address(&obligation_id),
            strategy_type,
            relayer_address,
        });

        (wrapped_cap, relayer_cap)
    }

    /// Borrow the obligation cap for rebalancing (creates hot potato)
    #[allow(lint(prefer_mut_tx_context))]
    public fun borrow_obligation_cap<P>(
        wrapped_cap: &mut WrappedObligationCap<P>,
        relayer_cap: &RelayerCap<P>,
        ctx: &TxContext
    ): (ObligationOwnerCap<P>, BorrowReceipt<P>) {
        assert!(wrapped_cap.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(relayer_cap.wrapped_cap_id == object::id(wrapped_cap), EUnauthorizedRelayer);
        assert!(tx_context::sender(ctx) == wrapped_cap.relayer_address, EUnauthorizedRelayer);
        assert!(option::is_some(&wrapped_cap.inner_cap), EObligationCapAlreadyBorrowed);

        let inner_cap = option::extract(&mut wrapped_cap.inner_cap);
        let obligation_id = lending_market::obligation_id(&inner_cap);
        let borrower = tx_context::sender(ctx);

        let receipt = BorrowReceipt {
            wrapped_cap_id: object::id(wrapped_cap),
            borrower,
        };

        event::emit(BorrowedObligationCap {
            wrapped_cap_id: object::id_address(wrapped_cap),
            obligation_id: object::id_to_address(&obligation_id),
            borrower,
        });

        (inner_cap, receipt)
    }

    /// Return the obligation cap (consumes hot potato)
    #[allow(lint(prefer_mut_tx_context))]
    public fun return_obligation_cap<P>(
        wrapped_cap: &mut WrappedObligationCap<P>,
        inner_cap: ObligationOwnerCap<P>,
        receipt: BorrowReceipt<P>,
        ctx: &TxContext
    ) {
        assert!(wrapped_cap.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(receipt.wrapped_cap_id == object::id(wrapped_cap), EUnauthorizedRelayer);
        assert!(tx_context::sender(ctx) == receipt.borrower, EUnauthorizedRelayer);
        assert!(option::is_none(&wrapped_cap.inner_cap), EObligationCapNotBorrowed);

        let obligation_id = lending_market::obligation_id(&inner_cap);
        
        option::fill(&mut wrapped_cap.inner_cap, inner_cap);
        
        let BorrowReceipt { wrapped_cap_id: _, borrower } = receipt;

        event::emit(ReturnedObligationCap {
            wrapped_cap_id: object::id_address(wrapped_cap),
            obligation_id: object::id_to_address(&obligation_id),
            borrower,
        });
    }

    /// Convert back to StrategyOwnerCap (for user to regain full control)
    #[allow(unused_let_mut)]
    public fun convert_back_to_strategy_cap<P>(
        mut wrapped_cap: WrappedObligationCap<P>,
        relayer_cap: RelayerCap<P>,
        ctx: &mut TxContext
    ): StrategyOwnerCap<P> {
        assert!(wrapped_cap.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(relayer_cap.wrapped_cap_id == object::id(&wrapped_cap), EUnauthorizedRelayer);
        assert!(option::is_some(&wrapped_cap.inner_cap), EObligationCapAlreadyBorrowed);

        let WrappedObligationCap { 
            id: wrapped_id, 
            version: _, 
            inner_cap, 
            strategy_type, 
            relayer_address: _ 
        } = wrapped_cap;
        
        let RelayerCap { 
            id: relayer_id, 
            wrapped_cap_id: _, 
            strategy_type: _ 
        } = relayer_cap;

        let inner_cap = option::destroy_some(inner_cap);
        object::delete(wrapped_id);
        object::delete(relayer_id);

        StrategyOwnerCap {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            inner_cap,
            strategy_type,
        }
    }

    // ===  Public Functions  ===

    // View functions
    public fun get_strategy_type<P>(cap: &StrategyOwnerCap<P>): u8 {
        assert_current_version(cap);
        cap.strategy_type
    }

    public fun get_version<P>(cap: &StrategyOwnerCap<P>): u64 {
        cap.version
    }

    // Getter for the inner obligation cap
    public fun inner_cap<P>(cap: &StrategyOwnerCap<P>): &ObligationOwnerCap<P> {
        assert_current_version(cap);
        &cap.inner_cap
    }

    // Get the obligation ID from the strategy cap
    public fun obligation_id<P>(cap: &StrategyOwnerCap<P>): ID {
        assert_current_version(cap);
        lending_market::obligation_id(&cap.inner_cap)
    }

    // Get a reference to the obligation from the lending market
    public fun get_obligation<P>(
        cap: &StrategyOwnerCap<P>,
        lending_market: &LendingMarket<P>
    ): &Obligation<P> {
        assert_current_version(cap);
        let obligation_id = lending_market::obligation_id(&cap.inner_cap);
        lending_market::obligation(lending_market, obligation_id)
    }

    // === New View Functions for Wrapped Cap ===

    public fun wrapped_cap_strategy_type<P>(cap: &WrappedObligationCap<P>): u8 {
        cap.strategy_type
    }

    public fun wrapped_cap_version<P>(cap: &WrappedObligationCap<P>): u64 {
        cap.version
    }

    public fun wrapped_cap_relayer_address<P>(cap: &WrappedObligationCap<P>): address {
        cap.relayer_address
    }

    public fun wrapped_cap_is_borrowed<P>(cap: &WrappedObligationCap<P>): bool {
        option::is_none(&cap.inner_cap)
    }

    public fun relayer_cap_wrapped_id<P>(cap: &RelayerCap<P>): ID {
        cap.wrapped_cap_id
    }

    public fun relayer_cap_strategy_type<P>(cap: &RelayerCap<P>): u8 {
        cap.strategy_type
    }

    // Helper functions for dynamic field access with auto-migration
    public(package) fun borrow_uid_mut<P>(cap: &mut StrategyOwnerCap<P>): &mut UID {
        assert_version_and_upgrade(cap);
        &mut cap.id
    }

    // Read-only UID access doesn't need migration
    public(package) fun borrow_uid<P>(cap: &StrategyOwnerCap<P>): &UID {
        assert_current_version(cap);
        &cap.id
    }

    // === Auto-Migration Functions ===
    
    /// Automatically migrate a strategy owner cap to the current version if needed
    fun auto_migrate<P>(strategy_cap: &mut StrategyOwnerCap<P>) {
        if (strategy_cap.version < CURRENT_VERSION) {
            let old_version = strategy_cap.version;
            strategy_cap.version = CURRENT_VERSION;
            
            event::emit(MigratedStrategyOwnerCap {
                cap_id: object::id_address(strategy_cap),
                old_version,
                new_version: CURRENT_VERSION,
            });
        }
    }

    /// Assert that the strategy cap is at the current version, auto-migrating if needed
    fun assert_version_and_upgrade<P>(strategy_cap: &mut StrategyOwnerCap<P>) {
        auto_migrate(strategy_cap);
        assert!(strategy_cap.version == CURRENT_VERSION, EIncorrectVersion);
    }

    /// Assert that the strategy cap is at the current version (read-only check)
    public fun assert_current_version<P>(cap: &StrategyOwnerCap<P>) {
        assert!(cap.version == CURRENT_VERSION, EIncorrectVersion);
    }

    // === Convenience Functions for PTB Compatibility ===
    
    /// Deposit liquidity and mint cTokens, then deposit into the strategy's obligation
    /// This is PTB-compatible since it doesn't expose references
    public fun deposit_liquidity_and_deposit_into_obligation<P, T>(
        strategy_cap: &StrategyOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        deposit: Coin<T>,
        ctx: &mut TxContext,
    ) {
        assert_current_version(strategy_cap);
        
        // First mint cTokens
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<P, T>(
            lending_market,
            reserve_array_index,
            clock,
            deposit,
            ctx,
        );
        
        // Then deposit cTokens into obligation using our inner cap
        lending_market::deposit_ctokens_into_obligation<P, T>(
            lending_market,
            reserve_array_index,
            &strategy_cap.inner_cap,
            clock,
            ctokens,
            ctx,
        );
        
    }
    
    /// Borrow from the strategy's obligation
    public fun borrow_from_obligation<P, T>(
        strategy_cap: &StrategyOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        amount: u64,
        ctx: &mut TxContext,
    ): Coin<T> {
        assert_current_version(strategy_cap);
        
        lending_market::borrow<P, T>(
            lending_market,
            reserve_array_index,
            &strategy_cap.inner_cap,
            clock,
            amount,
            ctx,
        )
    }

    /// Borrow SUI from the strategy's obligation (handles staker unstaking)
    public fun borrow_sui_from_obligation<P>(
        strategy_cap: &StrategyOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        amount: u64,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext,
    ): Coin<SUI> {
        assert_current_version(strategy_cap);
        
        // Create the borrow request first
        let liquidity_request = lending_market::borrow_request<P, SUI>(
            lending_market,
            reserve_array_index,
            &strategy_cap.inner_cap,
            clock,
            amount,
        );
        
        // Unstake from staker if needed to ensure liquidity
        lending_market::unstake_sui_from_staker<P>(
            lending_market,
            reserve_array_index,
            &liquidity_request,
            system_state,
            ctx,
        );
        
        // Fulfill the liquidity request
        lending_market::fulfill_liquidity_request<P, SUI>(
            lending_market,
            reserve_array_index,
            liquidity_request,
            ctx,
        )
    }

    /// Withdraw cTokens from obligation and redeem for underlying asset
    public fun withdraw_from_obligation_and_redeem<P, T>(
        strategy_cap: &StrategyOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        ctoken_amount: u64,
        ctx: &mut TxContext,
    ): Coin<T> {
        assert_current_version(strategy_cap);
        
        // First withdraw cTokens from obligation
        let ctokens = lending_market::withdraw_ctokens<P, T>(
            lending_market,
            reserve_array_index,
            &strategy_cap.inner_cap,
            clock,
            ctoken_amount,
            ctx,
        );
        
        // Then redeem cTokens for underlying asset
        lending_market::redeem_ctokens_and_withdraw_liquidity<P, T>(
            lending_market,
            reserve_array_index,
            clock,
            ctokens,
            option::none<RateLimiterExemption<P, T>>(),
            ctx,
        )
    }

    /// Withdraw cTokens from obligation (without redeeming)
    public fun withdraw_ctokens_from_obligation<P, T>(
        strategy_cap: &StrategyOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        ctoken_amount: u64,
        ctx: &mut TxContext,
    ): Coin<CToken<P, T>> {
        assert_current_version(strategy_cap);
        
        lending_market::withdraw_ctokens<P, T>(
            lending_market,
            reserve_array_index,
            &strategy_cap.inner_cap,
            clock,
            ctoken_amount,
            ctx,
        )
    }

    /// Deposit cTokens directly into obligation (for when you already have cTokens)
    public fun deposit_ctokens_into_obligation<P, T>(
        strategy_cap: &StrategyOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        ctokens: Coin<CToken<P, T>>,
        ctx: &mut TxContext,
    ) {
        assert_current_version(strategy_cap);
        
        lending_market::deposit_ctokens_into_obligation<P, T>(
            lending_market,
            reserve_array_index,
            &strategy_cap.inner_cap,
            clock,
            ctokens,
            ctx,
        )
    }

    /// Mint cTokens from underlying asset (without depositing into obligation)
    public fun mint_ctokens<P, T>(
        strategy_cap: &StrategyOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        deposit: Coin<T>,
        ctx: &mut TxContext,
    ): Coin<CToken<P, T>> {
        assert_current_version(strategy_cap);
        
        lending_market::deposit_liquidity_and_mint_ctokens<P, T>(
            lending_market,
            reserve_array_index,
            clock,
            deposit,
            ctx,
        )
    }

    /// Redeem cTokens for underlying asset (without withdrawing from obligation)
    public fun redeem_ctokens<P, T>(
        strategy_cap: &StrategyOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        ctokens: Coin<CToken<P, T>>,
        ctx: &mut TxContext,
    ): Coin<T> {
        assert_current_version(strategy_cap);
        
        lending_market::redeem_ctokens_and_withdraw_liquidity<P, T>(
            lending_market,
            reserve_array_index,
            clock,
            ctokens,
            option::none<RateLimiterExemption<P, T>>(),
            ctx,
        )
    }

    /// Claim rewards from the strategy's obligation
    public fun claim_rewards<P, T>(
        strategy_cap: &StrategyOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        clock: &Clock,
        reserve_id: u64,
        reward_index: u64,
        is_deposit_reward: bool,
        ctx: &mut TxContext,
    ): Coin<T> {
        assert_current_version(strategy_cap);
        
        lending_market::claim_rewards<P, T>(
            lending_market,
            &strategy_cap.inner_cap,
            clock,
            reserve_id,
            reward_index,
            is_deposit_reward,
            ctx,
        )
    }

    // === Test Functions ===
    #[test_only]
    public fun destroy_for_testing<P>(strategy_cap: StrategyOwnerCap<P>) {
        let StrategyOwnerCap { id, version: _, inner_cap, strategy_type: _ } = strategy_cap;
        object::delete(id);
        lending_market::destroy_for_testing(inner_cap);
    }

    #[test_only]
    public fun destroy_wrapped_cap_for_testing<P>(wrapped_cap: WrappedObligationCap<P>) {
        let WrappedObligationCap { id, version: _, inner_cap, strategy_type: _, relayer_address: _ } = wrapped_cap;
        if (option::is_some(&inner_cap)) {
            lending_market::destroy_for_testing(option::destroy_some(inner_cap));
        } else {
            option::destroy_none(inner_cap);
        };
        object::delete(id);
    }

    #[test_only]
    public fun destroy_relayer_cap_for_testing<P>(relayer_cap: RelayerCap<P>) {
        let RelayerCap { id, wrapped_cap_id: _, strategy_type: _ } = relayer_cap;
        object::delete(id);
    }
} 
