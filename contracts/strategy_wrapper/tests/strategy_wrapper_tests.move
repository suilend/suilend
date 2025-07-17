#[test_only]
module strategy_wrapper::strategy_wrapper_tests {
    use std::ascii::{Self};
    use std::type_name;
    use sui::clock::{Self, Clock};
    use sui::test_utils::{Self};
    use sui::bag::{Self};
    use sui::test_scenario::{Self};
    use suilend::lending_market::{Self,
        LendingMarket,
        ObligationOwnerCap};
    use suilend::reserve_config::{Self, default_reserve_config};
    use strategy_wrapper::strategy_wrapper::{Self};
    use suilend::lending_market_tests::{Self, LENDING_MARKET};
    use suilend::test_usdc::TEST_USDC;

    #[test_only]
    public fun setup(ctx: &mut TxContext): (LendingMarket<LENDING_MARKET>, ObligationOwnerCap<LENDING_MARKET>, Clock) {
        let mut reserve_args = bag::new(ctx);
           bag::add(
               &mut reserve_args,
               type_name::get<TEST_USDC>(),
               lending_market_tests::new_args(100 * 1_000_000, default_reserve_config(ctx))
           );

        let state = lending_market_tests::setup(reserve_args, ctx);
        let (clock, _owner_cap, mut lending_market, prices, type_to_index) = lending_market_tests::destruct_state(state);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        
        let obligation_cap = lending_market::create_obligation(&mut lending_market, ctx);
        test_utils::destroy(_owner_cap);
        
        (lending_market, obligation_cap, clock)
    }

    #[test]
    fun test_create_strategy_owner_cap() {
        let mut scenario = test_scenario::begin(@0x1);
        let (lending_market, obligation_cap, clock) = setup(scenario.ctx());
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(
            obligation_cap, 
            1, // STRATEGY_SUI_LOOPING_SSUI
            scenario.ctx()
        );
        
        // Check version is set correctly
        assert!(strategy_wrapper::get_version(&strategy_cap) == 1, 0);
        assert!(!strategy_wrapper::needs_migration(&strategy_cap), 1);
        
        // Check strategy type is set correctly
        assert!(strategy_wrapper::get_strategy_type(&strategy_cap) == 1, 2);
        
        // Cleanup
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_for_testing(strategy_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_strategy_types() {
        let mut scenario = test_scenario::begin(@0x1);
        let (lending_market1, obligation_cap1, clock1) = setup(scenario.ctx());
        let (lending_market2, obligation_cap2, clock2) = setup(scenario.ctx());
        
        // Test creating strategies with different types
        let sui_strategy = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(obligation_cap1, 1, scenario.ctx());
        let btc_strategy = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(obligation_cap2, 2, scenario.ctx());
        
        // Verify strategy types
        assert!(strategy_wrapper::get_strategy_type(&sui_strategy) == 1, 0);
        assert!(strategy_wrapper::get_strategy_type(&btc_strategy) == 2, 1);
        
        // Cleanup
        test_utils::destroy(lending_market1);
        test_utils::destroy(lending_market2);
        strategy_wrapper::destroy_for_testing(sui_strategy);
        strategy_wrapper::destroy_for_testing(btc_strategy);
        clock::destroy_for_testing(clock1);
        clock::destroy_for_testing(clock2);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)] // EInvalidStrategyType
    fun test_invalid_strategy_type() {
        let mut scenario = test_scenario::begin(@0x1);
        let (lending_market, obligation_cap, clock) = setup(scenario.ctx());
        
        // Try to create with invalid strategy type (99)
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(
            obligation_cap, 
            99, // Invalid strategy type
            scenario.ctx()
        );
        
        // Should never reach here
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_for_testing(strategy_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_strategy_type_validation() {
        // Test valid strategy types
        assert!(strategy_wrapper::is_valid_strategy_type(1), 0); // SUI looping
        assert!(strategy_wrapper::is_valid_strategy_type(2), 1); // BTC looping
        
        // Test invalid strategy types
        assert!(!strategy_wrapper::is_valid_strategy_type(0), 2);
        assert!(!strategy_wrapper::is_valid_strategy_type(99), 3);
        assert!(!strategy_wrapper::is_valid_strategy_type(255), 4);
    }

    #[test]
    fun test_eject() {
        let mut scenario = test_scenario::begin(@0x1);
        let (lending_market, obligation_cap, clock) = setup(scenario.ctx());
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(obligation_cap, 1, scenario.ctx());
        strategy_wrapper::eject<LENDING_MARKET>(strategy_cap, scenario.ctx());

        // Cleanup
        test_utils::destroy(lending_market);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_version_control() {
        let mut scenario = test_scenario::begin(@0x1);
        let (lending_market, obligation_cap, clock) = setup(scenario.ctx());
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(obligation_cap, 1, scenario.ctx());
        
        // Check initial version
        assert!(strategy_wrapper::get_version(&strategy_cap) == 1, 0);
        assert!(!strategy_wrapper::needs_migration(&strategy_cap), 1);
        
        // Test assert_current_version doesn't fail
        strategy_wrapper::assert_current_version(&strategy_cap);
        
        // Cleanup
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_for_testing(strategy_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }
}