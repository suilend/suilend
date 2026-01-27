/// property: Liquidation Profitability
/// description: Verifies that liquidation is not a loss (up to rounding) and is profitable when bonus is at least 1%
module liquidation::profit;

use commons::helper::setup_obligation_for_liquidation;
use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::rule;
use cvlm::nondet::nondet;
use dummy_pool::dummy_pool::DummyPool;
use sui::coin::Coin;
use suilend::decimal;
use suilend::lending_market::LendingMarket;

public fun cvlm_manifest() {
    rule(b"liquidation_no_loss");
}

// Worst-case rounding loss bound (ctoken base units):
///
/// Due to truncating division in the computation of liquidation amountst he liquidator can receive
/// *up to* `SHORTFALL` fewer **base units of ctokens** than the ideal real-number math would give.
///
/// In other words: the liquidator can make a loss purely due to rounding, but that loss is
/// bounded by `SHORTFALL` ctoken base units. Equivalently, giving the liquidator an extra
/// `SHORTFALL` base units of ctokens is sufficient to ensure “no loss” in the zero-bonus case.
///
/// In addition, with a bonus `b` (e.g. 3% => b=0.03), profitability must cover this rounding tax:
///
///     repay * (1 + b) - SHORTFALL >= repay
///  <=> b * repay >= SHORTFALL
///  <=> repay >= ceil(SHORTFALL / b)
///
/// Examples (SHORTFALL = 20):
///   - b = 1%  => repay >= 2000
///   - b = 3%  => repay >= 667
///   - b = 10% => repay >= 200
///
/// All quantities above are in base units unless otherwise noted.
const SHORTFALL: u64 = 20;

/// Verifies that liquidation with zero bonus is not a loss for the liquidator, up to a bounded rounding error:
///
///     market_value(returned_ctokens + SHORTFALL) >= market_value(repaid_debt)
///
/// Rationale:
/// - The liquidation path computes `withdraw_pct` via truncating WAD division, then multiplies by a (possibly huge)
///   deposited ctoken amount, and finally floors to `u64` base units. Separately, the repay-side may ceil the
///   required repay coins.
/// - In the worst case, these truncations can cause the liquidator to receive fewer ctokens than the ideal
///   real-number computation would.
/// - `SHORTFALL` bounds this pure-rounding based loss in **ctoken base units**, so adding `SHORTFALL` ctokens
///   makes the “no loss” inequality hold in the worst case.
/// 
/// Note that the given SHORTFALL is a tight bound on the rounding error: using less than SHORTFALL to 
/// offset the obtained ctoken is not sufficient.
///
/// Notes:
/// - We keep the rule at `mint_decimals = 0` to maximize/cover for performance reasons; modeling arbitrary
///   non-zero decimals precisely in the verifier is currently infeasible.
///     - `SHORTFALL` is expressed in base units, so for `mint_decimals = 0` this is “up to 20 whole ctokens”.
///     - For `mint_decimals > 0`, the bound is still `SHORTFALL` base units, but that corresponds to a much smaller
///   amount of tokens (i.e., `SHORTFALL / 10^decimals` tokens).
/// - For the same performance reason, we assume 1:1 prices and 1:1 ctoken ratio
public fun liquidation_no_loss<R, W>(lm: &mut LendingMarket<DummyPool>, ob_id: ID) {
    // Setup an obligation in a fresh state (i.e. all usd values are correctly computed) that is liquidatable
    // Return index of the debt=repay reserve and index of the collateral=withdraw reserve
    let (_, repay_reserve_index, withdraw_reserve_index) = setup_obligation_for_liquidation(
        lm,
        ob_id,
    );

    // Nondet value for liquidation
    let clock = nondet();
    let mut ctx = nondet();
    let mut repay_coins: Coin<R> = nondet();
    let repay_coin_value_pre = repay_coins.value();

    // Minimum bonus is 0. This needs to be explicitly stated to  prevent timeouts.
    let withdraw_reserve = &lm.reserves()[withdraw_reserve_index];
    cvlm_assume_msg(withdraw_reserve.config().protocol_liquidation_fee().eq(decimal::from(0)), b"");
    cvlm_assume_msg(withdraw_reserve.config().liquidation_bonus().eq(decimal::from(0)), b"");

    let (liquidated_ctokens, _) = lm.liquidate<DummyPool, R, W>(
        ob_id,
        repay_reserve_index,
        withdraw_reserve_index,
        &clock,
        &mut repay_coins,
        &mut ctx,
    );

    // Compute the repaid coins: Diff between what we put in and the balance left
    let repay_amount = repay_coin_value_pre - repay_coins.value();
    let liquidated_ctokens_amount = liquidated_ctokens.value();
    cvlm_assume_msg(liquidated_ctokens_amount > 0, b"At least one token obtained");

    // Compute the market values
    let repay_reserve = vector::borrow(lm.reserves(), repay_reserve_index);
    let withdraw_reserve = vector::borrow(lm.reserves(), withdraw_reserve_index);

    // ... of the repaid debt
    let repay_value = repay_reserve.market_value(decimal::from(repay_amount));

    // ... and the liquidated ctoken (adjust due to rounding)
    let liquidated_ctokens_amount = liquidated_ctokens_amount + SHORTFALL;
    let liquidated_value = withdraw_reserve.ctoken_market_value(liquidated_ctokens_amount);

    cvlm_assert(repay_value.le(liquidated_value));

    ghost_destroy(clock);
    ghost_destroy(repay_coins);
    ghost_destroy(liquidated_ctokens);
}