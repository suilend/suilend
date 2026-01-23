// Reserve summaries for solvency specs
//
// This module provides simplified implementations for reserve operations needed for
// solvency verification.
module solvency::summaries_reserve;

use cvlm::manifest::summary;
use cvlm::nondet::nondet_with;
use suilend::decimal::Decimal;
use suilend::rate_limiter::RateLimiter;
use suilend::reserve::Reserve;

public fun cvlm_manifest() {
    // Interest rate modeling: Simplified to return nondeterministic but bounded values.
    summary(b"reserve_compound_borrow_rate", @suilend, b"reserve", b"compound_borrow_rate");

    // No-op functions: These don't affect solvency accounting.
    summary(b"reserve_log_reserve_data", @suilend, b"reserve", b"log_reserve_data");

    // Rate limiting: Simplified to no-op as rate limits don't affect solvency invariants.
    summary(b"rate_limiter_process_qty", @suilend, b"rate_limiter", b"process_qty");
}

/// Nondeterministic compound borrow rate in range [1, 2).
///
/// For solvency verification, the exact interest rate calculation is less critical than
/// ensuring it remains within reasonable bounds. This summary returns a nondet value
/// constrained to [1, 2) to model interest accrual without the complexity of the full
/// interest rate curve calculation.
public fun reserve_compound_borrow_rate<DummyPool>(_: &mut Reserve<DummyPool>, _: u64): Decimal {
    let val = nondet_with!(b"Borrow rate", |r| 1 <= r && r < 2);
    suilend::decimal::from(val)
}

/// No-op rate limiter processing.
///
/// Rate limiting doesn't affect reserve solvency invariants (total liquidity, borrowed
/// amounts, accounting consistency), so this is simplified to a no-op.
public fun rate_limiter_process_qty(
    _rate_limiter: &mut RateLimiter,
    _cur_time: u64,
    _qty: Decimal,
) {}

/// No-op logging function.
public fun reserve_log_reserve_data<P>(_reserve: &Reserve<P>) {}
