/// This module contains logic for parsing pyth prices
module oracles::pyth {
    use pyth::price_info::{Self, PriceInfoObject};
    use pyth::price_feed::{Self, PriceFeed};
    use pyth::price_identifier::PriceIdentifier;
    use pyth::price::{Self, Price};
    use pyth::i64::{Self};
    use sui::clock::{Self, Clock};
    use oracles::oracle_decimal::{OracleDecimal, Self};

    // Errors
    const EConfidenceIntervalExceeded: u64 = 0;
    const EPriceIsStale: u64 = 1;
    const EWrongPriceIdentifier: u64 = 2;
    const EPythDecimalIsZero: u64 = 3;

    public(package) fun get_prices(
        price_info_obj: &PriceInfoObject, 
        clock: &Clock,
        max_staleness_threshold_s: u64,
        max_confidence_interval_pct: u64,
        expected_price_identifier: PriceIdentifier,
    ): (OracleDecimal, OracleDecimal, PriceFeed) {
        let price_info = price_info::get_price_info_from_price_info_object(price_info_obj);
        let price_feed = price_info::get_price_feed(&price_info);

        let price_identifier = price_feed::get_price_identifier(price_feed);
        assert!(price_identifier == expected_price_identifier, EWrongPriceIdentifier);

        let ema_price = price_feed::get_ema_price(price_feed);

        let price = price_feed::get_price(price_feed);
        let price_mag = i64::get_magnitude_if_positive(&price::get_price(&price));
        let conf = price::get_conf(&price);

        // confidence interval check
        // we want to make sure conf / price <= x%
        // -> conf * (100 / x )<= price
        assert!(
            (conf as u128) * 100u128 <= (price_mag as u128) * (max_confidence_interval_pct as u128),
            EConfidenceIntervalExceeded
        );

        // check current sui time against pythnet publish time. there can be some issues that arise because the
        // timestamps are from different sources and may get out of sync, but that's why we have a fallback oracle
        let cur_time_s = clock::timestamp_ms(clock) / 1000;
        if (cur_time_s > price::get_timestamp(&price) && // this is technically possible!
            cur_time_s - price::get_timestamp(&price) > max_staleness_threshold_s) {
            abort EPriceIsStale
        };

        (from_pyth_price(&price), from_pyth_price(&ema_price), *price_feed)
    }

    public(package) fun from_pyth_price(price: &Price): OracleDecimal {
        let price = oracle_decimal::new(
            price.get_price().get_magnitude_if_positive() as u128,
            if (price.get_expo().get_is_negative()) {
                price.get_expo().get_magnitude_if_negative()
            } else {
                price.get_expo().get_magnitude_if_positive()
            },
            price.get_expo().get_is_negative()
        );

        assert!(price.base() > 0, EPythDecimalIsZero);
        price
    }

}

