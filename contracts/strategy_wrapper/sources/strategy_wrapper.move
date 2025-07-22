module strategy_wrapper::strategy_wrapper {
    use sui::event;
    use suilend::lending_market::{Self, ObligationOwnerCap};

    // === Errors ===
    const EIncorrectVersion: u64 = 1;
    const EInvalidStrategyType: u64 = 2;

    // === Constants ===
    const CURRENT_VERSION: u64 = 1;

    // === Strategy Type Constants ===
    const STRATEGY_SUI_LOOPING_SSUI: u8 = 1;
    const STRATEGY_BTC_LOOPING_WBTC: u8 = 2;

    // Structs
    public struct StrategyOwnerCap<phantom P> has key, store {
        id: UID,
        version: u64,
        inner_cap: ObligationOwnerCap<P>,
        strategy_type: u8,
    }

    // Events
    public struct CreatedStrategyOwnerCap has copy, drop {
        cap_id: address,
        obligation_id: address,
        strategy_type: u8,
    }

    public struct EjectedInnerCap has copy, drop {
        cap_id: address,
        obligation_id: address,
    }

    public struct MigratedStrategyOwnerCap has copy, drop {
        cap_id: address,
        old_version: u64,
        new_version: u64,
    }

    // === Strategy Type Validation ===
    public fun is_valid_strategy_type(strategy_type: u8): bool {
        strategy_type == STRATEGY_SUI_LOOPING_SSUI ||
        strategy_type == STRATEGY_BTC_LOOPING_WBTC 
    }

    // === Public functions ===

    // Create a new strategy owner cap
    public fun create_strategy_owner_cap<P>(
        inner_cap: ObligationOwnerCap<P>,
        strategy_type: u8,
        ctx: &mut TxContext
    ): StrategyOwnerCap<P> {
        assert!(is_valid_strategy_type(strategy_type), EInvalidStrategyType);
        
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

    // ===  Public Functions  ===

    // Eject the strategy owner cap and return the inner obligation cap
    public fun eject<P>(
        mut strategy_cap: StrategyOwnerCap<P>,
        _ctx: &TxContext
    ): ObligationOwnerCap<P> {
        assert_version_and_upgrade(&mut strategy_cap);
        
        let StrategyOwnerCap { id, version: _, inner_cap, strategy_type: _ } = strategy_cap;
        let cap_id_addr = object::uid_to_address(&id);
        let obligation_id_addr = object::id_to_address(&lending_market::obligation_id(&inner_cap));
        object::delete(id);
        
        event::emit(EjectedInnerCap {
            cap_id: cap_id_addr,
            obligation_id: obligation_id_addr,
        });
        
        inner_cap
    }

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

    // Helper functions for dynamic field access with auto-migration
    public(package) fun borrow_uid_mut<P>(cap: &mut StrategyOwnerCap<P>): &mut UID {
        assert_version_and_upgrade(cap);
        &mut cap.id
    }

    // Read-only UID access doesn't need migration
    public fun borrow_uid<P>(cap: &StrategyOwnerCap<P>): &UID {
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

    // === Test Functions ===
    #[test_only]
    public fun destroy_for_testing<P>(strategy_cap: StrategyOwnerCap<P>) {
        let StrategyOwnerCap { id, version: _, inner_cap, strategy_type: _ } = strategy_cap;
        object::delete(id);
        lending_market::destroy_for_testing(inner_cap);
    }
} 