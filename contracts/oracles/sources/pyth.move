/// This module contains logic for parsing pyth prices
module oracles::pyth {
    use pyth::price_info::{Self, PriceInfoObject};
    use pyth::price_feed::{Self};
    use pyth::price_identifier::{PriceIdentifier, Self};
    use pyth::price::{Self, Price};
    use pyth::i64::{Self};
    use sui::math::{Self};
    use sui::clock::{Self, Clock};
    use oracles::oracle_decimal::{OracleDecimal, Self};

    // Errors
    const EConfidenceIntervalExceeded: u64 = 0;
    const EPriceIsStale: u64 = 1;
    const EWrongPriceIdentifier: u64 = 2;

    public(package) fun get_prices(
        price_info_obj: &PriceInfoObject, 
        clock: &Clock,
        max_staleness_threshold_s: u64,
        max_confidence_interval_pct: u64,
        expected_price_identifier: PriceIdentifier,
    ): (OracleDecimal, OracleDecimal) {
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
        assert!(conf * (100 / max_confidence_interval_pct) <= price_mag, EConfidenceIntervalExceeded);

        // check current sui time against pythnet publish time. there can be some issues that arise because the
        // timestamps are from different sources and may get out of sync, but that's why we have a fallback oracle
        let cur_time_s = clock::timestamp_ms(clock) / 1000;
        if (cur_time_s > price::get_timestamp(&price) && // this is technically possible!
            cur_time_s - price::get_timestamp(&price) > max_staleness_threshold_s) {
            abort EPriceIsStale
        };

        (from_pyth_price(&price), from_pyth_price(&ema_price))
    }

    fun from_pyth_price(price: &Price): OracleDecimal {
        oracle_decimal::new(
            price.get_price().get_magnitude_if_positive() as u128,
            if (price.get_expo().get_is_negative()) {
                price.get_expo().get_magnitude_if_negative()
            } else {
                price.get_expo().get_magnitude_if_positive()
            },
            price.get_expo().get_is_negative()
        )
    }


    #[test_only]
    fun example_price_identifier(): PriceIdentifier {
        let mut v = vector::empty<u8>();

        let mut i = 0;
        while (i < 32) {
            vector::push_back(&mut v, 0);
            i = i + 1;
        };

        price_identifier::from_byte_vec(v)
    }

    #[test]
    fun happy() {
        use sui::test_scenario::{Self};
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

        let spot_price = price::new(
            i64::new(8, false),
            0,
            i64::new(5, false),
            0
        );

        let ema_price = price::new(
            i64::new(8, false),
            0,
            i64::new(4, true),
            0
        );

        let price_info_object = price_info::new_price_info_object_for_testing(
            price_info::new_price_info(
                0,
                0,
                price_feed::new(
                    example_price_identifier(),
                    spot_price,
                    ema_price
                )
            ),
            test_scenario::ctx(&mut scenario)
        );

        let (actual_spot_price, actual_ema_price) = get_prices(
            &price_info_object,
            &clock,
            100,
            100,
            example_price_identifier(),
        );

        assert!(actual_spot_price == from_pyth_price(&spot_price), 0);
        assert!(actual_ema_price == from_pyth_price(&ema_price), 0);

        price_info::destroy(price_info_object);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EConfidenceIntervalExceeded)]
    fun confidence_interval_exceeded() {
        use sui::test_scenario::{Self};
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

        let spot_price = price::new(
            i64::new(100, false),
            11,
            i64::new(5, false),
            0
        );

        let ema_price = price::new(
            i64::new(8, false),
            0,
            i64::new(4, true),
            0
        );

        let price_info_object = price_info::new_price_info_object_for_testing(
            price_info::new_price_info(
                0,
                0,
                price_feed::new(
                    example_price_identifier(),
                    spot_price,
                    ema_price
                )
            ),
            test_scenario::ctx(&mut scenario)
        );

        get_prices(
            &price_info_object,
            &clock,
            100,
            10,
            example_price_identifier(),
        );

        price_info::destroy(price_info_object);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EPriceIsStale)]
    fun price_is_stale() {
        use sui::test_scenario::{Self};
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock.set_for_testing(5_000);

        let spot_price = price::new(
            i64::new(100, false),
            10,
            i64::new(5, false),
            1,
        );

        let ema_price = price::new(
            i64::new(8, false),
            0,
            i64::new(4, true),
            0
        );

        let price_info_object = price_info::new_price_info_object_for_testing(
            price_info::new_price_info(
                0,
                0,
                price_feed::new(
                    example_price_identifier(),
                    spot_price,
                    ema_price
                )
            ),
            test_scenario::ctx(&mut scenario)
        );

        get_prices(
            &price_info_object,
            &clock,
            3,
            10,
            example_price_identifier(),
        );

        price_info::destroy(price_info_object);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

}

