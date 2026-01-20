module health::no_col_decrease;

use cvlm::asserts::{cvlm_assert};
use cvlm::function::Function;
use cvlm::manifest::{target, invoker, rule};
use dummy_pool::dummy_pool::DummyPool;
use suilend::lending_market::LendingMarket;
use commons::helper::setup_obligation;
use sui::clock::Clock;

public fun cvlm_manifest() {
    // Public mut functions
    target(@dummy_pool, b"dummy_pool_lending_market", b"refresh_reserve_price");
    target(@dummy_pool, b"dummy_pool_lending_market", b"create_obligation");
    target(@dummy_pool, b"dummy_pool_lending_market", b"deposit_liquidity_and_mint_ctokens");
    target(@dummy_pool, b"dummy_pool_lending_market", b"redeem_ctokens_and_withdraw_liquidity");
    target(
        @dummy_pool,
        b"dummy_pool_lending_market",
        b"redeem_ctokens_and_withdraw_liquidity_request",
    );
    target(@dummy_pool, b"dummy_pool_lending_market", b"deposit_ctokens_into_obligation");
    target(@dummy_pool, b"dummy_pool_lending_market", b"borrow");
    target(@dummy_pool, b"dummy_pool_lending_market", b"compound_interest");
    target(@dummy_pool, b"dummy_pool_lending_market", b"borrow_request");
    target(@dummy_pool, b"dummy_pool_lending_market", b"fulfill_liquidity_request");
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

    rule(b"no_col_decrease");
}

native fun invoke(target: Function, lending_market: &mut LendingMarket<DummyPool>, obligation_id: ID);

public fun no_col_decrease(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
    clock: &Clock
) {
    let obligation = setup_obligation(lending_market, id);
    let col_pre = obligation.total_deposited_ctokens();

    
    invoke(target, lending_market, id);
    
    
    lending_market.refresh_obligation_health(id, clock);
    let obligation = lending_market.obligation_mut(id);
    let col_post = obligation.total_deposited_ctokens();


    cvlm_assert(col_pre <= col_post);   
    
}