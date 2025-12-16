module health::health;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule, summary};
use cvlm::nondet::{nondet_with, nondet};
use dummy_pool::dummy_pool::DummyPool;
use sui::clock::Clock;
use suilend::decimal::Decimal;
use suilend::lending_market::LendingMarket;
use suilend::liquidity_mining::PoolRewardManager;
use suilend::obligation::Obligation;
use suilend::rate_limiter::RateLimiter;
use suilend::reserve::{Reserve, LiquidityRequest};
use suilend::liquidity_mining::UserRewardManager;

public fun cvlm_manifest() {
    // Public mut functions
    target(@dummy_pool, b"dummy_pool_lending_market", b"refresh_reserve_price");
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
    target(@dummy_pool, b"dummy_pool_lending_market", b"update_reserve_config");
    target(@dummy_pool, b"dummy_pool_lending_market", b"change_reserve_price_feed");
    target(@dummy_pool, b"dummy_pool_lending_market", b"add_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"cancel_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"close_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"update_rate_limiter_config");
    target(@dummy_pool, b"dummy_pool_lending_market", b"set_fee_receivers");
    target(@dummy_pool, b"dummy_pool_lending_market", b"new_obligation_owner_cap");

    invoker(b"invoke");

    //summary(b"reserve_compound_borrow_rate", @suilend, b"reserve", b"compound_borrow_rate");
    summary(b"reserve_compound_interest", @suilend, b"reserve", b"compound_interest");
    summary(b"reserve_borrow_liquidity", @suilend, b"reserve", b"borrow_liquidity");

    summary(b"rate_limiter_process_qty", @suilend, b"rate_limiter", b"process_qty");

    summary(b"obligation_find_borrow_index", @suilend, b"obligation", b"find_borrow_index");
    summary(b"obligation_find_deposit_index", @suilend, b"obligation", b"find_deposit_index");
    summary(b"obligation_log_obligation_data", @suilend, b"obligation", b"log_obligation_data");
    summary(b"obligation_find_or_add_user_reward_manager", @suilend, b"obligation", b"find_or_add_user_reward_manager");
    summary(
        b"obligation_zero_out_rewards_if_looped",
        @suilend,
        b"obligation",
        b"zero_out_rewards_if_looped",
    );

    summary(
        b"mining_change_user_reward_manager_share",
        @suilend,
        b"liquidity_mining",
        b"change_user_reward_manager_share",
    );
    

    rule(b"obligation_health_base");
    rule(b"obligation_health_step");

    rule(b"no_deposits_no_borrow_base");
    rule(b"no_deposits_no_borrow_step");

    rule(b"unhealthy_only_if_borrow_increases");
}

native fun invoke(target: Function, lending_market: &mut LendingMarket<DummyPool>);

public fun reserve_compound_borrow_rate(_: &mut Reserve<DummyPool>, _: u64): Decimal {
    let val = nondet_with!(b"Borrow rate", |r| 1 <= r && r < 2);
    suilend::decimal::from(val)
}

public fun reserve_compound_interest<P>(_: &mut Reserve<P>, _: &Clock) {}

public fun reserve_borrow_liquidity<P, T>(
    _reserve: &mut Reserve<P>,
    _amount: u64,
): LiquidityRequest<P, T> {
    nondet()
}

public fun rate_limiter_process_qty(
    _rate_limiter: &mut RateLimiter,
    _cur_time: u64,
    _qty: Decimal,
) {} // noop

public fun obligation_find_borrow_index<P>(_: &Obligation<P>, _: &Reserve<P>): u64 {
    return nondet()
}

public fun obligation_find_deposit_index<P>(_: &Obligation<P>, _: &Reserve<P>): u64 {
    return nondet()
}

public fun mining_change_user_reward_manager_share(
    _pool_reward_manager: &mut PoolRewardManager,
    _user_reward_manager: &mut UserRewardManager,
    _new_share: u64,
    _clock: &Clock,
) {}

public fun obligation_log_obligation_data<P>(_obligation: &Obligation<P>) {} // no-op

public(package) fun obligation_zero_out_rewards_if_looped<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
) {} //noop



public fun obligation_find_or_add_user_reward_manager<P>(
        _obligation: &mut Obligation<P>,
        _pool_reward_manager: &mut PoolRewardManager,
        _clock: &Clock,
    ): (u64, &mut UserRewardManager) {
        let i = nondet();
        let mnrg = vector::borrow_mut(_obligation.user_reward_managers_mut(), i);
        (i, mnrg)
    }

/* -- Obligation health -- */

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
/// Asserts that if obligation is in a healthy state, no lending operation can make it unhealthy, unless enough interest is accrued.
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
