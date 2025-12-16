module health::health;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule};
use dummy_pool::dummy_pool::DummyPool;
use suilend::lending_market::LendingMarket;
use cvlm::manifest::summary;
use suilend::reserve::Reserve;



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

    rule(b"obligation_health_base");
    rule(b"obligation_health_step");

    summary(b"reserve_mint_decimals",@suilend, b"reserve", b"mint_decimals");
}


public fun reserve_mint_decimals<P>(_reserve: &Reserve<P>): u8 {
    9
}

native fun invoke(target: Function, lending_market: &mut LendingMarket<DummyPool>, obligation_id: ID);

/// The base case for the induction.
/// Asserts that in the initial state, i.e. right after creating a new obligation, it is healthy.
public fun obligation_health_base(
    lending_market: &mut LendingMarket<DummyPool>,
    ctx: &mut TxContext,
) {
    let cap = lending_market.create_obligation(ctx);

    let obligation = lending_market.obligation(cap.obligation_id());
    cvlm_assert(obligation.is_healthy());

    ghost_destroy(cap);
}

/// The step cases for the induction.
/// Asserts that if obligation is in a healthy state, no lending operation can make it unhealthy, unless debt is accumulated.
public fun obligation_health_step(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
) {

    let obligation = lending_market.obligation(id);

    // We store the cumulative borrow rates of all borrows in the obligation.
    // This allows to require that, after a call to a function, none of them changed,
    // implying that no debt has been accumulated.
    // Is is less expensive than a full refresh of the obligation.
    let mut rates_pre = vector[];
    let mut i = 0;
    while (i < obligation.borrows().length()) {
        let rate = obligation.borrows()[i].cumulative_borrow_rate();
        rates_pre.push_back(rate);
        i = i + 1;
    };

    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");

    // Liquidatable => Unhealthy
    cvlm_assume_msg(!obligation.is_liquidatable() || !obligation.is_healthy(), b"Require invariant: Obligation is only liquidatable if it is unhealthy");
    let forgivable = obligation.is_forgivable();
    let healthy = obligation.is_healthy();
    let no_debt = obligation.borrows().length() == 0;
    // forgivable => unhealthy | no borrows
    cvlm_assume_msg( !forgivable || (!healthy || no_debt), b"Require invariant: Obligation is only forgivable if it is unhealthy or has no debt");
    

    invoke(target, lending_market, id);

    let obligation = lending_market.obligation(id);

    // Require that no debt has been accumulated
    let mut i = 0;
    while (i < obligation.borrows().length()) {
        let rate = obligation.borrows()[i].cumulative_borrow_rate();
        cvlm_assume_msg(rate == rates_pre[i], b"");
        i = i + 1;
    };

    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}