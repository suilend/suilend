module strategy_wrapper::strategy_wrapper {
    use std::ascii::{Self, String};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use suilend::lending_market::{Self, ObligationOwnerCap};

    // === Errors ===
    const EIncorrectVersion: u64 = 1;

    // === Constants ===
    const CURRENT_VERSION: u64 = 1;

    // Structs
    public struct StrategyOwnerCap<phantom P> has key, store {
        id: UID,
        version: u64,
        inner_cap: ObligationOwnerCap<P>,
        tag: String,
    }

    // Events
    public struct CreatedStrategyOwnerCap has copy, drop {
        cap_id: address,
        obligation_id: address,
        tag: String,
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

    // Public functions
    public fun create_strategy_owner_cap<P>(
        inner_cap: ObligationOwnerCap<P>,
        tag: vector<u8>,
        ctx: &mut TxContext
    ): StrategyOwnerCap<P> {
        let obligation_id = lending_market::obligation_id(&inner_cap);

        let strategy_cap = StrategyOwnerCap {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            inner_cap,
            tag: ascii::string(tag),
        };

        event::emit(CreatedStrategyOwnerCap {
            cap_id: object::id_address(&strategy_cap),
            obligation_id: object::id_to_address(&obligation_id),
            tag: strategy_cap.tag,
        });

        strategy_cap
    }

    public entry fun eject<P>(
        strategy_cap: StrategyOwnerCap<P>,
        ctx: &TxContext
    ) {
        assert!(strategy_cap.version == CURRENT_VERSION, EIncorrectVersion);
        
        let StrategyOwnerCap { id, version: _, inner_cap, tag: _ } = strategy_cap;
        let cap_id_addr = object::uid_to_address(&id);
        let obligation_id_addr = object::id_to_address(&lending_market::obligation_id(&inner_cap));
        object::delete(id);
        transfer::public_transfer(inner_cap, tx_context::sender(ctx));
        event::emit(EjectedInnerCap {
            cap_id: cap_id_addr,
            obligation_id: obligation_id_addr,
        });
    }

    // View functions
    public fun get_tag<P>(cap: &StrategyOwnerCap<P>): &String {
        &cap.tag
    }

    public fun get_version<P>(cap: &StrategyOwnerCap<P>): u64 {
        cap.version
    }

    // Getter for the inner obligation cap
    public fun inner_cap<P>(cap: &StrategyOwnerCap<P>): &ObligationOwnerCap<P> {
        &cap.inner_cap
    }

    // === Migration Functions ===
    
    /// Migrate a strategy owner cap to the current version
    public entry fun migrate<P>(strategy_cap: &mut StrategyOwnerCap<P>) {
        assert!(strategy_cap.version <= CURRENT_VERSION - 1, EIncorrectVersion);
        
        let old_version = strategy_cap.version;
        strategy_cap.version = CURRENT_VERSION;
        
        event::emit(MigratedStrategyOwnerCap {
            cap_id: object::id_address(strategy_cap),
            old_version,
            new_version: CURRENT_VERSION,
        });
    }

    /// Check if a strategy cap needs migration
    public fun needs_migration<P>(cap: &StrategyOwnerCap<P>): bool {
        cap.version < CURRENT_VERSION
    }

    /// Assert that the strategy cap is at the current version
    public fun assert_current_version<P>(cap: &StrategyOwnerCap<P>) {
        assert!(cap.version == CURRENT_VERSION, EIncorrectVersion);
    }

    // === Test Functions ===
    #[test_only]
    public fun destroy_for_testing<P>(strategy_cap: StrategyOwnerCap<P>) {
        let StrategyOwnerCap { id, version: _, inner_cap, tag: _ } = strategy_cap;
        object::delete(id);
        lending_market::destroy_for_testing(inner_cap);
    }
} 