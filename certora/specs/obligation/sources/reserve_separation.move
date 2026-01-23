/// property: Reserve Separation
/// description: Verifies that obligations cannot simultaneously have both a borrow and a deposit from the same reserve
module obligation::reserve_separation;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{rule, target, invoker};
use dummy_pool::dummy_pool::DummyPool;
use dummy_pool::obligation::create_obligation;
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

    rule(b"no_borrow_and_deposit_from_same_reserve_base");
    rule(b"no_borrow_and_deposit_from_same_reserve_step");
}

native fun invoke(
    target: Function,
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    clock: &Clock,
);

public fun no_borrow_and_deposit_from_same_reserve(
    obligation: &Obligation<DummyPool>,
    reserve: &Reserve<DummyPool>,
): bool {
    let borrow_index = obligation.find_borrow_index(reserve);
    let deposit_index = obligation.find_deposit_index(reserve);

    (borrow_index == obligation.borrows().length()) || (deposit_index == obligation.deposits().length())
}

/// Verifies that newly created obligations have no simultaneous borrows and deposits from the same reserve
public fun no_borrow_and_deposit_from_same_reserve_base(
    lending_market_id: ID,
    reserve: &Reserve<DummyPool>,
    ctx: &mut TxContext,
) {
    let obligation = create_obligation(lending_market_id, ctx);
    cvlm_assert(no_borrow_and_deposit_from_same_reserve(&obligation, reserve));
    ghost_destroy(obligation);
}

/// Verifies that obligation operations maintain reserve separation.
/// An obligation cannot have both a borrow position and a deposit position for the same reserve
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
