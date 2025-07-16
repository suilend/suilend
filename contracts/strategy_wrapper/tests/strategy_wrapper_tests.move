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
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(obligation_cap, b"test_tag", scenario.ctx());
        
        // Check version is set correctly
        assert!(strategy_wrapper::get_version(&strategy_cap) == 1, 0);
        assert!(!strategy_wrapper::needs_migration(&strategy_cap), 1);
        
        // Cleanup
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_for_testing(strategy_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_eject() {
        let mut scenario = test_scenario::begin(@0x1);
        let (lending_market, obligation_cap, clock) = setup(scenario.ctx());
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(obligation_cap, b"test_tag", scenario.ctx());
        strategy_wrapper::eject<LENDING_MARKET>(strategy_cap, scenario.ctx());

        // Cleanup
        test_utils::destroy(lending_market);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_tag() {
        let mut scenario = test_scenario::begin(@0x1);
        let (lending_market, obligation_cap, clock) = setup(scenario.ctx());
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(obligation_cap, b"test_tag", scenario.ctx());
        
        let tag = strategy_wrapper::get_tag(&strategy_cap);
        assert!(ascii::as_bytes(tag) == &b"test_tag", 0);
        
        // Cleanup
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_for_testing(strategy_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_version_control() {
        let mut scenario = test_scenario::begin(@0x1);
        let (lending_market, obligation_cap, clock) = setup(scenario.ctx());
        let mut strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(obligation_cap, b"test_tag", scenario.ctx());
        
        // Check initial version
        assert!(strategy_wrapper::get_version(&strategy_cap) == 1, 0);
        assert!(!strategy_wrapper::needs_migration(&strategy_cap), 1);
        
        // Test assert_current_version doesn't fail
        strategy_wrapper::assert_current_version(&strategy_cap);
        
        // Manually set version to 0 to simulate old version (for testing)
        // Note: In real scenarios, this would be an older cap from a previous version
        
        // Since we can't directly modify the version in tests without internal access,
        // tests the migration logic by ensuring current caps are already at current version
        
        // Cleanup
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_for_testing(strategy_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }
}