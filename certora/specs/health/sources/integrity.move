/// property: Obligation Solvency Integrity
/// description: Various integrity rules regarding the healthiness of obligations.
module health::integrity;

use commons::helper::{setup_obligation, refresh_health};
use commons::inv::require_sound_obligation_state;
use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::function::Function;
use cvlm::manifest::{target, invoker, rule};
use dummy_pool::dummy_pool::DummyPool;
use suilend::decimal;
use suilend::lending_market::LendingMarket;

public fun cvlm_manifest() {
    // We ignore price changes and config updates
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
    
    // Excluded: Direct verification is computationally infeasible for this function. See health.move for rationale.
    // target(@dummy_pool, b"dummy_pool_lending_market", b"claim_rewards_and_deposit");
    
    target(@dummy_pool, b"dummy_pool_lending_market", b"init_staker");
    target(@dummy_pool, b"dummy_pool_lending_market", b"rebalance_staker");
    target(@dummy_pool, b"dummy_pool_lending_market", b"unstake_sui_from_staker");
    target(@dummy_pool, b"dummy_pool_lending_market", b"add_reserve");

    target(@dummy_pool, b"dummy_pool_lending_market", b"change_reserve_price_feed");
    target(@dummy_pool, b"dummy_pool_lending_market", b"add_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"cancel_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"close_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"update_rate_limiter_config");
    target(@dummy_pool, b"dummy_pool_lending_market", b"set_fee_receivers");
    target(@dummy_pool, b"dummy_pool_lending_market", b"new_obligation_owner_cap");

    invoker(b"invoke");

    rule(b"solvent_with_zero_debt");
    rule(b"increasing_collateral_stays_healthy");
}

native fun invoke(
    target: Function,
    lending_market: &mut LendingMarket<DummyPool>,
    obligation_id: ID,
);

/// Verifies that obligations with zero debt are always healthy
public(package) fun solvent_with_zero_debt(lm: &LendingMarket<DummyPool>, id: ID) {
    let zero = decimal::from(0);
    let obligation = setup_obligation(lm, id);

    cvlm_assume_msg(obligation.total_borrowed_amount() == zero, b"No debt");

    let healthy = obligation.is_healthy();

    cvlm_assert(healthy);
}

/// Verifies that increasing collateral preserves obligation health
public(package) fun increasing_collateral_stays_healthy(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
) {
    let obligation = setup_obligation(lending_market, id);
    let coll_pre = obligation.deposited_value_usd();
    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy");
    require_sound_obligation_state(obligation);

    invoke(target, lending_market, id);

    let (obligation, reserves) = lending_market.obligation_and_reserves_mut_for_testing(id);
    refresh_health(obligation, reserves);

    let coll_post = obligation.deposited_value_usd();

    let coll_increase = coll_post.gt(coll_pre);

    // If collateral increases, obligation remains healthy
    cvlm_assert(!coll_increase || obligation.is_healthy());
}
