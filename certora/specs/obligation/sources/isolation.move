module obligation::isolation;

use commons::helper::refresh_isolation;
use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{rule, target, invoker};
use cvlm::nondet::{nondet_with};
use dummy_pool::dummy_pool::DummyPool;
use dummy_pool::obligation::{ create_obligation};
use sui::clock::Clock;
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

    rule(b"exactly_one_borrow_in_isolation_base");
    rule(b"exactly_one_borrow_in_isolation_step");


    rule(b"isolation_borrow_integrity");
}

native fun invoke(
    target: Function,
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    clock: &Clock,
);

fun exactly_one_borrow_in_isolation(obligation: &Obligation<DummyPool>): bool {
    let isolated = obligation.borrowing_isolated_asset();
    let borrows = obligation.borrows().length();
    !isolated || borrows == 1
}

public fun exactly_one_borrow_in_isolation_base(lending_market_id: ID, ctx: &mut TxContext) {
    let obligation = create_obligation(lending_market_id, ctx);

    cvlm_assert(exactly_one_borrow_in_isolation(&obligation));
    ghost_destroy(obligation);
}

public fun exactly_one_borrow_in_isolation_step(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
    target: Function,
) {
    refresh_isolation(obligation, reserves);

    cvlm_assume_msg(exactly_one_borrow_in_isolation(obligation), b"Assume in pre condition");

    let r_index = nondet_with!(b"Index in range", |r| r < reserves.length());
    let reserve = &mut reserves[r_index];
    cvlm_assume_msg(reserve.array_index() == r_index, b"Consistent index");
    invoke(target, obligation, reserve, clock);

    refresh_isolation(obligation, reserves);

    cvlm_assert(exactly_one_borrow_in_isolation(obligation));
}

public fun isolation_borrow_integrity(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
    target: Function,
) {
    refresh_isolation(obligation, reserves);
    let isolated_pre = obligation.borrowing_isolated_asset();
    let borrows_pre = obligation.borrows().length();

    cvlm_assume_msg(exactly_one_borrow_in_isolation(obligation), b"Assume in pre condition");

    let r_index = nondet_with!(b"Index in range", |r| r < reserves.length());
    let reserve = &mut reserves[r_index];
    cvlm_assume_msg(reserve.array_index() == r_index, b"Consistent index");
    invoke(target, obligation, reserve, clock);

    refresh_isolation(obligation, reserves);

    let isolated_post = obligation.borrowing_isolated_asset();
    let borrows_post = obligation.borrows().length();

    // If isolation pre and it remains isolates, it must remain isolated and the number of borrows must not changed
    cvlm_assert(!(isolated_pre && isolated_post) || (borrows_pre == borrows_post));

    // If isolated post but not pre, then borrows pre must've been 0 and borrows post must be 1
    cvlm_assert(!(!isolated_pre && isolated_post) || (borrows_pre == 0 && borrows_post == 1));

    // If isolated pre but not post, we exited from isolation
    cvlm_assert(!(isolated_pre && !isolated_post) || borrows_post == 0);

    // Ensure we don't skip from 0 to 2+ borrows when entering isolation
    cvlm_assert(!(isolated_post && !isolated_pre) || borrows_post <= 1);
}
