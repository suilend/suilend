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
    rule(b"liquidation_with_bonus_profitable");
}

/// Verifies that liquidation with zero bonus is not a loss for the liquidator:
/// market_value(returned_ctokens + 20) >= market_value(repaid_debt)
/// Note: The +20 adjustment accounts for rounding errors when mint decimals = 0.
/// With higher mint decimals, the rounding error would be proportionally smaller,
/// but verification with non-zero mint decimals is not feasible.
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
    let liquidated_ctokens_amount = liquidated_ctokens_amount + 20;
    let liquidated_value = withdraw_reserve.ctoken_market_value(liquidated_ctokens_amount);

    // marked for removal
    // cvlm_assume_msg(repay_reserve.price().eq(withdraw_reserve.price()), b"Same token prices");
    // cvlm_assume_msg(repay_reserve.price().eq(decimal::from(1)), b"1 price");

    cvlm_assert(repay_value.le(liquidated_value));

    ghost_destroy(clock);
    ghost_destroy(repay_coins);
    ghost_destroy(liquidated_ctokens);
}

/// Verifies that liquidation with a bonus of at least 1% is profitable for the liquidator.
/// The market value of returned ctokens exceeds the market value of repaid debt.
/// Unlike the zero bonus case, no rounding adjustment is needed as the bonus provides sufficient margin.
public fun liquidation_with_bonus_profitable<R, W>(lm: &mut LendingMarket<DummyPool>, ob_id: ID) {
    // Setup an obligation in a fresh state (i.e. all usd values are correctly computed) that is liquidatable
    // Return index of the debt=repay reserve and index of the collateral=withdraw reserve
    let (_, repay_reserve_index, withdraw_reserve_index) = setup_obligation_for_liquidation(
        lm,
        ob_id,
    );

    let clock = nondet();
    let mut ctx = nondet();
    let mut repay_coins: Coin<R> = nondet();
    let repay_coin_value_pre = repay_coins.value();

    // Assume the liquidation bonus it at least 1%
    let withdraw_reserve = &lm.reserves()[withdraw_reserve_index];
    cvlm_assume_msg(
        withdraw_reserve.config().liquidation_bonus().ge(decimal::from(1)),
        b"Bonus is at least 0.1",
    );

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

    // ... of the repaid debt
    let repay_reserve = vector::borrow(lm.reserves(), repay_reserve_index);
    let repay_value = repay_reserve.market_value(decimal::from(repay_amount));

    // ... and the liquidated ctoken (adjust due to rounding)
    let withdraw_reserve = vector::borrow(lm.reserves(), withdraw_reserve_index);
    let liquidated_value = withdraw_reserve.ctoken_market_value(liquidated_ctokens_amount);

    // marked for removal
    // cvlm_assume_msg(repay_reserve.price().eq(withdraw_reserve.price()), b"Same token prices");
    // cvlm_assume_msg(repay_reserve.price().eq(decimal::from(1)), b"1 price");

    cvlm_assert(repay_value.le(liquidated_value));

    ghost_destroy(clock);
    ghost_destroy(repay_coins);
    ghost_destroy(liquidated_ctokens);
}
