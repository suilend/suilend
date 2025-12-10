module spec::health;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule};
use spec::dummy_pool::DummyPool;
use suilend::lending_market::{LendingMarket};
use suilend::obligation::{Obligation};
use cvlm::nondet::nondet;

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

    rule(b"obligation_health_base");
    rule(b"obligation_health_step");

    rule(b"no_deposits_no_borrow_base");
    rule(b"no_deposits_no_borrow_step");

    rule(b"unhealthy_only_if_borrow_increases");
    
    rule(b"consistency");
}

native fun invoke(target: Function, lending_market: &mut LendingMarket<DummyPool>);

/* -- Obligation health -- */

public fun consistency(lending_market: &mut LendingMarket<DummyPool>, id: ID) {
  let ob_a = lending_market.obligation(id);
  let d_a = ob_a.deposits().length();

  let mut ctx = nondet();

  let cap = lending_market.create_obligation(&mut ctx);

  let ob_b = lending_market.obligation(id);
  let d_b = ob_b.deposits().length();

  cvlm_assert(d_a == d_b);

  ghost_destroy(cap);
  ghost_destroy(ctx);

}

/// The base case for the induction.
/// Asserts that in the initial state, i.e. right after creating a new obligation, it is healthy.
/// ! Fails because somehow a different obligation is returned when retrieving it from the storage.
/// ! https://prover.certora.com/output/8195906/89205f681a9245d7a2fec9591bab5122?anonymousKey=07d2e7c012041f60f7a67b17ee4e2d75d0075737
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
/// Asserts that if obligation is in a healthy state, no lending operation can make it unhealthy.
/// This of course does when changing the prices or interest is accrued.
/// ! Fails because somehow a different obligation is returned when retrieving it from the storage.
/// ! https://prover.certora.com/output/8195906/89205f681a9245d7a2fec9591bab5122?anonymousKey=07d2e7c012041f60f7a67b17ee4e2d75d0075737
public fun obligation_health_step(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
) {
    let obligation = lending_market.obligation(id);
    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");

    invoke(target, lending_market);

    let obligation = lending_market.obligation(id);

    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}

/* No Deposits Means No Borrow */

// TODO this might need an additional invariant stating that there are not entry in the deposits/borrows vector with 0 amounts.

fun no_deposit_no_borrow(ob: &Obligation<DummyPool>): bool {
    let deposits = ob.deposits().length();
    let borrows = ob.borrows().length();

    deposits != 0 || borrows == 0
}

/// The base case for the induction.
/// Asserts that in the initial state, i.e. right after creating a new obligation, if the obligation has no deposits, it has no borrows.
public fun no_deposits_no_borrow_base(
    lending_market: &mut LendingMarket<DummyPool>,
    ctx: &mut TxContext,
) {
    let cap = lending_market.create_obligation(ctx);
    let obligation = lending_market.obligation(cap.obligation_id());
    cvlm_assert(no_deposit_no_borrow(obligation));

    ghost_destroy(cap);
}

/// The step cases for the induction.
public fun no_deposits_no_borrow_step(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
) {
    let obligation = lending_market.obligation(id);
    cvlm_assume_msg(no_deposit_no_borrow(obligation), b"Assume invariant in pre-state");

    invoke(target, lending_market);

    let obligation = lending_market.obligation(id);

    cvlm_assert_msg(no_deposit_no_borrow(obligation), b"Assert invariant in post-state");
}

/* Obligation only becomes unhealthy due to increasing borrow value */

public fun unhealthy_only_if_borrow_increases(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
) {
    let obligation = lending_market.obligation(id);

    cvlm_assume_msg(obligation.is_healthy(), b"Require invariant: obligation is healthy");

    let borrow_value_pre = obligation.weighted_borrowed_value_upper_bound_usd();

    invoke(target, lending_market);

    let obligation = lending_market.obligation(id);
    // TODO do we need to refresh the obligation here first to compound debt?
    let borrow_value_post = obligation.weighted_borrowed_value_upper_bound_usd();

    if (!obligation.is_healthy()) {
        cvlm_assert(borrow_value_pre.le(borrow_value_post));
    }
}
