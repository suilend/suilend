module spec::liquidation;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, rule};
use cvlm::nondet::nondet;
use spec::dummy_pool::DummyPool;
use spec::obligation_integrity::liquidatable_implies_unhealthy;
use sui::coin::Coin;
use suilend::lending_market::LendingMarket;
use suilend::reserve::CToken;
use suilend::decimal;


public fun cvlm_manifest() {
    // Public mut functions
    target(@spec, b"dummy_pool_lending_market", b"refresh_reserve_price");
    target(@spec, b"dummy_pool_lending_market", b"create_obligation");
    target(@spec, b"dummy_pool_lending_market", b"deposit_liquidity_and_mint_ctokens");
    target(@spec, b"dummy_pool_lending_market", b"redeem_ctokens_and_withdraw_liquidity");
    target(@spec, b"dummy_pool_lending_market", b"redeem_ctokens_and_withdraw_liquidity_request");
    target(@spec, b"dummy_pool_lending_market", b"deposit_ctokens_into_obligation");
    target(@spec, b"dummy_pool_lending_market", b"borrow");
    target(@spec, b"dummy_pool_lending_market", b"compound_interest");
    target(@spec, b"dummy_pool_lending_market", b"borrow_request");
    target(@spec, b"dummy_pool_lending_market", b"fulfill_liquidity_request");
    target(@spec, b"dummy_pool_lending_market", b"withdraw_ctokens");
    target(@spec, b"dummy_pool_lending_market", b"liquidate");
    target(@spec, b"dummy_pool_lending_market", b"repay");
    target(@spec, b"dummy_pool_lending_market", b"forgive");
    target(@spec, b"dummy_pool_lending_market", b"claim_rewards");
    target(@spec, b"dummy_pool_lending_market", b"claim_rewards_and_deposit");
    target(@spec, b"dummy_pool_lending_market", b"init_staker");
    target(@spec, b"dummy_pool_lending_market", b"rebalance_staker");
    target(@spec, b"dummy_pool_lending_market", b"unstake_sui_from_staker");

    // Admin mut functions
    target(@spec, b"dummy_pool_lending_market", b"add_reserve");
    target(@spec, b"dummy_pool_lending_market", b"update_reserve_config");
    target(@spec, b"dummy_pool_lending_market", b"change_reserve_price_feed");
    target(@spec, b"dummy_pool_lending_market", b"add_pool_reward");
    target(@spec, b"dummy_pool_lending_market", b"cancel_pool_reward");
    target(@spec, b"dummy_pool_lending_market", b"close_pool_reward");
    target(@spec, b"dummy_pool_lending_market", b"update_rate_limiter_config");
    target(@spec, b"dummy_pool_lending_market", b"set_fee_receivers");
    target(@spec, b"dummy_pool_lending_market", b"new_obligation_owner_cap");

    rule(b"liquidation_only_unhealthy_obligation");
    rule(b"liquidation_with_bonus_profitable");
    rule(b"liquidation_no_loss");
    rule(b"liquidation_reduces_collateral_and_debt");
}

/* Liquidation reverts on healthy obligation */

public fun liquidation_only_unhealthy_obligation<R, W>(
    lm: &mut LendingMarket<DummyPool>,
    ob_id: ID,
) {
    let obligation = lm.obligation(ob_id);

    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"liquidatable => unhealthy");
    let healthy = obligation.is_healthy();

    // We don't care about the actual reserve to withdraw from/deposit to;
    let repay_reserve_array_index = nondet();
    let withdraw_reserve_array_index = nondet();

    let clock = nondet();
    let mut ctx = nondet();

    // The coins to repay
    let mut repay_coins: Coin<R> = nondet();

    let (coin, _) = lm.liquidate<DummyPool, R, W>(
        ob_id,
        repay_reserve_array_index,
        withdraw_reserve_array_index,
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

public fun liquidation_reduces_collateral_and_debt<R, W>(lm: &mut LendingMarket<DummyPool>, ob_id: ID) {

    let (deposits_pre, borrows_pre) = {
        let obligation = lm.obligation(ob_id);
        let deposits = obligation.deposited_value_usd();
        let borrows = obligation.unweighted_borrowed_value_usd();
        (deposits, borrows)
    };
    
    

    let repay_reserve_array_index = nondet();
    let withdraw_reserve_array_index = nondet();
    cvlm_assume_msg(repay_reserve_array_index != withdraw_reserve_array_index, b"Different reserves");
    let clock = nondet();
    let mut ctx = nondet();
    let mut repay_coins: Coin<R> = nondet();

    
    let (c, _) = lm.liquidate<DummyPool, R, W>(
        ob_id,
        repay_reserve_array_index,
        withdraw_reserve_array_index,
        &clock,
        &mut repay_coins,
        &mut ctx,
    );

    let (deposits_post, borrows_post) = {
        let obligation = lm.obligation(ob_id);
        let deposits = obligation.deposited_value_usd();
        let borrows = obligation.unweighted_borrowed_value_usd();
        (deposits, borrows)
    };

    cvlm_assert(deposits_pre.gt( deposits_post));
    cvlm_assert(borrows_pre.gt(borrows_post));

    ghost_destroy(c);
    ghost_destroy(clock);
    ghost_destroy(repay_coins);
}