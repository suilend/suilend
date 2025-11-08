#[test_only]
module suilend::obligation_tests {
    use std::type_name;
    use sui::clock;
    use sui::test_scenario;
    use suilend::decimal::{Self, add};
    use suilend::liquidity_mining;
    use suilend::obligation::{
        Self,
        create_obligation,
        deposit,
        borrow,
        refresh,
        withdraw,
        repay,
        liquidate,
        forgive,
        create_borrow_for_testing
    };
    use suilend::reserve::{Self, Reserve, config};
    use suilend::reserve_config::{Self, default_reserve_config};

    public struct TEST_MARKET {}

    public struct TEST_SUI {}

    public struct TEST_USDC {}

    public struct TEST_USDT {}

    public struct TEST_ETH {}

    public struct TEST_AUSD {}

    fun sui_reserve<P>(ctx: &mut TxContext): Reserve<P> {
        let config = default_reserve_config(ctx);
        let mut builder = reserve_config::from(&config, ctx);
        reserve_config::set_open_ltv_pct(&mut builder, 20);
        reserve_config::set_close_ltv_pct(&mut builder, 50);
        reserve_config::set_max_close_ltv_pct(&mut builder, 50);
        reserve_config::set_interest_rate_utils(&mut builder, {
                let mut v = vector::empty();
                vector::push_back(&mut v, 0);
                vector::push_back(&mut v, 100);
                v
            });
        reserve_config::set_interest_rate_aprs(&mut builder, {
                let mut v = vector::empty();
                vector::push_back(&mut v, 31536000 * 4);
                vector::push_back(&mut v, 31536000 * 8);
                v
            });

        sui::test_utils::destroy(config);
        let config = reserve_config::build(builder, ctx);
        reserve::create_for_testing<P, TEST_SUI>(
            config,
            0,
            9,
            decimal::from(10),
            0,
            0,
            0,
            decimal::from(0),
            decimal::from(3),
            0,
            ctx,
        )
    }

    fun usdc_reserve<P>(ctx: &mut TxContext): Reserve<P> {

        let config = default_reserve_config(ctx);
        let mut builder = reserve_config::from(&config, ctx);
        reserve_config::set_open_ltv_pct(&mut builder, 50);
        reserve_config::set_close_ltv_pct(&mut builder, 80);
        reserve_config::set_max_close_ltv_pct(&mut builder, 80);
        reserve_config::set_borrow_weight_bps(&mut builder, 20_000);
        reserve_config::set_interest_rate_utils(&mut builder, {
                let mut v = vector::empty();
                vector::push_back(&mut v, 0);
                vector::push_back(&mut v, 100);
                v
            });
        reserve_config::set_interest_rate_aprs(&mut builder, {
                let mut v = vector::empty();
                vector::push_back(&mut v, 3153600000);
                vector::push_back(&mut v, 3153600000 * 2);
                v
            });

        sui::test_utils::destroy(config);
        let config = reserve_config::build(builder, ctx);

        reserve::create_for_testing<P, TEST_USDC>(
            config,
            1,
            6,
            decimal::from(1),
            0,
            0,
            0,
            decimal::from(0),
            decimal::from(2),
            0,
            ctx,
        )
    }

    fun usdt_reserve<P>(ctx: &mut TxContext): Reserve<P> {
        let config = default_reserve_config(ctx);
        let mut builder = reserve_config::from(&config, ctx);
        reserve_config::set_open_ltv_pct(&mut builder, 50);
        reserve_config::set_close_ltv_pct(&mut builder, 80);
        reserve_config::set_max_close_ltv_pct(&mut builder, 80);
        reserve_config::set_borrow_weight_bps(&mut builder, 20_000);
        reserve_config::set_interest_rate_utils(&mut builder, {
                let mut v = vector::empty();
                vector::push_back(&mut v, 0);
                vector::push_back(&mut v, 100);
                v
            });
        reserve_config::set_interest_rate_aprs(&mut builder, {
                let mut v = vector::empty();
                vector::push_back(&mut v, 3153600000);
                vector::push_back(&mut v, 3153600000 * 2);

                v
            });

        sui::test_utils::destroy(config);
        let config = reserve_config::build(builder, ctx);

        reserve::create_for_testing<P, TEST_USDT>(
            config,
            2,
            6,
            decimal::from(1),
            0,
            0,
            0,
            decimal::from(0),
            decimal::from(2),
            0,
            ctx,
        )
    }

    fun eth_reserve<P>(ctx: &mut TxContext): Reserve<P> {
        let config = default_reserve_config(ctx);
        let mut builder = reserve_config::from(&config, ctx);
        reserve_config::set_open_ltv_pct(&mut builder, 10);
        reserve_config::set_close_ltv_pct(&mut builder, 20);
        reserve_config::set_max_close_ltv_pct(&mut builder, 20);
        reserve_config::set_borrow_weight_bps(&mut builder, 30_000);
        reserve_config::set_interest_rate_utils(&mut builder, {
                let mut v = vector::empty();
                vector::push_back(&mut v, 0);
                vector::push_back(&mut v, 100);
                v
            });
        reserve_config::set_interest_rate_aprs(&mut builder, {
                let mut v = vector::empty();
                vector::push_back(&mut v, 3153600000 * 10);
                vector::push_back(&mut v, 3153600000 * 20);

                v
            });

        sui::test_utils::destroy(config);
        let config = reserve_config::build(builder, ctx);

        reserve::create_for_testing<P, TEST_ETH>(
            config,
            3,
            8,
            decimal::from(2000),
            0,
            0,
            0,
            decimal::from(0),
            decimal::from(3),
            0,
            ctx,
        )
    }

    fun ausd_reserve<P>(ctx: &mut TxContext): Reserve<P> {
        let config = default_reserve_config(ctx);
        let mut builder = reserve_config::from(&config, ctx);
        reserve_config::set_open_ltv_pct(&mut builder, 50);
        reserve_config::set_close_ltv_pct(&mut builder, 80);
        reserve_config::set_max_close_ltv_pct(&mut builder, 80);
        reserve_config::set_borrow_weight_bps(&mut builder, 20_000);
        reserve_config::set_interest_rate_utils(&mut builder, {
                let mut v = vector::empty();
                vector::push_back(&mut v, 0);
                vector::push_back(&mut v, 100);
                v
            });
        reserve_config::set_interest_rate_aprs(&mut builder, {
                let mut v = vector::empty();
                vector::push_back(&mut v, 3153600000);
                vector::push_back(&mut v, 3153600000 * 2);

                v
            });

        sui::test_utils::destroy(config);
        let config = reserve_config::build(builder, ctx);

        reserve::create_for_testing<P, TEST_AUSD>(
            config,
            5,
            6,
            decimal::from(1),
            0,
            0,
            0,
            decimal::from(0),
            decimal::from(2),
            0,
            ctx,
        )
    }

    fun reserves<P>(ctx: &mut TxContext): vector<Reserve<P>> {
        let mut v = vector::empty();
        vector::push_back(&mut v, sui_reserve(ctx));
        vector::push_back(&mut v, usdc_reserve(ctx));
        vector::push_back(&mut v, usdt_reserve(ctx));
        vector::push_back(&mut v, eth_reserve(ctx));
        vector::push_back(&mut v, ausd_reserve(ctx));

        v
    }

    fun get_reserve_array_index<P, T>(reserves: &vector<Reserve<P>>): u64 {
        let mut i = 0;
        while (i < vector::length(reserves)) {
            let reserve = vector::borrow(reserves, i);
            if (type_name::with_defining_ids<T>() == reserve::coin_type(reserve)) {
                return i
            };

            i = i + 1;
        };

        i
    }

    fun get_reserve<P, T>(reserves: &vector<Reserve<P>>): &Reserve<P> {
        let i = get_reserve_array_index<P, T>(reserves);
        assert!(i < vector::length(reserves));
        vector::borrow(reserves, i)
    }

    fun get_reserve_mut<P, T>(reserves: &mut vector<Reserve<P>>): &mut Reserve<P> {
        let i = get_reserve_array_index<P, T>(reserves);
        assert!(i < vector::length(reserves));
        vector::borrow_mut(reserves, i)
    }

    #[test]
    public fun test_deposit() {
        use sui::test_utils::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));

        let mut usdc_reserve = usdc_reserve(scenario.ctx());
        let mut sui_reserve = sui_reserve(scenario.ctx());

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        reserve::update_price_for_testing(
            &mut usdc_reserve,
            &clock,
            decimal::from(1),
            decimal::from_percent(90),
        );
        reserve::update_price_for_testing(
            &mut sui_reserve,
            &clock,
            decimal::from(10),
            decimal::from(9),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 100 * 1_000_000);
        deposit<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 100 * 1_000_000);
        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);

        let deposits = obligation.deposits();
        assert!(deposits.length() == 2);

        let usdc_deposit = &deposits[0];
        assert!(usdc_deposit.deposited_ctoken_amount() == 200 * 1_000_000);
        assert!(usdc_deposit.market_value() == decimal::from(200));

        let user_reward_manager =
            &obligation.user_reward_managers()[usdc_deposit.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 200 * 1_000_000);

        let sui_deposit = &deposits[1];
        assert!(sui_deposit.deposited_ctoken_amount() == 100 * 1_000_000_000);
        assert!(sui_deposit.market_value() == decimal::from(1000));

        let user_reward_manager =
            &obligation.user_reward_managers()[sui_deposit.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 100 * 1_000_000_000);

        assert!(obligation.borrows().length() == 0);
        assert!(obligation.deposited_value_usd() == decimal::from(1200));
        assert!(obligation.allowed_borrow_value_usd() == decimal::from(270));
        assert!(obligation.unhealthy_borrow_value_usd() == decimal::from(660));
        assert!(obligation.unweighted_borrowed_value_usd() == decimal::from(0));
        assert!(obligation.weighted_borrowed_value_usd() == decimal::from(0));

        sui::test_utils::destroy(lending_market_id);
        test_utils::destroy(usdc_reserve);
        test_utils::destroy(sui_reserve);
        test_utils::destroy(obligation);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::obligation::EObligationIsNotHealthy)]
    public fun test_borrow_fail() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut usdc_reserve = usdc_reserve(scenario.ctx());
        let mut sui_reserve = sui_reserve(scenario.ctx());

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);
        borrow<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 200 * 1_000_000 + 1);

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(usdc_reserve);
        sui::test_utils::destroy(sui_reserve);
        sui::test_utils::destroy(obligation);
        sui::test_utils::destroy(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::obligation::ECannotDepositAndBorrowSameAsset)]
    public fun test_borrow_fail_deposit_borrow_same_asset_1() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut usdc_reserve = usdc_reserve(scenario.ctx());
        let mut sui_reserve = sui_reserve(scenario.ctx());

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);
        borrow<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 1);
        deposit<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 1);

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(usdc_reserve);
        sui::test_utils::destroy(sui_reserve);
        sui::test_utils::destroy(obligation);
        sui::test_utils::destroy(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::obligation::ECannotDepositAndBorrowSameAsset)]
    public fun test_borrow_fail_deposit_borrow_same_asset_2() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut sui_reserve = sui_reserve(scenario.ctx());

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);
        borrow<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 1);

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(sui_reserve);
        sui::test_utils::destroy(obligation);
        sui::test_utils::destroy(clock);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_borrow_isolated_happy() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            100 * 1_000_000_000,
        );

        let config = {
            let mut builder = reserve_config::from(
                config(get_reserve<TEST_MARKET, TEST_USDC>(&reserves)),
                test_scenario::ctx(&mut scenario),
            );
            reserve_config::set_open_ltv_pct(&mut builder, 0);
            reserve_config::set_close_ltv_pct(&mut builder, 0);
            reserve_config::set_isolated(&mut builder, true);
            reserve_config::build(builder, test_scenario::ctx(&mut scenario))
        };

        reserve::update_reserve_config(
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            config,
        );

        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            1,
        );

        let exist_stale_oracles = refresh<TEST_MARKET>(&mut obligation, &mut reserves, &clock);
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        // this fails
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            1,
        );

        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::obligation::EIsolatedAssetViolation)]
    public fun test_borrow_isolated_fail() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            100 * 1_000_000_000,
        );

        let config = {
            let mut builder = reserve_config::from(
                config(get_reserve<TEST_MARKET, TEST_USDC>(&reserves)),
                test_scenario::ctx(&mut scenario),
            );
            reserve_config::set_open_ltv_pct(&mut builder, 0);
            reserve_config::set_close_ltv_pct(&mut builder, 0);
            reserve_config::set_isolated(&mut builder, true);
            reserve_config::build(builder, test_scenario::ctx(&mut scenario))
        };

        reserve::update_reserve_config(
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            config,
        );

        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            1,
        );

        let exist_stale_oracles = refresh<TEST_MARKET>(&mut obligation, &mut reserves, &clock);
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        // this fails
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
            &clock,
            1,
        );

        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::obligation::EIsolatedAssetViolation)]
    public fun test_borrow_isolated_fail_2() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            100 * 1_000_000_000,
        );

        let config = {
            let mut builder = reserve_config::from(
                config(get_reserve<TEST_MARKET, TEST_USDC>(&reserves)),
                test_scenario::ctx(&mut scenario),
            );
            reserve_config::set_open_ltv_pct(&mut builder, 0);
            reserve_config::set_close_ltv_pct(&mut builder, 0);
            reserve_config::set_isolated(&mut builder, true);
            reserve_config::build(builder, test_scenario::ctx(&mut scenario))
        };

        reserve::update_reserve_config(
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            config,
        );

        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
            &clock,
            1,
        );

        let exist_stale_oracles = refresh<TEST_MARKET>(&mut obligation, &mut reserves, &clock);
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        // this fails
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            1,
        );

        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_max_borrow() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));

        let mut usdc_reserve = usdc_reserve(scenario.ctx());
        let mut sui_reserve = sui_reserve(scenario.ctx());

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

        reserve::update_price_for_testing(
            &mut usdc_reserve,
            &clock,
            decimal::from(1),
            decimal::from(2),
        );
        reserve::update_price_for_testing(
            &mut sui_reserve,
            &clock,
            decimal::from(10),
            decimal::from(5),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);

        let max_borrow = obligation.max_borrow_amount(&usdc_reserve);
        assert!(max_borrow == 25_000_000);

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(usdc_reserve);
        sui::test_utils::destroy(sui_reserve);
        sui::test_utils::destroy(obligation);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_borrow_happy() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));

        let mut usdc_reserve = usdc_reserve(scenario.ctx());
        let mut sui_reserve = sui_reserve(scenario.ctx());

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

        reserve::update_price_for_testing(
            &mut usdc_reserve,
            &clock,
            decimal::from(1),
            decimal::from(2),
        );
        reserve::update_price_for_testing(
            &mut sui_reserve,
            &clock,
            decimal::from(10),
            decimal::from(5),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);
        borrow<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 12_500_000);
        borrow<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 12_500_000);

        assert!(obligation.deposits().length() == 1);

        let sui_deposit = &obligation.deposits()[0];
        assert!(sui_deposit.deposited_ctoken_amount() == 100 * 1_000_000_000);
        assert!(sui_deposit.market_value() == decimal::from(1000));

        let user_reward_manager =
            &obligation.user_reward_managers()[sui_deposit.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 100 * 1_000_000_000);

        assert!(obligation.borrows().length() == 1);

        let usdc_borrow = &obligation.borrows()[0];
        assert!(usdc_borrow.borrowed_amount() == decimal::from(25 * 1_000_000));
        assert!(usdc_borrow.cumulative_borrow_rate() == decimal::from(2));
        assert!(usdc_borrow.market_value() == decimal::from(25));

        let user_reward_manager =
            &obligation.user_reward_managers()[usdc_borrow.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 25 * 1_000_000 / 2);

        assert!(obligation.deposited_value_usd() == decimal::from(1000));
        assert!(obligation.allowed_borrow_value_usd() == decimal::from(100));
        assert!(obligation.unhealthy_borrow_value_usd() == decimal::from(500));
        assert!(obligation.unweighted_borrowed_value_usd() == decimal::from(25));
        assert!(obligation.weighted_borrowed_value_usd() == decimal::from(50));
        assert!(obligation.weighted_borrowed_value_upper_bound_usd() == decimal::from(100));

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(usdc_reserve);
        sui::test_utils::destroy(sui_reserve);
        sui::test_utils::destroy(obligation);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::obligation::EObligationIsNotHealthy)]
    public fun test_withdraw_fail_unhealthy() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));

        let mut usdc_reserve = usdc_reserve(scenario.ctx());
        let mut sui_reserve = sui_reserve(scenario.ctx());
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);
        borrow<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 50 * 1_000_000);

        withdraw<TEST_MARKET>(
            &mut obligation,
            &mut sui_reserve,
            &clock,
            50 * 1_000_000_000 + 1,
            option::none(),
        );

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(usdc_reserve);
        sui::test_utils::destroy(sui_reserve);
        sui::test_utils::destroy(obligation);
        sui::test_utils::destroy(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::obligation::EDepositNotFound)]
    public fun test_withdraw_fail_deposit_not_found() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));

        let mut usdc_reserve = usdc_reserve(scenario.ctx());
        let mut sui_reserve = sui_reserve(scenario.ctx());
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);
        borrow<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 50 * 1_000_000);

        withdraw<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 1, option::none());

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(usdc_reserve);
        sui::test_utils::destroy(sui_reserve);
        sui::test_utils::destroy(obligation);
        sui::test_utils::destroy(clock);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_max_withdraw() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));

        let mut usdc_reserve = usdc_reserve(scenario.ctx());
        let mut usdt_reserve = usdt_reserve(scenario.ctx());
        let mut sui_reserve = sui_reserve(scenario.ctx());

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

        reserve::update_price_for_testing(
            &mut usdc_reserve,
            &clock,
            decimal::from(1),
            decimal::from(2),
        );
        reserve::update_price_for_testing(
            &mut usdt_reserve,
            &clock,
            decimal::from(1),
            decimal::from(2),
        );
        reserve::update_price_for_testing(
            &mut sui_reserve,
            &clock,
            decimal::from(10),
            decimal::from(5),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);

        let amount = obligation.max_withdraw_amount(&sui_reserve);
        assert!(amount == 100 * 1_000_000_000);

        borrow<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 20 * 1_000_000);

        // sui open ltv is 0.2
        // allowed borrow value = 100 * 0.2 * 5 = 100
        // weighted upper bound borrow value = 20 * 2 * 2 = 80
        // => max withdraw amount should be 20
        let amount = obligation.max_withdraw_amount(&sui_reserve);
        assert!(amount == 20 * 1_000_000_000);

        deposit<TEST_MARKET>(&mut obligation, &mut usdt_reserve, &clock, 100 * 1_000_000);

        let amount = obligation.max_withdraw_amount(&usdt_reserve);
        assert!(amount == 100 * 1_000_000);

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(usdc_reserve);
        sui::test_utils::destroy(usdt_reserve);
        sui::test_utils::destroy(sui_reserve);
        sui::test_utils::destroy(obligation);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_withdraw_happy() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));

        let mut usdc_reserve = usdc_reserve(scenario.ctx());
        let mut sui_reserve = sui_reserve(scenario.ctx());

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

        reserve::update_price_for_testing(
            &mut usdc_reserve,
            &clock,
            decimal::from(1),
            decimal::from(2),
        );
        reserve::update_price_for_testing(
            &mut sui_reserve,
            &clock,
            decimal::from(10),
            decimal::from(5),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);
        borrow<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 20 * 1_000_000);
        withdraw<TEST_MARKET>(
            &mut obligation,
            &mut sui_reserve,
            &clock,
            20 * 1_000_000_000,
            option::none(),
        );

        assert!(obligation.deposits().length() == 1);

        let sui_deposit = &obligation.deposits()[0];
        assert!(sui_deposit.deposited_ctoken_amount() == 80 * 1_000_000_000);
        assert!(sui_deposit.market_value() == decimal::from(800));

        let user_reward_manager =
            &obligation.user_reward_managers()[sui_deposit.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 80 * 1_000_000_000);

        assert!(obligation.borrows().length() == 1);

        let usdc_borrow = &obligation.borrows()[0];
        assert!(usdc_borrow.borrowed_amount() == decimal::from(20 * 1_000_000));
        assert!(usdc_borrow.cumulative_borrow_rate() == decimal::from(2));
        assert!(usdc_borrow.market_value() == decimal::from(20));

        let user_reward_manager =
            &obligation.user_reward_managers()[usdc_borrow.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 20 * 1_000_000 / 2);

        assert!(obligation.deposited_value_usd() == decimal::from(800));
        assert!(obligation.allowed_borrow_value_usd() == decimal::from(80));
        assert!(obligation.unhealthy_borrow_value_usd() == decimal::from(400));
        assert!(obligation.unweighted_borrowed_value_usd() == decimal::from(20));
        assert!(obligation.weighted_borrowed_value_usd() == decimal::from(40));
        assert!(obligation.weighted_borrowed_value_upper_bound_usd() == decimal::from(80));

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(usdc_reserve);
        sui::test_utils::destroy(sui_reserve);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_repay_happy() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut usdc_reserve = usdc_reserve(scenario.ctx());
        let mut sui_reserve = sui_reserve(scenario.ctx());

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        reserve::update_price_for_testing(
            &mut usdc_reserve,
            &clock,
            decimal::from(1),
            decimal::from(2),
        );
        reserve::update_price_for_testing(
            &mut sui_reserve,
            &clock,
            decimal::from(10),
            decimal::from(5),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);
        borrow<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 25 * 1_000_000);

        clock::set_for_testing(&mut clock, 1000);
        reserve::compound_interest(&mut usdc_reserve, &clock);

        let repay_amount = repay<TEST_MARKET>(
            &mut obligation,
            &mut usdc_reserve,
            &clock,
            decimal::from(25 * 1_000_000),
        );
        assert!(repay_amount == decimal::from(25 * 1_000_000));

        assert!(obligation.deposits().length() == 1);

        let sui_deposit = &obligation.deposits()[0];
        assert!(sui_deposit.deposited_ctoken_amount() == 100 * 1_000_000_000);
        assert!(sui_deposit.market_value() == decimal::from(1000));

        let user_reward_manager =
            &obligation.user_reward_managers()[sui_deposit.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 100 * 1_000_000_000);

        assert!(obligation.borrows().length() == 1);

        // borrow was compounded by 1% so there should be borrows outstanding
        let usdc_borrow = &obligation.borrows()[0];
        assert!(usdc_borrow.borrowed_amount() == decimal::from(250_000));
        assert!(usdc_borrow.cumulative_borrow_rate() == decimal::from_percent(202));
        assert!(usdc_borrow.market_value() == decimal::from_percent(25));

        let user_reward_manager =
            &obligation.user_reward_managers()[usdc_borrow.user_reward_manager_index()];
        // 250_000 / 2.02 = 123762.376238
        assert!(liquidity_mining::shares(user_reward_manager) == 123_762);

        assert!(obligation.deposited_value_usd() == decimal::from(1000));
        assert!(obligation.allowed_borrow_value_usd() == decimal::from(100));
        assert!(obligation.unhealthy_borrow_value_usd() == decimal::from(500));
        assert!(obligation.unweighted_borrowed_value_usd() == decimal::from_percent(25));
        assert!(obligation.weighted_borrowed_value_usd() == decimal::from_percent(50));
        assert!(obligation.weighted_borrowed_value_upper_bound_usd() == decimal::from(1));

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(usdc_reserve);
        sui::test_utils::destroy(sui_reserve);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_repay_happy_2() {
        let owner = @0x27777;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut usdc_reserve = usdc_reserve(scenario.ctx());
        let mut sui_reserve = sui_reserve(scenario.ctx());

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);
        borrow<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 100 * 1_000_000);

        clock::set_for_testing(&mut clock, 1000);
        reserve::compound_interest(&mut usdc_reserve, &clock);

        let repay_amount = repay<TEST_MARKET>(
            &mut obligation,
            &mut usdc_reserve,
            &clock,
            decimal::from(500_000),
        );
        assert!(repay_amount == decimal::from(500_000));

        assert!(obligation.deposits().length() == 1);

        let sui_deposit = &obligation.deposits()[0];
        assert!(sui_deposit.deposited_ctoken_amount() == 100 * 1_000_000_000);
        assert!(sui_deposit.market_value() == decimal::from(1000));

        let user_reward_manager =
            &obligation.user_reward_managers()[sui_deposit.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 100 * 1_000_000_000);

        assert!(obligation.borrows().length() == 1);

        // borrow was compounded by 1% so there should be borrows outstanding
        let usdc_borrow = &obligation.borrows()[0];
        assert!(usdc_borrow.borrowed_amount() == decimal::from(101 * 1_000_000 - 500_000));
        assert!(usdc_borrow.cumulative_borrow_rate() == decimal::from_percent(202));
        assert!(usdc_borrow.market_value() == decimal::from_percent_u64(10_050));

        let user_reward_manager =
            &obligation.user_reward_managers()[usdc_borrow.user_reward_manager_index()];
        // (101 * 1e6 - 500_000) / 2.02 == 49752475.2475
        assert!(liquidity_mining::shares(user_reward_manager) == 49752475);

        assert!(obligation.deposited_value_usd() == decimal::from(1000));
        assert!(obligation.allowed_borrow_value_usd() == decimal::from(200));
        assert!(obligation.unhealthy_borrow_value_usd() == decimal::from(500));
        assert!(obligation.unweighted_borrowed_value_usd() == decimal::from_percent_u64(10_050));
        assert!(obligation.weighted_borrowed_value_usd() == decimal::from_percent_u64(20_100));

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(usdc_reserve);
        sui::test_utils::destroy(sui_reserve);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_repay_regression() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut usdc_reserve = usdc_reserve(scenario.ctx());
        let mut sui_reserve = sui_reserve(scenario.ctx());

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);
        borrow<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 100 * 1_000_000);

        clock::set_for_testing(&mut clock, 1000);
        reserve::update_price_for_testing(
            &mut usdc_reserve,
            &clock,
            decimal::from(10),
            decimal::from(10),
        );

        reserve::compound_interest(&mut usdc_reserve, &clock);
        let _repay_amount = repay<TEST_MARKET>(
            &mut obligation,
            &mut usdc_reserve,
            &clock,
            decimal::from(100 * 1_000_000),
        );

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(usdc_reserve);
        sui::test_utils::destroy(sui_reserve);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_repay_max() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut usdc_reserve = usdc_reserve(scenario.ctx());
        let mut sui_reserve = sui_reserve(scenario.ctx());

        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(&mut obligation, &mut sui_reserve, &clock, 100 * 1_000_000_000);
        borrow<TEST_MARKET>(&mut obligation, &mut usdc_reserve, &clock, 100 * 1_000_000);

        let repay_amount = repay<TEST_MARKET>(
            &mut obligation,
            &mut usdc_reserve,
            &clock,
            decimal::from(101 * 1_000_000),
        );
        assert!(repay_amount == decimal::from(100 * 1_000_000));

        assert!(obligation.deposits().length() == 1);

        let sui_deposit = &obligation.deposits()[0];
        assert!(sui_deposit.deposited_ctoken_amount() == 100 * 1_000_000_000);
        assert!(sui_deposit.market_value() == decimal::from(1000));

        assert!(obligation.borrows().length() == 0);

        let user_reward_manager_index = obligation.find_user_reward_manager_index(
            reserve::borrows_pool_reward_manager_mut(&mut usdc_reserve),
        );
        let user_reward_manager = &obligation.user_reward_managers()[user_reward_manager_index];
        assert!(liquidity_mining::shares(user_reward_manager) == 0);

        assert!(obligation.deposited_value_usd() == decimal::from(1000));
        assert!(obligation.allowed_borrow_value_usd() == decimal::from(200));
        assert!(obligation.unhealthy_borrow_value_usd() == decimal::from(500));
        assert!(obligation.unweighted_borrowed_value_usd() == decimal::from_percent_u64(0));
        assert!(obligation.weighted_borrowed_value_usd() == decimal::from_percent_u64(0));

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(usdc_reserve);
        sui::test_utils::destroy(sui_reserve);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::obligation::EOraclesAreStale)]
    public fun test_refresh_fail_deposit_price_stale() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            100 * 1_000_000,
        );

        clock::set_for_testing(&mut clock, 1000);

        let exist_stale_oracles = refresh<TEST_MARKET>(
            &mut obligation,
            &mut reserves,
            &clock,
        );
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        sui::test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::obligation::EOraclesAreStale)]
    public fun test_refresh_fail_borrow_price_stale() {
        use sui::test_utils::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            100 * 1_000_000_000,
        );
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            100 * 1_000_000,
        );

        clock::set_for_testing(&mut clock, 1000);
        reserve::update_price_for_testing(
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            decimal::from(10),
            decimal::from(10),
        );

        let exist_stale_oracles = refresh<TEST_MARKET>(
            &mut obligation,
            &mut reserves,
            &clock,
        );
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_refresh_happy() {
        use sui::test_utils::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            100 * 1_000_000_000,
        );
        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            100 * 1_000_000,
        );
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
            &clock,
            100 * 1_000_000,
        );

        clock::set_for_testing(&mut clock, 1000);
        reserve::update_price_for_testing(
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            decimal::from(10),
            decimal::from(9),
        );
        reserve::update_price_for_testing(
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            decimal::from(1),
            decimal::from(2),
        );
        reserve::update_price_for_testing(
            get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
            &clock,
            decimal::from(1),
            decimal::from(2),
        );

        let exist_stale_oracles = refresh<TEST_MARKET>(
            &mut obligation,
            &mut reserves,
            &clock,
        );
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        assert!(obligation.deposits().length() == 2);

        let sui_deposit = &obligation.deposits()[0];
        assert!(sui_deposit.deposited_ctoken_amount() == 100 * 1_000_000_000);
        assert!(sui_deposit.market_value() == decimal::from(1000));

        let usdc_deposit = &obligation.deposits()[1];
        assert!(usdc_deposit.deposited_ctoken_amount() == 100 * 1_000_000);
        assert!(usdc_deposit.market_value() == decimal::from(100));

        assert!(obligation.borrows().length() == 1);

        let usdt_borrow = &obligation.borrows()[0];
        assert!(usdt_borrow.borrowed_amount() == decimal::from(101 * 1_000_000));
        assert!(usdt_borrow.cumulative_borrow_rate() == decimal::from_percent(202));
        assert!(usdt_borrow.market_value() == decimal::from(101));

        assert!(obligation.deposited_value_usd() == decimal::from(1100));
        assert!(obligation.allowed_borrow_value_usd() == decimal::from(230));
        assert!(obligation.unhealthy_borrow_value_usd() == decimal::from(580));
        assert!(obligation.unweighted_borrowed_value_usd() == decimal::from(101));
        assert!(obligation.weighted_borrowed_value_usd() == decimal::from(202));
        assert!(obligation.weighted_borrowed_value_upper_bound_usd() == decimal::from(404));

        test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::obligation::EObligationIsNotLiquidatable)]
    public fun test_liquidate_fail_healthy() {
        use sui::test_utils::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            100 * 1_000_000_000,
        );
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            100 * 1_000_000,
        );

        let exist_stale_oracles = refresh<TEST_MARKET>(
            &mut obligation,
            &mut reserves,
            &clock,
        );
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        liquidate<TEST_MARKET>(
            &mut obligation,
            &mut reserves,
            0,
            1,
            &clock,
            100 * 1_000_000_000,
        );

        test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_liquidate_happy_1() {
        use sui::test_utils::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            100 * 1_000_000_000,
        );
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            50 * 1_000_000,
        );
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
            &clock,
            50 * 1_000_000,
        );

        let config = {
            let mut builder = reserve_config::from(
                reserve::config(get_reserve<TEST_MARKET, TEST_SUI>(&reserves)),
                test_scenario::ctx(&mut scenario),
            );
            reserve_config::set_open_ltv_pct(&mut builder, 0);
            reserve_config::set_close_ltv_pct(&mut builder, 0);
            reserve_config::set_liquidation_bonus_bps(&mut builder, 1000);
            reserve_config::set_max_liquidation_bonus_bps(&mut builder, 1000);
            reserve_config::build(builder, test_scenario::ctx(&mut scenario))
        };
        reserve::update_reserve_config(
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            config,
        );

        let exist_stale_oracles = refresh<TEST_MARKET>(
            &mut obligation,
            &mut reserves,
            &clock,
        );
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        let (withdraw_amount, repay_amount) = liquidate<TEST_MARKET>(
            &mut obligation,
            &mut reserves,
            1,
            0,
            &clock,
            100 * 1_000_000_000,
        );
        assert!(withdraw_amount == 4_400_000_000);
        assert!(repay_amount == decimal::from(40 * 1_000_000));

        assert!(obligation.deposits().length() == 1);

        // $40 was liquidated with a 10% bonus = $44 = 4.4 sui => 95.6 sui remaining
        let sui_deposit = &obligation.deposits()[0];
        assert!(sui_deposit.deposited_ctoken_amount() == 95 * 1_000_000_000 + 600_000_000);
        assert!(sui_deposit.market_value() == decimal::from(956));

        let user_reward_manager =
            &obligation.user_reward_managers()[sui_deposit.user_reward_manager_index()];
        assert!(
            liquidity_mining::shares(user_reward_manager) == 95 * 1_000_000_000 + 600_000_000
        );

        assert!(obligation.borrows().length() == 2);

        let usdc_borrow = &obligation.borrows()[0];
        assert!(usdc_borrow.borrowed_amount() == decimal::from(10 * 1_000_000));
        assert!(usdc_borrow.market_value() == decimal::from(10));

        let user_reward_manager =
            &obligation.user_reward_managers()[usdc_borrow.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 10 * 1_000_000 / 2);

        let usdt_borrow = &obligation.borrows()[1];
        assert!(usdt_borrow.borrowed_amount() == decimal::from(50 * 1_000_000));
        assert!(usdt_borrow.market_value() == decimal::from(50));

        let user_reward_manager =
            &obligation.user_reward_managers()[usdt_borrow.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 50 * 1_000_000 / 2);

        assert!(obligation.deposited_value_usd() == decimal::from(956));
        assert!(obligation.allowed_borrow_value_usd() == decimal::from(0));
        assert!(obligation.unhealthy_borrow_value_usd() == decimal::from(0));
        assert!(obligation.unweighted_borrowed_value_usd() == decimal::from(60));
        assert!(obligation.weighted_borrowed_value_usd() == decimal::from(120));

        test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_liquidate_happy_2() {
        use sui::test_utils::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            1 * 1_000_000_000 + 100_000_000,
        );
        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_ETH>(&mut reserves),
            &clock,
            2 * 100_000_000,
        );
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            100 * 1_000_000,
        );

        let eth_reserve = get_reserve_mut<TEST_MARKET, TEST_ETH>(&mut reserves);
        let config = {
            let mut builder = reserve_config::from(
                reserve::config(eth_reserve),
                test_scenario::ctx(&mut scenario),
            );
            reserve_config::set_open_ltv_pct(&mut builder, 0);
            reserve_config::set_close_ltv_pct(&mut builder, 0);

            reserve_config::build(builder, test_scenario::ctx(&mut scenario))
        };
        reserve::update_reserve_config(eth_reserve, config);

        let sui_reserve = get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves);
        let config = {
            let mut builder = reserve_config::from(
                reserve::config(sui_reserve),
                test_scenario::ctx(&mut scenario),
            );
            reserve_config::set_open_ltv_pct(&mut builder, 0);
            reserve_config::set_close_ltv_pct(&mut builder, 0);
            reserve_config::set_liquidation_bonus_bps(&mut builder, 1000);
            reserve_config::set_max_liquidation_bonus_bps(&mut builder, 1000);

            reserve_config::build(builder, test_scenario::ctx(&mut scenario))
        };
        reserve::update_reserve_config(sui_reserve, config);

        let exist_stale_oracles = refresh<TEST_MARKET>(
            &mut obligation,
            &mut reserves,
            &clock,
        );
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        let (withdraw_amount, repay_amount) = liquidate<TEST_MARKET>(
            &mut obligation,
            &mut reserves,
            1,
            0,
            &clock,
            100 * 1_000_000_000,
        );
        assert!(withdraw_amount == 1_100_000_000);
        assert!(repay_amount == decimal::from(10 * 1_000_000));

        assert!(obligation.deposits().length() == 1);

        let user_reward_manager_index = obligation.find_user_reward_manager_index(
            reserve::deposits_pool_reward_manager_mut(
                get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            ),
        );
        let user_reward_manager = &obligation.user_reward_managers()[user_reward_manager_index];
        assert!(liquidity_mining::shares(user_reward_manager) == 0);

        let eth_deposit = &obligation.deposits()[0];
        assert!(eth_deposit.deposited_ctoken_amount() == 2 * 100_000_000);
        assert!(eth_deposit.market_value() == decimal::from(4000));

        let user_reward_manager =
            &obligation.user_reward_managers()[eth_deposit.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 2 * 100_000_000);

        assert!(obligation.borrows().length() == 1);

        let usdc_borrow = &obligation.borrows()[0];
        assert!(usdc_borrow.borrowed_amount() == decimal::from(90 * 1_000_000));
        assert!(usdc_borrow.market_value() == decimal::from(90));

        let user_reward_manager =
            &obligation.user_reward_managers()[usdc_borrow.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 90 * 1_000_000 / 2);

        assert!(obligation.deposited_value_usd() == decimal::from(4000));
        assert!(obligation.allowed_borrow_value_usd() == decimal::from(0));
        assert!(obligation.unhealthy_borrow_value_usd() == decimal::from(0));
        assert!(obligation.unweighted_borrowed_value_usd() == decimal::from(90));
        assert!(obligation.weighted_borrowed_value_usd() == decimal::from(180));

        test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_liquidate_full_1() {
        use sui::test_utils::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            100 * 1_000_000_000,
        );
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            1 * 1_000_000,
        );

        let config = {
            let mut builder = reserve_config::from(
                reserve::config(get_reserve<TEST_MARKET, TEST_SUI>(&reserves)),
                test_scenario::ctx(&mut scenario),
            );
            reserve_config::set_open_ltv_pct(&mut builder, 0);
            reserve_config::set_close_ltv_pct(&mut builder, 0);
            reserve_config::set_liquidation_bonus_bps(&mut builder, 1000);
            reserve_config::set_max_liquidation_bonus_bps(&mut builder, 1000);
            reserve_config::build(builder, test_scenario::ctx(&mut scenario))
        };
        reserve::update_reserve_config(
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            config,
        );

        let exist_stale_oracles = refresh<TEST_MARKET>(
            &mut obligation,
            &mut reserves,
            &clock,
        );
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        let (withdraw_amount, repay_amount) = liquidate<TEST_MARKET>(
            &mut obligation,
            &mut reserves,
            1,
            0,
            &clock,
            1_000_000_000,
        );
        assert!(withdraw_amount == 110_000_000);
        assert!(repay_amount == decimal::from(1_000_000));

        assert!(obligation.deposits().length() == 1);

        // $1 was liquidated with a 10% bonus = $1.1 => 0.11 sui => 99.89 sui remaining
        let sui_deposit = obligation.find_deposit(get_reserve<TEST_MARKET, TEST_SUI>(&reserves));
        assert!(sui_deposit.deposited_ctoken_amount() == 99 * 1_000_000_000 + 890_000_000);
        assert!(
            sui_deposit.market_value() == add(decimal::from(998), decimal::from_percent(90))
        );

        let user_reward_manager =
            &obligation.user_reward_managers()[sui_deposit.user_reward_manager_index()];
        assert!(
            liquidity_mining::shares(user_reward_manager) == 99 * 1_000_000_000 + 890_000_000
        );

        assert!(obligation.borrows().length() == 0);

        let user_reward_manager_index = obligation.find_user_reward_manager_index(
            reserve::borrows_pool_reward_manager_mut(
                get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            ),
        );
        let user_reward_manager = &obligation.user_reward_managers()[user_reward_manager_index];
        assert!(liquidity_mining::shares(user_reward_manager) == 0);

        assert!(
            obligation.deposited_value_usd() == add(decimal::from(998), decimal::from_percent(90))
        );
        assert!(obligation.allowed_borrow_value_usd() == decimal::from(0));
        assert!(obligation.unhealthy_borrow_value_usd() == decimal::from(0));
        assert!(obligation.unweighted_borrowed_value_usd() == decimal::from(0));
        assert!(obligation.weighted_borrowed_value_usd() == decimal::from(0));

        test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_liquidate_full_2() {
        use sui::test_utils::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            10 * 1_000_000_000,
        );
        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            550_000,
        );
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
            &clock,
            10 * 1_000_000,
        );

        let usdc_reserve = get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves);
        let config = {
            let mut builder = reserve_config::from(
                reserve::config(usdc_reserve),
                test_scenario::ctx(&mut scenario),
            );
            reserve_config::set_open_ltv_pct(&mut builder, 0);
            reserve_config::set_close_ltv_pct(&mut builder, 0);
            reserve_config::set_liquidation_bonus_bps(&mut builder, 1000);
            reserve_config::set_max_liquidation_bonus_bps(&mut builder, 1000);
            reserve_config::set_protocol_liquidation_fee_bps(&mut builder, 0);

            reserve_config::build(builder, test_scenario::ctx(&mut scenario))
        };
        reserve::update_reserve_config(usdc_reserve, config);

        let sui_reserve = get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves);
        let config = {
            let mut builder = reserve_config::from(
                reserve::config(sui_reserve),
                test_scenario::ctx(&mut scenario),
            );
            reserve_config::set_open_ltv_pct(&mut builder, 0);
            reserve_config::set_close_ltv_pct(&mut builder, 0);
            reserve_config::set_liquidation_bonus_bps(&mut builder, 1000);
            reserve_config::set_max_liquidation_bonus_bps(&mut builder, 1000);

            reserve_config::build(builder, test_scenario::ctx(&mut scenario))
        };
        reserve::update_reserve_config(sui_reserve, config);

        let exist_stale_oracles = refresh<TEST_MARKET>(
            &mut obligation,
            &mut reserves,
            &clock,
        );
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        let (withdraw_amount, repay_amount) = liquidate<TEST_MARKET>(
            &mut obligation,
            &mut reserves,
            2,
            1,
            &clock,
            100 * 1_000_000_000,
        );
        assert!(withdraw_amount == 550_000);
        assert!(repay_amount == decimal::from(500_000));

        assert!(obligation.deposits().length() == 1);

        // unchanged
        let sui_deposit = obligation.find_deposit(get_reserve<TEST_MARKET, TEST_SUI>(&reserves));
        assert!(sui_deposit.deposited_ctoken_amount() == 10_000_000_000);
        assert!(sui_deposit.market_value() == decimal::from(100));

        let user_reward_manager =
            &obligation.user_reward_managers()[sui_deposit.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 10_000_000_000);

        let user_reward_manager_index = obligation.find_user_reward_manager_index(
            reserve::deposits_pool_reward_manager_mut(
                get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            ),
        );
        let user_reward_manager = &obligation.user_reward_managers()[user_reward_manager_index];
        assert!(liquidity_mining::shares(user_reward_manager) == 0);

        assert!(obligation.borrows().length() == 1);

        let usdt_borrow = obligation.find_borrow(get_reserve<TEST_MARKET, TEST_USDT>(&reserves));
        assert!(usdt_borrow.borrowed_amount() == decimal::from(9_500_000));
        assert!(usdt_borrow.market_value() == decimal::from_percent_u64(950));

        let user_reward_manager =
            &obligation.user_reward_managers()[usdt_borrow.user_reward_manager_index()];
        assert!(liquidity_mining::shares(user_reward_manager) == 9_500_000 / 2);

        assert!(obligation.deposited_value_usd() == decimal::from(100));
        assert!(obligation.allowed_borrow_value_usd() == decimal::from(0));
        assert!(obligation.unhealthy_borrow_value_usd() == decimal::from(0));
        assert!(obligation.unweighted_borrowed_value_usd() == decimal::from_percent_u64(950));
        assert!(obligation.weighted_borrowed_value_usd() == decimal::from(19));

        test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::obligation::EObligationIsNotForgivable)]
    fun test_forgive_debt_fail() {
        use sui::test_utils::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            10 * 1_000_000_000,
        );
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            1_000_000,
        );

        forgive<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            decimal::from(1_000_000_000),
        );

        test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_is_looped() {
        use sui::test_utils::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            100 * 1_000_000,
        );
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            1_000_000_000,
        );

        assert!(!obligation.is_looped());

        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
            &clock,
            1_000_000,
        );

        assert!(obligation.is_looped());

        repay<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
            &clock,
            decimal::from(1_000_000),
        );

        assert!(!obligation.is_looped());

        vector::push_back(
            obligation.borrows_mut(),
            create_borrow_for_testing(
                type_name::with_defining_ids<TEST_USDC>(),
                2,
                decimal::from(1_000_000),
                decimal::from_percent(100),
                decimal::from(1),
                0,
            ),
        );

        assert!(obligation.is_looped());

        test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_is_looped_2() {
        use sui::test_utils::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());

        // Check USDC
        {
            let mut obligation = create_obligation<TEST_MARKET>(
                object::uid_to_inner(&lending_market_id),
                test_scenario::ctx(&mut scenario),
            );

            deposit<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
                &clock,
                100 * 1_000_000,
            );
            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
                &clock,
                1_000_000_000,
            );

            assert!(!obligation.is_looped());

            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_ETH>(&mut reserves),
                &clock,
                1_000,
            );

            assert!(!obligation.is_looped());

            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
                &clock,
                1_000_000,
            );

            assert!(obligation.is_looped());

            repay<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
                &clock,
                decimal::from(1_000_000),
            );

            assert!(!obligation.is_looped());

            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_AUSD>(&mut reserves),
                &clock,
                1_000_000,
            );

            assert!(obligation.is_looped());

            repay<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_AUSD>(&mut reserves),
                &clock,
                decimal::from(1_000_000),
            );

            assert!(!obligation.is_looped());

            vector::push_back(
                obligation.borrows_mut(),
                create_borrow_for_testing(
                    type_name::with_defining_ids<TEST_USDC>(),
                    1,
                    decimal::from(1_000_000),
                    decimal::from_percent(100),
                    decimal::from(1),
                    0,
                ),
            );

            assert!(obligation.is_looped());
            sui::test_utils::destroy(obligation);
        };

        // Check USDT
        {
            let mut obligation = create_obligation<TEST_MARKET>(
                object::uid_to_inner(&lending_market_id),
                test_scenario::ctx(&mut scenario),
            );

            deposit<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
                &clock,
                100 * 1_000_000,
            );
            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
                &clock,
                1_000_000_000,
            );

            assert!(!obligation.is_looped());

            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_ETH>(&mut reserves),
                &clock,
                1_000,
            );

            assert!(!obligation.is_looped());

            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
                &clock,
                1_000_000,
            );

            assert!(obligation.is_looped());

            repay<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
                &clock,
                decimal::from(1_000_000),
            );

            assert!(!obligation.is_looped());

            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_AUSD>(&mut reserves),
                &clock,
                1_000_000,
            );

            assert!(obligation.is_looped());

            repay<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_AUSD>(&mut reserves),
                &clock,
                decimal::from(1_000_000),
            );

            assert!(!obligation.is_looped());

            vector::push_back(
                obligation.borrows_mut(),
                create_borrow_for_testing(
                    type_name::with_defining_ids<TEST_USDT>(),
                    2,
                    decimal::from(1_000_000),
                    decimal::from_percent(100),
                    decimal::from(1),
                    0,
                ),
            );

            assert!(obligation.is_looped());
            sui::test_utils::destroy(obligation);
        };

        // Check AUSD
        {
            let mut obligation = create_obligation<TEST_MARKET>(
                object::uid_to_inner(&lending_market_id),
                test_scenario::ctx(&mut scenario),
            );

            deposit<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_AUSD>(&mut reserves),
                &clock,
                100 * 1_000_000,
            );
            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
                &clock,
                1_000_000_000,
            );

            assert!(!obligation.is_looped());

            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_ETH>(&mut reserves),
                &clock,
                1_000,
            );

            assert!(!obligation.is_looped());

            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
                &clock,
                1_000_000,
            );

            assert!(obligation.is_looped());

            repay<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
                &clock,
                decimal::from(1_000_000),
            );

            assert!(!obligation.is_looped());

            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
                &clock,
                1_000_000,
            );

            assert!(obligation.is_looped());

            repay<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
                &clock,
                decimal::from(1_000_000),
            );

            assert!(!obligation.is_looped());

            vector::push_back(
                obligation.borrows_mut(),
                create_borrow_for_testing(
                    type_name::with_defining_ids<TEST_AUSD>(),
                    5,
                    decimal::from(1_000_000),
                    decimal::from_percent(100),
                    decimal::from(1),
                    0,
                ),
            );

            assert!(obligation.is_looped());
            sui::test_utils::destroy(obligation);
        };

        // Check SUI
        {
            let mut obligation = create_obligation<TEST_MARKET>(
                object::uid_to_inner(&lending_market_id),
                test_scenario::ctx(&mut scenario),
            );

            deposit<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
                &clock,
                100 * 1_000_000,
            );

            vector::push_back(
                obligation.borrows_mut(),
                create_borrow_for_testing(
                    type_name::with_defining_ids<TEST_SUI>(),
                    0,
                    decimal::from(1_000_000),
                    decimal::from_percent(100),
                    decimal::from(1),
                    0,
                ),
            );

            assert!(obligation.is_looped());

            sui::test_utils::destroy(vector::pop_back(obligation.borrows_mut()));

            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
                &clock,
                1_000,
            );

            assert!(!obligation.is_looped());

            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_ETH>(&mut reserves),
                &clock,
                1_000,
            );

            assert!(!obligation.is_looped());

            borrow<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
                &clock,
                1_000,
            );

            assert!(!obligation.is_looped());

            repay<TEST_MARKET>(
                &mut obligation,
                get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
                &clock,
                decimal::from(1_000),
            );

            assert!(!obligation.is_looped());

            sui::test_utils::destroy(obligation);
        };

        test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_zero_out_rewards_if_looped() {
        use sui::test_utils::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        let mut reserves = reserves<TEST_MARKET>(scenario.ctx());
        let mut obligation = create_obligation<TEST_MARKET>(
            object::uid_to_inner(&lending_market_id),
            test_scenario::ctx(&mut scenario),
        );

        deposit<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDC>(&mut reserves),
            &clock,
            100 * 1_000_000,
        );
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_SUI>(&mut reserves),
            &clock,
            1_000_000_000,
        );

        // 1. shouldn't do anything
        obligation.zero_out_rewards_if_looped(&mut reserves, &clock);

        let mut i = 0;
        while (i < vector::length(obligation.user_reward_managers())) {
            let user_reward_manager = vector::borrow(obligation.user_reward_managers(), i);
            assert!(liquidity_mining::shares(user_reward_manager) != 0);
            i = i + 1;
        };

        // actually loop
        borrow<TEST_MARKET>(
            &mut obligation,
            get_reserve_mut<TEST_MARKET, TEST_USDT>(&mut reserves),
            &clock,
            1_000_000,
        );

        obligation.zero_out_rewards_if_looped(&mut reserves, &clock);

        let mut i = 0;
        while (i < vector::length(obligation.user_reward_managers())) {
            let user_reward_manager = vector::borrow(obligation.user_reward_managers(), i);
            assert!(liquidity_mining::shares(user_reward_manager) == 0);
            i = i + 1;
        };

        test_utils::destroy(reserves);
        sui::test_utils::destroy(lending_market_id);
        clock::destroy_for_testing(clock);
        sui::test_utils::destroy(obligation);
        test_scenario::end(scenario);
    }
}
