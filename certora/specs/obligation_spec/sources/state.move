module obligation_spec::obligation_integrity;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{rule, target, invoker};
use cvlm::nondet::nondet;
use dummy_pool::dummy_pool::DummyPool;
use suilend::obligation::Obligation;
use suilend::reserve::Reserve;
use suilend::decimal;
use suilend::obligation;
use sui::clock::Clock;
use dummy_pool::obligation::create_obligation;

public fun cvlm_manifest() {
    target(@dummy_pool, b"dummy_pool_obligation", b"refresh");
    target(@dummy_pool, b"dummy_pool_obligation", b"deposit");
    target(@dummy_pool, b"dummy_pool_obligation", b"borrow");
    target(@dummy_pool, b"dummy_pool_obligation", b"repay");
    target(@dummy_pool, b"dummy_pool_obligation", b"withdraw");
    target(@dummy_pool, b"dummy_pool_obligation", b"liquidate");
    target(@dummy_pool, b"dummy_pool_obligation", b"forgive");
    target(@dummy_pool, b"dummy_pool_obligation", b"claim_rewards");

    invoker(b"invoke");

    rule(b"liquidatable_implies_unhealthy_base");
    rule(b"liquidatable_implies_unhealthy_step");
}

native fun invoke(target: Function, obligation: &mut Obligation<DummyPool>, reserve: &mut Reserve<DummyPool>);

public fun liquidatable_implies_unhealthy(obligation: &Obligation<DummyPool>): bool {
    let healthy = obligation.is_healthy();
    let liquidatable = obligation.is_liquidatable();
    // liquidatable -> unhealthy  <==> !liquidatable || unhealthy
    return !liquidatable || !healthy
}


public fun weighted_borrow_leq_weighted_borrow_upper_bound(obligation: &Obligation<DummyPool>): bool {
    let weighted = obligation.weighted_borrowed_value_usd();
    let weighted_ub = obligation.weighted_borrowed_value_upper_bound_usd();
    weighted.le(weighted_ub)
}

public fun allowed_borrow_value_leq_unhealthy_borrow_value(obligation: &Obligation<DummyPool>): bool {
    let allowed = obligation.allowed_borrow_value_usd();
    let unhealthy = obligation.unhealthy_borrow_value_usd();
    allowed.le(unhealthy)
}


public fun liquidatable_implies_unhealthy_base(lending_market_id: ID, ctx: &mut TxContext) {
    let obligation = create_obligation(lending_market_id, ctx);


    cvlm_assert(liquidatable_implies_unhealthy(&obligation));


    ghost_destroy(obligation);
}

public fun liquidatable_implies_unhealthy_step(
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
    target: Function,
) {
    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"Assume invariant in pre-state");

    cvlm_assume_msg(weighted_borrow_leq_weighted_borrow_upper_bound(obligation), b"Require 1");
    cvlm_assume_msg( reserve.config().open_ltv().lt(reserve.config().close_ltv()), b"Require 2");
    let one = decimal::from_percent(100);
    cvlm_assume_msg( reserve.config().close_ltv().lt(one), b"Require 3");
    cvlm_assume_msg( allowed_borrow_value_leq_unhealthy_borrow_value(obligation), b"Require 4");

    cvlm_assume_msg(reserves.length() == 1, b"");
    cvlm_assume_msg(&mut reserves[1] == reserve, b"");
    let rfr = obligation.refresh(reserves, clock);
    ghost_destroy(rfr);
    invoke(target, obligation, reserve);

    cvlm_assert(liquidatable_implies_unhealthy(obligation));
}

public fun liquidatable_implies_unhealthy_step_refresh(obligation: &mut Obligation<DummyPool>) {
    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"Assume invariant in pre-state");

    let mut reserves = nondet();
    let clock = nondet();

    //let r = obligation.refresh(&mut reserves, &clock);
    let r = obligation::refresh(obligation, &mut reserves, &clock);

    cvlm_assert(liquidatable_implies_unhealthy(obligation));

    ghost_destroy(r);
    ghost_destroy(clock);
    ghost_destroy(reserves);
}
