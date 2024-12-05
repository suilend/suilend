/// This module contains logic for parsing pyth prices (and eventually switchboard prices)
module suilend::oracles {
    use pyth::price_info::{Self, PriceInfoObject};
    use pyth::price_feed::{Self};
    use pyth::price_identifier::{PriceIdentifier, Self};
    use pyth::price::{Self, Price};
    use pyth::i64::{Self};
    use suilend::decimal::{Self, Decimal};
    use switchboard::aggregator::{Aggregator};
    use switchboard::decimal::Decimal as SwitchboardDecimal;    
    use sui::clock::{Self, Clock};
    use std::u64::{Self};

    // min confidence ratio of X means that the confidence interval must be less than (100/x)% of the price
    const MIN_CONFIDENCE_RATIO: u64 = 10;
    const MAX_STALENESS_SECONDS: u64 = 60;

    /// parse the pyth price info object to get a price and identifier. This function returns an None if the
    /// price is invalid due to confidence interval checks or staleness checks. It returns None instead of aborting
    /// so the caller can handle invalid prices gracefully by eg falling back to a different oracle
    /// return type: (spot price, ema price, price identifier)
    public fun get_pyth_price_and_identifier(price_info_obj: &PriceInfoObject, clock: &Clock): (Option<Decimal>, Decimal, PriceIdentifier) {
        let price_info = price_info::get_price_info_from_price_info_object(price_info_obj);
        let price_feed = price_info::get_price_feed(&price_info);
        let price_identifier = price_feed::get_price_identifier(price_feed);

        let ema_price = parse_price_to_decimal(price_feed::get_ema_price(price_feed));

        let price = price_feed::get_price(price_feed);
        let price_mag = i64::get_magnitude_if_positive(&price::get_price(&price));
        let conf = price::get_conf(&price);

        // confidence interval check
        // we want to make sure conf / price <= x%
        // -> conf * (100 / x )<= price
        if (conf * MIN_CONFIDENCE_RATIO > price_mag) {
            return (option::none(), ema_price, price_identifier)
        };

        // check current sui time against pythnet publish time. there can be some issues that arise because the
        // timestamps are from different sources and may get out of sync, but that's why we have a fallback oracle
        let cur_time_s = clock::timestamp_ms(clock) / 1000;
        if (cur_time_s > price::get_timestamp(&price) && // this is technically possible!
            cur_time_s - price::get_timestamp(&price) > MAX_STALENESS_SECONDS) {
            return (option::none(), ema_price, price_identifier)
        };

        let spot_price = parse_price_to_decimal(price);
        (option::some(spot_price), ema_price, price_identifier)
    }

    fun parse_price_to_decimal(price: Price): Decimal {
        // suilend doesn't support negative prices
        let price_mag = i64::get_magnitude_if_positive(&price::get_price(&price));
        let expo = price::get_expo(&price);

        if (i64::get_is_negative(&expo)) {
            decimal::div(
                decimal::from(price_mag),
                decimal::from(u64::pow(10, (i64::get_magnitude_if_negative(&expo) as u8)))
            )
        }
        else {
            decimal::mul(
                decimal::from(price_mag),
                decimal::from(u64::pow(10, (i64::get_magnitude_if_positive(&expo) as u8)))
            )
        }
    }

    /// parse the switchboard price info object to get a price and identifier. This function returns an None if the
    /// price is invalid due to staleness checks or invalid submitted price range. It returns None instead of aborting
    /// so the caller can handle invalid prices gracefully by eg falling back to a different oracle
    /// return type: (spot price, feed id)
    public fun get_switchboard_price_and_identifier(switchboard_feed: &Aggregator, clock: &Clock): (Option<Decimal>, ID) {

        // get the switchboard feed id as a price identifier - here it's just 32 bytes
        let feed_id = switchboard_feed.id();

        // extract the current values from the switchboard feed
        let current_result = switchboard_feed.current_result();
        let update_timestamp_ms = current_result.timestamp_ms();
        let result: &SwitchboardDecimal = current_result.result();
        let range: &SwitchboardDecimal = current_result.range();

        // check current sui time against feed's update time to make sure the price is not stale
        let cur_time_ms = clock::timestamp_ms(clock);
        if (cur_time_ms > update_timestamp_ms &&
            cur_time_ms - update_timestamp_ms > MAX_STALENESS_SECONDS * 1000) {
            return (option::none(), feed_id)
        };
        
        // check non-zero and range is less than 10x the price (sanity checks) 
        // @TODO evaluate: maybe add result.value() == 0 though this would prevent uninitialized feeds from being added 
        if (range.value() * 10u128 > result.value()) {  
            return (option::none(), feed_id)
        };

        // get the spot price
        let price = parse_switchboard_decimal_to_decimal(result);

        // deliver the price and identifier
        (option::some(price), feed_id)
    }

    /// parse a switchboard decimal to a decimal
    fun parse_switchboard_decimal_to_decimal(price: &SwitchboardDecimal): Decimal {
        
        // switchboard values are scaled to 18 decimals (as are suilend decimals)
        decimal::from_scaled_val(price.value() as u256)
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

        let price_info_object = price_info::new_price_info_object_for_testing(
            price_info::new_price_info(
                0,
                0,
                price_feed::new(
                    example_price_identifier(),
                    price::new(
                        i64::new(8, false),
                        0,
                        i64::new(5, false),
                        0
                    ),
                    price::new(
                        i64::new(8, false),
                        0,
                        i64::new(4, true),
                        0
                    )
                )
            ),
            test_scenario::ctx(&mut scenario)
        );
        let (spot_price, ema_price, price_identifier) = get_pyth_price_and_identifier(&price_info_object, &clock);
        assert!(spot_price == option::some(decimal::from(800_000)), 0);
        assert!(ema_price == decimal::from_bps(8), 0);
        assert!(price_identifier == example_price_identifier(), 0);

        price_info::destroy(price_info_object);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
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

        let (spot_price, price_identifier) = get_switchboard_price_and_identifier(&aggregator, &clock);
        assert!(spot_price == option::some(decimal::from(800_000)), 0);
        assert!(price_identifier == aggregator.id(), 0);

        switchboard::aggregator_delete_action::run(aggregator, sui::test_scenario::ctx(&mut scenario));
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun confidence_interval_exceeded() {
        use sui::test_scenario::{Self};
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

        let price_info_object = price_info::new_price_info_object_for_testing(
            price_info::new_price_info(
                0,
                0,
                price_feed::new(
                    example_price_identifier(),
                    price::new(
                        i64::new(100, false),
                        11,
                        i64::new(5, false),
                        0
                    ),
                    price::new(
                        i64::new(8, false),
                        0,
                        i64::new(4, true),
                        0
                    )
                )
            ),
            test_scenario::ctx(&mut scenario)
        );

        let (spot_price, ema_price, price_identifier) = get_pyth_price_and_identifier(&price_info_object, &clock);

        // condience interval higher than 10% of the price
        assert!(spot_price == option::none(), 0);
        assert!(ema_price == decimal::from_bps(8), 0);
        assert!(price_identifier == example_price_identifier(), 0);

        price_info::destroy(price_info_object);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun switchboard_range_exceeded() {
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

        // modify the range to be 1/10th 
        let range = 80_001 * 10u128.pow(18);

        // set the current value (scaled, of course)
        aggregator::set_current_value(
            &mut aggregator,
            switchboard_decimal::new(price, true),
            1337,
            1337,
            1337,
            switchboard_decimal::new(low_price, true),
            switchboard_decimal::new(high_price, true),
            switchboard_decimal::new(0, false),
            switchboard_decimal::new(range, false),
            switchboard_decimal::new(price, true)
        );

        let (spot_price, price_identifier) = get_switchboard_price_and_identifier(&aggregator, &clock);
        assert!(spot_price == option::none(), 0);
        assert!(price_identifier == aggregator.id(), 0);

        switchboard::aggregator_delete_action::run(aggregator, sui::test_scenario::ctx(&mut scenario));
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun pyth_price_is_stale() {
        use sui::test_scenario::{Self};
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 61_000);

        let price_info_object = price_info::new_price_info_object_for_testing(
            price_info::new_price_info(
                0,
                0,
                price_feed::new(
                    example_price_identifier(),
                    price::new(
                        i64::new(100, false),
                        0,
                        i64::new(5, false),
                        0
                    ),
                    price::new(
                        i64::new(8, false),
                        0,
                        i64::new(4, true),
                        0
                    )
                )
            ),
            test_scenario::ctx(&mut scenario)
        );

        let (spot_price, ema_price, price_identifier) = get_pyth_price_and_identifier(&price_info_object, &clock);

        assert!(spot_price == option::none(), 0);
        assert!(ema_price == decimal::from_bps(8), 0);
        assert!(price_identifier == example_price_identifier(), 0);

        price_info::destroy(price_info_object);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun switchboard_price_is_stale() {
        use sui::test_scenario::{Self};
        use switchboard::decimal as switchboard_decimal;
        use switchboard::aggregator;

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 610_000);

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

        let (spot_price, price_identifier) = get_switchboard_price_and_identifier(&aggregator,  &clock);
        assert!(spot_price == option::none(), 0);
        assert!(price_identifier == aggregator.id(), 0);

        switchboard::aggregator_delete_action::run(aggregator, sui::test_scenario::ctx(&mut scenario));
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);

    }
}

