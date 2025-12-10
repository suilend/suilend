module solvency::ratios;

use suilend::lending_market::LendingMarket;
use cvlm::function::Function;
use cvlm::asserts::cvlm_assume_msg;
use dummy_pool::dummy_pool::DummyPool;
use cvlm::manifest::invoker;
use cvlm::manifest::target;
use cvlm::manifest::rule;
use cvlm::asserts::cvlm_assert;
use solvency::solvency::solvency;



public fun cvlm_manifest() {
    // Public mut functions
    target(@dummy_pool, b"dummy_pool_lending_market", b"refresh_reserve_price");
    target(@dummy_pool, b"dummy_pool_lending_market", b"create_obligation");
    target(@dummy_pool, b"dummy_pool_lending_market", b"deposit_liquidity_and_mint_ctokens");
    target(@dummy_pool, b"dummy_pool_lending_market", b"redeem_ctokens_and_withdraw_liquidity");
    target(@dummy_pool, b"dummy_pool_lending_market", b"redeem_ctokens_and_withdraw_liquidity_request");
    target(@dummy_pool, b"dummy_pool_lending_market", b"deposit_ctokens_into_obligation");
    target(@dummy_pool, b"dummy_pool_lending_market", b"borrow");
    target(@dummy_pool, b"dummy_pool_lending_market", b"compound_interest");
    target(@dummy_pool, b"dummy_pool_lending_market", b"borrow_request");
    target(@dummy_pool, b"dummy_pool_lending_market", b"fulfill_liquidity_request");
    target(@dummy_pool, b"dummy_pool_lending_market", b"withdraw_ctokens");
    target(@dummy_pool, b"dummy_pool_lending_market", b"liquidate");
    target(@dummy_pool, b"dummy_pool_lending_market", b"repay");
    target(@dummy_pool, b"dummy_pool_lending_market", b"forgive");
    target(@dummy_pool, b"dummy_pool_lending_market", b"claim_rewards");
    target(@dummy_pool, b"dummy_pool_lending_market", b"claim_rewards_and_deposit");
    target(@dummy_pool, b"dummy_pool_lending_market", b"init_staker");
    target(@dummy_pool, b"dummy_pool_lending_market", b"rebalance_staker");
    target(@dummy_pool, b"dummy_pool_lending_market", b"unstake_sui_from_staker");

    // Admin mut functions
    target(@dummy_pool, b"dummy_pool_lending_market", b"add_reserve");
    target(@dummy_pool, b"dummy_pool_lending_market", b"update_reserve_config");
    target(@dummy_pool, b"dummy_pool_lending_market", b"change_reserve_price_feed");
    target(@dummy_pool, b"dummy_pool_lending_market", b"add_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"cancel_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"close_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"update_rate_limiter_config");
    target(@dummy_pool, b"dummy_pool_lending_market", b"set_fee_receivers");
    target(@dummy_pool, b"dummy_pool_lending_market", b"new_obligation_owner_cap");

    invoker(b"invoke");

    rule(b"solvency_ratio_monotonicity");

}

native fun invoke(target: Function, lending_market: &mut LendingMarket<DummyPool>);

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
        let shares = suilend::decimal::from(reserve.ctoken_supply());
        (assets, shares)
    };

    cvlm_assume_msg(shares_pre.gt(suilend::decimal::from(0)), b"Assume non-zero collateral");

    invoke(target, lending_market);

    let reserve = &lending_market.reserves()[i];
    // let ratio_post = reserve.ctoken_ratio();

    let (assets_post, shares_post) = {
        let assets = reserve.total_supply();
        let shares = suilend::decimal::from(reserve.ctoken_supply());
        (assets, shares)
    };

    // Assert that the ratio assets/shares did not decrease:
    //      assets_pre/shares_pre <= assets_post/shares_post
    // <==> assets_pre * shares_post <= assets_post * shares_pre

    cvlm_assert(suilend::decimal::le(assets_pre.mul(shares_post), assets_post.mul(shares_pre)));
    // cvlm_assert(ratio_pre.le(ratio_post));
}