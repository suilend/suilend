/// property: Obligation Health Consistency
/// description: Verifies consistency between obligation health states: liquidatable obligations must be unhealthy,
/// and forgivable obligations must be either unhealthy or debt-free
module obligation::health_consistency;

use commons::helper::refresh_health;
use commons::inv::{liquidatable_implies_unhealthy, forgivable_only_if_unhealthy_or_debt_free};
use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{rule, target, invoker};
use cvlm::nondet::nondet;
use dummy_pool::dummy_pool::DummyPool;
use dummy_pool::obligation::create_obligation;
use sui::clock::Clock;
use suilend::decimal;
use suilend::obligation::Obligation;
use suilend::reserve::Reserve;

public fun cvlm_manifest() {
    target(@dummy_pool, b"obligation", b"deposit");
    target(@dummy_pool, b"obligation", b"borrow");
    target(@dummy_pool, b"obligation", b"withdraw");
    target(@dummy_pool, b"obligation", b"repay");
    target(@dummy_pool, b"obligation", b"liquidate");
    target(@dummy_pool, b"obligation", b"forgive");
    target(@dummy_pool, b"obligation", b"claim_rewards");

    invoker(b"invoke");

    rule(b"liquidatable_implies_unhealthy_base");
    rule(b"liquidatable_implies_unhealthy_step");
    rule(b"forgivable_only_if_unhealthy_or_debt_free_base");
    rule(b"forgivable_only_if_unhealthy_or_debt_free_step");
}

native fun invoke(
    target: Function,
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    clock: &Clock,
);

/// Verifies that newly created obligations satisfy the liquidatable-implies-unhealthy invariant
public fun liquidatable_implies_unhealthy_base(lending_market_id: ID, ctx: &mut TxContext) {
    let obligation = create_obligation(lending_market_id, ctx);
    cvlm_assert(liquidatable_implies_unhealthy(&obligation));
    ghost_destroy(obligation);
}

/// Verifies that obligation operations maintain the property that
/// any obligation eligible for liquidation must be in an unhealthy state
public fun liquidatable_implies_unhealthy_step(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
    target: Function,
) {
    /* Restrict model size */
    cvlm_assume_msg(reserves.length() <= 2, b"");
    cvlm_assume_msg(obligation.borrows().length() <= 1, b"");
    cvlm_assume_msg(obligation.deposits().length() <= 1, b"");

    // Pick a reserve
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"Existing reserve");
    cvlm_assume_msg(reserves[i].array_index() == i, b"array_index == position");

    refresh_health(obligation, reserves);

    let allowed = obligation.allowed_borrow_value_usd();
    let unhealthy = obligation.unhealthy_borrow_value_usd();
    let borrowed = obligation.weighted_borrowed_value_usd();
    let borrowed_upper = obligation.weighted_borrowed_value_upper_bound_usd();

    // Sound state:
    // - allowed_borrow_value < unhealthy_borrow_value
    // - borrowed_value <= borrowed_value_upper_bound
    cvlm_assert(allowed.le(unhealthy));
    cvlm_assert(borrowed.le(borrowed_upper));

    //  Require invariant in pre state
    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"");

    // Perform action
    invoke(target, obligation, &mut reserves[i], clock);

    refresh_health(obligation, reserves);

    // Assert invariant in post state
    cvlm_assert(liquidatable_implies_unhealthy(obligation));
}

/// Verifies that newly created obligations can only be forgiven if they are unhealthy or have no debt
public fun forgivable_only_if_unhealthy_or_debt_free_base(
    lending_market_id: ID,
    ctx: &mut TxContext,
) {
    let obligation = create_obligation(lending_market_id, ctx);
    cvlm_assert(forgivable_only_if_unhealthy_or_debt_free(&obligation));
    ghost_destroy(obligation);
}

/// Verifies that obligation operations maintain the property that
/// debt can only be forgiven on obligations that are either unhealthy or debt-free
public fun forgivable_only_if_unhealthy_or_debt_free_step(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
    target: Function,
) {
    /* Restrict model size */
    cvlm_assume_msg(reserves.length() <= 2, b"");
    cvlm_assume_msg(obligation.borrows().length() <= 1, b"");
    cvlm_assume_msg(obligation.deposits().length() <= 1, b"");

    // Pick a reserve
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"Existing reserve");
    cvlm_assume_msg(reserves[i].array_index() == i, b"array_index == position");

    // Assume fresh state
    refresh_health(obligation, reserves);
    let allowed = obligation.allowed_borrow_value_usd();
    let unhealthy = obligation.unhealthy_borrow_value_usd();
    let borrowed = obligation.weighted_borrowed_value_usd();
    let borrowed_upper = obligation.weighted_borrowed_value_upper_bound_usd();

    // Sound state:
    // - allowed_borrow_value < unhealthy_borrow_value
    // - borrowed_value <= borrowed_value_upper_bound
    cvlm_assert_msg(allowed.le(unhealthy), b"");
    cvlm_assert_msg(borrowed.le(borrowed_upper), b"");

    let mut i = 0;
    while (i < obligation.deposits().length()) {
        let deposited = obligation.deposits()[i].deposited_ctoken_amount();
        cvlm_assume_msg(deposited > 0, b"");
        i = i+1;
    };
    let mut i = 0;
    while (i < obligation.borrows().length()) {
        let borrowed = obligation.borrows()[i].borrowed_amount();
        cvlm_assume_msg(decimal::from(0).lt(borrowed), b"");
        i = i+1;
    };

    if (obligation.borrows().length() > 0) {
        cvlm_assume_msg(obligation.weighted_borrowed_value_usd().gt(decimal::from(0)), b"");
    };

    cvlm_assert_msg(liquidatable_implies_unhealthy(obligation), b"Require invariant");

    //  Require invariant in pre state
    cvlm_assume_msg(forgivable_only_if_unhealthy_or_debt_free(obligation), b"");

    invoke(target, obligation, &mut reserves[i], clock);

    // Assume fresh state again
    refresh_health(obligation, reserves);

    // Assert invariant in post state
    cvlm_assert(forgivable_only_if_unhealthy_or_debt_free(obligation));
}
