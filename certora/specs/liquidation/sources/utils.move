module liquidation::utils;

use cvlm::asserts::{cvlm_assume_msg};
use dummy_pool::dummy_pool::DummyPool;
use suilend::lending_market::LendingMarket;
use suilend::obligation::Obligation;
use suilend::decimal;


public fun setup_obligation(
    lm: &LendingMarket<DummyPool>,
    ob_id: ID,
): (&Obligation<DummyPool>, u64, u64) {

    let obligation = lm.obligation(ob_id);
    cvlm_assume_msg(lm.reserves().length() == 2, b"");
    cvlm_assume_msg(obligation.deposits().length() == 1, b"");
    cvlm_assume_msg(obligation.borrows().length() == 1, b"");

    let borrow = &obligation.borrows()[0];
    let deposit = &obligation.deposits()[0];
    
    let repay_reserve_index = borrow.reserve_array_index();
    let withdraw_reserve_index= deposit.reserve_array_index();

    cvlm_assume_msg(withdraw_reserve_index != repay_reserve_index, b"");
    
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
    cvlm_assume_msg(borrow_weight.le(one), b"");

    // Deposit reserve must be solvent, otherwise we get counterexamples due to rounding with token ratio < 1
    // This is safe since we proved solvency in a different spec.
    // Additionally assume total supply and ctoken supply are both larger than zero to omit rounding by 0 cases.
    // cvlm_assume_msg(deposit_reserve.total_supply().gt(decimal::from(deposit_reserve.ctoken_supply())) , b"Solvency");
    // cvlm_assume_msg(deposit_reserve.total_supply().gt(one) , b"Solvency");
    // cvlm_assume_msg(deposit_reserve.ctoken_supply() > 1 , b"Solvency");

    cvlm_assume_msg(deposit_reserve.ctoken_ratio().eq(one) , b"Solvency");
    cvlm_assume_msg(borrow_reserve.ctoken_ratio().eq(one) , b"Solvency");


    // let twenty_percent = decimal::from_bps(2_000);
    // let fees = deposit_reserve.config().protocol_liquidation_fee().add(deposit_reserve.config().liquidation_bonus());
    // cvlm_assume_msg(fees.lt(twenty_percent), b"");
    cvlm_assume_msg(deposit_reserve.config().protocol_liquidation_fee().eq(zero), b"");
    cvlm_assume_msg(deposit_reserve.config().liquidation_bonus().eq(zero), b"");

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
