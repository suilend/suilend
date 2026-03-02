/// property: Obligation Health Preservation
/// description: Verifies that obligations remain healthy after lending operations, assuming no debt accumulation and stable prices/configs
module health::health;

use commons::helper::{setup_obligation, refresh_health};
use commons::inv::require_sound_obligation_state;
use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule};
use dummy_pool::dummy_pool::DummyPool;
use health::summaries_obligation::debt_factor;
use suilend::decimal;
use suilend::lending_market::LendingMarket;

public fun cvlm_manifest() {
    // We explicitly ignore price changes and config updates
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
    target(@dummy_pool, b"dummy_pool_lending_market", b"add_reserve");
    target(@dummy_pool, b"dummy_pool_lending_market", b"change_reserve_price_feed");
    target(@dummy_pool, b"dummy_pool_lending_market", b"add_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"cancel_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"close_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"update_rate_limiter_config");
    target(@dummy_pool, b"dummy_pool_lending_market", b"set_fee_receivers");
    target(@dummy_pool, b"dummy_pool_lending_market", b"new_obligation_owner_cap");

    invoker(b"invoke");

    rule(b"obligation_health_base");
    rule(b"obligation_health_step");
}

native fun invoke(
    target: Function,
    lending_market: &mut LendingMarket<DummyPool>,
    obligation_id: ID,
);

/// Verifies that newly created obligations are healthy
public(package) fun obligation_health_base(
    lending_market: &mut LendingMarket<DummyPool>,
    ctx: &mut TxContext,
) {
    let cap = lending_market.create_obligation(ctx);

    let obligation = lending_market.obligation(cap.obligation_id());
    cvlm_assert(obligation.is_healthy());

    ghost_destroy(cap);
}

/// Verifies that healthy obligations remain healthy after operations (excluding debt accumulation, price changes, and config updates)
public(package) fun obligation_health_step(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
) {
    let obligation = setup_obligation(lending_market, id);

    cvlm_assume_msg(lending_market.reserves().length() <= 2, b"At most 2 reserves");
    cvlm_assume_msg(debt_factor().eq(decimal::from(1)), b"No debt accumulates");
    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");

    require_sound_obligation_state(obligation);

    invoke(target, lending_market, id);

    let (ob, reserves) = lending_market.obligation_and_reserves_mut_for_testing(id);
    refresh_health(ob, reserves);

    cvlm_assert_msg(
        ob.is_healthy(),
        b"Assert obligation is healthy in post-state after refresh",
    );
}
