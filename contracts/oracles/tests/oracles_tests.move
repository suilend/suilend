module oracles::oracles_tests {
    use sui::test_scenario::{Self};
    use oracles::oracles::{Self, OracleRegistryConfig, OraclePriceUpdate};
    use sui::clock::{Self, Clock};
    use oracles::mock_pyth::{Self, PriceState};
    use sui::sui::{SUI};
    use sui::test_scenario::Scenario; // Ensure Scenario is imported
    use pyth::i64::{Self};

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

        let config = oracles::new_oracle_registry_config(
            60,
            10,
            60,
            10,
            scenario.ctx()
        );

        let (mut registry, admin_cap) = oracles::new_oracle_registry(
            config,
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

        let price: OraclePriceUpdate<TEST_USDC> = registry.get_pyth_price<TEST_USDC>(
            mock_pyth::get_price_obj<TEST_USDC>(&prices), 
            0,
            &clock
        );

        assert!(price.base() == i64::new(1, false));
        assert!(price.expo() == i64::new(0, false));

        sui::test_utils::destroy(admin_cap);
        sui::test_utils::destroy(registry);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(prices);
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ::oracles::oracles::EWrongCoinType)]
    fun test_oracles_fail_wrong_type() {
        let owner = @0x26;
        let (mut scenario, clock, mut prices) = setup(owner);

        let config = oracles::new_oracle_registry_config(
            60,
            10,
            60,
            10,
            scenario.ctx()
        );

        let (mut registry, admin_cap) = oracles::new_oracle_registry(
            config,
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