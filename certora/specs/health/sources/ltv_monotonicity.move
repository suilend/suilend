module health::ltv_monotonicity;

use cvlm::asserts::{cvlm_assert};
use cvlm::function::Function;
use cvlm::manifest::{target, invoker, rule};
use dummy_pool::dummy_pool::DummyPool;
use suilend::decimal::Decimal;
use suilend::lending_market::LendingMarket;
use suilend::obligation::Obligation;
use sui::clock::Clock;
use health::utils::{ setup_obligation};

public fun cvlm_manifest() {
    // Public mut functions
    
    // We ignore price changes and config updates
    // target(@dummy_pool, b"dummy_pool_lending_market", b"refresh_reserve_price");
    // target(@dummy_pool, b"dummy_pool_lending_market", b"update_reserve_config");
    
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

    target(@dummy_pool, b"dummy_pool_lending_market", b"change_reserve_price_feed");
    target(@dummy_pool, b"dummy_pool_lending_market", b"add_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"cancel_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"close_pool_reward");
    target(@dummy_pool, b"dummy_pool_lending_market", b"update_rate_limiter_config");
    target(@dummy_pool, b"dummy_pool_lending_market", b"set_fee_receivers");
    target(@dummy_pool, b"dummy_pool_lending_market", b"new_obligation_owner_cap");

    invoker(b"invoke");

    rule(b"ltv_increases_with_debt");
    rule(b"ltv_decreases_with_collateral");
}


native fun invoke(
    target: Function,
    lending_market: &mut LendingMarket<DummyPool>,
    obligation_id: ID,
);


fun ltv<P>(ob: &Obligation<P>): Decimal {
    let loan = ob.weighted_borrowed_value_upper_bound_usd();
    let value = ob.deposited_value_usd();
    loan.div(value)
}


fun ltv_increases_with_debt(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
    clock: &Clock
) {
  let obligation = setup_obligation(lending_market, id);
  let debt_pre = obligation.weighted_borrowed_value_usd();
  let ltv_pre = ltv(obligation);

  invoke(target, lending_market, id);

  
  lending_market.refresh_obligation(id, clock);
  let obligation = lending_market.obligation_mut(id);
  let debt_post = obligation.weighted_borrowed_value_usd();
  let ltv_post = ltv(obligation);

  let debt_increase = debt_post.gt(debt_pre);
  let ltv_increase = ltv_post.ge(ltv_pre);
  

  // debt_increase -> ltv_increase <==> !debt_increase || ltv_increase
  cvlm_assert(!debt_increase || ltv_increase);
}

fun ltv_decreases_with_collateral(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
    clock: &Clock
) {

  let obligation = setup_obligation(lending_market, id);

  let coll_pre = obligation.deposited_value_usd();
  let ltv_pre = ltv(obligation);

  invoke(target, lending_market, id);

  
  lending_market.refresh_obligation(id, clock);
  let obligation = lending_market.obligation_mut(id);
  let coll_post = obligation.deposited_value_usd();
  let ltv_post = ltv(obligation);

  let coll_increase = coll_post.gt(coll_pre);
  let ltv_decrease = ltv_post.le(ltv_pre);

  

  // coll_increase -> ltv_decrease <==> !coll_increase || ltv_decrease
  cvlm_assert(!coll_increase || ltv_decrease);

}