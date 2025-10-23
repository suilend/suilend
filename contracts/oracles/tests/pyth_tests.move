#[test_only]
module oracles::pyth_tests {
    use pyth::price_info;
    use pyth::price_feed::{Self};
    use pyth::price_identifier::{PriceIdentifier, Self};
    use pyth::price;
    use pyth::i64::{Self};
    use sui::clock;
    use oracles::pyth::{get_prices, from_pyth_price};

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

        let (actual_spot_price, actual_ema_price, price_feed) = get_prices(
            &price_info_object,
            &clock,
            100,
            100,
            example_price_identifier(),
        );

        assert!(actual_spot_price == from_pyth_price(&spot_price));
        assert!(actual_ema_price == from_pyth_price(&ema_price));
        assert!(price_feed == price_info_object.get_price_info_from_price_info_object().get_price_feed());

        price_info::destroy(price_info_object);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = oracles::pyth::EConfidenceIntervalExceeded)]
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
    #[expected_failure(abort_code = oracles::pyth::EPriceIsStale)]
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

    #[test]
    #[expected_failure(abort_code = oracles::pyth::EWrongPriceIdentifier)]
    fun wrong_price_identifier() {
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
            price_identifier::from_byte_vec(b"asdfasdfasdfasdfasdfasdfasdfasdf"),
        );

        price_info::destroy(price_info_object);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }


}
