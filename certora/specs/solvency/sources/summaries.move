module solvency::summaries;


use cvlm::manifest::summary;
use sui::clock::Clock;
use suilend::reserve::Reserve;
use suilend::obligation::Obligation;
use suilend::decimal::{Decimal};
use cvlm::nondet::nondet;
use cvlm::nondet::nondet_with;
use suilend::rate_limiter::RateLimiter;
use cvlm::ghost::ghost_destroy;
use suilend::staker::Staker;
use sui::balance::Balance;
use sui::sui::SUI;
use sui_system::sui_system::SuiSystemState;

public fun cvlm_manifest() {

    // Obligation Summaries
    summary(b"obligation_repay", @suilend, b"obligation", b"repay");
    summary(b"obligation_find_borrow_index", @suilend, b"obligation", b"find_borrow_index");
    summary(b"obligation_refresh", @suilend, b"obligation", b"refresh");
    summary(b"obligation_borrow", @suilend, b"obligation", b"borrow");
    summary(b"obligation_deposit", @suilend, b"obligation", b"deposit");
    summary(b"obligation_liquidate", @suilend, b"obligation", b"liquidate");
    summary(
        b"obligation_zero_out_rewards_if_looped",
        @suilend,
        b"obligation",
        b"zero_out_rewards_if_looped",
    );
    // Reserve Summaries
    summary(b"reserve_compound_borrow_rate", @suilend, b"reserve", b"compound_borrow_rate");
    // Rate Limiter
    summary(b"rate_limiter_process_qty", @suilend, b"rate_limiter", b"process_qty");
    // Staker
    summary(b"staker_deposit", @suilend, b"staker", b"deposit");
    summary(b"staker_rebalance", @suilend, b"staker", b"rebalance");
    summary(b"staker_withdraw", @suilend, b"staker", b"withdraw");
}


public fun obligation_find_borrow_index<P>(_: &Obligation<P>, _: &Reserve<P>): u64 {
    return nondet()
}

public fun obligation_repay<DummyPool>(
    _: &mut Obligation<DummyPool>,
    _: &mut Reserve<DummyPool>,
    _: &Clock,
    _: Decimal,
): Decimal {
    // let borrow_index = nondet();// find_borrow_index<DummyPool>(obligation, reserve);
    // let borrow = vector::borrow( obligation.borrows(), borrow_index);
    // return min(max_repay_amount, borrow.borrowed_amount())
    return nondet()
}

public fun obligation_refresh<DummyPool>(
    _: &mut Obligation<DummyPool>,
    _: &mut vector<Reserve<DummyPool>>,
    _: &Clock,
): Option<suilend::obligation::ExistStaleOracles> {
    return nondet()
}

public(package) fun obligation_deposit<P>(
    _obligation: &mut Obligation<P>,
    _reserve: &mut Reserve<P>,
    _clock: &Clock,
    _ctoken_amount: u64,
) {} //no-op

public(package) fun obligation_borrow<P>(
    _obligation: &mut Obligation<P>,
    _reserve: &mut Reserve<P>,
    _clock: &Clock,
    _amount: u64,
) {} // no-op

public(package) fun obligation_liquidate<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _repay_reserve_array_index: u64,
    _withdraw_reserve_array_index: u64,
    _clock: &Clock,
    _repay_amount: u64,
): (u64, Decimal) {
    (nondet(), nondet())
}

public(package) fun obligation_zero_out_rewards_if_looped<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
) {} //noop

public fun reserve_compound_borrow_rate<DummyPool>(_: &mut Reserve<DummyPool>, _: u64): Decimal {
    let val = nondet_with!(b"Borrow rate", |r| 1 <= r && r < 2);
    suilend::decimal::from(val)
}

public fun rate_limiter_process_qty(
    _rate_limiter: &mut RateLimiter,
    _cur_time: u64,
    _qty: Decimal,
) {} // noop

public(package) fun staker_deposit<P>(_staker: &mut Staker<P>, sui: Balance<SUI>) {
    ghost_destroy(sui);
} // noop
public(package) fun staker_rebalance<P: drop>(_staker: &mut Staker<P>, _system_state: &mut SuiSystemState, _ctx: &mut TxContext) {} // noop
public(package) fun staker_withdraw<P: drop>(_staker: &mut Staker<P>, _withdraw_amount: u64, _system_state: &mut SuiSystemState, _ctx: &mut TxContext): Balance<SUI> {
    nondet()
}
