module health::ltv_monotonicity;

use commons::helper::{setup_obligation, refresh_health, zero};
use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::function::Function;
use cvlm::manifest::{target, invoker, rule};
use dummy_pool::dummy_pool::DummyPool;
use suilend::decimal::Decimal;
use suilend::lending_market::LendingMarket;
use suilend::obligation::Obligation;

public fun cvlm_manifest() {
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

fun ltv<P>(ob: &Obligation<P>): (Decimal, Decimal) {
    let loan = ob.weighted_borrowed_value_upper_bound_usd();
    let value = ob.deposited_value_usd();
    (loan, value)
}

public(package) fun ltv_increases_with_debt(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
) {
    let obligation = setup_obligation(lending_market, id);
    let debt_pre = obligation.weighted_borrowed_value_usd();
    let (loan_pre, value_pre) = ltv(obligation);

    invoke(target, lending_market, id);

    let (obligation, reserves) = lending_market.obligation_and_reserves_mut_for_testing(id);
    refresh_health(obligation, reserves);
    let debt_post = obligation.weighted_borrowed_value_usd();

    let (loan_post, value_post) = ltv(obligation);

    let debt_increase = debt_post.gt(debt_pre);

    //          ltv_pre < ltv_post
    // <==>     loan_pre/value_pre < loan_post/value_post
    // <==>     loan_pre*value_post < loan_post/value_pre
    cvlm_assume_msg(value_pre.gt(zero()), b"Non-zero collateral");
    cvlm_assume_msg(value_post.gt(zero()), b"Non-zero collateral");

    // needs to be <= instead of < due to rounding
    let ltv_increase = loan_pre.mul(value_post).le(loan_post.mul(value_pre));

    // It is better for performance to use a assumption here instead of "!debt_increase || ltv_increase"
    // This is fine since we are not interested in the case where debt does not increase.
    cvlm_assume_msg(debt_increase, b"Debt increases");
    cvlm_assert(ltv_increase);
}

public(package) fun ltv_decreases_with_collateral(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
) {
    let obligation = setup_obligation(lending_market, id);

    let coll_pre = obligation.deposited_value_usd();
    let (loan_pre, value_pre) = ltv(obligation);

    invoke(target, lending_market, id);

    let (obligation, reserves) = lending_market.obligation_and_reserves_mut_for_testing(id);
    refresh_health(obligation, reserves);

    let coll_post = obligation.deposited_value_usd();

    // needs to be >= instead of > due to rounding
    let (loan_post, value_post) = ltv(obligation);

    let coll_increase = coll_post.gt(coll_pre);

    //          ltv_pre > ltv_post
    // <==>     loan_pre/value_pre > loan_post/value_post
    // <==>     loan_pre*value_post > loan_post/value_pre
    cvlm_assume_msg(value_pre.gt(zero()), b"Non-zero collateral");
    cvlm_assume_msg(value_post.gt(zero()), b"Non-zero collateral");
    let ltv_decrease = loan_pre.mul(value_post).ge(loan_post.mul(value_pre));

    // See comment in above rule
    cvlm_assume_msg(coll_increase, b"Assume collateral increases");
    cvlm_assert(ltv_decrease);
}
