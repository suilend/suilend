module liquidation::profit;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{rule};
use cvlm::nondet::nondet;
use dummy_pool::dummy_pool::DummyPool;
use sui::coin::Coin;
use suilend::lending_market::LendingMarket;
use suilend::reserve::CToken;
use suilend::decimal;
use liquidation::utils::setup_obligation;

public fun cvlm_manifest() {
    rule(b"liquidation_no_loss");
}


/// Verifies that liquidation is not a loss for the liquidator. 
/// That means that the market value of the returned CTokens is at least the market value of the repaid debt.
public fun liquidation_no_loss(lm: &mut LendingMarket<DummyPool>, ob_id: ID) {

    let (ob, repay_reserve_index, withdraw_reserve_index) = setup_obligation(lm, ob_id);


    let repay_reserve = vector::borrow(lm.reserves(), repay_reserve_index);
    let withdraw_reserve = vector::borrow(lm.reserves(), withdraw_reserve_index);
    let borrow = ob.find_borrow( repay_reserve);  
    let deposit = ob.find_deposit( withdraw_reserve);


    let repay_amount = nondet();
    let (final_settle_amount, final_withdraw_amount) = ob.liquidation_amounts(repay_amount, withdraw_reserve, repay_reserve, borrow, deposit);


    let repay_value = repay_reserve.market_value(final_settle_amount);

    
    let liquidated_value = withdraw_reserve.ctoken_market_value(final_withdraw_amount + 2);

    cvlm_assert(repay_value.le(liquidated_value));
}
