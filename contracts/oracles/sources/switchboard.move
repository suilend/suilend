module oracles::switchboard {
    use std::vector::{Self};
    use pyth::price_identifier::{PriceIdentifier, Self};
    use pyth::price::{Self, Price};
    use pyth::i64::{Self};
    use sui::math::{Self};
    use std::option::{Self, Option};
    use switchboard::aggregator::{Aggregator};
    use switchboard::decimal::Decimal;    
    use oracles::oracle_decimal::{OracleDecimal, Self};
    use sui::clock::{Self, Clock};
    use std::u64::{Self};

    // Errors
    const EPriceIsStale: u64 = 0;
    const EPriceRangeIsTooLarge: u64 = 1;
    const EWrongFeedId: u64 = 2;
    const ESwitchboardDecimalIsNegative: u64 = 3;

    /// parse the switchboard price info object to get a price and identifier. This function returns an None if the
    /// price is invalid due to staleness checks or invalid submitted price range. It returns None instead of aborting
    /// so the caller can handle invalid prices gracefully by eg falling back to a different oracle
    /// return type: (spot price, feed id)
    public fun get_price(
        switchboard_feed: &Aggregator, 
        clock: &Clock,
        max_staleness_s: u64,
        max_confidence_interval_pct: u64,
        expected_feed_id: ID,
    ): OracleDecimal {

        // get the switchboard feed id as a price identifier - here it's just 32 bytes
        assert!(switchboard_feed.id() == expected_feed_id, EWrongFeedId);

        // extract the current values from the switchboard feed
        let current_result = switchboard_feed.current_result();
        let update_timestamp_ms = current_result.timestamp_ms();

        let result: &Decimal = current_result.result();
        let stdev: &Decimal = current_result.stdev();

        // check current sui time against feed's update time to make sure the price is not stale
        let cur_time_ms = clock::timestamp_ms(clock);
        if (cur_time_ms > update_timestamp_ms &&
            cur_time_ms - update_timestamp_ms > max_staleness_s * 1000) {
            abort EPriceIsStale
        };

        // stddev / result <= x/100
        // stddev * 100 <= result * x
        assert!(
            stdev.value() * 100u128 <= result.value() * (max_confidence_interval_pct as u128), 
            EPriceRangeIsTooLarge
        );

        from_switchboard_decimal(result)
    }

    public(package) fun from_switchboard_decimal(d: &Decimal): OracleDecimal {
        assert!(!d.neg(), ESwitchboardDecimalIsNegative);

        oracle_decimal::new(d.value(), 18, false)
    }

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

        let spot_price = get_price(
            &aggregator, 
            &clock,
            60,
            10,
            aggregator.id()
        );

        assert!(spot_price == from_switchboard_decimal(&switchboard_decimal::new(price, false)), 0);

        switchboard::aggregator_delete_action::run(aggregator, sui::test_scenario::ctx(&mut scenario));
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EPriceIsStale)]
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

        let spot_price = get_price(
            &aggregator, 
            &clock,
            60,
            10,
            aggregator.id()
        );

        assert!(spot_price == from_switchboard_decimal(&switchboard_decimal::new(price, false)), 0);

        switchboard::aggregator_delete_action::run(aggregator, sui::test_scenario::ctx(&mut scenario));
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EPriceIsStale)]
    fun switchboard_fail_confidence_interval() {
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
        let price = 200 * 10u128.pow(18);
        let low_price = 190 * 10u128.pow(18);
        let high_price = 210* 10u128.pow(18);
        let stddev = 20 * 10u128.pow(18);

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

        clock.set_for_testing(62_000);

        let spot_price = get_price(
            &aggregator, 
            &clock,
            60,
            10,
            aggregator.id()
        );

        assert!(spot_price == from_switchboard_decimal(&switchboard_decimal::new(price, false)), 0);

        switchboard::aggregator_delete_action::run(aggregator, sui::test_scenario::ctx(&mut scenario));
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }
}