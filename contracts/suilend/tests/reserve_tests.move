module suilend::reserve_tests {
    // === Imports ===
    use sui::balance::{Self, Balance, Supply};
    use suilend::decimal::{Decimal, Self, add, sub, mul, div, eq, floor, pow, le, ceil, min, max, saturating_sub};
    use pyth::price_identifier::{PriceIdentifier};
    use suilend::reserve_config::{
        Self, 
        ReserveConfig, 
        calculate_apr, 
        calculate_supply_apr,
        deposit_limit, 
        deposit_limit_usd, 
        borrow_limit, 
        borrow_limit_usd, 
        borrow_fee,
        protocol_liquidation_fee,
        spread_fee,
        liquidation_bonus
    };
    use suilend::reserve::{
        Self,
        create_for_testing,
        deposit_liquidity_and_mint_ctokens,
        redeem_ctokens,
        borrow_liquidity,
        claim_fees,
        compound_interest,
        repay_liquidity,
        Balances
    };
    use sui::clock::{Self};
    use suilend::liquidity_mining::{Self, PoolRewardManager};

    use sui::test_scenario::{Self};

    #[test_only]
    public struct TEST_LM {}

    #[test]
    fun test_deposit_happy() {
        use suilend::test_usdc::{TEST_USDC};
        use sui::test_scenario::{Self};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        
        let mut reserve = create_for_testing<TEST_LM, TEST_USDC>(
            default_reserve_config(),
            0,
            6,
            decimal::from(1),
            0,
            500,
            200,
            decimal::from(500),
            decimal::from(1),
            1,
            test_scenario::ctx(&mut scenario)
        );

        let ctokens = deposit_liquidity_and_mint_ctokens<TEST_LM, TEST_USDC>(
            &mut reserve, 
            balance::create_for_testing(1000)
        );

        assert!(balance::value(&ctokens) == 200, 0);
        assert!(reserve.available_amount() == 1500, 0);
        assert!(reserve.ctoken_supply() == 400, 0);

        let balances: &Balances<TEST_LM, TEST_USDC> = reserve::balances(&reserve);

        assert!(balance::value(balances.available_amount()) == 1500, 0);
        assert!(balance::supply_value(balances.ctoken_supply()) == 400, 0);

        sui::test_utils::destroy(reserve);
        sui::test_utils::destroy(ctokens);

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::reserve::EDepositLimitExceeded)]
    fun test_deposit_fail() {
        use suilend::test_usdc::{TEST_USDC};
        use sui::test_scenario::{Self};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let mut reserve = create_for_testing<TEST_LM, TEST_USDC>(
            {
                let config = default_reserve_config();
                let mut builder = reserve_config::from(&config, test_scenario::ctx(&mut scenario));
                reserve_config::set_deposit_limit(&mut builder, 1000);
                sui::test_utils::destroy(config);

                reserve_config::build(builder, test_scenario::ctx(&mut scenario))
            },
            0,
            6,
            decimal::from(1),
            0,
            500,
            200,
            decimal::from(500),
            decimal::from(1),
            1,
            test_scenario::ctx(&mut scenario)
        );

        let coins = balance::create_for_testing<TEST_USDC>(1);
        let ctokens = deposit_liquidity_and_mint_ctokens(&mut reserve, coins);

        sui::test_utils::destroy(reserve);
        sui::test_utils::destroy(ctokens);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::reserve::EDepositLimitExceeded)]
    fun test_deposit_fail_usd_limit() {
        use suilend::test_usdc::{TEST_USDC};
        use sui::test_scenario::{Self};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let mut reserve = create_for_testing<TEST_LM, TEST_USDC>(
            {
                let config = default_reserve_config();
                let mut builder = reserve_config::from(&config, test_scenario::ctx(&mut scenario));
                reserve_config::set_deposit_limit(&mut builder, 18_446_744_073_709_551_615);
                reserve_config::set_deposit_limit_usd(&mut builder, 1);
                sui::test_utils::destroy(config);

                reserve_config::build(builder, test_scenario::ctx(&mut scenario))
            },
            0,
            6,
            decimal::from(1),
            0,
            500_000,
            1_000_000,
            decimal::from(500_000),
            decimal::from(1),
            1,
            test_scenario::ctx(&mut scenario)
        );

        let coins = balance::create_for_testing<TEST_USDC>(1);
        let ctokens = deposit_liquidity_and_mint_ctokens(&mut reserve, coins);

        sui::test_utils::destroy(reserve);
        sui::test_utils::destroy(ctokens);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_redeem_happy() {
        use suilend::test_usdc::{TEST_USDC};
        use sui::test_scenario::{Self};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let mut reserve = create_for_testing<TEST_LM, TEST_USDC>(
            default_reserve_config(),
            0,
            6,
            decimal::from(1),
            0,
            500,
            200,
            decimal::from(500),
            decimal::from(1),
            1,
            test_scenario::ctx(&mut scenario)
        );

        let available_amount_old = reserve.available_amount();
        let ctoken_supply_old = reserve.ctoken_supply();

        let ctokens = balance::create_for_testing(10);
        let liquidity_request = redeem_ctokens<TEST_LM, TEST_USDC>(&mut reserve, ctokens);
        assert!(reserve::liquidity_request_amount(&liquidity_request) == 50, 0);
        assert!(reserve::liquidity_request_fee(&liquidity_request) == 0, 0);

        let tokens = reserve::fulfill_liquidity_request(&mut reserve, liquidity_request);

        assert!(balance::value(&tokens) == 50, 0);
        assert!(reserve.available_amount() == available_amount_old - 50, 0);
        assert!(reserve.ctoken_supply() == ctoken_supply_old - 10, 0);

        let balances: &Balances<TEST_LM, TEST_USDC> = reserve::balances(&reserve);

        assert!(balance::value(balances.available_amount()) == available_amount_old - 50, 0);
        assert!(balance::supply_value(balances.ctoken_supply()) == ctoken_supply_old - 10, 0);

        sui::test_utils::destroy(reserve);
        sui::test_utils::destroy(tokens);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_borrow_happy() {
        use suilend::test_usdc::{TEST_USDC};
        use sui::test_scenario::{Self};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let mut reserve = create_for_testing<TEST_LM, TEST_USDC>(
            {
                let config = default_reserve_config();
                let mut builder = reserve_config::from(&config, test_scenario::ctx(&mut scenario));
                reserve_config::set_borrow_fee_bps(&mut builder, 100);
                sui::test_utils::destroy(config);

                reserve_config::build(builder, test_scenario::ctx(&mut scenario))
            },
            0,
            6,
            decimal::from(1),
            0,
            0,
            0,
            decimal::from(0),
            decimal::from(1),
            1,
            test_scenario::ctx(&mut scenario)
        );

        let ctokens = deposit_liquidity_and_mint_ctokens<TEST_LM, TEST_USDC>(
            &mut reserve, 
            balance::create_for_testing(1000)
        );

        let available_amount_old = reserve.available_amount();
        let borrowed_amount_old = reserve.borrowed_amount();

        let liquidity_request = borrow_liquidity<TEST_LM, TEST_USDC>(&mut reserve, 400);
        assert!(reserve::liquidity_request_amount(&liquidity_request) == 404, 0);
        assert!(reserve::liquidity_request_fee(&liquidity_request) == 4, 0);

        let tokens = reserve::fulfill_liquidity_request(&mut reserve, liquidity_request);
        assert!(balance::value(&tokens) == 400, 0);

        assert!(reserve.available_amount() == available_amount_old - 404, 0);
        assert!(reserve.borrowed_amount() == add(borrowed_amount_old, decimal::from(404)), 0);

        let balances: &Balances<TEST_LM, TEST_USDC> = reserve::balances(&reserve);

        assert!(balance::value(balances.available_amount()) == available_amount_old - 404, 0);
        assert!(balance::value(balances.fees()) == 4, 0);

        let (ctoken_fees, fees) = claim_fees<TEST_LM, TEST_USDC>(&mut reserve);
        assert!(balance::value(&fees) == 4, 0);
        assert!(balance::value(&ctoken_fees) == 0, 0);

        sui::test_utils::destroy(fees);
        sui::test_utils::destroy(ctoken_fees);
        sui::test_utils::destroy(reserve);
        sui::test_utils::destroy(tokens);
        sui::test_utils::destroy(ctokens);

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::reserve::EBorrowLimitExceeded)]
    fun test_borrow_fail() {
        use suilend::test_usdc::{TEST_USDC};
        use sui::test_scenario::{Self};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let mut reserve = create_for_testing<TEST_LM, TEST_USDC>(
            {
                let config = default_reserve_config();
                let mut builder = reserve_config::from(&config, test_scenario::ctx(&mut scenario));
                reserve_config::set_borrow_limit(&mut builder, 0);
                sui::test_utils::destroy(config);

                reserve_config::build(builder, test_scenario::ctx(&mut scenario))
            },
            0,
            6,
            decimal::from(1),
            0,
            0,
            0,
            decimal::from(0),
            decimal::from(1),
            1,
            test_scenario::ctx(&mut scenario)
        );

        let ctokens = deposit_liquidity_and_mint_ctokens<TEST_LM, TEST_USDC>(
            &mut reserve, 
            balance::create_for_testing(1000)
        );

        let liquidity_request = borrow_liquidity<TEST_LM, TEST_USDC>(&mut reserve, 1);

        sui::test_utils::destroy(liquidity_request);
        sui::test_utils::destroy(reserve);
        sui::test_utils::destroy(ctokens);

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suilend::reserve::EBorrowLimitExceeded)]
    fun test_borrow_fail_usd_limit() {
        use suilend::test_usdc::{TEST_USDC};
        use sui::test_scenario::{Self};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let mut reserve = create_for_testing<TEST_LM, TEST_USDC>(
            {
                let config = default_reserve_config();
                let mut builder = reserve_config::from(&config, test_scenario::ctx(&mut scenario));
                reserve_config::set_borrow_limit_usd(&mut builder, 1);
                sui::test_utils::destroy(config);

                reserve_config::build(builder, test_scenario::ctx(&mut scenario))
            },
            0,
            6,
            decimal::from(1),
            0,
            0,
            0,
            decimal::from(0),
            decimal::from(1),
            1,
            test_scenario::ctx(&mut scenario)
        );

        let ctokens = deposit_liquidity_and_mint_ctokens<TEST_LM, TEST_USDC>(
            &mut reserve, 
            balance::create_for_testing(10_000_000)
        );

        let liquidity_request = borrow_liquidity<TEST_LM, TEST_USDC>(&mut reserve, 1_000_000 + 1);

        sui::test_utils::destroy(liquidity_request);
        sui::test_utils::destroy(reserve);
        sui::test_utils::destroy(ctokens);

        test_scenario::end(scenario);
    }


    #[test]
    fun test_claim_fees() {
        use suilend::test_usdc::{TEST_USDC};
        use sui::test_scenario::{Self};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

        let mut reserve = create_for_testing<TEST_LM, TEST_USDC>(
            {
                let config = default_reserve_config();
                let mut builder = reserve_config::from(&config, test_scenario::ctx(&mut scenario));
                reserve_config::set_deposit_limit(&mut builder, 1000 * 1_000_000);
                reserve_config::set_borrow_limit(&mut builder, 1000 * 1_000_000);
                reserve_config::set_borrow_fee_bps(&mut builder, 0);
                reserve_config::set_spread_fee_bps(&mut builder, 5000);
                reserve_config::set_interest_rate_utils(&mut builder, {
                    let mut v = vector::empty();
                    vector::push_back(&mut v, 0);
                    vector::push_back(&mut v, 100);
                    v
                });
                reserve_config::set_interest_rate_aprs(&mut builder, {
                    let mut v = vector::empty();
                    vector::push_back(&mut v, 0);
                    vector::push_back(&mut v, 3153600000);
                    v
                });

                sui::test_utils::destroy(config);

                reserve_config::build(builder, test_scenario::ctx(&mut scenario))
            },
            0,
            6,
            decimal::from(1),
            0,
            0,
            0,
            decimal::from(0),
            decimal::from(1),
            0,
            test_scenario::ctx(&mut scenario)
        );

        let ctokens = deposit_liquidity_and_mint_ctokens<TEST_LM, TEST_USDC>(
            &mut reserve, 
            balance::create_for_testing(100 * 1_000_000)
        );

        let liquidity_request = borrow_liquidity<TEST_LM, TEST_USDC>(&mut reserve, 50 * 1_000_000);
        let tokens = reserve::fulfill_liquidity_request(&mut reserve, liquidity_request);

        clock::set_for_testing(&mut clock, 1000);
        compound_interest(&mut reserve, &clock);

        let old_available_amount = reserve.available_amount();
        let old_unclaimed_spread_fees = reserve.unclaimed_spread_fees();

        let (ctoken_fees, fees) = claim_fees<TEST_LM, TEST_USDC>(&mut reserve);

        // 0.5% interest a second with 50% take rate => 0.25% fee on 50 USDC = 0.125 USDC
        assert!(balance::value(&fees) == 125_000, 0);
        assert!(balance::value(&ctoken_fees) == 0, 0);

        assert!(reserve.available_amount() == old_available_amount - 125_000, 0);
        assert!(reserve.unclaimed_spread_fees() == sub(old_unclaimed_spread_fees, decimal::from(125_000)), 0);

        let balances: &Balances<TEST_LM, TEST_USDC> = reserve::balances(&reserve);
        assert!(balance::value(balances.available_amount()) == old_available_amount - 125_000, 0);

        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(ctoken_fees);
        sui::test_utils::destroy(fees);
        sui::test_utils::destroy(reserve);
        sui::test_utils::destroy(tokens);
        sui::test_utils::destroy(ctokens);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_repay_happy() {
        use suilend::test_usdc::{TEST_USDC};
        use sui::test_scenario::{Self};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let mut reserve = create_for_testing<TEST_LM, TEST_USDC>(
            {
                let config = default_reserve_config();
                let mut builder = reserve_config::from(&config, test_scenario::ctx(&mut scenario));
                reserve_config::set_borrow_fee_bps(&mut builder, 100);
                sui::test_utils::destroy(config);

                reserve_config::build(builder, test_scenario::ctx(&mut scenario))
            },
            0,
            6,
            decimal::from(1),
            0,
            0,
            0,
            decimal::from(0),
            decimal::from(1),
            1,
            test_scenario::ctx(&mut scenario)
        );

        let ctokens = deposit_liquidity_and_mint_ctokens<TEST_LM, TEST_USDC>(
            &mut reserve, 
            balance::create_for_testing(1000)
        );

        let liquidity_request = borrow_liquidity<TEST_LM, TEST_USDC>(&mut reserve, 400);
        let tokens = reserve::fulfill_liquidity_request(&mut reserve, liquidity_request);

        let available_amount_old = reserve.available_amount();
        let borrowed_amount_old = reserve.borrowed_amount();

        repay_liquidity(&mut reserve, tokens, decimal::from_percent_u64(39_901));

        assert!(reserve.available_amount() == available_amount_old + 400, 0);
        assert!(reserve.borrowed_amount() == sub(borrowed_amount_old, decimal::from_percent_u64(39_901)), 0);

        let balances: &Balances<TEST_LM, TEST_USDC> = reserve::balances(&reserve);
        assert!(balance::value(balances.available_amount()) == available_amount_old + 400, 0);

        sui::test_utils::destroy(reserve);
        sui::test_utils::destroy(ctokens);

        test_scenario::end(scenario);
    }


}