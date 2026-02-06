// Reserve summaries for obligation health specs
//
// This module provides simplified or no-op implementations for reserve operations.
// Almost all reserve functions are set to nondet()/no-ops because they are irrelevant
// for obligation health verification. The health checks only depend on market values,
// LTV ratios, and borrow weights, not on the internal reserve state management.
//
// IMPORTANT: The ctoken_ratio is summarized to a constant 1:1 ratio to make verification
// feasible (verification times out otherwise). However, this is an oversimplification since
// health depends on the ctoken ratio through the market value of deposits, meaning this
// assumption may mask real violations where health changes are caused by ctoken ratio changes.
module health::summaries_reserve;

use commons::helper::one;
use cvlm::asserts::cvlm_assume_msg;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::summary;
use cvlm::nondet::{nondet_with, nondet};
use dummy_pool::dummy_pool::DummyPool;
use sui::balance::Balance;
use sui::clock::Clock;
use sui::coin::TreasuryCap;
use sui_system::sui_system::SuiSystemState;
use suilend::decimal::{Self, Decimal};
use suilend::reserve::{Reserve, LiquidityRequest, CToken};
use suilend::reserve_config::ReserveConfig;

public fun cvlm_manifest() {
    // Reserve state management: These operations are irrelevant for obligation health verification
    // as they only affect internal reserve accounting (liquidity, fees, staking, etc.) and not
    // the market values or LTV ratios that determine obligation health.
    summary(b"compound_interest", @suilend, b"reserve", b"compound_interest");
    summary(b"borrow_liquidity", @suilend, b"reserve", b"borrow_liquidity");
    summary(b"unstake_sui_from_staker", @suilend, b"reserve", b"unstake_sui_from_staker");
    summary(b"rebalance_staker", @suilend, b"reserve", b"rebalance_staker");
    summary(b"repay_liquidity", @suilend, b"reserve", b"repay_liquidity");
    summary(b"deposit_ctokens", @suilend, b"reserve", b"deposit_ctokens");
    summary(b"init_staker", @suilend, b"reserve", b"init_staker");
    summary(b"log_reserve_data", @suilend, b"reserve", b"log_reserve_data");
    summary(b"assert_price_is_fresh", @suilend, b"reserve", b"assert_price_is_fresh");
    summary(b"withdraw_ctokens", @suilend, b"reserve", b"withdraw_ctokens");
    summary(b"deduct_liquidation_fee", @suilend, b"reserve", b"deduct_liquidation_fee");
    summary(b"join_fees", @suilend, b"reserve", b"join_fees");

    // Pricing / Market Value: NOT summarized - these are critical for health calculations.
    // Fixing price = 1 would simplify verification but would mask real violations.
    // https://prover.certora.com/output/8195906/847f354fbfc14a81b6af1e81d8889e97?anonymousKey=5731c150853bb7d2a3f766372ede4bfe392d9a63
    // summary(b"market_value", @suilend, b"reserve", b"market_value");
    // summary(b"market_value_upper_bound", @suilend, b"reserve", b"market_value_upper_bound");
    // summary(b"market_value_lower_bound", @suilend, b"reserve", b"market_value_lower_bound");

    // Simplified constants: These return fixed values for simplification.
    summary(b"mint_decimals", @suilend, b"reserve", b"mint_decimals");
    summary(b"borrow_weight", @suilend, b"reserve_config", b"borrow_weight");

    // CToken market value functions: Simplified implementations based on basic market value.
    summary(b"ctoken_market_value", @suilend, b"reserve", b"ctoken_market_value");
    summary(
        b"ctoken_market_value_lower_bound",
        @suilend,
        b"reserve",
        b"ctoken_market_value_lower_bound",
    );
    summary(
        b"ctoken_market_value_upper_bound",
        @suilend,
        b"reserve",
        b"ctoken_market_value_upper_bound",
    );
}

/// Fixed mint decimals for simplification. Returns 18 for all reserves.
public fun mint_decimals<P>(_reserve: &Reserve<P>): u8 {
    18
}

/// Fixed borrow weight for simplification. Returns 1.0 (100%).
public fun borrow_weight(_config: &ReserveConfig): Decimal {
    decimal::from_bps(10000)
}

/// Nondeterministic compound borrow rate in range [1, 2).
/// Not directly relevant for obligation health, but may be used in debt compounding.
public fun compound_borrow_rate(_: &mut Reserve<DummyPool>, _: u64): Decimal {
    let val = nondet_with!(b"Borrow rate", |r| 1 <= r && r < 2);
    suilend::decimal::from(val)
}

/// No-op compound interest. Actual interest compounding is irrelevant for health verification.
public fun compound_interest<P>(_: &mut Reserve<P>, _: &Clock) {}

/// Nondeterministic borrow liquidity request.
/// Returns a liquidity request where the total amount equals the requested amount plus fees.
public fun borrow_liquidity<P, T>(_reserve: &mut Reserve<P>, _amount: u64): LiquidityRequest<P, T> {
    let lq: LiquidityRequest<P, T> = nondet();

    let amount: u64 = lq.liquidity_request_amount();
    let fees: u64 = lq.liquidity_request_fee();
    cvlm_assume_msg(amount == _amount + fees, b"");
    lq
}

/// No-op SUI unstaking. Staking operations don't affect obligation health.
public fun unstake_sui_from_staker<P, T>(
    _reserve: &mut Reserve<P>,
    _liquidity_request: &LiquidityRequest<P, T>,
    _system_state: &mut SuiSystemState,
    _ctx: &mut TxContext,
) {}

/// No-op staker rebalancing. Staking operations don't affect obligation health.
public fun rebalance_staker<P>(
    _reserve: &mut Reserve<P>,
    _system_state: &mut SuiSystemState,
    _ctx: &mut TxContext,
) {}

/// Destroys deposited ctokens. The actual reserve state management is irrelevant for health.
public fun deposit_ctokens<P, T>(_reserve: &mut Reserve<P>, ctokens: Balance<CToken<P, T>>) {
    ghost_destroy(ctokens);
}

public fun deduct_liquidation_fee<P, T>(
    _reserve: &mut Reserve<P>,
    ctokens: &mut Balance<CToken<P, T>>,
    _bonus: Decimal
): (u64, u64) {
    let fees: u64 = nondet();
    let bonus: u64 = nondet();
    let total = fees + bonus;
    cvlm_assume_msg(total < ctokens.value(), b"Fees don't exceed coin value");
    let r = ctokens.split(fees);
    ghost_destroy(r);

    (fees, bonus)
}

/// Destroys staker treasury cap. Staker initialization doesn't affect obligation health.
public fun init_staker<P, S: drop>(
    _reserve: &mut Reserve<P>,
    treasury_cap: TreasuryCap<S>,
    _ctx: &mut TxContext,
) {
    ghost_destroy(treasury_cap)
}

/// No-op logging function.
public fun log_reserve_data<P>(_reserve: &Reserve<P>) {}

/// Destroys repaid liquidity after verifying the amount matches the settle amount.
public fun repay_liquidity<P, T>(
    _reserve: &mut Reserve<P>,
    liquidity: Balance<T>,
    settle_amount: Decimal,
) {
    cvlm_assume_msg(liquidity.value() == settle_amount.ceil(), b"");
    ghost_destroy(liquidity);
}

public fun join_fees<P, T>(_reserve: &mut Reserve<P>, fees: Balance<T>) {
    ghost_destroy(fees)
}

/// Market value calculation - CURRENTLY UNUSED (not summarized in manifest).
/// The actual reserve implementation is used instead for more precise health verification.
/// If summarized, this would convert liquidity amount to USD by dividing by 10^decimals.
public fun market_value<P>(reserve: &Reserve<P>, liquidity_amount: Decimal): Decimal {
    liquidity_amount.div(decimal::from(std::u64::pow(10, reserve.mint_decimals())))
}

/// Market value upper bound - CURRENTLY UNUSED (not summarized in manifest).
/// The actual reserve implementation is used instead for more precise health verification.
public fun market_value_upper_bound<P>(reserve: &Reserve<P>, liquidity_amount: Decimal): Decimal {
    liquidity_amount.div(decimal::from(std::u64::pow(10, reserve.mint_decimals())))
}

/// Market value lower bound - CURRENTLY UNUSED (not summarized in manifest).
/// The actual reserve implementation is used instead for more precise health verification.
public fun market_value_lower_bound<P>(reserve: &Reserve<P>, liquidity_amount: Decimal): Decimal {
    liquidity_amount.div(decimal::from(std::u64::pow(10, reserve.mint_decimals())))
}

/// Assuming a 1:1 ctoken ratio.
/// This especially means that we assume no operation changes the rate of deposited assets to ctokens.
///
/// IMPORTANT: This is an oversimplification! Since health depends on the ctoken ratio (through the
/// market value of deposits), assuming it remains constant at 1:1 during execution means we cannot
/// detect violations where health changes are caused by ctoken ratio changes. The ctoken ratio affects
/// the actual value of collateral, so this assumption may mask real issues in health calculations.
public fun ctoken_ratio<P>(_reserve: &Reserve<P>): Decimal {
    one()
}

/// CToken market value calculation assuming a 1:1 ctoken ratio.
/// Converts ctoken amount to market value using the reserve's market value function.
public fun ctoken_market_value<P>(reserve: &Reserve<P>, ctoken_amount: u64): Decimal {
    let liquidity_amount = decimal::from(ctoken_amount);
    reserve.market_value(liquidity_amount)
}

/// CToken market value lower bound calculation assuming a 1:1 ctoken ratio.
/// For simplification, uses the same logic as ctoken_market_value.
public fun ctoken_market_value_lower_bound<P>(reserve: &Reserve<P>, ctoken_amount: u64): Decimal {
    let liquidity_amount = decimal::from(ctoken_amount);
    reserve.market_value(liquidity_amount)
}

/// CToken market value upper bound calculation assuming a 1:1 ctoken ratio.
/// For simplification, uses the same logic as ctoken_market_value.
public fun ctoken_market_value_upper_bound<P>(reserve: &Reserve<P>, ctoken_amount: u64): Decimal {
    let liquidity_amount = decimal::from(ctoken_amount);
    reserve.market_value(liquidity_amount)
}

/// No-op price freshness check. Oracle staleness is not verified in obligation health specs.
public fun assert_price_is_fresh<P>(_reserve: &Reserve<P>, _clock: &Clock) {}

/// Returns nondeterministic ctokens when withdrawing from reserve.
/// The actual reserve ctoken balance management is irrelevant for obligation health verification.
public fun withdraw_ctokens<P, T>(_reserve: &mut Reserve<P>, _amount: u64): Balance<CToken<P, T>> {
    nondet()
}
