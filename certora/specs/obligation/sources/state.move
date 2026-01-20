module obligation::state;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{rule, target, invoker};
use cvlm::nondet::nondet;
use dummy_pool::dummy_pool::DummyPool;
use dummy_pool::obligation::{ create_obligation};
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
    
    rule(b"no_borrow_and_deposit_from_same_reserve_base");
    rule(b"no_borrow_and_deposit_from_same_reserve_step");
}

native fun invoke(
    target: Function,
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    clock: &Clock,
);

/* INVARIANT: liquidatable implies unhealthy */

/// In other words, only unhealthy obligations may be liquidated.
public fun liquidatable_implies_unhealthy(obligation: &Obligation<DummyPool>): bool {
    let healthy = obligation.is_healthy();
    let liquidatable = obligation.is_liquidatable();
    // liquidatable -> unhealthy  <==> !liquidatable || unhealthy
    return !liquidatable || !healthy
}

public fun liquidatable_implies_unhealthy_base(lending_market_id: ID, ctx: &mut TxContext) {
    let obligation = create_obligation(lending_market_id, ctx);
    cvlm_assert(liquidatable_implies_unhealthy(&obligation));
    ghost_destroy(obligation);
}

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

    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();
    let allowed = obligation.allowed_borrow_value_usd();
    let unhealthy = obligation.unhealthy_borrow_value_usd();
    let borrowed = obligation.weighted_borrowed_value_usd();
    let borrowed_upper = obligation.weighted_borrowed_value_upper_bound_usd();

    // Sound state:
    // - allowed_borrow_value < unhealthy_borrow_value
    // - borrowed_value <= borrowed_value_upper_bound
    cvlm_assume_msg(allowed.lt(unhealthy), b"");
    cvlm_assume_msg(borrowed.le(borrowed_upper), b"");

    //  Require invariant in pre state
    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"");

    // Pick a reserve
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");

    // Perform action
    invoke(target, obligation, reserve, clock);

    // Make sure obligation is fresh
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state
    cvlm_assert_msg(liquidatable_implies_unhealthy(obligation), b"");
}

/* INVARIANT: Forgivable implies unhealthy or debt free */

/// If an obligation is liquidatable, then is also unhealthy.
/// In other words, only unhealthy obligations may be liquidated.

public fun forgivable_only_if_unhealthy_or_debt_free(obligation: &Obligation<DummyPool>): bool {
    let healthy = obligation.is_healthy();
    let forgivable = obligation.is_forgivable();
    let no_debt = obligation.borrows().length() == 0;
    // forgivable => unhealthy | no borrows
    return !forgivable || !healthy || no_debt
}

public fun forgivable_only_if_unhealthy_or_debt_free_base(
    lending_market_id: ID,
    ctx: &mut TxContext,
) {
    let obligation = create_obligation(lending_market_id, ctx);
    cvlm_assert(forgivable_only_if_unhealthy_or_debt_free(&obligation));
    ghost_destroy(obligation);
}

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

    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();
    let allowed = obligation.allowed_borrow_value_usd();
    let unhealthy = obligation.unhealthy_borrow_value_usd();
    let borrowed = obligation.weighted_borrowed_value_usd();
    let borrowed_upper = obligation.weighted_borrowed_value_upper_bound_usd();

    // Sound state:
    // - allowed_borrow_value < unhealthy_borrow_value
    // - borrowed_value <= borrowed_value_upper_bound
    cvlm_assume_msg(allowed.lt(unhealthy), b"");
    cvlm_assume_msg(borrowed.le(borrowed_upper), b"");

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

    // Perform action
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");

    invoke(target, obligation, reserve, clock);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state
    cvlm_assert_msg(forgivable_only_if_unhealthy_or_debt_free(obligation), b"");
}

public fun no_borrow_and_deposit_from_same_reserve(
    obligation: &Obligation<DummyPool>,
    reserve: &Reserve<DummyPool>,
): bool {
    let borrow_index = obligation.find_borrow_index(reserve);
    let deposit_index = obligation.find_deposit_index(reserve);

    (borrow_index == obligation.borrows().length()) || (deposit_index == obligation.deposits().length())
}

public fun no_borrow_and_deposit_from_same_reserve_base(
    lending_market_id: ID,
    reserve: &Reserve<DummyPool>,
    ctx: &mut TxContext,
) {
    let obligation = create_obligation(lending_market_id, ctx);
    cvlm_assert(no_borrow_and_deposit_from_same_reserve(&obligation, reserve));
    ghost_destroy(obligation);
}


public fun no_borrow_and_deposit_from_same_reserve_step(
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    clock: &Clock,
    target: Function,
) {
    cvlm_assume_msg(no_borrow_and_deposit_from_same_reserve(obligation, reserve), b"");

    invoke(target, obligation, reserve, clock);

    cvlm_assert_msg(no_borrow_and_deposit_from_same_reserve(obligation, reserve), b"");
    
        
}
