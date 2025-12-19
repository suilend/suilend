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

public fun cvlm_manifest() {
    rule(b"liquidation_only_unhealthy_obligation");
    rule(b"liquidation_reduces_collateral_and_debt");
}

/* Liquidation reverts on healthy obligation */

fun setup_obligation(
    lm: &LendingMarket<DummyPool>,
    ob_id: ID,
): (&Obligation<DummyPool>, u64, u64) {

    let obligation = lm.obligation(ob_id);
    cvlm_assume_msg(obligation.deposits().length() == 1, b"");
    cvlm_assume_msg(obligation.borrows().length() == 1, b"");

    let borrow = &obligation.borrows()[0];
    let deposit = &obligation.deposits()[0];
    let repay_reserve_index = borrow.reserve_array_index();
    let withdraw_reserve_index= deposit.reserve_array_index();
    let borrow_reserve = &lm.reserves()[repay_reserve_index];
    let deposit_reserve = &lm.reserves()[withdraw_reserve_index];
    cvlm_assume_msg(borrow_reserve != deposit_reserve, b"");

    let open_ltv = deposit_reserve.config().open_ltv();
    let close_ltv =  deposit_reserve.config().close_ltv();
    let borrow_weight = borrow_reserve.config().borrow_weight();
    let zero = decimal::from(0);
    let one = decimal::from(1);
    cvlm_assume_msg(zero.lt(open_ltv), b"");
    cvlm_assume_msg(open_ltv.le(close_ltv), b"");
    cvlm_assume_msg(close_ltv.lt(one), b"");
    cvlm_assume_msg(borrow_weight.lt(one), b"");

    // Deposit reserve must be solvent, otherwise we get counterexamples due to rounding with token ratio < 1
    // This is safe since we proved solvency in a different spec.
    // Additionally assume total supply and ctoken supply are both larger than zero to omit rounding by 0 cases.
    cvlm_assume_msg(deposit_reserve.total_supply().gt(decimal::from(deposit_reserve.ctoken_supply())) , b"Solvency");
    cvlm_assume_msg(deposit_reserve.total_supply().gt(one) , b"Solvency");
    cvlm_assume_msg(deposit_reserve.ctoken_supply() > 1 , b"Solvency");

    /* Freshness */

    // Collateral
    let deposited_value_usd = deposit_reserve.ctoken_market_value(deposit.deposited_ctoken_amount());
    let deposited_value_usd_lb = deposit_reserve.ctoken_market_value_lower_bound(deposit.deposited_ctoken_amount());
    let allowed_borrow_value = deposited_value_usd_lb.mul(open_ltv);
    let unhealthy_borrow_value_usd = deposited_value_usd_lb.mul(close_ltv);
    
    cvlm_assume_msg(deposit.market_value() == deposited_value_usd, b"");
    cvlm_assume_msg(obligation.deposited_value_usd() == deposited_value_usd, b"");
    cvlm_assume_msg(obligation.allowed_borrow_value_usd() == allowed_borrow_value, b"");
    cvlm_assume_msg(obligation.unhealthy_borrow_value_usd() == unhealthy_borrow_value_usd, b"");

    // Debt
    let unweighted_borrowed_value_usd = borrow_reserve.market_value(borrow.borrowed_amount());
    let unweighted_borrowed_value_usd_ub = borrow_reserve.market_value_upper_bound(borrow.borrowed_amount());
    let weighted_borrowed_value_usd = unweighted_borrowed_value_usd.mul(borrow_weight);
    let weighted_borrowed_value_upper_bound_usd = unweighted_borrowed_value_usd_ub.mul(borrow_weight);

    cvlm_assume_msg(borrow.market_value() == unweighted_borrowed_value_usd, b"");
    cvlm_assume_msg(obligation.unweighted_borrowed_value_usd() == unweighted_borrowed_value_usd, b"");
    cvlm_assume_msg(obligation.weighted_borrowed_value_usd() == weighted_borrowed_value_usd, b"");
    cvlm_assume_msg(obligation.weighted_borrowed_value_upper_bound_usd() == weighted_borrowed_value_upper_bound_usd, b"");

    (obligation, repay_reserve_index, withdraw_reserve_index)
}

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
