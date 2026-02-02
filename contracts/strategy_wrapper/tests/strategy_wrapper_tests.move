#[test_only]
module strategy_wrapper::strategy_wrapper_tests {
    use std::type_name;
    use sui::clock::{Self, Clock};
    use sui::test_utils::{Self};
    use sui::bag::{Self};
    use sui::test_scenario::{Self};
    use suilend::lending_market::{Self,
        LendingMarket,
        ObligationOwnerCap};
    use suilend::reserve_config::{default_reserve_config};
    use strategy_wrapper::strategy_wrapper;
    use suilend::lending_market_tests::{Self, LENDING_MARKET};
    use suilend::test_usdc::TEST_USDC;

    const ALICE: address = @0xa11ce;
    const BACKEND: address = @0xbac;
    const EVIL: address = @0xe11;

    #[error]
    const EShouldNotReach: u64 = 0;

    #[test_only]
    public fun setup(ctx: &mut TxContext): (LendingMarket<LENDING_MARKET>, ObligationOwnerCap<LENDING_MARKET>, Clock) {
        let mut reserve_args = bag::new(ctx);
           bag::add(
               &mut reserve_args,
               type_name::with_defining_ids<TEST_USDC>(),
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
        let (mut lending_market, obligation_cap, clock) = setup(scenario.ctx());
        test_utils::destroy(obligation_cap); // Don't need this anymore
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(
            &mut lending_market, 
            1, // STRATEGY_SUI_LOOPING_SSUI
            scenario.ctx()
        );
        
        // Check version is set correctly
        assert!(strategy_wrapper::get_version(&strategy_cap) == 1);
        
        // Check strategy type is set correctly
        assert!(strategy_wrapper::get_strategy_type(&strategy_cap) == 1);
        
        // Cleanup
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_for_testing(strategy_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_strategy_types() {
        let mut scenario = test_scenario::begin(@0x1);
        let (mut lending_market1, obligation_cap1, clock1) = setup(scenario.ctx());
        let (mut lending_market2, obligation_cap2, clock2) = setup(scenario.ctx());
        test_utils::destroy(obligation_cap1); // Don't need these anymore
        test_utils::destroy(obligation_cap2);
        
        // Test creating strategies with different types
        let sui_strategy = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(&mut lending_market1, 1, scenario.ctx());
        let btc_strategy = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(&mut lending_market2, 2, scenario.ctx());
        
        // Verify strategy types
        assert!(strategy_wrapper::get_strategy_type(&sui_strategy) == 1);
        assert!(strategy_wrapper::get_strategy_type(&btc_strategy) == 2);
        
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
    #[expected_failure(abort_code = strategy_wrapper::EInvalidStrategyType)]
    fun test_invalid_strategy_type() {
        let mut scenario = test_scenario::begin(@0x1);
        let (mut lending_market, obligation_cap, clock) = setup(scenario.ctx());
        test_utils::destroy(obligation_cap); // Don't need this anymore
        
        // Try to create with invalid strategy type (99)
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(
            &mut lending_market, 
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
        assert!(strategy_wrapper::is_valid_strategy_type(1)); // SUI looping
        assert!(strategy_wrapper::is_valid_strategy_type(2)); // BTC looping
        
        // Test invalid strategy types
        assert!(!strategy_wrapper::is_valid_strategy_type(0));
        assert!(!strategy_wrapper::is_valid_strategy_type(99));
        assert!(!strategy_wrapper::is_valid_strategy_type(255));
    }

    #[test]
    fun test_version_control() {
        let mut scenario = test_scenario::begin(@0x1);
        let (mut lending_market, obligation_cap, clock) = setup(scenario.ctx());
        test_utils::destroy(obligation_cap); // Don't need this anymore
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(&mut lending_market, 1, scenario.ctx());
        
        // Check initial version
        assert!(strategy_wrapper::get_version(&strategy_cap) == 1);
        
        // Test assert_current_version doesn't fail
        strategy_wrapper::assert_current_version(&strategy_cap);
        
        // Cleanup
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_for_testing(strategy_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_auto_migration_functionality() {
        let mut scenario = test_scenario::begin(@0x1);
        let (mut lending_market, obligation_cap, clock) = setup(scenario.ctx());
        test_utils::destroy(obligation_cap); // Don't need this anymore
        let mut strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(&mut lending_market, 1, scenario.ctx());
        
        // Test that functions work regardless of version (auto-migration)
        let initial_version = strategy_wrapper::get_version(&strategy_cap);
        assert!(initial_version == 1);
        
        // Test mutable access (which would trigger auto-migration if needed)
        let _uid = strategy_wrapper::borrow_uid_mut(&mut strategy_cap);
        
        // Version should still be current after auto-migration check
        assert!(strategy_wrapper::get_version(&strategy_cap) == 1);
        
        // Test read-only access
        let _uid_readonly = strategy_wrapper::borrow_uid(&strategy_cap);
        let _inner_cap = strategy_wrapper::inner_cap(&strategy_cap);
        let _strategy_type = strategy_wrapper::get_strategy_type(&strategy_cap);
        
        // Cleanup
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_for_testing(strategy_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    // === HOT POTATO PATTERN TESTS ===

    #[test]
    fun test_convert_to_wrapped_cap() {
        let mut scenario = test_scenario::begin(ALICE);
        let (mut lending_market, obligation_cap, clock) = setup(scenario.ctx());
        test_utils::destroy(obligation_cap); // Don't need this anymore
        
        // Create strategy owner cap
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(
            &mut lending_market, 
            1, // STRATEGY_SUI_LOOPING_SSUI
            scenario.ctx()
        );
        
        // Convert to wrapped cap
        let (wrapped_cap, relayer_cap) = strategy_wrapper::convert_to_wrapped_cap<LENDING_MARKET>(
            strategy_cap,
            BACKEND,
            scenario.ctx()
        );
        
        // Verify wrapped cap properties
        assert!(strategy_wrapper::wrapped_cap_strategy_type(&wrapped_cap) == 1);
        assert!(strategy_wrapper::wrapped_cap_relayer_address(&wrapped_cap) == BACKEND);
        assert!(!strategy_wrapper::wrapped_cap_is_borrowed(&wrapped_cap));
        assert!(strategy_wrapper::wrapped_cap_version(&wrapped_cap) == 1);
        
        // Verify relayer cap properties
        assert!(strategy_wrapper::relayer_cap_strategy_type(&relayer_cap) == 1);
        assert!(strategy_wrapper::relayer_cap_wrapped_id(&relayer_cap) == object::id(&wrapped_cap));
        
        // Cleanup
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_wrapped_cap_for_testing(wrapped_cap);
        strategy_wrapper::destroy_relayer_cap_for_testing(relayer_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_wrapped_cap_properties() {
        let mut scenario = test_scenario::begin(ALICE);
        let (mut lending_market, obligation_cap, clock) = setup(scenario.ctx());
        test_utils::destroy(obligation_cap); // Don't need this anymore
        
        // Create and convert to wrapped cap
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(&mut lending_market, 1, scenario.ctx());
        let (wrapped_cap, relayer_cap) = strategy_wrapper::convert_to_wrapped_cap<LENDING_MARKET>(
            strategy_cap,
            BACKEND,
            scenario.ctx()
        );
        
        // Verify wrapped cap properties without borrowing/returning
        assert!(strategy_wrapper::wrapped_cap_strategy_type(&wrapped_cap) == 1);
        assert!(strategy_wrapper::wrapped_cap_relayer_address(&wrapped_cap) == BACKEND);
        assert!(!strategy_wrapper::wrapped_cap_is_borrowed(&wrapped_cap));
        assert!(strategy_wrapper::wrapped_cap_version(&wrapped_cap) == 1);
        
        // Verify relayer cap properties
        assert!(strategy_wrapper::relayer_cap_strategy_type(&relayer_cap) == 1);
        assert!(strategy_wrapper::relayer_cap_wrapped_id(&relayer_cap) == object::id(&wrapped_cap));
        
        // Cleanup
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_wrapped_cap_for_testing(wrapped_cap);
        strategy_wrapper::destroy_relayer_cap_for_testing(relayer_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = strategy_wrapper::EUnauthorizedRelayer)]
    fun test_unauthorized_relayer_borrow() {
        let mut scenario = test_scenario::begin(ALICE);
        let (mut lending_market, obligation_cap, clock) = setup(scenario.ctx());
        test_utils::destroy(obligation_cap); // Don't need this anymore
        
        // Create and convert to wrapped cap
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(&mut lending_market, 1, scenario.ctx());
        let (mut wrapped_cap, relayer_cap) = strategy_wrapper::convert_to_wrapped_cap<LENDING_MARKET>(
            strategy_cap,
            BACKEND,
            scenario.ctx()
        );
        
        // Evil user tries to borrow with wrong address - this should abort before returning values
        test_scenario::next_tx(&mut scenario, EVIL);
        let (borrowed_cap, receipt) = strategy_wrapper::borrow_obligation_cap<LENDING_MARKET>(
            &mut wrapped_cap,
            &relayer_cap,
            scenario.ctx()
        );
        
        // This shouldn't be reached, but if it is, clean up properly
        strategy_wrapper::return_obligation_cap<LENDING_MARKET>(
            &mut wrapped_cap,
            borrowed_cap,
            receipt,
            scenario.ctx()
        );
        
        // Cleanup (won't be reached due to expected failure)
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_wrapped_cap_for_testing(wrapped_cap);
        strategy_wrapper::destroy_relayer_cap_for_testing(relayer_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = strategy_wrapper::EObligationCapAlreadyBorrowed)]
    fun test_double_borrow_fails() {
        let mut scenario = test_scenario::begin(ALICE);
        let (mut lending_market, obligation_cap, clock) = setup(scenario.ctx());
        test_utils::destroy(obligation_cap); // Don't need this anymore
        
        // Create and convert to wrapped cap
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(&mut lending_market, 1, scenario.ctx());
        let (mut wrapped_cap, relayer_cap) = strategy_wrapper::convert_to_wrapped_cap<LENDING_MARKET>(
            strategy_cap,
            BACKEND,
            scenario.ctx()
        );
        
        // Change to backend context
        test_scenario::next_tx(&mut scenario, BACKEND);
        
        // First borrow - should succeed
        let (obligation_cap, receipt) = strategy_wrapper::borrow_obligation_cap<LENDING_MARKET>(
            &mut wrapped_cap,
            &relayer_cap,
            scenario.ctx()
        );
        
        // Try to borrow again - should fail and abort
        let (obligation_cap2, receipt2) = strategy_wrapper::borrow_obligation_cap<LENDING_MARKET>(
            &mut wrapped_cap,
            &relayer_cap,
            scenario.ctx()
        );
        
        // This shouldn't be reached, but if it is, clean up properly
        strategy_wrapper::return_obligation_cap(&mut wrapped_cap, obligation_cap2, receipt2, scenario.ctx());
        strategy_wrapper::return_obligation_cap(&mut wrapped_cap, obligation_cap, receipt, scenario.ctx());
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_wrapped_cap_for_testing(wrapped_cap);
        strategy_wrapper::destroy_relayer_cap_for_testing(relayer_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    // Note: Cannot test return_without_borrow because BorrowReceipt is a hot potato
    // and cannot be created independently - this is the intended security feature

    #[test]
    fun test_convert_back_to_strategy_cap() {
        let mut scenario = test_scenario::begin(ALICE);
        let (mut lending_market, obligation_cap, clock) = setup(scenario.ctx());
        test_utils::destroy(obligation_cap); // Don't need this anymore
        
        // Create and convert to wrapped cap
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(&mut lending_market, 1, scenario.ctx());
        let original_strategy_type = strategy_wrapper::get_strategy_type(&strategy_cap);
        
        let (wrapped_cap, relayer_cap) = strategy_wrapper::convert_to_wrapped_cap<LENDING_MARKET>(
            strategy_cap,
            BACKEND,
            scenario.ctx()
        );
        
        // Convert back to strategy cap
        let restored_strategy_cap = strategy_wrapper::convert_back_to_strategy_cap<LENDING_MARKET>(
            wrapped_cap,
            relayer_cap,
            scenario.ctx()
        );
        
        // Verify it's back to normal
        assert!(strategy_wrapper::get_strategy_type(&restored_strategy_cap) == original_strategy_type);
        assert!(strategy_wrapper::get_version(&restored_strategy_cap) == 1);
        
        // Cleanup
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_for_testing(restored_strategy_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = strategy_wrapper::EObligationCapAlreadyBorrowed)]
    fun test_convert_back_while_borrowed_fails() {
        let mut scenario = test_scenario::begin(ALICE);
        let (mut lending_market, obligation_cap, _clock) = setup(scenario.ctx());
        test_utils::destroy(obligation_cap); // Don't need this anymore
        
        // Create and convert to wrapped cap
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(&mut lending_market, 1, scenario.ctx());
        let (mut wrapped_cap, relayer_cap) = strategy_wrapper::convert_to_wrapped_cap<LENDING_MARKET>(
            strategy_cap,
            BACKEND,
            scenario.ctx()
        );
        
        // Backend borrows the cap
        test_scenario::next_tx(&mut scenario, BACKEND);
        let (borrowed_cap, receipt) = strategy_wrapper::borrow_obligation_cap<LENDING_MARKET>(
            &mut wrapped_cap,
            &relayer_cap,
            scenario.ctx()
        );
        
        // Since we can't drop the hot potato, return it first then immediately borrow again
        strategy_wrapper::return_obligation_cap<LENDING_MARKET>(
            &mut wrapped_cap,
            borrowed_cap,
            receipt,
            scenario.ctx()
        );
        
        // Borrow again to put wrapped_cap in borrowed state
        let (borrowed_cap2, _receipt2) = strategy_wrapper::borrow_obligation_cap<LENDING_MARKET>(
            &mut wrapped_cap,
            &relayer_cap,
            scenario.ctx()
        );
        
        // Try to convert back while borrowed - should fail and abort
        let restored_strategy_cap = strategy_wrapper::convert_back_to_strategy_cap<LENDING_MARKET>(
            wrapped_cap,
            relayer_cap,
            scenario.ctx()
        );
        
        // This shouldn't be reached due to abort, but handle values properly if it is
        strategy_wrapper::destroy_for_testing(restored_strategy_cap);
        lending_market::destroy_for_testing(borrowed_cap2);
        // receipt2 is a hot potato and cannot be destroyed
        abort EShouldNotReach // Force abort to prevent reaching unreachable cleanup
    }

    #[test]
    fun test_wrapped_cap_view_functions() {
        let mut scenario = test_scenario::begin(ALICE);
        let (mut lending_market, obligation_cap, clock) = setup(scenario.ctx());
        test_utils::destroy(obligation_cap); // Don't need this anymore
        
        // Create and convert to wrapped cap
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(&mut lending_market, 1, scenario.ctx());
        let (wrapped_cap, relayer_cap) = strategy_wrapper::convert_to_wrapped_cap<LENDING_MARKET>(
            strategy_cap,
            BACKEND,
            scenario.ctx()
        );
        
        // Test all view functions
        assert!(strategy_wrapper::wrapped_cap_strategy_type(&wrapped_cap) == 1);
        assert!(strategy_wrapper::wrapped_cap_version(&wrapped_cap) == 1);
        assert!(strategy_wrapper::wrapped_cap_relayer_address(&wrapped_cap) == BACKEND);
        assert!(!strategy_wrapper::wrapped_cap_is_borrowed(&wrapped_cap));
        
        assert!(strategy_wrapper::relayer_cap_strategy_type(&relayer_cap) == 1);
        assert!(strategy_wrapper::relayer_cap_wrapped_id(&relayer_cap) == object::id(&wrapped_cap));
        
        // Cleanup
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_wrapped_cap_for_testing(wrapped_cap);
        strategy_wrapper::destroy_relayer_cap_for_testing(relayer_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_hot_potato_complete_workflow() {
        let mut scenario = test_scenario::begin(ALICE);
        let (mut lending_market, obligation_cap, clock) = setup(scenario.ctx());
        test_utils::destroy(obligation_cap); // Don't need this anymore
        
        // Step 1: Create strategy cap
        let strategy_cap = strategy_wrapper::create_strategy_owner_cap<LENDING_MARKET>(&mut lending_market, 1, scenario.ctx());
        
        // Step 2: Convert to wrapped pattern
        let (mut wrapped_cap, relayer_cap) = strategy_wrapper::convert_to_wrapped_cap<LENDING_MARKET>(
            strategy_cap,
            BACKEND,
            scenario.ctx()
        );
        
        // Step 3: Backend borrows and returns multiple times
        test_scenario::next_tx(&mut scenario, BACKEND);
        
        // First borrow-return cycle
        let (obligation_cap1, receipt1) = strategy_wrapper::borrow_obligation_cap<LENDING_MARKET>(
            &mut wrapped_cap,
            &relayer_cap,
            scenario.ctx()
        );
        assert!(strategy_wrapper::wrapped_cap_is_borrowed(&wrapped_cap));
        
        strategy_wrapper::return_obligation_cap<LENDING_MARKET>(
            &mut wrapped_cap,
            obligation_cap1,
            receipt1,
            scenario.ctx()
        );
        assert!(!strategy_wrapper::wrapped_cap_is_borrowed(&wrapped_cap));
        
        // Second borrow-return cycle
        let (obligation_cap2, receipt2) = strategy_wrapper::borrow_obligation_cap<LENDING_MARKET>(
            &mut wrapped_cap,
            &relayer_cap,
            scenario.ctx()
        );
        assert!(strategy_wrapper::wrapped_cap_is_borrowed(&wrapped_cap));
        
        strategy_wrapper::return_obligation_cap<LENDING_MARKET>(
            &mut wrapped_cap,
            obligation_cap2,
            receipt2,
            scenario.ctx()
        );
        assert!(!strategy_wrapper::wrapped_cap_is_borrowed(&wrapped_cap));
        
        // Step 4: Convert back to strategy cap
        let restored_strategy_cap = strategy_wrapper::convert_back_to_strategy_cap<LENDING_MARKET>(
            wrapped_cap,
            relayer_cap,
            scenario.ctx()
        );
        
        // Verify everything is back to normal
        assert!(strategy_wrapper::get_strategy_type(&restored_strategy_cap) == 1);
        
        // Cleanup
        test_utils::destroy(lending_market);
        strategy_wrapper::destroy_for_testing(restored_strategy_cap);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }
}
