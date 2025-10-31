module suilend::lending_market_tests {
    use sprungsui::sprungsui::SPRUNGSUI;
    use std::type_name;
    use sui::bag::{Self, Bag};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::test_scenario::{Self, Scenario};
    use sui_system::governance_test_utils::{
        advance_epoch_with_reward_amounts,
        create_validator_for_testing,
        create_sui_system_state_for_testing
    };
    use sui_system::sui_system::SuiSystemState;
    use suilend::decimal;
    use suilend::lending_market::{
        Self,
        create_lending_market,
        LendingMarketOwnerCap,
        LendingMarket
    };
    use suilend::mock_pyth::PriceState;
    use suilend::obligation;
    use suilend::rate_limiter;
    use suilend::reserve::{Self, CToken};
    use suilend::reserve_config::ReserveConfig;

    public struct LENDING_MARKET has drop {}

    const U64_MAX: u64 = 18446744073709551615;
    const MIST_PER_SUI: u64 = 1_000_000_000;

    #[test]
    fun test_create_lending_market() {
        use sui::test_utils::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let (owner_cap, lending_market) = create_lending_market<LENDING_MARKET>(
            scenario.ctx(),
        );

        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::lending_market::EDuplicateReserve)]
    fun duplicate_reserves() {
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::reserve_config::{Self};
        use sui::test_utils::{Self};
        use suilend::mock_pyth::{Self};
        use suilend::mock_metadata::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let clock = clock::create_for_testing(scenario.ctx());
        let metadata = mock_metadata::init_metadata(scenario.ctx());

        let (owner_cap, mut lending_market) = create_lending_market<LENDING_MARKET>(
            scenario.ctx(),
        );

        let mut prices = mock_pyth::init_state(scenario.ctx());
        mock_pyth::register<TEST_USDC>(&mut prices, scenario.ctx());
        mock_pyth::register<TEST_SUI>(&mut prices, scenario.ctx());

        lending_market::add_reserve<LENDING_MARKET, TEST_USDC>(
            &owner_cap,
            &mut lending_market,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
            reserve_config::default_reserve_config(scenario.ctx()),
            mock_metadata::get<TEST_USDC>(&metadata),
            &clock,
            scenario.ctx(),
        );

        lending_market::add_reserve<LENDING_MARKET, TEST_USDC>(
            &owner_cap,
            &mut lending_market,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
            reserve_config::default_reserve_config(scenario.ctx()),
            mock_metadata::get<TEST_USDC>(&metadata),
            &clock,
            scenario.ctx(),
        );

        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(metadata);
        test_scenario::end(scenario);
    }

    public struct State {
        clock: Clock,
        owner_cap: LendingMarketOwnerCap<LENDING_MARKET>,
        lending_market: LendingMarket<LENDING_MARKET>,
        prices: PriceState,
        type_to_index: Bag,
    }

    public struct ReserveArgs has store {
        config: ReserveConfig,
        initial_deposit: u64,
    }

    #[test_only]
    public fun setup(mut reserve_args: Bag, ctx: &mut TxContext): State {
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::reserve_config::{Self};
        use sui::test_utils::{Self};
        use suilend::mock_pyth::{Self};
        use suilend::mock_metadata::{Self};

        let clock = clock::create_for_testing(ctx);
        let metadata = mock_metadata::init_metadata(ctx);

        let (owner_cap, mut lending_market) = create_lending_market<LENDING_MARKET>(
            ctx,
        );

        let mut prices = mock_pyth::init_state(ctx);
        mock_pyth::register<TEST_USDC>(&mut prices, ctx);
        mock_pyth::register<TEST_SUI>(&mut prices, ctx);
        mock_pyth::register<SUI>(&mut prices, ctx);

        let mut type_to_index = bag::new(ctx);
        bag::add(&mut type_to_index, type_name::with_defining_ids<TEST_USDC>(), 0);
        bag::add(&mut type_to_index, type_name::with_defining_ids<TEST_SUI>(), 1);
        bag::add(&mut type_to_index, type_name::with_defining_ids<SUI>(), 2);

        lending_market::add_reserve<LENDING_MARKET, TEST_USDC>(
            &owner_cap,
            &mut lending_market,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
            reserve_config::default_reserve_config(ctx),
            mock_metadata::get<TEST_USDC>(&metadata),
            &clock,
            ctx,
        );

        lending_market::add_reserve<LENDING_MARKET, TEST_SUI>(
            &owner_cap,
            &mut lending_market,
            mock_pyth::get_price_obj<TEST_SUI>(&prices),
            reserve_config::default_reserve_config(ctx),
            mock_metadata::get<TEST_SUI>(&metadata),
            &clock,
            ctx,
        );

        lending_market::add_reserve_for_testing<LENDING_MARKET, SUI>(
            &owner_cap,
            &mut lending_market,
            mock_pyth::get_price_obj<SUI>(&prices),
            reserve_config::default_reserve_config(ctx),
            9,
            &clock,
            ctx,
        );

        if (bag::contains(&reserve_args, type_name::with_defining_ids<TEST_USDC>())) {
            let ReserveArgs { config, initial_deposit } = bag::remove(
                &mut reserve_args,
                type_name::with_defining_ids<TEST_USDC>(),
            );
            let coins = coin::mint_for_testing<TEST_USDC>(
                initial_deposit,
                ctx,
            );

            let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<
                LENDING_MARKET,
                TEST_USDC,
            >(
                &mut lending_market,
                0,
                &clock,
                coins,
                ctx,
            );

            lending_market::update_reserve_config<LENDING_MARKET, TEST_USDC>(
                &owner_cap,
                &mut lending_market,
                0,
                config,
            );

            test_utils::destroy(ctokens);
        };
        if (bag::contains(&reserve_args, type_name::with_defining_ids<TEST_SUI>())) {
            let ReserveArgs { config, initial_deposit } = bag::remove(
                &mut reserve_args,
                type_name::with_defining_ids<TEST_SUI>(),
            );
            let coins = coin::mint_for_testing<TEST_SUI>(
                initial_deposit,
                ctx,
            );

            let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<
                LENDING_MARKET,
                TEST_SUI,
            >(
                &mut lending_market,
                1,
                &clock,
                coins,
                ctx,
            );

            lending_market::update_reserve_config<LENDING_MARKET, TEST_SUI>(
                &owner_cap,
                &mut lending_market,
                1,
                config,
            );

            test_utils::destroy(ctokens);
        };
        if (bag::contains(&reserve_args, type_name::with_defining_ids<SUI>())) {
            let ReserveArgs { config, initial_deposit } = bag::remove(
                &mut reserve_args,
                type_name::with_defining_ids<SUI>(),
            );
            let coins = coin::mint_for_testing<SUI>(
                initial_deposit,
                ctx,
            );

            let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, SUI>(
                &mut lending_market,
                2,
                &clock,
                coins,
                ctx,
            );

            lending_market::update_reserve_config<LENDING_MARKET, SUI>(
                &owner_cap,
                &mut lending_market,
                2,
                config,
            );

            test_utils::destroy(ctokens);
        };

        test_utils::destroy(reserve_args);
        test_utils::destroy(metadata);

        State {
            clock,
            owner_cap,
            lending_market,
            prices,
            type_to_index,
        }
    }

    #[test_only]
    public fun new_args(initial_deposit: u64, config: ReserveConfig): ReserveArgs {
        ReserveArgs {
            config,
            initial_deposit,
        }
    }

    #[test_only]
    public fun destruct_state(state: State): (
        Clock,
        LendingMarketOwnerCap<LENDING_MARKET>,
        LendingMarket<LENDING_MARKET>,
        PriceState,
        Bag
    ) {
        let State {
            clock,
            owner_cap,
            lending_market,
            prices,
            type_to_index,
        } = state;

        (clock, owner_cap, lending_market, prices, type_to_index)
    }


    #[test]
    public fun test_deposit() {
        use sui::test_utils::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::reserve_config::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let State { clock, owner_cap, mut lending_market, prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: reserve_config::default_reserve_config(scenario.ctx()),
                        initial_deposit: 100 * 1_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        let obligation_owner_cap = lending_market::create_obligation(
            &mut lending_market,
            scenario.ctx(),
        );

        let coins = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );

        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            coins,
            scenario.ctx(),
        );
        assert!(coin::value(&ctokens) == 100 * 1_000_000);

        let usdc_reserve = lending_market::reserve<LENDING_MARKET, TEST_USDC>(&lending_market);
        assert!(reserve::available_amount<LENDING_MARKET>(usdc_reserve) == 200 * 1_000_000);

        lending_market::deposit_ctokens_into_obligation<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            ctokens,
            scenario.ctx(),
        );

        let obligation = lending_market::obligation(
            &lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
        );
        assert!(
            obligation::deposited_ctoken_amount<LENDING_MARKET, TEST_USDC>(obligation) == 100 * 1_000_000
        );

        test_utils::destroy(obligation_owner_cap);
        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_redeem() {
        use sui::test_utils::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::reserve_config::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let State { clock, owner_cap, mut lending_market, prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: reserve_config::default_reserve_config(scenario.ctx()),
                        initial_deposit: 100 * 1_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        let coins = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            coins,
            scenario.ctx(),
        );
        assert!(coin::value(&ctokens) == 100 * 1_000_000);

        let usdc_reserve = lending_market::reserve<LENDING_MARKET, TEST_USDC>(&lending_market);
        let old_available_amount = reserve::available_amount<LENDING_MARKET>(usdc_reserve);

        let tokens = lending_market::redeem_ctokens_and_withdraw_liquidity<
            LENDING_MARKET,
            TEST_USDC,
        >(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            ctokens,
            option::none(),
            scenario.ctx(),
        );
        assert!(coin::value(&tokens) == 100 * 1_000_000);

        let usdc_reserve = lending_market::reserve<LENDING_MARKET, TEST_USDC>(&lending_market);
        let new_available_amount = reserve::available_amount<LENDING_MARKET>(usdc_reserve);
        assert!(new_available_amount == old_available_amount - 100 * 1_000_000);

        test_utils::destroy(tokens);
        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_borrow_and_repay() {
        use sui::test_utils::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::mock_pyth::{Self};
        use suilend::reserve_config::{Self, default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        setup_sui_system(&mut scenario);
        let State { mut clock, owner_cap, mut lending_market, mut prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_open_ltv_pct(&mut builder, 50);
                            reserve_config::set_close_ltv_pct(&mut builder, 50);
                            reserve_config::set_max_close_ltv_pct(&mut builder, 50);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000,
                    },
                );
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_SUI>(),
                    ReserveArgs {
                        config: {
                            let config = reserve_config::default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );

                            test_utils::destroy(config);

                            reserve_config::set_borrow_fee_bps(&mut builder, 10);
                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        clock::set_for_testing(&mut clock, 1 * 1000);

        // set reserve parameters and prices
        mock_pyth::update_price<TEST_USDC>(&mut prices, 1, 0, &clock); // $1
        mock_pyth::update_price<TEST_SUI>(&mut prices, 1, 1, &clock); // $10

        // create obligation
        let obligation_owner_cap = lending_market::create_obligation(
            &mut lending_market,
            scenario.ctx(),
        );

        let coins = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            coins,
            scenario.ctx(),
        );
        lending_market::deposit_ctokens_into_obligation<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            ctokens,
            scenario.ctx(),
        );

        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
        );
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &clock,
            mock_pyth::get_price_obj<TEST_SUI>(&prices),
        );

        let mut sui = lending_market::borrow<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &obligation_owner_cap,
            &clock,
            1 * 1_000_000_000,
            scenario.ctx(),
        );

        assert!(coin::value(&sui) == 1 * 1_000_000_000);

        // state checks
        let sui_reserve = lending_market::reserve<LENDING_MARKET, TEST_SUI>(&lending_market);
        assert!(
            reserve::borrowed_amount<LENDING_MARKET>(sui_reserve) == decimal::from(1_001_000_000)
        );

        let obligation = lending_market::obligation(
            &lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
        );
        assert!(
            obligation::borrowed_amount<LENDING_MARKET, TEST_SUI>(obligation) == decimal::from(1_001_000_000)
        );

        lending_market::repay<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            lending_market::obligation_id(&obligation_owner_cap),
            &clock,
            &mut sui,
            scenario.ctx(),
        );

        assert!(coin::value(&sui) == 0);
        test_utils::destroy(sui);

        let sui_reserve = lending_market::reserve<LENDING_MARKET, TEST_SUI>(&lending_market);
        assert!(
            reserve::borrowed_amount<LENDING_MARKET>(sui_reserve) == decimal::from(1_000_000)
        );

        let obligation = lending_market::obligation(
            &lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
        );
        assert!(
            obligation::borrowed_amount<LENDING_MARKET, TEST_SUI>(obligation) == decimal::from(1_000_000)
        );

        let mut sui = coin::mint_for_testing<TEST_SUI>(
            1_000_000_000,
            scenario.ctx(),
        );
        lending_market::repay<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            lending_market::obligation_id(&obligation_owner_cap),
            &clock,
            &mut sui,
            scenario.ctx(),
        );
        assert!(coin::value(&sui) == 1_000_000_000 - 1_000_000);

        let sui_reserve = lending_market::reserve<LENDING_MARKET, TEST_SUI>(&lending_market);
        assert!(reserve::borrowed_amount<LENDING_MARKET>(sui_reserve) == decimal::from(0));

        let obligation = lending_market::obligation(&lending_market, lending_market::obligation_id(&obligation_owner_cap));
        assert!(obligation::borrowed_amount<LENDING_MARKET, TEST_SUI>(obligation) == decimal::from(0));

        test_scenario::next_tx(&mut scenario, owner);

        let mut system_state = test_scenario::take_shared(&scenario);

        lending_market::set_fee_receivers<LENDING_MARKET>(
            &owner_cap,
            &mut lending_market,
            vector[tx_context::sender(scenario.ctx()), @0x27],
            vector[1, 2],
        );

        lending_market::claim_fees<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &mut system_state,
            scenario.ctx(),
        );
        lending_market::claim_fees<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &mut system_state,
            scenario.ctx()
        );

        test_scenario::return_shared(system_state);

        test_scenario::next_tx(&mut scenario, owner);

        let fees: Coin<TEST_SUI> = test_scenario::take_from_address(&scenario, @0x26);
        assert!(coin::value(&fees) == 1_000_000 / 3);
        test_utils::destroy(fees);

        let fees: Coin<TEST_SUI> = test_scenario::take_from_address(&scenario, @0x27);
        assert!(coin::value(&fees) == 2 * 1_000_000 / 3 + 1);
        test_utils::destroy(fees);

        test_utils::destroy(sui);
        test_utils::destroy(obligation_owner_cap);
        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_withdraw() {
        use sui::test_utils::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::mock_pyth::{Self};
        use suilend::reserve_config::{Self, default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let State { mut clock, owner_cap, mut lending_market, mut prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_open_ltv_pct(&mut builder, 50);
                            reserve_config::set_close_ltv_pct(&mut builder, 50);
                            reserve_config::set_max_close_ltv_pct(&mut builder, 50);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000,
                    },
                );
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_SUI>(),
                    ReserveArgs {
                        config: reserve_config::default_reserve_config(scenario.ctx()),
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        clock::set_for_testing(&mut clock, 1 * 1000);

        // set reserve parameters and prices
        mock_pyth::update_price<TEST_USDC>(&mut prices, 1, 0, &clock); // $1
        mock_pyth::update_price<TEST_SUI>(&mut prices, 1, 1, &clock); // $10

        // create obligation
        let obligation_owner_cap = lending_market::create_obligation(
            &mut lending_market,
            scenario.ctx(),
        );

        let coins = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            coins,
            scenario.ctx(),
        );
        lending_market::deposit_ctokens_into_obligation<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            ctokens,
            scenario.ctx(),
        );

        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
        );
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &clock,
            mock_pyth::get_price_obj<TEST_SUI>(&prices),
        );

        let sui = lending_market::borrow<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &obligation_owner_cap,
            &clock,
            2_500_000_000,
            scenario.ctx(),
        );

        let obligation = lending_market::obligation(
            &lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
        );
        let old_deposited_amount = obligation::deposited_ctoken_amount<LENDING_MARKET, TEST_USDC>(
            obligation,
        );

        let usdc = lending_market::withdraw_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            50 * 1_000_000,
            scenario.ctx(),
        );

        let obligation = lending_market::obligation(
            &lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
        );
        let deposited_amount = obligation::deposited_ctoken_amount<LENDING_MARKET, TEST_USDC>(
            obligation,
        );

        assert!(coin::value(&usdc) == 50_000_000);
        assert!(deposited_amount == old_deposited_amount - 50 * 1_000_000);

        test_utils::destroy(sui);
        test_utils::destroy(usdc);
        test_utils::destroy(obligation_owner_cap);
        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::obligation::EOraclesAreStale)]
    public fun test_withdraw_price_stale_with_borrows() {
        use sui::test_utils::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::mock_pyth::{Self};
        use suilend::reserve_config::{Self, default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let State { mut clock, owner_cap, mut lending_market, mut prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_open_ltv_pct(&mut builder, 50);
                            reserve_config::set_close_ltv_pct(&mut builder, 50);
                            reserve_config::set_max_close_ltv_pct(&mut builder, 50);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000,
                    },
                );
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_SUI>(),
                    ReserveArgs {
                        config: reserve_config::default_reserve_config(scenario.ctx()),
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        clock::set_for_testing(&mut clock, 1 * 1000);

        // set reserve parameters and prices
        mock_pyth::update_price<TEST_USDC>(&mut prices, 1, 0, &clock); // $1
        mock_pyth::update_price<TEST_SUI>(&mut prices, 1, 1, &clock); // $10

        // create obligation
        let obligation_owner_cap = lending_market::create_obligation(
            &mut lending_market,
            scenario.ctx(),
        );

        let coins = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            coins,
            scenario.ctx(),
        );
        lending_market::deposit_ctokens_into_obligation<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            ctokens,
            scenario.ctx(),
        );

        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
        );
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &clock,
            mock_pyth::get_price_obj<TEST_SUI>(&prices),
        );

        let sui = lending_market::borrow<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &obligation_owner_cap,
            &clock,
            2_500_000_000,
            scenario.ctx(),
        );

        let obligation = lending_market::obligation(
            &lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
        );
        let old_deposited_amount = obligation::deposited_ctoken_amount<LENDING_MARKET, TEST_USDC>(
            obligation,
        );

        clock.increment_for_testing(100_000);

        // this should fail because the price is stale and we have borrows
        let usdc = lending_market::withdraw_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            50 * 1_000_000,
            scenario.ctx(),
        );

        let obligation = lending_market::obligation(
            &lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
        );
        let deposited_amount = obligation::deposited_ctoken_amount<LENDING_MARKET, TEST_USDC>(
            obligation,
        );

        assert!(coin::value(&usdc) == 50_000_000);
        assert!(deposited_amount == old_deposited_amount - 50 * 1_000_000);

        test_utils::destroy(sui);
        test_utils::destroy(usdc);
        test_utils::destroy(obligation_owner_cap);
        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_withdraw_price_stale_no_borrows() {
        use sui::test_utils::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::mock_pyth::{Self};
        use suilend::reserve_config::{Self, default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let State { mut clock, owner_cap, mut lending_market, mut prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_open_ltv_pct(&mut builder, 50);
                            reserve_config::set_close_ltv_pct(&mut builder, 50);
                            reserve_config::set_max_close_ltv_pct(&mut builder, 50);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000,
                    },
                );
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_SUI>(),
                    ReserveArgs {
                        config: reserve_config::default_reserve_config(scenario.ctx()),
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        clock::set_for_testing(&mut clock, 1 * 1000);

        // set reserve parameters and prices
        mock_pyth::update_price<TEST_USDC>(&mut prices, 1, 0, &clock); // $1
        mock_pyth::update_price<TEST_SUI>(&mut prices, 1, 1, &clock); // $10

        // create obligation
        let obligation_owner_cap = lending_market::create_obligation(
            &mut lending_market,
            scenario.ctx(),
        );

        let coins = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            coins,
            scenario.ctx(),
        );
        lending_market::deposit_ctokens_into_obligation<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            ctokens,
            scenario.ctx(),
        );

        let obligation = lending_market::obligation(
            &lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
        );
        let old_deposited_amount = obligation::deposited_ctoken_amount<LENDING_MARKET, TEST_USDC>(
            obligation,
        );

        clock.increment_for_testing(100_000);

        // this should succeed even though price is stale
        let usdc = lending_market::withdraw_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            50 * 1_000_000,
            scenario.ctx(),
        );

        let obligation = lending_market::obligation(
            &lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
        );
        let deposited_amount = obligation::deposited_ctoken_amount<LENDING_MARKET, TEST_USDC>(
            obligation,
        );

        assert!(coin::value(&usdc) == 50_000_000);
        assert!(deposited_amount == old_deposited_amount - 50 * 1_000_000);

        test_utils::destroy(usdc);
        test_utils::destroy(obligation_owner_cap);
        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_liquidate() {
        use sui::test_utils::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::mock_pyth::{Self};
        use suilend::reserve_config::{Self, default_reserve_config};
        use suilend::decimal::{sub};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        setup_sui_system(&mut scenario);

        let State { mut clock, owner_cap, mut lending_market, mut prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_open_ltv_pct(&mut builder, 50);
                            reserve_config::set_close_ltv_pct(&mut builder, 50);
                            reserve_config::set_max_close_ltv_pct(&mut builder, 50);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000,
                    },
                );
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_SUI>(),
                    ReserveArgs {
                        config: reserve_config::default_reserve_config(scenario.ctx()),
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        clock::set_for_testing(&mut clock, 1 * 1000);

        // set reserve parameters and prices
        mock_pyth::update_price<TEST_USDC>(&mut prices, 1, 0, &clock); // $1
        mock_pyth::update_price<TEST_SUI>(&mut prices, 1, 1, &clock); // $10

        // create obligation
        let obligation_owner_cap = lending_market::create_obligation(
            &mut lending_market,
            scenario.ctx(),
        );

        let coins = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            coins,
            scenario.ctx(),
        );
        lending_market::deposit_ctokens_into_obligation<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            ctokens,
            scenario.ctx(),
        );

        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
        );
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &clock,
            mock_pyth::get_price_obj<TEST_SUI>(&prices),
        );

        let sui = lending_market::borrow<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &obligation_owner_cap,
            &clock,
            5 * 1_000_000_000,
            scenario.ctx(),
        );
        test_utils::destroy(sui);

        // set the open and close ltvs of the usdc reserve to 0
        let usdc_reserve = lending_market::reserve<LENDING_MARKET, TEST_USDC>(&lending_market);
        lending_market::update_reserve_config<LENDING_MARKET, TEST_USDC>(
            &owner_cap,
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            {
                let mut builder = reserve_config::from(
                    reserve::config(usdc_reserve),
                    scenario.ctx(),
                );
                reserve_config::set_open_ltv_pct(&mut builder, 0);
                reserve_config::set_close_ltv_pct(&mut builder, 0);
                reserve_config::set_max_close_ltv_pct(&mut builder, 0);
                reserve_config::set_liquidation_bonus_bps(&mut builder, 400);
                reserve_config::set_max_liquidation_bonus_bps(&mut builder, 400);
                reserve_config::set_protocol_liquidation_fee_bps(&mut builder, 600);

                reserve_config::build(builder, scenario.ctx())
            },
        );

        let obligation = lending_market::obligation(
            &lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
        );

        let sui_reserve = lending_market::reserve<LENDING_MARKET, TEST_SUI>(&lending_market);
        let old_reserve_borrowed_amount = reserve::borrowed_amount<LENDING_MARKET>(sui_reserve);

        let old_deposited_amount = obligation::deposited_ctoken_amount<LENDING_MARKET, TEST_USDC>(
            obligation,
        );
        let old_borrowed_amount = obligation::borrowed_amount<LENDING_MARKET, TEST_SUI>(obligation);

        // liquidate the obligation
        let mut sui = coin::mint_for_testing<TEST_SUI>(
            5 * 1_000_000_000,
            scenario.ctx(),
        );
        let (usdc, exemption) = lending_market::liquidate<LENDING_MARKET, TEST_SUI, TEST_USDC>(
            &mut lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            &mut sui,
            scenario.ctx(),
        );

        assert!(coin::value(&sui) == 4 * 1_000_000_000);
        assert!(coin::value(&usdc) == 10 * 1_000_000 + 400_000);
        assert!(exemption.amount() == 10 * 1_000_000 + 400_000);

        let obligation = lending_market::obligation(
            &lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
        );

        let sui_reserve = lending_market::reserve<LENDING_MARKET, TEST_SUI>(&lending_market);
        let reserve_borrowed_amount = reserve::borrowed_amount<LENDING_MARKET>(sui_reserve);

        let deposited_amount = obligation::deposited_ctoken_amount<LENDING_MARKET, TEST_USDC>(
            obligation,
        );
        let borrowed_amount = obligation::borrowed_amount<LENDING_MARKET, TEST_SUI>(obligation);

        assert!(
            reserve_borrowed_amount == sub(old_reserve_borrowed_amount, decimal::from(1_000_000_000))
        );
        assert!(borrowed_amount == sub(old_borrowed_amount, decimal::from(1_000_000_000)));
        assert!(deposited_amount == old_deposited_amount - 11 * 1_000_000);

        // check to see if we can do a full redeem even with rate limiter is disabled
        lending_market::update_rate_limiter_config<LENDING_MARKET>(
            &owner_cap,
            &mut lending_market,
            &clock,
            rate_limiter::new_config(1, 0), // disabled
        );

        let tokens = lending_market::redeem_ctokens_and_withdraw_liquidity<
            LENDING_MARKET,
            TEST_USDC,
        >(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            usdc,
            option::some(exemption),
            scenario.ctx(),
        );
        assert!(coin::value(&tokens) == 10 * 1_000_000 + 400_000);

        // claim fees
        test_scenario::next_tx(&mut scenario, owner);
        let mut system_state = test_scenario::take_shared<SuiSystemState>(&scenario);
        lending_market::claim_fees<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &mut system_state,
            scenario.ctx()
        );
        test_scenario::return_shared(system_state);
        test_scenario::next_tx(&mut scenario, owner);

        let ctoken_fees: Coin<CToken<LENDING_MARKET, TEST_USDC>> = test_scenario::take_from_address(
            &scenario,
            lending_market::fee_receiver(&lending_market),
        );
        assert!(coin::value(&ctoken_fees) == 600_000);

        test_utils::destroy(ctoken_fees);
        test_utils::destroy(sui);
        test_utils::destroy(tokens);
        test_utils::destroy(obligation_owner_cap);
        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    const MILLISECONDS_IN_DAY: u64 = 86_400_000;

    #[test]
    fun test_liquidity_mining() {
        use sui::test_utils::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::reserve_config::{Self, default_reserve_config};
        use suilend::mock_pyth::{Self};

        let owner = @0x26;

        let mut scenario = test_scenario::begin(owner);
        let State { mut clock, owner_cap, mut lending_market, mut prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_open_ltv_pct(&mut builder, 50);
                            reserve_config::set_close_ltv_pct(&mut builder, 50);
                            reserve_config::set_max_close_ltv_pct(&mut builder, 50);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000,
                    },
                );
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_SUI>(),
                    ReserveArgs {
                        config: reserve_config::default_reserve_config(scenario.ctx()),
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        let usdc_rewards = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );
        let sui_rewards = coin::mint_for_testing<TEST_SUI>(
            100 * 1_000_000_000,
            scenario.ctx(),
        );

        lending_market::add_pool_reward<LENDING_MARKET, TEST_USDC>(
            &owner_cap,
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            true,
            usdc_rewards,
            0,
            10 * MILLISECONDS_IN_DAY,
            &clock,
            scenario.ctx(),
        );

        lending_market::add_pool_reward<LENDING_MARKET, TEST_SUI>(
            &owner_cap,
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            true,
            sui_rewards,
            4 * MILLISECONDS_IN_DAY,
            14 * MILLISECONDS_IN_DAY,
            &clock,
            scenario.ctx(),
        );

        clock::set_for_testing(&mut clock, MILLISECONDS_IN_DAY);

        // create obligation
        let obligation_owner_cap = lending_market::create_obligation(
            &mut lending_market,
            scenario.ctx(),
        );

        let coins = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            coins,
            scenario.ctx(),
        );
        lending_market::deposit_ctokens_into_obligation<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            ctokens,
            scenario.ctx(),
        );

        clock::set_for_testing(&mut clock, 9 * MILLISECONDS_IN_DAY);

        // set reserve parameters and prices
        mock_pyth::update_price<TEST_USDC>(&mut prices, 1, 0, &clock); // $1
        mock_pyth::update_price<TEST_SUI>(&mut prices, 1, 1, &clock); // $10

        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
        );
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &clock,
            mock_pyth::get_price_obj<TEST_SUI>(&prices),
        );
        let sui = lending_market::borrow<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &obligation_owner_cap,
            &clock,
            1_000_000_000,
            scenario.ctx(),
        );

        let claimed_usdc = lending_market::claim_rewards<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            &obligation_owner_cap,
            &clock,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            0,
            true,
            scenario.ctx(),
        );
        assert!(coin::value(&claimed_usdc) == 80 * 1_000_000);

        // this fails because but rewards period is not over
        // claim_rewards_and_deposit<LENDING_MARKET, TEST_SUI>(
        //     &mut lending_market,
        //     obligation_owner_cap.obligation_id,
        //     &clock,
        //     *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
        //     1,
        //     true,
        //     *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
        //     scenario.ctx()
        // );

        let remaining_sui_rewards = lending_market::cancel_pool_reward<LENDING_MARKET, TEST_SUI>(
            &owner_cap,
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            true,
            1,
            &clock,
            scenario.ctx(),
        );
        assert!(coin::value(&remaining_sui_rewards) == 50 * 1_000_000_000);

        lending_market::claim_rewards_and_deposit<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
            &clock,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            1,
            true,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            scenario.ctx(),
        );

        assert!(
            obligation::deposited_ctoken_amount<LENDING_MARKET, TEST_SUI>(
            lending_market::obligation(&lending_market, lending_market::obligation_id(&obligation_owner_cap))
        ) == 49 * 1_000_000_000
        );
        assert!(
            obligation::borrowed_amount<LENDING_MARKET, TEST_SUI>(
            lending_market::obligation(&lending_market, lending_market::obligation_id(&obligation_owner_cap))
        ) == decimal::from(0)
        );

        let dust_sui_rewards = lending_market::close_pool_reward<LENDING_MARKET, TEST_SUI>(
            &owner_cap,
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            true,
            1,
            &clock,
            scenario.ctx(),
        );

        assert!(coin::value(&dust_sui_rewards) == 0);

        test_utils::destroy(dust_sui_rewards);
        test_utils::destroy(remaining_sui_rewards);
        test_utils::destroy(sui);
        test_utils::destroy(owner_cap);
        test_utils::destroy(obligation_owner_cap);
        test_utils::destroy(claimed_usdc);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_forgive_debt() {
        use sui::test_utils::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::mock_pyth::{Self};
        use suilend::reserve_config::{Self, default_reserve_config};
        use suilend::decimal::{sub, eq};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let State { mut clock, owner_cap, mut lending_market, mut prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_open_ltv_pct(&mut builder, 50);
                            reserve_config::set_close_ltv_pct(&mut builder, 50);
                            reserve_config::set_max_close_ltv_pct(&mut builder, 50);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000,
                    },
                );
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_SUI>(),
                    ReserveArgs {
                        config: reserve_config::default_reserve_config(scenario.ctx()),
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        clock::set_for_testing(&mut clock, 1 * 1000);

        // set reserve parameters and prices
        mock_pyth::update_price<TEST_USDC>(&mut prices, 1, 0, &clock); // $1
        mock_pyth::update_price<TEST_SUI>(&mut prices, 1, 1, &clock); // $10

        // create obligation
        let obligation_owner_cap = lending_market::create_obligation(
            &mut lending_market,
            scenario.ctx(),
        );

        let coins = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            coins,
            scenario.ctx(),
        );
        lending_market::deposit_ctokens_into_obligation<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            ctokens,
            scenario.ctx(),
        );

        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
        );
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &clock,
            mock_pyth::get_price_obj<TEST_SUI>(&prices),
        );

        let sui = lending_market::borrow<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &obligation_owner_cap,
            &clock,
            5 * 1_000_000_000,
            scenario.ctx(),
        );
        test_utils::destroy(sui);

        mock_pyth::update_price<TEST_SUI>(&mut prices, 1, 2, &clock); // $10
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &clock,
            mock_pyth::get_price_obj<TEST_SUI>(&prices),
        );

        // liquidate the obligation
        let mut sui = coin::mint_for_testing<TEST_SUI>(
            1 * 1_000_000_000,
            scenario.ctx(),
        );
        let (usdc, _exemption) = lending_market::liquidate<LENDING_MARKET, TEST_SUI, TEST_USDC>(
            &mut lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            &mut sui,
            scenario.ctx(),
        );

        let obligation = lending_market::obligation(
            &lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
        );
        let sui_reserve = lending_market::reserve<LENDING_MARKET, TEST_SUI>(&lending_market);
        let old_reserve_borrowed_amount = reserve::borrowed_amount<LENDING_MARKET>(sui_reserve);
        let old_borrowed_amount = obligation::borrowed_amount<LENDING_MARKET, TEST_SUI>(obligation);

        lending_market::forgive<LENDING_MARKET, TEST_SUI>(
            &owner_cap,
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            lending_market::obligation_id(&obligation_owner_cap),
            &clock,
            1_000_000_000,
        );

        let obligation = lending_market::obligation(
            &lending_market,
            lending_market::obligation_id(&obligation_owner_cap),
        );
        let sui_reserve = lending_market::reserve<LENDING_MARKET, TEST_SUI>(&lending_market);
        let reserve_borrowed_amount = reserve::borrowed_amount<LENDING_MARKET>(sui_reserve);
        let borrowed_amount = obligation::borrowed_amount<LENDING_MARKET, TEST_SUI>(obligation);

        assert!(eq(sub(old_borrowed_amount, borrowed_amount), decimal::from(1_000_000_000)));
        assert!(
            eq(
                sub(old_reserve_borrowed_amount, reserve_borrowed_amount),
                decimal::from(1_000_000_000),
            )
        );

        test_utils::destroy(usdc);
        test_utils::destroy(sui);
        test_utils::destroy(obligation_owner_cap);
        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_max_borrow() {
        use sui::test_utils::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::mock_pyth::{Self};
        use suilend::reserve_config::{Self, default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let State { mut clock, owner_cap, mut lending_market, mut prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_open_ltv_pct(&mut builder, 50);
                            reserve_config::set_close_ltv_pct(&mut builder, 50);
                            reserve_config::set_max_close_ltv_pct(&mut builder, 50);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000,
                    },
                );
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_SUI>(),
                    ReserveArgs {
                        config: {
                            let config = reserve_config::default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );

                            test_utils::destroy(config);

                            reserve_config::set_borrow_fee_bps(&mut builder, 10);
                            // reserve_config::set_borrow_limit(&mut builder, 4 * 1_000_000_000);
                            // reserve_config::set_borrow_limit_usd(&mut builder, 20);
                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        clock::set_for_testing(&mut clock, 1 * 1000);

        // set reserve parameters and prices
        mock_pyth::update_price<TEST_USDC>(&mut prices, 1, 0, &clock); // $1
        mock_pyth::update_price<TEST_SUI>(&mut prices, 1, 1, &clock); // $10

        // create obligation
        let obligation_owner_cap = lending_market::create_obligation(
            &mut lending_market,
            scenario.ctx(),
        );

        let coins = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            coins,
            scenario.ctx(),
        );
        lending_market::deposit_ctokens_into_obligation<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            ctokens,
            scenario.ctx(),
        );

        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
        );
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &clock,
            mock_pyth::get_price_obj<TEST_SUI>(&prices),
        );

        let sui = lending_market::borrow<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &obligation_owner_cap,
            &clock,
            U64_MAX,
            scenario.ctx(),
        );

        assert!(coin::value(&sui) == 4_995_004_995);

        test_utils::destroy(sui);
        test_utils::destroy(obligation_owner_cap);
        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_max_withdraw() {
        use sui::test_utils::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::mock_pyth::{Self};
        use suilend::reserve_config::{Self, default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let State { mut clock, owner_cap, mut lending_market, mut prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_open_ltv_pct(&mut builder, 50);
                            reserve_config::set_close_ltv_pct(&mut builder, 50);
                            reserve_config::set_max_close_ltv_pct(&mut builder, 50);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000,
                    },
                );
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_SUI>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_borrow_weight_bps(&mut builder, 20_000);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        clock::set_for_testing(&mut clock, 1 * 1000);

        // set reserve parameters and prices
        mock_pyth::update_price<TEST_USDC>(&mut prices, 1, 0, &clock); // $1
        mock_pyth::update_price<TEST_SUI>(&mut prices, 1, 1, &clock); // $10

        // create obligation
        let obligation_owner_cap = lending_market::create_obligation(
            &mut lending_market,
            scenario.ctx(),
        );

        let coins = coin::mint_for_testing<TEST_USDC>(
            200 * 1_000_000,
            scenario.ctx(),
        );
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            coins,
            scenario.ctx(),
        );

        lending_market::deposit_ctokens_into_obligation<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            ctokens,
            scenario.ctx(),
        );

        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
        );
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &clock,
            mock_pyth::get_price_obj<TEST_SUI>(&prices),
        );

        let sui = lending_market::borrow<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &obligation_owner_cap,
            &clock,
            2_500_000_000,
            scenario.ctx(),
        );

        lending_market::update_rate_limiter_config<LENDING_MARKET>(
            &owner_cap,
            &mut lending_market,
            &clock,
            rate_limiter::new_config(1, 10), // disabled
        );

        let cusdc = lending_market::withdraw_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            U64_MAX,
            scenario.ctx(),
        );
        let usdc = lending_market::redeem_ctokens_and_withdraw_liquidity<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            cusdc,
            option::none(),
            scenario.ctx(),
        );

        assert!(coin::value(&usdc) == 10 * 1_000_000);

        test_utils::destroy(sui);
        test_utils::destroy(usdc);
        test_utils::destroy(obligation_owner_cap);
        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_change_pyth_price_feed() {
        use sui::test_utils;
        use sui::test_scenario::ctx;
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::mock_pyth::{Self};
        use suilend::reserve_config::{Self, default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let State { mut clock, owner_cap, mut lending_market, prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_open_ltv_pct(&mut builder, 50);
                            reserve_config::set_close_ltv_pct(&mut builder, 50);
                            reserve_config::set_max_close_ltv_pct(&mut builder, 50);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000,
                    },
                );
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_SUI>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_borrow_weight_bps(&mut builder, 20_000);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        clock::set_for_testing(&mut clock, 1 * 1000);

        // change the price feed as admin
        let new_price_info_obj = mock_pyth::new_price_info_obj(3_u8, ctx(&mut scenario));

        let array_idx = *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>());

        lending_market::change_reserve_price_feed<LENDING_MARKET, TEST_USDC>(
            &owner_cap,
            &mut lending_market,
            array_idx,
            &new_price_info_obj,
            &clock,
        );

        // TODO: assert changes
        let reserve_ref = lending_market::reserve<LENDING_MARKET, TEST_USDC>(&lending_market);
        let price_id = pyth::price_info::get_price_identifier(
            &pyth::price_info::get_price_info_from_price_info_object(&new_price_info_obj),
        );

        assert!(*reserve::price_identifier(reserve_ref) == price_id);

        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_utils::destroy(new_price_info_obj);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_admin_new_obligation_cap() {
        use sui::test_utils::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::mock_pyth::{Self};
        use suilend::reserve_config::{Self, default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let State { mut clock, owner_cap, mut lending_market, mut prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_open_ltv_pct(&mut builder, 50);
                            reserve_config::set_close_ltv_pct(&mut builder, 50);
                            reserve_config::set_max_close_ltv_pct(&mut builder, 50);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000,
                    },
                );
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_SUI>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_borrow_weight_bps(&mut builder, 20_000);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        clock::set_for_testing(&mut clock, 1 * 1000);

        // set reserve parameters and prices
        mock_pyth::update_price<TEST_USDC>(&mut prices, 1, 0, &clock); // $1
        mock_pyth::update_price<TEST_SUI>(&mut prices, 1, 1, &clock); // $10

        // create obligation
        let obligation_owner_cap = lending_market::create_obligation(
            &mut lending_market,
            scenario.ctx(),
        );

        let obligation_id = lending_market::obligation_id(&obligation_owner_cap);

        // Mock accidental burning of obligation cap
        transfer::public_transfer(obligation_owner_cap, @0x0);

        let obligation_owner_cap = lending_market::new_obligation_owner_cap(
            &owner_cap,
            &lending_market,
            obligation_id,
            scenario.ctx(),
        );

        assert!(lending_market::obligation_id(&obligation_owner_cap) == obligation_id);

        test_utils::destroy(obligation_owner_cap);
        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    const SUILEND_VALIDATOR: address =
        @0xce8e537664ba5d1d5a6a857b17bd142097138706281882be6805e17065ecde89;

    #[allow(deprecated_usage)] // governance_test_utils -> sui_system::test_runner
    fun setup_sui_system(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUILEND_VALIDATOR);
        let validator = create_validator_for_testing(
            SUILEND_VALIDATOR,
            100,
            scenario.ctx(),
        );
        create_sui_system_state_for_testing(vector[validator], 0, 0, scenario.ctx());

        advance_epoch_with_reward_amounts(0, 0, scenario);
    }

    #[test]
    public fun test_staker_e2e_redeem() {
        use sui::test_utils::{Self};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        setup_sui_system(&mut scenario);

        let State { mut clock, owner_cap, mut lending_market, prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<SUI>(),
                    ReserveArgs {
                        config: default_reserve_config(scenario.ctx()),
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        clock::set_for_testing(&mut clock, 1 * 1000);
        let treasury_cap = coin::create_treasury_cap_for_testing<SPRUNGSUI>(scenario.ctx());
        lending_market::init_staker(
            &mut lending_market,
            &owner_cap,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            treasury_cap,
            scenario.ctx(),
        );

        let sui_reserve = lending_market::reserve<LENDING_MARKET, SUI>(&lending_market);
        let staker = reserve::staker<LENDING_MARKET, SPRUNGSUI>(sui_reserve);
        assert!(staker.total_sui_supply() == 0);
        assert!(staker.liabilities() == 0);

        let mut system_state = test_scenario::take_shared<SuiSystemState>(&scenario);
        lending_market::rebalance_staker<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            &mut system_state,
            scenario.ctx(),
        );

        let sui_reserve = lending_market::reserve<LENDING_MARKET, SUI>(&lending_market);
        let staker = reserve::staker<LENDING_MARKET, SPRUNGSUI>(sui_reserve);
        assert!(staker.total_sui_supply() == 100 * MIST_PER_SUI);
        assert!(staker.liabilities() == 100 * MIST_PER_SUI);

        let sui = coin::mint_for_testing<SUI>(
            100 * 1_000_000_000,
            scenario.ctx(),
        );
        let c_sui = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            &clock,
            sui,
            scenario.ctx(),
        );

        lending_market::rebalance_staker<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            &mut system_state,
            scenario.ctx(),
        );

        let sui_reserve = lending_market::reserve<LENDING_MARKET, SUI>(&lending_market);
        let staker = reserve::staker<LENDING_MARKET, SPRUNGSUI>(sui_reserve);
        assert!(staker.total_sui_supply() == 200 * MIST_PER_SUI);
        assert!(staker.liabilities() == 200 * MIST_PER_SUI);

        let sui_reserve = lending_market::reserve<LENDING_MARKET, SUI>(&lending_market);
        let _staker = reserve::staker<LENDING_MARKET, SPRUNGSUI>(sui_reserve);
        // std::debug::print(staker);

        let liquidity_request = lending_market::redeem_ctokens_and_withdraw_liquidity_request<
            LENDING_MARKET,
            SUI,
        >(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            &clock,
            c_sui,
            option::none(),
            scenario.ctx(),
        );

        lending_market::unstake_sui_from_staker<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            &liquidity_request,
            &mut system_state,
            scenario.ctx(),
        );

        let sui = lending_market::fulfill_liquidity_request<LENDING_MARKET, SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            liquidity_request,
            scenario.ctx(),
        );
        assert!(coin::value(&sui) == 100 * MIST_PER_SUI);

        let sui_reserve = lending_market::reserve<LENDING_MARKET, SUI>(&lending_market);
        let staker = reserve::staker<LENDING_MARKET, SPRUNGSUI>(sui_reserve);
        assert!(staker.total_sui_supply() == 100 * MIST_PER_SUI);
        assert!(staker.liabilities() == 100 * MIST_PER_SUI);

        test_scenario::return_shared(system_state);

        test_utils::destroy(sui);
        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_staker_e2e_borrow() {
        use sui::test_utils::{Self};
        use suilend::reserve_config::{Self, default_reserve_config};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::mock_pyth::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        setup_sui_system(&mut scenario);

        let State { mut clock, owner_cap, mut lending_market, prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<SUI>(),
                    ReserveArgs {
                        config: {
                            let reserve_config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &reserve_config,
                                scenario.ctx(),
                            );
                            builder.set_borrow_fee_bps(100);

                            sui::test_utils::destroy(reserve_config);

                            builder.build(scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: {
                            let reserve_config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &reserve_config,
                                scenario.ctx(),
                            );
                            builder.set_open_ltv_pct(50);
                            builder.set_close_ltv_pct(50);
                            builder.set_max_close_ltv_pct(50);

                            sui::test_utils::destroy(reserve_config);

                            builder.build(scenario.ctx())
                        },
                        initial_deposit: 100 * 1_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        clock::set_for_testing(&mut clock, 1 * 1000);
        let treasury_cap = coin::create_treasury_cap_for_testing<SPRUNGSUI>(scenario.ctx());
        lending_market::init_staker(
            &mut lending_market,
            &owner_cap,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            treasury_cap,
            scenario.ctx(),
        );

        let sui_reserve = lending_market::reserve<LENDING_MARKET, SUI>(&lending_market);
        let staker = reserve::staker<LENDING_MARKET, SPRUNGSUI>(sui_reserve);
        assert!(staker.total_sui_supply() == 0);
        assert!(staker.liabilities() == 0);

        let obligation_owner_cap = lending_market::create_obligation(
            &mut lending_market,
            scenario.ctx(),
        );

        let coins = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            coins,
            scenario.ctx(),
        );
        lending_market::deposit_ctokens_into_obligation<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            ctokens,
            scenario.ctx(),
        );

        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
        );
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            &clock,
            mock_pyth::get_price_obj<SUI>(&prices),
        );

        let liquidity_request = lending_market::borrow_request<LENDING_MARKET, SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            &obligation_owner_cap,
            &clock,
            1 * 1_000_000_000,
        );
        assert!(
            reserve::liquidity_request_amount(&liquidity_request) == 1 * 1_000_000_000 + 10_000_000,
        );
        assert!(reserve::liquidity_request_fee(&liquidity_request) == 10_000_000);

        let mut system_state = test_scenario::take_shared<SuiSystemState>(&scenario);

        lending_market::unstake_sui_from_staker<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            &liquidity_request,
            &mut system_state,
            scenario.ctx(),
        );

        let sui = lending_market::fulfill_liquidity_request<LENDING_MARKET, SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            liquidity_request,
            scenario.ctx(),
        );
        assert!(coin::value(&sui) == MIST_PER_SUI);

        test_scenario::return_shared(system_state);

        test_utils::destroy(sui);
        test_utils::destroy(owner_cap);
        test_utils::destroy(obligation_owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    #[test]
    #[allow(deprecated_usage)] // governance_test_utils -> sui_system::test_runner
    public fun test_staker_e2e_claim_fees() {
        use sui::test_utils::{Self};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        setup_sui_system(&mut scenario);

        let State { mut clock, owner_cap, mut lending_market, prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<SUI>(),
                    ReserveArgs {
                        config: default_reserve_config(scenario.ctx()),
                        initial_deposit: 100 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        clock::set_for_testing(&mut clock, 1 * 1000);
        let treasury_cap = coin::create_treasury_cap_for_testing<SPRUNGSUI>(scenario.ctx());
        lending_market::init_staker(
            &mut lending_market,
            &owner_cap,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            treasury_cap,
            scenario.ctx(),
        );

        let sui_reserve = lending_market::reserve<LENDING_MARKET, SUI>(&lending_market);
        let staker = reserve::staker<LENDING_MARKET, SPRUNGSUI>(sui_reserve);
        assert!(staker.total_sui_supply() == 0);
        assert!(staker.liabilities() == 0);

        let mut system_state = test_scenario::take_shared<SuiSystemState>(&scenario);
        lending_market::rebalance_staker<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            &mut system_state,
            scenario.ctx(),
        );
        test_scenario::return_shared(system_state);

        let sui_reserve = lending_market::reserve<LENDING_MARKET, SUI>(&lending_market);
        let staker = reserve::staker<LENDING_MARKET, SPRUNGSUI>(sui_reserve);
        assert!(staker.total_sui_supply() == 100 * MIST_PER_SUI);
        assert!(staker.sui_balance().value() == 0);
        assert!(staker.liabilities() == 100 * MIST_PER_SUI);

        advance_epoch_with_reward_amounts(0, 0, &mut scenario);
        advance_epoch_with_reward_amounts(0, 100, &mut scenario);

        let mut system_state = test_scenario::take_shared<SuiSystemState>(&scenario);
        lending_market::rebalance_staker<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            &mut system_state,
            scenario.ctx(),
        );

        let sui_reserve = lending_market::reserve<LENDING_MARKET, SUI>(&lending_market);
        let staker = reserve::staker<LENDING_MARKET, SPRUNGSUI>(sui_reserve);
        // std::debug::print(&staker.total_sui_supply());
        // the extra 50 sui gained has been transferred to the fees balance already
        assert!(staker.total_sui_supply() == 101 * MIST_PER_SUI);
        assert!(staker.liabilities() == 100 * MIST_PER_SUI);

        lending_market::claim_fees<LENDING_MARKET, SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<SUI>()),
            &mut system_state,
            scenario.ctx()
        );

        test_scenario::return_shared(system_state);
        test_scenario::next_tx(&mut scenario, owner);

        let fees: Coin<SUI> = test_scenario::take_from_address(
            &scenario,
            lending_market::fee_receiver(&lending_market),
        );
        assert!(coin::value(&fees) == 49 * MIST_PER_SUI);

        test_utils::destroy(fees);

        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::lending_market::EClaimRewardsWithBadDebt)]
    fun test_claim_rewards_with_bad_debt() {
        use sui::test_utils::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::test_sui::{TEST_SUI};
        use suilend::reserve_config::{Self, default_reserve_config};
        use suilend::mock_pyth::{Self};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let State { mut clock, owner_cap, mut lending_market, mut prices, type_to_index } = setup({
                let mut bag = bag::new(scenario.ctx());
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_USDC>(),
                    ReserveArgs {
                        config: {
                            let config = default_reserve_config(scenario.ctx());
                            let mut builder = reserve_config::from(
                                &config,
                                scenario.ctx(),
                            );
                            reserve_config::set_open_ltv_pct(&mut builder, 50);
                            reserve_config::set_close_ltv_pct(&mut builder, 50);
                            reserve_config::set_max_close_ltv_pct(&mut builder, 50);
                            sui::test_utils::destroy(config);

                            reserve_config::build(builder, scenario.ctx())
                        },
                        initial_deposit: 1000 * 1_000_000,
                    },
                );
                bag::add(
                    &mut bag,
                    type_name::with_defining_ids<TEST_SUI>(),
                    ReserveArgs {
                        config: reserve_config::default_reserve_config(scenario.ctx()),
                        initial_deposit: 1000 * 1_000_000_000,
                    },
                );

                bag
            }, scenario.ctx());

        // Add USDC rewards to the pool
        let usdc_rewards = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );
        lending_market::add_pool_reward<LENDING_MARKET, TEST_USDC>(
            &owner_cap,
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            true,
            usdc_rewards,
            0,
            10 * MILLISECONDS_IN_DAY,
            &clock,
            scenario.ctx(),
        );

        let obligation_owner_cap = lending_market::create_obligation(
            &mut lending_market,
            scenario.ctx(),
        );

        // Deposit USDC collateral
        let coins = coin::mint_for_testing<TEST_USDC>(
            100 * 1_000_000,
            scenario.ctx(),
        );
        let ctokens = lending_market::deposit_liquidity_and_mint_ctokens<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            coins,
            scenario.ctx(),
        );
        lending_market::deposit_ctokens_into_obligation<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &obligation_owner_cap,
            &clock,
            ctokens,
            scenario.ctx(),
        );

        // Set initial prices
        mock_pyth::update_price<TEST_USDC>(&mut prices, 1, 0, &clock);
        mock_pyth::update_price<TEST_SUI>(&mut prices, 1, 1, &clock);
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
        );
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &clock,
            mock_pyth::get_price_obj<TEST_SUI>(&prices),
        );

        // Borrow SUI
        let sui = lending_market::borrow<LENDING_MARKET, TEST_SUI>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &obligation_owner_cap,
            &clock,
            4 * 1_000_000_000, // 4 SUI = $40
            scenario.ctx(),
        );

        // Advance time
        clock::set_for_testing(&mut clock, 2 * MILLISECONDS_IN_DAY);

        // Crash USDC price to to $0.30
        // deposited_value = 100 * $0.30 = $30
        // borrowed_value = 4 * $10 = $40
        mock_pyth::update_decimal_price<TEST_USDC>(&mut prices, 3, 1, true, &clock); // $0.30
        mock_pyth::update_price<TEST_SUI>(&mut prices, 1, 1, &clock); // $10
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            &clock,
            mock_pyth::get_price_obj<TEST_USDC>(&prices),
        );
        lending_market::refresh_reserve_price<LENDING_MARKET>(
            &mut lending_market,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_SUI>()),
            &clock,
            mock_pyth::get_price_obj<TEST_SUI>(&prices),
        );

        let _exist_stale_oracles = lending_market.refresh_obligation_for_testing(obligation_owner_cap.obligation_id(), &clock);

        // Try to claim rewards - should fail
        let _claimed_usdc = lending_market::claim_rewards<LENDING_MARKET, TEST_USDC>(
            &mut lending_market,
            &obligation_owner_cap,
            &clock,
            *bag::borrow(&type_to_index, type_name::with_defining_ids<TEST_USDC>()),
            0,
            true,
            scenario.ctx(),
        );

        test_utils::destroy(_claimed_usdc);
        test_utils::destroy(sui);
        test_utils::destroy(obligation_owner_cap);
        test_utils::destroy(owner_cap);
        test_utils::destroy(lending_market);
        test_utils::destroy(clock);
        test_utils::destroy(prices);
        test_utils::destroy(type_to_index);
        test_utils::destroy(_exist_stale_oracles);
        test_scenario::end(scenario);
    }
}
