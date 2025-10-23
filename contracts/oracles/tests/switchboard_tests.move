#[test_only]
module oracles::switchboard_tests {
    use sui::clock::{Self};
    use oracles::switchboard::{get_price, from_switchboard_decimal};

    #[test]
    fun happy_switchboard() {
        use sui::test_scenario::{Self};
        use switchboard::decimal as switchboard_decimal;
        use switchboard::aggregator;

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

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

        // scale the price to 18 decimals
        let price = 800_000 * 10u128.pow(18);
        let low_price = 799_900 * 10u128.pow(18);
        let high_price = 800_100 * 10u128.pow(18);
        let range = 200 * 10u128.pow(18);

        // set the current value (scaled, of course)
        aggregator::set_current_value(
            &mut aggregator,
            switchboard_decimal::new(price, false),
            1337,
            1337,
            1337,
            switchboard_decimal::new(low_price, false),
            switchboard_decimal::new(high_price, false),
            switchboard_decimal::new(range, false),
            switchboard_decimal::new(0, false),
            switchboard_decimal::new(price, false)
        );

        let (spot_price, current_result) = get_price(
            &aggregator, 
            &clock,
            60,
            10,
            aggregator.id()
        );

        assert!(spot_price == from_switchboard_decimal(&switchboard_decimal::new(price, false)));
        assert!(current_result == aggregator.current_result());

        switchboard::aggregator_delete_action::run(aggregator, sui::test_scenario::ctx(&mut scenario));
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = oracles::switchboard::EPriceIsStale)]
    fun switchboard_fail_stale() {
        use sui::test_scenario::{Self};
        use switchboard::decimal as switchboard_decimal;
        use switchboard::aggregator;

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

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

        // scale the price to 18 decimals
        let price = 800_000 * 10u128.pow(18);
        let low_price = 799_900 * 10u128.pow(18);
        let high_price = 800_100 * 10u128.pow(18);
        let range = 200 * 10u128.pow(18);

        // set the current value (scaled, of course)
        aggregator::set_current_value(
            &mut aggregator,
            switchboard_decimal::new(price, false),
            1337,
            1337,
            1337,
            switchboard_decimal::new(low_price, false),
            switchboard_decimal::new(high_price, false),
            switchboard_decimal::new(range, false),
            switchboard_decimal::new(0, false),
            switchboard_decimal::new(price, false)
        );

        clock.set_for_testing(62_000);

        get_price(
            &aggregator, 
            &clock,
            60,
            10,
            aggregator.id()
        );

        switchboard::aggregator_delete_action::run(aggregator, sui::test_scenario::ctx(&mut scenario));
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = oracles::switchboard::EPriceRangeIsTooLarge)]
    fun switchboard_fail_confidence_interval() {
        use sui::test_scenario::{Self};
        use switchboard::decimal as switchboard_decimal;
        use switchboard::aggregator;

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

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

        // scale the price to 18 decimals
        let price = 200 * 10u128.pow(18);
        let low_price = 190 * 10u128.pow(18);
        let high_price = 210* 10u128.pow(18);
        let stddev = 21 * 10u128.pow(18);

        // set the current value (scaled, of course)
        aggregator::set_current_value(
            &mut aggregator,
            switchboard_decimal::new(price, false),
            1337,
            1337,
            1337,
            switchboard_decimal::new(low_price, false),
            switchboard_decimal::new(high_price, false),
            switchboard_decimal::new(stddev, false),
            switchboard_decimal::new(0, false),
            switchboard_decimal::new(price, false)
        );

        get_price(
            &aggregator, 
            &clock,
            60,
            10,
            aggregator.id()
        );

        switchboard::aggregator_delete_action::run(aggregator, sui::test_scenario::ctx(&mut scenario));
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = oracles::switchboard::EWrongFeedId)]
    fun switchboard_fail_wrong_feed_id() {
        use sui::test_scenario::{Self};
        use switchboard::decimal as switchboard_decimal;
        use switchboard::aggregator;

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

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

        // scale the price to 18 decimals
        let price = 200 * 10u128.pow(18);
        let low_price = 190 * 10u128.pow(18);
        let high_price = 210* 10u128.pow(18);
        let stddev = 21 * 10u128.pow(18);

        // set the current value (scaled, of course)
        aggregator::set_current_value(
            &mut aggregator,
            switchboard_decimal::new(price, false),
            1337,
            1337,
            1337,
            switchboard_decimal::new(low_price, false),
            switchboard_decimal::new(high_price, false),
            switchboard_decimal::new(stddev, false),
            switchboard_decimal::new(0, false),
            switchboard_decimal::new(price, false)
        );

        let random_id = object::new(scenario.ctx());
        get_price(
            &aggregator, 
            &clock,
            60,
            10,
            random_id.to_inner()
        );

        switchboard::aggregator_delete_action::run(aggregator, sui::test_scenario::ctx(&mut scenario));
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(random_id);

        test_scenario::end(scenario);
    }
}
