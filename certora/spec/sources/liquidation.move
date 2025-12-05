module spec::liquidation;

use cvlm::asserts::cvlm_assert;
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule};
use cvlm::nondet::nondet;
use spec::dummy_pool_lending_market::DummyPool;
use sui::coin::Coin;
use suilend::lending_market::LendingMarket;
use cvlm::asserts::cvlm_assume_msg;
use suilend::obligation::Obligation;
use spec::obligation_integrity::liquidatable_implies_unhealthy;

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

    rule(b"liquidated_only_unhealthy_obligation");
}

native fun invoke(target: Function, lending_market: &mut LendingMarket<DummyPool>);

/* Liquidation reverts on healthy obligation */

public fun liquidated_only_unhealthy_obligation<R, W>(
    lm: &mut LendingMarket<DummyPool>,
    ob_id: ID,
) {
    let obligation = lm.obligation(ob_id);

    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"liquidatable => unhealthy");
    let healthy = obligation.is_healthy();

    // We don't care about the actual reserve to withdraw from/deposit to;
    let repay_reserve_array_index = nondet();
    let withdraw_reserve_array_index = nondet();

    let clock = nondet();
    let mut ctx = nondet();

    // The coins to repay
    let mut repay_coins: Coin<R> = nondet();

    let (coin, _) = lm.liquidate<DummyPool, R, W>(
        ob_id,
        repay_reserve_array_index,
        withdraw_reserve_array_index,
        &clock,
        &mut repay_coins,
        &mut ctx,
    );

    ghost_destroy(coin);
    ghost_destroy(clock);
    ghost_destroy(repay_coins);

    // We cannot check for aborts yet, but we can assert that the liquidation only passed in the obligation was unhealthy
    cvlm_assert(!healthy);
}