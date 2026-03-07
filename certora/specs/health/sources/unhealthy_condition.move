/// property: Unhealthy Obligation Condition
/// description: Verifies that obligations only become unhealthy when borrow value increases (excluding config and price changes)
module health::unhealthy_condition;

use commons::helper::{setup_obligation, refresh_health_compound_debt};
use commons::inv::require_sound_obligation_state;
use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::function::Function;
use cvlm::manifest::{target, invoker, rule};
use dummy_pool::dummy_pool::DummyPool;
use suilend::lending_market::LendingMarket;
use suilend::obligation::is_healthy;

public fun cvlm_manifest() {
    // Public mut functions

    // Ignore price and config changes
    // target(@dummy_pool, b"dummy_pool_lending_market", b"refresh_reserve_price");
    // target(@dummy_pool, b"dummy_pool_lending_market", b"update_reserve_config");

    target(@dummy_pool, b"dummy_pool_lending_market", b"create_obligation");
    target(@dummy_pool, b"dummy_pool_lending_market", b"deposit_liquidity_and_mint_ctokens");
    target(@dummy_pool, b"dummy_pool_lending_market", b"redeem_ctokens_and_withdraw_liquidity");
    target(
        @dummy_pool,
        b"dummy_pool_lending_market",
        b"redeem_ctokens_and_withdraw_liquidity_request",
    );
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
    target(@dummy_pool, b"dummy_pool_lending_market", b"change_reserve_price_feed");
    target(@dummy_pool, b"dummy_pool_lending_market", b"add_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"cancel_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"close_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"update_rate_limiter_config");
    target(@dummy_pool, b"dummy_pool_lending_market", b"set_fee_receivers");
    target(@dummy_pool, b"dummy_pool_lending_market", b"new_obligation_owner_cap");

    invoker(b"invoke");

    rule(b"unhealthy_only_if_borrow_increases");
}

native fun invoke(
    target: Function,
    lending_market: &mut LendingMarket<DummyPool>,
    obligation_id: ID,
);

/// Verifies that obligations only become unhealthy when borrow value increases
public(package) fun unhealthy_only_if_borrow_increases(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
) {
    let obligation = setup_obligation(lending_market, id);

    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy");

    // Liquidatable => Unhealthy
    require_sound_obligation_state(obligation);
    let borrow_value_pre = obligation.weighted_borrowed_value_upper_bound_usd();

    invoke(target, lending_market, id);

    let (obligation, reserves) = lending_market.obligation_and_reserves_mut_for_testing(id);
    refresh_health_compound_debt(obligation, reserves);

    let borrow_value_post = obligation.weighted_borrowed_value_upper_bound_usd();

    if (!obligation.is_healthy()) {
        cvlm_assert(borrow_value_pre.le(borrow_value_post));
    }
}
