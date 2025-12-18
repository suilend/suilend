module obligation_spec::obligation_integrity;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::rule;
use dummy_pool::dummy_pool::DummyPool;
use dummy_pool::obligation::create_obligation;
use obligation_spec::state::liquidatable_implies_unhealthy;
use sui::clock::Clock;
use suilend::decimal::Decimal;
use suilend::liquidity_mining::PoolRewardManager;
use suilend::obligation::{Obligation, compound_debt, ExistStaleOracles};
use suilend::reserve::Reserve;
use cvlm::nondet::nondet;
use obligation_spec::state::forgivable_only_if_unhealthy_or_debt_free;


public fun cvlm_manifest() {
    rule(b"obligation_health_base");

    rule(b"obligation_health_step_refresh");
    rule(b"obligation_health_step_deposit");
    rule(b"obligation_health_step_borrow");
    rule(b"obligation_health_step_repay");
    rule(b"obligation_health_step_withdraw");
    rule(b"obligation_health_step_liquidate");
    rule(b"obligation_health_step_forgive");
    rule(b"obligation_health_step_claim_rewards");
}




/// The base case for the induction.
/// Asserts that in the initial state, i.e. right after creating a new obligation, it is healthy.
public fun obligation_health_base(lending_market_id: ID, ctx: &mut TxContext) {
    let obligation = create_obligation(lending_market_id, ctx);
    cvlm_assert(obligation.is_healthy());
    ghost_destroy(obligation);
}



fun require_fresh_state(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {
    cvlm_assume_msg(reserves.length() <= 2, b"At most three reserves");
    cvlm_assume_msg(obligation.deposits().length() <= 2, b"At most two deposits");
    cvlm_assume_msg(obligation.borrows().length() <= 2, b"At most two borrows");

    // Fresh prices + no pending interest accrual
    let mut i = 0;
    while (i < reserves.length()) {
        reserves[i].assert_price_is_fresh(clock);
        i = i + 1;
    };

    // bring obligation into a fully refreshed snapshot
    let ret1 = obligation.refresh(reserves, clock);
    ret1.destroy_none();
}

fun get_reserve(reserves: &mut vector<Reserve<DummyPool>>): &mut Reserve<DummyPool> {
    let i = nondet();
    let res = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(res.array_index() == i, b"array_index == position");
    res
}

public fun obligation_health_step_refresh(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {
   
   require_fresh_state(obligation, reserves, clock);

    cvlm_assume_msg(
        obligation.is_healthy(),
        b"Assume obligation is healthy in refreshed pre-state",
    );

    // 2nd refresh: prove that refreshing a already-refreshed healthy obligation preserves health
    let ret2 = obligation.refresh(reserves, clock);
    ret2.destroy_none();

    cvlm_assert_msg(
        obligation.is_healthy(),
        b"Assert obligation is healthy in post-state",
    );
}

public fun obligation_health_step_deposit(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
    ctoken_amount: u64,
) {
    require_fresh_state(obligation, reserves, clock);
    let reserve = get_reserve(reserves);

    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");
    reserve.assert_price_is_fresh(clock);
    obligation.deposit(reserve, clock, ctoken_amount);
    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}

public fun obligation_health_step_borrow(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
    amount: u64,
) {
    require_fresh_state(obligation, reserves, clock);
    let reserve = get_reserve(reserves);

    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");
    reserve.assert_price_is_fresh(clock);
    obligation.borrow(reserve, clock, amount);
    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}


public fun obligation_health_step_repay(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
    max_repay_amount: Decimal,
) {
    require_fresh_state(obligation, reserves, clock);
    let reserve = get_reserve(reserves);
    

    let borrow = obligation.find_borrow_mut(reserve);
    borrow.compound_debt(reserve);

    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");

    obligation.repay(reserve, clock, max_repay_amount);
    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}

public fun obligation_health_step_withdraw(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
    ctoken_amount: u64,
    stale_oracles: Option<ExistStaleOracles>,
) {
    require_fresh_state(obligation, reserves, clock);
    let reserve = get_reserve(reserves);

    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");
    reserve.assert_price_is_fresh(clock);
    obligation.withdraw(reserve, clock, ctoken_amount, stale_oracles);
    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}

public fun obligation_health_step_liquidate(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    repay_reserve_array_index: u64,
    withdraw_reserve_array_index: u64,
    clock: &Clock,
    repay_amount: u64,
) {
    require_fresh_state(obligation, reserves, clock);

    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"Require invaraint");
    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");

    obligation.liquidate(
        reserves,
        repay_reserve_array_index,
        withdraw_reserve_array_index,
        clock,
        repay_amount,
    );

    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}

public fun obligation_health_step_forgive(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
    max_forgive_amount: Decimal,
) {
    require_fresh_state(obligation, reserves, clock);
    cvlm_assume_msg(forgivable_only_if_unhealthy_or_debt_free(obligation), b"Require invariant");
    let reserve = get_reserve(reserves);

    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");
    reserve.assert_price_is_fresh(clock);
    obligation.forgive(reserve, clock, max_forgive_amount);
    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}

public fun obligation_health_step_claim_rewards<T>(
    obligation: &mut Obligation<DummyPool>,
    pool_reward_manager: &mut PoolRewardManager,
    clock: &Clock,
    reward_index: u64,
) {
    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");
    let rew = obligation.claim_rewards<DummyPool, T>(pool_reward_manager, clock, reward_index);
    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");

    ghost_destroy(rew);
}
