module solvency::increase;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::function::Function;
use cvlm::manifest::{target, invoker, rule};
use dummy_pool::dummy_pool::DummyPool;
use sui::sui::SUI;
use suilend::lending_market::LendingMarket;



public fun cvlm_manifest() {
    // Public mut functions
    target(@dummy_pool, b"dummy_pool_lending_market", b"refresh_reserve_price");
    target(@dummy_pool, b"dummy_pool_lending_market", b"create_obligation");
    target(@dummy_pool, b"dummy_pool_lending_market", b"deposit_liquidity_and_mint_ctokens");
    target(@dummy_pool, b"dummy_pool_lending_market", b"redeem_ctokens_and_withdraw_liquidity");
    target(@dummy_pool, b"dummy_pool_lending_market", b"redeem_ctokens_and_withdraw_liquidity_request");
    target(@dummy_pool, b"dummy_pool_lending_market", b"deposit_ctokens_into_obligation");
    target(@dummy_pool, b"dummy_pool_lending_market", b"borrow");
    target(@dummy_pool, b"dummy_pool_lending_market", b"compound_interest");
    target(@dummy_pool, b"dummy_pool_lending_market", b"borrow_request");
    target(@dummy_pool, b"dummy_pool_lending_market", b"fulfill_liquidity_request");
    target(@dummy_pool, b"dummy_pool_lending_market", b"withdraw_ctokens");
    target(@dummy_pool, b"dummy_pool_lending_market", b"liquidate");
    target(@dummy_pool, b"dummy_pool_lending_market", b"repay");
    target(@dummy_pool, b"dummy_pool_lending_market", b"forgive");
    target(@dummy_pool, b"dummy_pool_lending_market", b"claim_rewards");
    target(@dummy_pool, b"dummy_pool_lending_market", b"claim_rewards_and_deposit");
    target(@dummy_pool, b"dummy_pool_lending_market", b"init_staker");
    target(@dummy_pool, b"dummy_pool_lending_market", b"rebalance_staker");
    target(@dummy_pool, b"dummy_pool_lending_market", b"unstake_sui_from_staker");

    // Admin mut functions
    target(@dummy_pool, b"dummy_pool_lending_market", b"add_reserve");
    target(@dummy_pool, b"dummy_pool_lending_market", b"update_reserve_config");
    target(@dummy_pool, b"dummy_pool_lending_market", b"change_reserve_price_feed");
    target(@dummy_pool, b"dummy_pool_lending_market", b"add_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"cancel_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"close_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"update_rate_limiter_config");
    target(@dummy_pool, b"dummy_pool_lending_market", b"set_fee_receivers");
    target(@dummy_pool, b"dummy_pool_lending_market", b"new_obligation_owner_cap");

    invoker(b"invoke");

    rule(b"obligation_col_increase_implies_reserve_asset_increase");
}

native fun invoke(target: Function, lending_market: &mut LendingMarket<DummyPool>);


/// Spurious cex in invalid states(?) and timeouts.
fun get_ctoken_amounts(lm: &LendingMarket<DummyPool>, ri: u64, obi: ID): (u64, u64) {
    let reserve = &lm.reserves()[ri];
    let reserve_ctokens = reserve.balances().deposited_ctoken_amount<DummyPool, SUI>().value();

    let obligation = lm.obligation(obi);
    let obligation_ctokens = obligation.deposited_ctoken_amount<DummyPool, SUI>();
    (obligation_ctokens, reserve_ctokens)
}


public fun obligation_col_increase_implies_reserve_asset_increase(
    lending_market: &mut LendingMarket<DummyPool>,
    i: u64,
    ob_id: ID,
    target: Function,
) {
    cvlm_assume_msg(i < lending_market.reserves().length(), b"Index is in range");

    let (ob_ctokens_pre, res_ctokens_pre) = get_ctoken_amounts(lending_market, i, ob_id);


    invoke(target, lending_market);

   let (ob_ctokens_post, res_ctokens_post) = get_ctoken_amounts(lending_market, i, ob_id);
   

    if (ob_ctokens_post > ob_ctokens_pre) {
        let obligation_diff = ob_ctokens_post - ob_ctokens_pre;
        cvlm_assert(res_ctokens_post > res_ctokens_pre);
        let reserve_diff = res_ctokens_post - res_ctokens_pre;
        cvlm_assert(obligation_diff == reserve_diff);
    }
}
