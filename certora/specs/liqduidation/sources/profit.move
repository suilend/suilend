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

public fun cvlm_manifest() {
    rule(b"liquidation_with_bonus_profitable");
    rule(b"liquidation_no_loss");
}


/// Verifies that liquidation is profitable to the liquidator, given the bonus rate is not 0.
/// That means that the market value of the returned CTokens exceeds the market value of the repaid debt.
public fun liquidation_with_bonus_profitable<R, W>(lm: &mut LendingMarket<DummyPool>, ob_id: ID) {

    let repay_reserve_array_index = nondet();
    let withdraw_reserve_array_index = nondet();

    {
        let withdraw_reserve = vector::borrow(lm.reserves(), withdraw_reserve_array_index);
        let bonus = withdraw_reserve.config().liquidation_bonus();
        cvlm_assume_msg(bonus.gt(decimal::from(0)), b"positive bonus");
    };

    cvlm_assume_msg(repay_reserve_array_index != withdraw_reserve_array_index, b"Different reserves");

    let clock = nondet();
    let mut ctx = nondet();
    let mut repay_coins: Coin<R> = nondet();
    let repay_coin_value_pre = repay_coins.value();

    let liquidated_ctokens: Coin<CToken<DummyPool, W>>;
    (liquidated_ctokens,  _) = lm.liquidate<DummyPool, R, W>(
        ob_id,
        repay_reserve_array_index,
        withdraw_reserve_array_index,
        &clock,
        &mut repay_coins,
        &mut ctx,
    );

    // Less than the repay coins value might have been use to repay the debt. 
    let repay_amount = repay_coin_value_pre - repay_coins.value();    
    let repay_reserve = vector::borrow(lm.reserves(), repay_reserve_array_index);
    let repay_value = repay_reserve.market_value(decimal::from(repay_amount));

    let liquidated_ctokens_amount = liquidated_ctokens.value();
    let withdraw_reserve = vector::borrow(lm.reserves(), withdraw_reserve_array_index);
    let liquidated_value = withdraw_reserve.ctoken_market_value(liquidated_ctokens_amount);

    cvlm_assert(repay_value.le(liquidated_value));
    ghost_destroy(clock);
    ghost_destroy(repay_coins);
    ghost_destroy(liquidated_ctokens);
}

/// Verifies that liquidation is not a loss for the liquidator. 
/// That means that the market value of the returned CTokens is at least the market value of the repaid debt.
public fun liquidation_no_loss<R, W>(lm: &mut LendingMarket<DummyPool>, ob_id: ID) {

    let repay_reserve_array_index = nondet();
    let withdraw_reserve_array_index = nondet();

    cvlm_assume_msg(repay_reserve_array_index != withdraw_reserve_array_index, b"Different reserves");

    let clock = nondet();
    let mut ctx = nondet();
    let mut repay_coins: Coin<R> = nondet();
    let repay_coin_value_pre = repay_coins.value();

    
    let (liquidated_ctokens,  _) = lm.liquidate<DummyPool, R, W>(
        ob_id,
        repay_reserve_array_index,
        withdraw_reserve_array_index,
        &clock,
        &mut repay_coins,
        &mut ctx,
    );

    // Less than the repay coins value might have been use to repay the debt. 
    let repay_amount = repay_coin_value_pre - repay_coins.value();    

    // Convert to repay amount to usd
    let repay_reserve = vector::borrow(lm.reserves(), repay_reserve_array_index);
    let repay_value = repay_reserve.market_value(decimal::from(repay_amount));

    // Convert liquidation result (= ctokens obtained) to usd
    let liquidated_ctokens_amount = liquidated_ctokens.value();
    let withdraw_reserve = vector::borrow(lm.reserves(), withdraw_reserve_array_index);
    let liquidated_value = withdraw_reserve.ctoken_market_value(liquidated_ctokens_amount);

    cvlm_assert(repay_value.le(liquidated_value));


    ghost_destroy(clock);
    ghost_destroy(repay_coins);
    ghost_destroy(liquidated_ctokens);
}
