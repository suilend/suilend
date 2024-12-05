#[test_only]
module suilend::mock_switchboard {
    use switchboard::aggregator::Aggregator;
    use switchboard::queue::Queue;
    use std::string;
    use sui::bag::{Self, Bag};
    use sui::clock::{Clock};
    use sui::test_scenario::{Scenario};

    public struct PriceState has key {
        id: UID,
        price_objs: Bag
    }

    public fun init_state(scenario: &mut Scenario): PriceState {
        build_test_queues(scenario);
        PriceState {
            id: object::new(sui::test_scenario::ctx(scenario)),
            price_objs: bag::new(sui::test_scenario::ctx(scenario))
        }
    }

    public fun register<T>(scenario: &mut Scenario, clock: &Clock, state: &mut PriceState) {
        let id = new_aggregator((bag::length(&state.price_objs) as u8), scenario, clock);
        bag::add(&mut state.price_objs, std::type_name::get<T>(), id);
    }

    public fun build_test_queues(scenario: &mut Scenario): ID {
        let queue_key = x"963fead0d455c024345ec1c3726843693bbe6426825862a6d38ba9ccd8e5bd7c";
        let authority = @0x27;
        let name = string::utf8(b"Mainnet Guardian Queue");
        let fee = 0;
        let fee_recipient = @0x27;
        let min_attestations = 3;
        let oracle_validity_length_ms = 1000 * 60 * 60 * 24 * 365 * 5;
        switchboard::guardian_queue_init_action::run(
            queue_key,
            authority,
            name,
            fee,
            fee_recipient,
            min_attestations,
            oracle_validity_length_ms,
            sui::test_scenario::ctx(scenario),
        );
        sui::test_scenario::next_tx(scenario, authority);
        let guardian_queue = sui::test_scenario::take_shared<Queue>(scenario);
        switchboard::oracle_queue_init_action::run(
            queue_key,
            authority,
            name,
            fee,
            fee_recipient,
            min_attestations,
            oracle_validity_length_ms,
            &guardian_queue,
            sui::test_scenario::ctx(scenario)
        );
        sui::test_scenario::return_shared(guardian_queue);
        sui::test_scenario::next_tx(scenario, authority);
        sui::test_scenario::most_recent_id_shared<Queue>().extract()
    }

    public fun new_aggregator(idx: u8, scenario: &mut Scenario, clock: &Clock): ID {
        let mut v = vector::empty<u8>();
        vector::push_back(&mut v, idx);
        let mut i = 1;
        while (i < 32) {
            vector::push_back(&mut v, 0);
            i = i + 1;
        }; 

        let oracle_queue = sui::test_scenario::take_shared<Queue>(scenario);
        switchboard::aggregator_init_action::run(
            &oracle_queue,
            @0x26,
            string::utf8(b"test"),
            v,
            1,
            60,
            1_000_000_000,
            1,
            clock,
            sui::test_scenario::ctx(scenario)
        );

        sui::test_scenario::return_shared(oracle_queue);
        sui::test_scenario::next_tx(scenario, @0x26);
        sui::test_scenario::most_recent_id_shared<Aggregator>().extract()
    }

    public fun get_aggregator<T>(scenario: &Scenario, state: &PriceState): Aggregator {
        let id: ID = *bag::borrow(&state.price_objs, std::type_name::get<T>());
        sui::test_scenario::take_shared_by_id<Aggregator>(scenario, id)
    }

    public fun return_aggregator(aggregator: Aggregator) {
        sui::test_scenario::return_shared(aggregator);
    }


    public fun get_aggregator_id<T>(state: &PriceState): ID {
        *bag::borrow(&state.price_objs, std::type_name::get<T>())
    }

    public fun update_price<T>(scenario: &Scenario, state: &mut PriceState, price: u64, expo: u8, clock: &Clock) {
        let id: ID = *bag::borrow(&state.price_objs, std::type_name::get<T>());
        let mut aggregator = sui::test_scenario::take_shared_by_id<Aggregator>(scenario, id);

        let price = std::u128::pow(10, expo) * (price as u128);
        let dec = switchboard::decimal::new(price as u128, false);

        // scale the price to 18 decimals / extract the value
        let raw_scaled = dec.scale_to_decimals(0);

        // set that scaled price as the current value
        let sb_decimal = switchboard::decimal::new(raw_scaled, false);

        // set the current value for the aggregator
        switchboard::aggregator::set_current_value(
            &mut aggregator,
            copy sb_decimal,
            clock.timestamp_ms(),
            clock.timestamp_ms(),
            clock.timestamp_ms(),
            copy sb_decimal,
            copy sb_decimal,
            switchboard::decimal::new(0, false),
            switchboard::decimal::new(0, false),
            copy sb_decimal
        );

        // place it in the global state
        sui::test_scenario::return_shared(aggregator);
    }
}
