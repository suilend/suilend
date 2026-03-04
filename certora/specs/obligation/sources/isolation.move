/// property: Obligation Isolation Mode
/// description: Verifies isolation mode constraints: obligations borrowing isolated assets can only have one borrow,
/// and deposits of isolated assets provide zero borrowing power
module obligation::isolation;

use commons::helper::{refresh_isolation, zero, refresh_health};
use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{rule, target, invoker};
use cvlm::nondet::nondet_with;
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

    rule(b"exactly_one_borrow_in_isolation_base");
    rule(b"exactly_one_borrow_in_isolation_step");

    rule(b"isolation_borrow_integrity");

    rule(b"isolated_deposit_has_zero_borrowing_power");
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

/// Verifies that newly created obligations satisfy the isolation constraint
/// (if borrowing isolated assets, must have exactly one borrow)
public fun exactly_one_borrow_in_isolation_base(lending_market_id: ID, ctx: &mut TxContext) {
    let obligation = create_obligation(lending_market_id, ctx);

    cvlm_assert(exactly_one_borrow_in_isolation(&obligation));
    ghost_destroy(obligation);
}

fun pick_reserve<P>(reserves: &mut vector<Reserve<P>>): (u64, &mut Reserve<P>) {
    let r_index = nondet_with!(b"Index in range", |r| r < reserves.length());
    let reserve = &mut reserves[r_index];
    cvlm_assume_msg(reserve.array_index() == r_index, b"Consistent index");
    (r_index, reserve)
}

/// Verifies that operations on obligations maintain the isolation constraint.
/// Obligations borrowing isolated assets must have exactly one borrow position
public fun exactly_one_borrow_in_isolation_step(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
    target: Function,
) {
    refresh_isolation(obligation, reserves);

    cvlm_assume_msg(exactly_one_borrow_in_isolation(obligation), b"Assume in pre condition");

    let (_, reserve) = pick_reserve(reserves);
    invoke(target, obligation, reserve, clock);

    refresh_isolation(obligation, reserves);

    cvlm_assert(exactly_one_borrow_in_isolation(obligation));
}

/// Verifies the integrity of isolation mode transitions:
/// - Remaining in isolation maintains borrow count
/// - Exiting isolation requires clearing all borrows
/// - Cannot skip directly to multiple borrows when entering isolation
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

    let (_, reserve) = pick_reserve(reserves);
    invoke(target, obligation, reserve, clock);

    refresh_isolation(obligation, reserves);

    let isolated_post = obligation.borrowing_isolated_asset();
    let borrows_post = obligation.borrows().length();

    // If isolation pre and it remains isolates, it must remain isolated and the number of borrows must not changed
    cvlm_assert(!(isolated_pre && isolated_post) || (borrows_pre == borrows_post));


    // If isolated pre but not post, we exited from isolation
    cvlm_assert(!(isolated_pre && !isolated_post) || borrows_post == 0);

    // Ensure we don't skip from 0 to 2+ borrows when entering isolation
    cvlm_assert(!(isolated_post && !isolated_pre) || borrows_post <= 1);
}

/// Verifies that depositing isolated assets provides zero borrowing power.
/// Isolated assets have zero LTV, so deposits should not increase allowed or unhealthy borrow values
public fun isolated_deposit_has_zero_borrowing_power(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
    target: Function,
) {
    refresh_health(obligation, reserves);

    let allowed_borrow_pre = obligation.allowed_borrow_value_usd();
    let unhealthy_borrow_pre = obligation.unhealthy_borrow_value_usd();
    let (r_index, reserve) = pick_reserve(reserves);

    // Assume the reserve is isolated
    // This implies open_ltv = close_ltv = 0 (per reserve_config::validate_reserve_config)
    cvlm_assume_msg(reserve.config().isolated(), b"Reserve is isolated");
    cvlm_assume_msg(reserve.config().open_ltv().eq(zero()), b"open_ltv is 0");
    cvlm_assume_msg(reserve.config().close_ltv().eq(zero()), b"close_ltv is 0");

    let index = obligation.find_deposit_index(reserve);
    let tokens_pre = if (index == obligation.deposits().length()) {
        0
    } else {
        obligation.deposits()[index].deposited_ctoken_amount()
    };

    invoke(target, obligation, reserve, clock);

    refresh_health(obligation, reserves);

    let index = obligation.find_deposit_index(&reserves[r_index]);
    cvlm_assume_msg(
        index < obligation.deposits().length(),
        b"Assume there is a deposit for this reserve",
    );
    let tokens_post = obligation.deposits()[index].deposited_ctoken_amount();

    cvlm_assume_msg(tokens_post > tokens_pre, b"Assume we deposited");

    let allowed_borrow_post = obligation.allowed_borrow_value_usd();
    let unhealthy_borrow_post = obligation.unhealthy_borrow_value_usd();

    // Isolated assets have 0 LTV, so depositing them should not increase borrowing power
    cvlm_assert(allowed_borrow_pre.eq(allowed_borrow_post));
    cvlm_assert(unhealthy_borrow_pre.eq(unhealthy_borrow_post));
}
