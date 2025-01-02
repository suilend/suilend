module oracles::switchboard {
    use std::vector::{Self};
    use pyth::price_identifier::{PriceIdentifier, Self};
    use pyth::price::{Self, Price};
    use pyth::i64::{Self};
    use sui::math::{Self};
    use std::option::{Self, Option};
    use switchboard::aggregator::{Aggregator};
    use switchboard::decimal::Decimal;    
    use sui::clock::{Self, Clock};
    use std::u64::{Self};

    // Errors
    const EPriceIsStale: u64 = 0;
    const EPriceRangeIsTooLarge: u64 = 1;
    const EWrongFeedId: u64 = 2;

    /// parse the switchboard price info object to get a price and identifier. This function returns an None if the
    /// price is invalid due to staleness checks or invalid submitted price range. It returns None instead of aborting
    /// so the caller can handle invalid prices gracefully by eg falling back to a different oracle
    /// return type: (spot price, feed id)
    public fun get_switchboard_price(
        switchboard_feed: &Aggregator, 
        clock: &Clock,
        max_staleness_s: u64,
        max_confidence_interval_pct: u8,
        expected_feed_id: ID,
    ): Decimal {

        // get the switchboard feed id as a price identifier - here it's just 32 bytes
        assert!(switchboard_feed.id() == expected_feed_id, EWrongFeedId);

        // extract the current values from the switchboard feed
        let current_result = switchboard_feed.current_result();
        let update_timestamp_ms = current_result.timestamp_ms();

        let result: &Decimal = current_result.result();
        let range: &Decimal = current_result.range();

        // check current sui time against feed's update time to make sure the price is not stale
        let cur_time_ms = clock::timestamp_ms(clock);
        if (cur_time_ms > update_timestamp_ms &&
            cur_time_ms - update_timestamp_ms > max_staleness_s * 1000) {
            abort EPriceIsStale
        };

        // range / result <= x/100
        // range * 100 <= result * x
        assert!(
            range.value() * 100u128 <= result.value() * (max_confidence_interval_pct as u128), 
            EPriceRangeIsTooLarge
        );

        *result
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
            switchboard_decimal::new(price, true),
            1337,
            1337,
            1337,
            switchboard_decimal::new(low_price, true),
            switchboard_decimal::new(high_price, true),
            switchboard_decimal::new(range, false),
            switchboard_decimal::new(0, false),
            switchboard_decimal::new(price, true)
        );

        let spot_price = get_switchboard_price(
            &aggregator, 
            &clock,
            60,
            10,
            aggregator.id()
        );

        assert!(spot_price == switchboard_decimal::new(price, true), 0);

        switchboard::aggregator_delete_action::run(aggregator, sui::test_scenario::ctx(&mut scenario));
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }
}