module liquidation::profit;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{rule};
use cvlm::nondet::nondet;
use dummy_pool::dummy_pool::DummyPool;
use sui::coin::Coin;
use suilend::lending_market::LendingMarket;
use suilend::decimal;
use liquidation::utils::setup_obligation;


public fun cvlm_manifest() {
    rule(b"liquidation_no_loss");
}



/// Verifies that liquidation is not a loss for the liquidator. 
/// That means that the market value of the returned CTokens is at least the market value of the repaid debt.
public fun liquidation_no_loss<R, W>(lm: &mut LendingMarket<DummyPool>, ob_id: ID) {

    let (_, repay_reserve_index, withdraw_reserve_index) = setup_obligation(lm, ob_id);

    let clock = nondet();
    let mut ctx = nondet();
    let mut repay_coins: Coin<R> = nondet();
    let repay_coin_value_pre = repay_coins.value();

    cvlm_assume_msg(repay_coin_value_pre > 0, b"At least one coin to repay");
    
    let (liquidated_ctokens,  _) = lm.liquidate<DummyPool, R, W>(
        ob_id,
        repay_reserve_index,
        withdraw_reserve_index,
        &clock,
        &mut repay_coins,
        &mut ctx,
    );
    
    

    // Less than the repay coins value might have been use to repay the debt. 
    let repay_amount = repay_coin_value_pre - repay_coins.value();    
    let liquidated_ctokens_amount = liquidated_ctokens.value();
    cvlm_assume_msg(liquidated_ctokens_amount > 0, b"At least one token obtained");


    let repay_reserve = vector::borrow(lm.reserves(), repay_reserve_index);
    let repay_value = repay_reserve.market_value(decimal::from(repay_amount));


    let withdraw_reserve = vector::borrow(lm.reserves(), withdraw_reserve_index);
    let liquidated_value = withdraw_reserve.ctoken_market_value(liquidated_ctokens_amount+2);
    cvlm_assert(liquidated_value.ge(decimal::from(liquidated_ctokens_amount+2)));

    cvlm_assert(repay_value.le(liquidated_value));
    
    ghost_destroy(clock);
    ghost_destroy(repay_coins);
    ghost_destroy(liquidated_ctokens);

}


/// Verifies that liquidation is not a loss for the liquidator. 
/// That means that the market value of the returned CTokens is at least the market value of the repaid debt.
public fun liquidation_amounts_no_loss(lm: &mut LendingMarket<DummyPool>, ob_id: ID) {

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