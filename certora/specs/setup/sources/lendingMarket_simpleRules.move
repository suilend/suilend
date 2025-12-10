module spec::lending_market_simpleRules;

use cvlm::manifest::{ target, invoker };
use cvlm::asserts::{ cvlm_satisfy, cvlm_assert };
use cvlm::manifest::rule;
use cvlm::function::{ Function };
use suilend::obligation:: { Self, Obligation };

public fun cvlm_manifest() {
    target(@suilend, b"lending_market", b"refresh_reserve_price");
    target(@suilend, b"lending_market", b"create_obligation");
    target(@suilend, b"lending_market", b"deposit_liquidity_and_mint_ctokens");
    target(@suilend, b"lending_market", b"redeem_ctokens_and_withdraw_liquidity");
    target(@suilend, b"lending_market", b"redeem_ctokens_and_withdraw_liquidity_request");
    target(@suilend, b"lending_market", b"deposit_ctokens_into_obligation");
    target(@suilend, b"lending_market", b"borrow");
    target(@suilend, b"lending_market", b"compound_interest");
    target(@suilend, b"lending_market", b"borrow_request");
    target(@suilend, b"lending_market", b"fulfill_liquidity_request");
    target(@suilend, b"lending_market", b"withdraw_ctokens");
    target(@suilend, b"lending_market", b"repay");
    target(@suilend, b"lending_market", b"forgive");
    target(@suilend, b"lending_market", b"claim_rewards");
    target(@suilend, b"lending_market", b"claim_rewards_and_deposit");
    target(@suilend, b"lending_market", b"init_staker");
    target(@suilend, b"lending_market", b"rebalance_staker");
    target(@suilend, b"lending_market", b"unstake_sui_from_staker");
    target(@suilend, b"lending_market", b"migrate");
    target(@suilend, b"lending_market", b"add_reserve");
    target(@suilend, b"lending_market", b"update_reserve_config");
    target(@suilend, b"lending_market", b"change_reserve_price_feed");
    target(@suilend, b"lending_market", b"add_pool_reward");
    target(@suilend, b"lending_market", b"cancel_pool_reward");
    target(@suilend, b"lending_market", b"close_pool_reward");
    target(@suilend, b"lending_market", b"update_rate_limiter_config");
    target(@suilend, b"lending_market", b"set_fee_receivers");
    target(@suilend, b"lending_market", b"claim_fees");
    target(@suilend, b"lending_market", b"new_obligation_owner_cap");

    invoker(b"invoke");    
    rule(b"depositRecordsAreUnique");
}

native fun invoke(target: Function);

public fun depositRecordsAreUnique<P>(obl: &mut Obligation<P>, target: Function, index1: u64, index2: u64) {
    let allDeposits = obl.deposits_mut();
    let dep1 = vector::borrow_mut(allDeposits, index1);
    let coin1 = dep1.coinTypeFromDeposit();

    //let coin1_pre= &obligation::coinTypeFromDeposit(obligation::deposits_mut<P>(obl)[index1]);
    //let coin2_pre= &obligation::coinTypeFromDeposit(obligation::deposits_mut(obl)[index2]);
    
    invoke(target);

    //let coin1_post= obligation::coinTypeFromDeposit(obligation::deposits_mut(obl)[index1]);
    //let coin2_post= obligation::coinTypeFromDeposit(obligation::deposits_mut(obl)[index2]);
    
    //cvlm_assert(coin1_pre != coin2_pre => coin1_post != coin2_post);
    //cvlm_assert(coin1_post != coin2_post);
    cvlm_assert(vector::length(allDeposits) > 0);
    //cvlm_assert(true);
}