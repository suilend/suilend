module spec::solvency;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule};
use pyth::price_info::PriceInfoObject;
use spec::dummy_pool_lending_market::DummyPool;
use spec::utils::log;
use sui::clock::Clock;
use sui::sui::SUI;
use suilend::lending_market::{LendingMarket};
use suilend::reserve::{Reserve, create_reserve};
use suilend::reserve_config::ReserveConfig;
use suilend::decimal;

public fun cvlm_manifest() {
    // Public mut functions
    target(@spec, b"dummy_pool_lending_market", b"refresh_reserve_price");
    target(@spec, b"dummy_pool_lending_market", b"create_obligation");
    target(@spec, b"dummy_pool_lending_market", b"deposit_liquidity_and_mint_ctokens");
    target(@spec, b"dummy_pool_lending_market", b"redeem_ctokens_and_withdraw_liquidity");
    target(@spec, b"dummy_pool_lending_market", b"redeem_ctokens_and_withdraw_liquidity_request");
    target(@spec, b"dummy_pool_lending_market", b"deposit_ctokens_into_obligation");
    target(@spec, b"dummy_pool_lending_market", b"borrow");
    target(@spec, b"dummy_pool_lending_market", b"compound_interest");
    target(@spec, b"dummy_pool_lending_market", b"borrow_request");
    target(@spec, b"dummy_pool_lending_market", b"fulfill_liquidity_request");
    target(@spec, b"dummy_pool_lending_market", b"withdraw_ctokens");
    target(@spec, b"dummy_pool_lending_market", b"liquidate");
    target(@spec, b"dummy_pool_lending_market", b"repay");
    target(@spec, b"dummy_pool_lending_market", b"forgive");
    target(@spec, b"dummy_pool_lending_market", b"claim_rewards");
    target(@spec, b"dummy_pool_lending_market", b"claim_rewards_and_deposit");
    target(@spec, b"dummy_pool_lending_market", b"init_staker");
    target(@spec, b"dummy_pool_lending_market", b"rebalance_staker");
    target(@spec, b"dummy_pool_lending_market", b"unstake_sui_from_staker");

    // Admin mut functions
    target(@spec, b"dummy_pool_lending_market", b"add_reserve");
    target(@spec, b"dummy_pool_lending_market", b"update_reserve_config");
    target(@spec, b"dummy_pool_lending_market", b"change_reserve_price_feed");
    target(@spec, b"dummy_pool_lending_market", b"add_pool_reward");
    target(@spec, b"dummy_pool_lending_market", b"cancel_pool_reward");
    target(@spec, b"dummy_pool_lending_market", b"close_pool_reward");
    target(@spec, b"dummy_pool_lending_market", b"update_rate_limiter_config");
    target(@spec, b"dummy_pool_lending_market", b"set_fee_receivers");
    target(@spec, b"dummy_pool_lending_market", b"new_obligation_owner_cap");

    invoker(b"invoke");

    rule(b"solvency_base");
    rule(b"solvency_step");

    rule(b"solvency_ratio_monotonicity");

    rule(b"obligation_col_increase_implies_reserve_asset_increase");
}

native fun invoke(target: Function, lending_market: &mut LendingMarket<DummyPool>);

/* -- Solvency -- */

/// Returns whether given reserve is solvent, i.e., whether the total supply of assets is equal to or greater than the amount of cTokens.
fun solvency(reserve: &Reserve<DummyPool>): bool {
    let assets = reserve.total_supply().floor();
    let shares = reserve.ctoken_supply();

    log(&assets);
    log(&shares);

    assets >= shares
}

/// The base case for the induction.
/// Asserts that in the initial state, i.e. right after creating a new reserve, the solvency property holds.
public fun solvency_base<T>(
    lending_market_id: ID,
    config: ReserveConfig,
    array_index: u64,
    mint_decimals: u8,
    price_info_obj: &PriceInfoObject,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let reserve: Reserve<DummyPool> = create_reserve<DummyPool, T>(
        lending_market_id,
        config,
        array_index,
        mint_decimals,
        price_info_obj,
        clock,
        ctx,
    );
    cvlm_assert(solvency(&reserve));
    ghost_destroy(reserve);
}

/// The induction steps for the solvency invariant.
/// Assumes an arbitrary reserve, identified by its index in the lending market, that is in a solvent state,
/// and assert that every function that can modify the state preserves the solvency.
/// ! Timeouts
public fun solvency_step(lending_market: &mut LendingMarket<DummyPool>, i: u64, target: Function) {
    cvlm_assume_msg(i < lending_market.reserves().length(), b"Index is in range");

    {
        let reserve = &lending_market.reserves()[i];
        cvlm_assume_msg(solvency(reserve), b"Assume reserve is solvent pre-state");
    };

    invoke(target, lending_market);

    {
        let reserve = &lending_market.reserves()[i];
        cvlm_assert_msg(solvency(reserve), b"Assert reserve is solvent in post-state");
    };
}

/* Solvency Ratio Monotonicity */

/// Verifies that the solvency ratio, i.e. liquidity to collateral ratio, cannot decrease by
/// user operations. This ensure that no action performed by any user can depreciate the value
/// of a ctoken.
/// This does not hold for the privileged `forgive` function.
public fun solvency_ratio_monotonicity(
    lending_market: &mut LendingMarket<DummyPool>,
    i: u64,
    target: Function,
) {
    cvlm_assume_msg(i < lending_market.reserves().length(), b"Index is in range");

    let reserve = &lending_market.reserves()[i];
    cvlm_assume_msg(solvency(reserve), b"Require invariant reserve is solvent");

    // let ratio_pre = reserve.ctoken_ratio();
    let (assets_pre, shares_pre) = {
        let assets = reserve.total_supply();
        let shares = decimal::from(reserve.ctoken_supply());
        (assets, shares)
    };

    cvlm_assume_msg(shares_pre.gt(decimal::from(0)), b"Assume non-zero collateral");

    invoke(target, lending_market);

    let reserve = &lending_market.reserves()[i];
    // let ratio_post = reserve.ctoken_ratio();
    
    let (assets_post, shares_post) = {
        let assets = reserve.total_supply();
        let shares =  decimal::from(reserve.ctoken_supply());
        (assets, shares)
    };

    // Assert that the ratio assets/shares did not decrease:
    //      assets_pre/shares_pre <= assets_post/shares_post
    // <==> assets_pre * shares_post <= assets_post * shares_pre

   cvlm_assert(decimal::le(assets_pre.mul(shares_post), assets_post.mul(shares_pre)));
   // cvlm_assert(ratio_pre.le(ratio_post));
}


/* Other Rules */

/// Spurious cex in invalid states(?) and timeouts.
/// !https://prover.certora.com/output/8195906/85d1b933016345b480f2ebe7e1552068?anonymousKey=ff7b6e36154ea2f9318757c8431ad5668910278a
fun get_ctoken_amounts(lm: &LendingMarket<DummyPool>, ri: u64, obi: ID): (u64, u64) {
    let reserve = &lm.reserves()[ri];
    let reserve_ctokens = reserve.balances().deposited_ctoken_amount<DummyPool, SUI>().value();

    let obligation = lm.obligation(obi);
    let obligation_ctokens = obligation.deposited_ctoken_amount<DummyPool, SUI>();
    (obligation_ctokens, reserve_ctokens)
}



public fun obligation_col_increase_implies_reserve_asset_increase(
    lending_market: &mut LendingMarket<DummyPool>,
    i: u64,
    ob_id: ID,
    target: Function,
) {
    cvlm_assume_msg(i < lending_market.reserves().length(), b"Index is in range");

    //let (ob_ctokens_pre, res_ctokens_pre) = get_ctoken_amounts(lending_market, i, ob_id);
    let (ob_ctokens_pre, res_ctokens_pre) = {
        let reserve = &lending_market.reserves()[i];
        let reserve_ctokens = reserve.balances().deposited_ctoken_amount<DummyPool, SUI>().value();

        let obligation = lending_market.obligation(ob_id);
        let obligation_ctokens = obligation.deposited_ctoken_amount<DummyPool, SUI>();
        (obligation_ctokens, reserve_ctokens)
    };

    invoke(target, lending_market);

    // let (ob_ctokens_post, res_ctokens_post) = get_ctoken_amounts(lending_market, i, ob_id);
    let (ob_ctokens_post, res_ctokens_post) = {
        let reserve = &lending_market.reserves()[i];
        let reserve_ctokens = reserve.balances().deposited_ctoken_amount<DummyPool, SUI>().value();

        let obligation = lending_market.obligation(ob_id);
        let obligation_ctokens = obligation.deposited_ctoken_amount<DummyPool, SUI>();
        (obligation_ctokens, reserve_ctokens)
    };

    if (ob_ctokens_post > ob_ctokens_pre) {
        let obligation_diff = ob_ctokens_post - ob_ctokens_pre;
        cvlm_assert(res_ctokens_post > res_ctokens_pre);
        let reserve_diff = res_ctokens_post - res_ctokens_pre;
        cvlm_assert(obligation_diff == reserve_diff);
    }
}
