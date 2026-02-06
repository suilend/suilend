/// property: Liquidation Integrity
/// description: Verifies liquidation only occurs on unhealthy obligations, reduces collateral and debt, and improves health
module liquidation::integrity;

use commons::helper::setup_obligation_for_liquidation;
use commons::utils::log;
use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::rule;
use cvlm::nondet::nondet;
use dummy_pool::dummy_pool::DummyPool;
use sui::coin::Coin;
use suilend::lending_market::LendingMarket;
use suilend::decimal::{ge, gt, Self};
use commons::helper::zero;



public fun cvlm_manifest() {
    rule(b"liquidation_only_unhealthy_obligation");
    rule(b"liquidation_reduces_collateral_and_debt");
    rule(b"liquidation_improves_health");
}

/// Verifies that if liquidation executes successfully, the obligation was unhealthy
public fun liquidation_only_unhealthy_obligation<R, W>(
    lm: &mut LendingMarket<DummyPool>,
    ob_id: ID,
) {
    let (
        obligation,
        repay_reserve_index,
        withdraw_reserve_index,
    ) = setup_obligation_for_liquidation(lm, ob_id);

    let liquidatable = obligation.is_liquidatable();
    let healthy = obligation.is_healthy();

    cvlm_assume_msg(!liquidatable || !healthy, b"Liquidatable => Unhealthy");

    let clock = nondet();
    let mut ctx = nondet();

    // The coins to repay
    let mut repay_coins: Coin<R> = nondet();

    let (coin, _) = lm.liquidate<DummyPool, R, W>(
        ob_id,
        repay_reserve_index,
        withdraw_reserve_index,
        &clock,
        &mut repay_coins,
        &mut ctx,
    );

    ghost_destroy(coin);
    ghost_destroy(clock);
    ghost_destroy(repay_coins);

    // We cannot check for aborts yet, but we can assert that the liquidation only passed in the obligation was unhealthy
    cvlm_assert(!healthy);
}

/// Verifies that liquidation reduces both collateral and debt amounts
public fun liquidation_reduces_collateral_and_debt<R, W>(
    lm: &mut LendingMarket<DummyPool>,
    ob_id: ID,
) {
    let (
        obligation,
        repay_reserve_index,
        withdraw_reserve_index,
    ) = setup_obligation_for_liquidation(lm, ob_id);

    let (deposits_pre, borrows_pre) = {
        let deposits = obligation.deposits()[0].deposited_ctoken_amount();
        let borrows = obligation.borrows()[0].borrowed_amount();
        (deposits, borrows)
    };

    // Perform liquidation
    let clock = nondet();
    let mut ctx = nondet();
    let mut repay_coins: Coin<R> = nondet();

    let (c, _) = lm.liquidate<DummyPool, R, W>(
        ob_id,
        repay_reserve_index,
        withdraw_reserve_index,
        &clock,
        &mut repay_coins,
        &mut ctx,
    );
    // Uncommenting this will make the rule pass.
    // cvlm_assume_msg(c.value() > 0, b"Assume at least one coin was withdrawn");

    // Deposits and borrows after liquidation
    let (deposits_post, borrows_post) = {
        let obligation = lm.obligation(ob_id);
        let deposits = obligation.deposits()[0].deposited_ctoken_amount();
        let borrows = obligation.borrows()[0].borrowed_amount();
        (deposits, borrows)
    };

    cvlm_assert(deposits_pre > deposits_post);
    cvlm_assert(borrows_pre.gt(borrows_post));

    ghost_destroy(c);
    ghost_destroy(clock);
    ghost_destroy(repay_coins);
}

/// Verifies that liquidation improves or maintains the loan-to-value (LTV) ratio
///
/// This rule ensures that when a liquidation occurs, the resulting LTV ratio
/// (debt/collateral) does not worsen. Specifically, it checks that:
/// debt_pre / collateral_pre >= debt_post / collateral_post
///
/// The rule assumes:
/// - Some collateral exists to seize (collateral market value > 0)
/// - No bad debt (debt <= collateral in market value terms)
/// - Repay amount is positive and at most covers the full debt
/// - At least one cToken was seized during liquidation
/// - Post-liquidation collateral is positive (well-defined LTV)
/// - 1:1 prices, 1:1 ctoken ratio, and no mint decimals
public fun liquidation_improves_health(lm: &mut LendingMarket<DummyPool>, ob_id: ID) {
    let (ob, repay_reserve_index, withdraw_reserve_index) = setup_obligation_for_liquidation(
        lm,
        ob_id,
    );
    let repay_reserve = &lm.reserves()[repay_reserve_index];
    let withdraw_reserve = &lm.reserves()[withdraw_reserve_index];
    let conf = withdraw_reserve.config();
    
    /* Obtain debt, collateral and their respective marked values */
    
    let collateral_pre = ob.deposits()[0].deposited_ctoken_amount();
    let collateral_pre_mv = ob.deposits()[0].market_value();
    cvlm_assume_msg(collateral_pre_mv.ge(zero()), b"Some collateral to seize exists");
    let debt_pre = ob.borrows()[0].borrowed_amount();
    let debt_pre_mv = ob.borrows()[0].market_value();
    cvlm_assume_msg(debt_pre_mv.le(collateral_pre_mv), b"No bad debt");
    
    /* Setup a sound repay amount */

    let repay_amount = nondet();
    cvlm_assume_msg(repay_amount > 0, b"At least one coin to repay");
    cvlm_assume_msg(decimal::from(repay_amount).le(debt_pre_mv), b"At most full liquidation");
    



    // Uncomment for a "nice" counterexample:
    // Repaying $18 debt at an LTV of $90/$100 using 20% fees, we obtain an LTV of 72/79 > 0.9
    // cvlm_assume_msg(repay_amount == 18, b"");
    // cvlm_assume_msg(collateral_pre == 100, b"");
    // cvlm_assume_msg(debt_pre == decimal::from(90), b"");
    // cvlm_assume_msg(conf.protocol_liquidation_fee() == decimal::from_percent(20), b"");

    /* Compute the liquidation amounts */
    
    // final_withdraw_amount: seized cToken from the collateral
    // final_settle_amount: repaid debt
    // We assume at least one cToken was seized for this rule

    let (final_withdraw_amount, final_settle_amount) = ob.liquidation_amounts(repay_reserve, withdraw_reserve, &ob.borrows()[0], &ob.deposits()[0], repay_amount);
    cvlm_assume_msg(final_withdraw_amount > 0, b"Collateral was seized");

    /* Compute marked values of the debt and collateral post liquidation */

    let collateral_post = collateral_pre - final_withdraw_amount;
    let collateral_post_mv = withdraw_reserve.ctoken_market_value(collateral_post);
    cvlm_assume_msg(collateral_post > 0, b"Well-defined ltv");
    cvlm_assert(collateral_pre > collateral_post);

    let debt_post = debt_pre.sub(final_settle_amount);
    let debt_post_mv = repay_reserve.market_value(debt_post);
    
    // Logging
    log(&debt_pre);
    log(&collateral_pre);
    log(&debt_post);
    log(&collateral_post);

    /* Assert that liquidation did not worsen the LTV */

    // LTV did not make the LTV worse: debt_pre/collateral_pre  >= debt_post/collateral_post
    // <==> debt_pre*collateral_post >= debt_post*collateral_pre

    cvlm_assert(ge(debt_pre_mv.mul(collateral_post_mv), debt_post_mv.mul(collateral_pre_mv)));

}