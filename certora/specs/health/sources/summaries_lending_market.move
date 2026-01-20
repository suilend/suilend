// Lending market summaries for obligation health specs
//
// This module provides simplified implementations for lending market operations.
// Rate limiting and borrow amount calculations are abstracted as they don't affect
// the core obligation health verification (which depends on actual borrowed amounts,
// not the maximum allowed borrow amounts).
module health::summaries_lending_market;

use cvlm::manifest::summary;
use cvlm::nondet::{nondet};
use sui::clock::Clock;
use suilend::decimal::{Decimal};
use suilend::obligation::Obligation;
use suilend::rate_limiter::RateLimiter;
use suilend::reserve::{Reserve};

public fun cvlm_manifest() {
    // Rate limiter: Ignored for obligation health verification as rate limiting doesn't affect
    // health calculations.
    summary(b"rate_limiter_process_qty", @suilend, b"rate_limiter", b"process_qty");

    // Max borrow amount: Returns nondeterministic value. The actual amount borrowed is what matters
    // for health, not the maximum allowed amount.
    summary(b"max_borrow_amount", @suilend, b"lending_market", b"max_borrow_amount");
}

/// No-op rate limiter processing.
/// Rate limiting doesn't affect obligation health calculations.
public fun rate_limiter_process_qty(
    _rate_limiter: &mut RateLimiter,
    _cur_time: u64,
    _qty: Decimal,
) {}

/// Returns a nondeterministic maximum borrow amount.
/// For health verification, we only care about actual borrowed amounts, not limits.
public fun max_borrow_amount<P>(
    mut _rate_limiter: RateLimiter,
    _obligation: &Obligation<P>,
    _reserve: &Reserve<P>,
    _clock: &Clock,
): u64 {
    nondet()
}

