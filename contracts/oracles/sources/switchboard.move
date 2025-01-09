module oracles::switchboard {
    use switchboard::aggregator::{Aggregator};
    use switchboard::decimal::Decimal;    
    use oracles::oracle_decimal::{OracleDecimal, Self};
    use sui::clock::{Self, Clock};

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
}