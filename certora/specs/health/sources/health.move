module health::health;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule};
use cvlm::nondet::nondet;
use dummy_pool::dummy_pool::DummyPool;
use health::summaries::debt_factor;
use health::utils::setup_obligation;
use sui::clock::Clock;
use suilend::decimal;
use suilend::lending_market::LendingMarket;

public fun cvlm_manifest() {
    // Public mut functions
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

    rule(b"obligation_health_base");
    rule(b"obligation_health_step");
}

native fun invoke(
    target: Function,
    lending_market: &mut LendingMarket<DummyPool>,
    obligation_id: ID,
);

/// The base case for the induction.
/// Asserts that in the initial state, i.e. right after creating a new obligation, it is healthy.
public fun obligation_health_base(
    lending_market: &mut LendingMarket<DummyPool>,
    ctx: &mut TxContext,
) {
    let cap = lending_market.create_obligation(ctx);

    let obligation = lending_market.obligation(cap.obligation_id());
    cvlm_assert(obligation.is_healthy());

    ghost_destroy(cap);
}

/// The step cases for the induction.
/// Asserts that if obligation is in a healthy state, no lending operation can make it unhealthy, unless debt is accumulated.
///
/// This is not true if
/// - reserve config is updated, or
/// - prices fluctuate
/// Hence we assume none of these happen
public fun obligation_health_step(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
    clock: &Clock,
) {

    let obligation = setup_obligation(lending_market, id);

    cvlm_assume_msg(lending_market.reserves().length() <= 2, b"At most 2 reserves");
    cvlm_assume_msg(debt_factor().ge(decimal::from(1)), b"No debt accumulates");

    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");

    // Liquidatable => Unhealthy
    cvlm_assume_msg(
        !obligation.is_liquidatable() || !obligation.is_healthy(),
        b"Require invariant: Obligation is only liquidatable if it is unhealthy",
    );
    let forgivable = obligation.is_forgivable();
    let healthy = obligation.is_healthy();
    let no_debt = obligation.borrows().length() == 0;
    // forgivable => unhealthy | no borrows
    cvlm_assume_msg(
        !forgivable || (!healthy || no_debt),
        b"Require invariant: Obligation is only forgivable if it is unhealthy or has no debt",
    );

    invoke(target, lending_market, id);


    {
        lending_market.refresh_obligation(id, clock);
        let obligation = lending_market.obligation_mut(id);

        cvlm_assert_msg(
            obligation.is_healthy(),
            b"Assert obligation is healthy in post-state after refresh",
        );
    }
}
