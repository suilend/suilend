module oracles::oracles_tests {
    use sui::test_scenario::{Self};
    use oracles::oracles::{Self, OracleRegistryConfig, OraclePriceUpdate};
    use sui::clock::{Self, Clock};
    use oracles::mock_pyth::{Self, PriceState};
    use sui::sui::{SUI};
    use sui::test_scenario::Scenario; // Ensure Scenario is imported
    use pyth::i64::{Self};
    use switchboard::decimal::{Self};

    public struct TEST_USDC has drop {}

    fun setup(owner: address): (Scenario, Clock, PriceState) {
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        let mut prices = mock_pyth::init_state(test_scenario::ctx(&mut scenario));

        prices.register<TEST_USDC>(scenario.ctx());
        prices.register<SUI>(scenario.ctx());

        (scenario, clock, prices)
    }

    #[test]
    fun test_oracles_happy() {
        let owner = @0x26;
        let (mut scenario, clock, mut prices) = setup(owner);

        let (mut registry, admin_cap) = oracles::new_oracle_registry_for_testing(
            oracles::new_oracle_registry_config(
                60,
                10,
                60,
                10,
                scenario.ctx()
            ),
            scenario.ctx()
        );

        registry.set_pyth_oracle<TEST_USDC>(
            &admin_cap, 
            mock_pyth::get_price_obj<TEST_USDC>(&prices), 
            scenario.ctx()
        );

        prices.update_price<TEST_USDC>(
            1,
            0,
            &clock
        );

        let price_update: OraclePriceUpdate<TEST_USDC> = registry.get_pyth_price<TEST_USDC>(
            mock_pyth::get_price_obj<TEST_USDC>(&prices), 
            0,
            &clock
        );

        assert!(price_update.price().base() == 1);
        assert!(price_update.price().expo() == 0);
        assert!(price_update.price().is_expo_negative() == false);

        // switch oracle type to switchboard
        let mut aggregator = switchboard::aggregator::new_aggregator(
            object::id_from_bytes(x"add8f0a36f15156b5f4720f94a62230dbef3c5d8bbfc6a799b5e6bfb56671bd4"),
            std::string::utf8(b"test"),
            @0x26,
            x"add8f0a36f15156b5f4720f94a62230dbef3c5d8bbfc6a799b5e6bfb56671bd4", // feed hash
            1, // min samples
            60, // max staleness for updates
            1_000_000_000, // max variance scaled to 9 decimals (1e9 == 1%)
            1, // min job responses
            1337, // created at ms
            sui::test_scenario::ctx(&mut scenario)
        );

        let price = 2 * 1_000_000_000_000_000_000;
        aggregator.set_current_value(
            decimal::new(price, false),
            1337,
            1337,
            1337,
            decimal::new(price, false),
            decimal::new(price, false),
            decimal::new(1, false),
            decimal::new(0, false),
            decimal::new(price, false)
        );

        registry.set_switchboard_oracle<TEST_USDC>(
            &admin_cap, 
            &aggregator, 
            scenario.ctx()
        );

        let price_update: OraclePriceUpdate<TEST_USDC> = registry.get_switchboard_price<TEST_USDC>(
            &aggregator, 
            0,
            &clock
        );

        assert!(price_update.price().base() == price);
        assert!(price_update.price().expo() == 18);
        assert!(price_update.price().is_expo_negative() == false);

        sui::test_utils::destroy(admin_cap);
        sui::test_utils::destroy(registry);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(prices);
        sui::test_utils::destroy(aggregator);

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ::oracles::oracles::EWrongCoinType)]
    fun test_oracles_fail_wrong_type() {
        let owner = @0x26;
        let (mut scenario, clock, mut prices) = setup(owner);


        let (mut registry, admin_cap) = oracles::new_oracle_registry_for_testing(
            oracles::new_oracle_registry_config(
                60,
                10,
                60,
                10,
                scenario.ctx()
            ),
            scenario.ctx()
        );

        registry.set_pyth_oracle<TEST_USDC>(
            &admin_cap, 
            mock_pyth::get_price_obj<TEST_USDC>(&prices), 
            scenario.ctx()
        );

        prices.update_price<TEST_USDC>(
            1,
            0,
            &clock
        );

        let price: OraclePriceUpdate<SUI> = registry.get_pyth_price<SUI>(
            mock_pyth::get_price_obj<SUI>(&prices), 
            0,
            &clock
        );

        sui::test_utils::destroy(admin_cap);
        sui::test_utils::destroy(registry);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(prices);
        
        test_scenario::end(scenario);
    }

}