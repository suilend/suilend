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
use suilend::decimal::gt;
use suilend::lending_market::LendingMarket;
use suilend::reserve::market_value;
use suilend::decimal::ge;
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

/// Verifies that liquidation improves the obligation's LTV ratio
public fun liquidation_improves_health<R, W>(lm: &mut LendingMarket<DummyPool>, ob_id: ID) {
    let (ob, repay_reserve_index, withdraw_reserve_index) = setup_obligation_for_liquidation(
        lm,
        ob_id,
    );

    let clock = nondet();
    let mut ctx = nondet();
    let mut repay_coins: Coin<R> = nondet();
    let repay_coin_value_pre = repay_coins.value();

    let collateral_pre = ob.deposits()[0].market_value();
    let debt_pre = ob.borrows()[0].market_value();

    cvlm_assume_msg(debt_pre.le(collateral_pre), b"No bad debt");

    // Uncomment for a "nice" counterexample:
    // Repaying $18 debt at an LTV of $90/$100 using 20% fees, we obtain an LTV of 72/79 > 0.9
    // let deposit_reserve = &lm.reserves()[withdraw_reserve_index];
    // cvlm_assume_msg(repay_coin_value_pre == 18, b"");
    // cvlm_assume_msg(collateral_pre == decimal::from(100), b"");
    // cvlm_assume_msg(debt_pre == decimal::from(90), b"");

    // cvlm_assume_msg(deposit_reserve.config().protocol_liquidation_fee() == decimal::from_percent(20), b"");

    cvlm_assume_msg(repay_coin_value_pre > 0, b"At least one coin to repay");

    let (liquidated_ctokens, _) = lm.liquidate<DummyPool, R, W>(
        ob_id,
        repay_reserve_index,
        withdraw_reserve_index,
        &clock,
        &mut repay_coins,
        &mut ctx,
    );


    let repay_reserve = vector::borrow(lm.reserves(), repay_reserve_index);
    let withdraw_reserve = vector::borrow(lm.reserves(), withdraw_reserve_index);
    let ob = lm.obligation(ob_id);
    let debt_post = repay_reserve.market_value(ob.borrows()[0].borrowed_amount());
    let collateral_post = withdraw_reserve.ctoken_market_value(ob
        .deposits()[0]
        .deposited_ctoken_amount());

    log(&debt_pre);
    log(&collateral_pre);
    log(&debt_post);
    log(&collateral_post);

    // LTV improves: debt_pre/collateral_pre  >= debt_post/collateral_post
    // <==> debt_pre*collateral_post >= debt_post*collateral_pre
    cvlm_assume_msg(collateral_pre.gt(zero()), b"non-zero denominator");
    cvlm_assume_msg(collateral_post.gt(zero()), b"non-zero denominator");
    cvlm_assume_msg(collateral_pre.gt(collateral_post), b"non-zero of collateral was seized");


    cvlm_assert(ge(debt_pre.mul(collateral_post), debt_post.mul(collateral_pre)));

    ghost_destroy(clock);
    ghost_destroy(repay_coins);
    ghost_destroy(liquidated_ctokens);
}
