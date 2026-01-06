module liquidation::integrity;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::rule;
use cvlm::nondet::nondet;
use dummy_pool::dummy_pool::DummyPool;
use sui::coin::Coin;
use suilend::lending_market::LendingMarket;
use suilend::obligation::Obligation;
use suilend::decimal;
use liquidation::utils::setup_obligation;

public fun cvlm_manifest() {
    rule(b"liquidation_only_unhealthy_obligation");
    rule(b"liquidation_reduces_collateral_and_debt");
}

/* Liquidation reverts on healthy obligation */

public fun liquidation_only_unhealthy_obligation<R, W>(
    lm: &mut LendingMarket<DummyPool>,
    ob_id: ID,
) {
    let (obligation, repay_reserve_index, withdraw_reserve_index) = setup_obligation(lm, ob_id);

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

public fun liquidation_reduces_collateral_and_debt<R, W>(
    lm: &mut LendingMarket<DummyPool>,
    ob_id: ID,
) {

    let (obligation, repay_reserve_index, withdraw_reserve_index) = setup_obligation(lm, ob_id);

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
