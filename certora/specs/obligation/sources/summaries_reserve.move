// Reserve summaries
module obligation::summaries_reserve;

use cvlm::manifest::summary;
use cvlm::nondet::nondet_with;
use suilend::decimal::Decimal;
use suilend::reserve::Reserve;

public fun cvlm_manifest() {
    // Interest rate modeling: Simplified to return nondeterministic but bounded values.
    summary(b"reserve_compound_borrow_rate", @suilend, b"reserve", b"compound_borrow_rate");

    // Market value functions: Simplified to 1:1 conversion (price = 1) for efficiency.
    // This abstracts away oracle price lookups and decimal conversions, which are not needed for proving state invariants of obligations
    summary(b"reserve_market_value", @suilend, b"reserve", b"market_value");
    summary(b"reserve_market_value_upper_bound", @suilend, b"reserve", b"market_value_upper_bound");
    summary(b"reserve_market_value_lower_bound", @suilend, b"reserve", b"market_value_lower_bound");

    // No-op logging function.
    summary(b"reserve_log_reserve_data", @suilend, b"reserve", b"log_reserve_data");
}

/// Nondeterministic compound borrow rate in range [1, 2).
///
/// For verification, the exact interest rate calculation is less critical than ensuring
/// it remains within reasonable bounds. This summary returns a nondet value constrained
/// to [1, 2) to model interest accrual without the complexity of the full interest rate
/// curve calculation.
public fun reserve_compound_borrow_rate<DummyPool>(_: &mut Reserve<DummyPool>, _: u64): Decimal {
    let val = nondet_with!(b"Borrow rate", |r| 1 <= r && r < 2);
    suilend::decimal::from(val)
}

/// Simplified market value calculation.
///
/// Returns the liquidity amount directly, effectively treating the price as 1:1.
/// This abstracts away price lookups and decimal conversions for efficiency.
public fun reserve_market_value<P>(_reserve: &Reserve<P>, liquidity_amount: Decimal): Decimal {
    liquidity_amount
}

/// Simplified market value upper bound calculation.
///
/// Returns the liquidity amount directly. In the real implementation, this would
/// use the upper bound of the price range from the oracle.
public fun reserve_market_value_upper_bound<P>(
    _reserve: &Reserve<P>,
    liquidity_amount: Decimal,
): Decimal {
    liquidity_amount
}

/// Simplified market value lower bound calculation.
///
/// Returns the liquidity amount directly. In the real implementation, this would
/// use the lower bound of the price range from the oracle.
public fun reserve_market_value_lower_bound<P>(
    _reserve: &Reserve<P>,
    liquidity_amount: Decimal,
): Decimal {
    liquidity_amount
}

/// No-op logging function.
public fun reserve_log_reserve_data<P>(_reserve: &Reserve<P>) {}
