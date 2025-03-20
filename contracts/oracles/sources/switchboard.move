module oracles::switchboard {
    use switchboard::aggregator::{Aggregator, CurrentResult};
    use switchboard::decimal::Decimal;    
    use oracles::oracle_decimal::{OracleDecimal, Self};
    use sui::clock::{Self, Clock};

    // Errors
    const EPriceIsStale: u64 = 0;
    const EPriceRangeIsTooLarge: u64 = 1;
    const EWrongFeedId: u64 = 2;
    const ESwitchboardDecimalIsNegative: u64 = 3;
    const ESwitchboardDecimalIsZero: u64 = 4;

    public fun get_price(
        switchboard_feed: &Aggregator, 
        clock: &Clock,
        max_staleness_s: u64,
        max_confidence_interval_pct: u64,
        expected_feed_id: ID,
    ): (OracleDecimal, CurrentResult) {

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
            (stdev.value() as u256) * 100u256 <= (result.value() as u256) * (max_confidence_interval_pct as u256), 
            EPriceRangeIsTooLarge
        );

        (from_switchboard_decimal(result), *current_result)
    }

    public(package) fun from_switchboard_decimal(d: &Decimal): OracleDecimal {
        assert!(!d.neg(), ESwitchboardDecimalIsNegative);
        assert!(d.value() > 0, ESwitchboardDecimalIsZero);

        oracle_decimal::new(d.value(), 18, true)
    }
}