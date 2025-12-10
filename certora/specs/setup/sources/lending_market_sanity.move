module spec::lending_market_sanity;

use cvlm::manifest::{ target, target_sanity };

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

    target_sanity();
}