module health::no_deposit_no_debt;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule};
use dummy_pool::dummy_pool::DummyPool;
use suilend::lending_market::LendingMarket;
use suilend::obligation::Obligation;
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


    rule(b"no_deposits_no_borrow_base");
    rule(b"no_deposits_no_borrow_step");

}

native fun invoke(target: Function, lending_market: &mut LendingMarket<DummyPool>, obligation_id: ID);



fun no_deposit_no_borrow(ob: &Obligation<DummyPool>): bool {
    let deposits = ob.deposits().length();
    let borrows = ob.borrows().length();

    deposits != 0 || borrows == 0
}

/// The base case for the induction.
/// Asserts that in the initial state, i.e. right after creating a new obligation, if the obligation has no deposits, it has no borrows.
public fun no_deposits_no_borrow_base(
    lending_market: &mut LendingMarket<DummyPool>,
    ctx: &mut TxContext,
) {
    let cap = lending_market.create_obligation(ctx);
    let obligation = lending_market.obligation(cap.obligation_id());
    cvlm_assert(no_deposit_no_borrow(obligation));

    ghost_destroy(cap);
}

/// The step cases for the induction.
public fun no_deposits_no_borrow_step(
    lending_market: &mut LendingMarket<DummyPool>,
    id: ID,
    target: Function,
    clock: &Clock
) {
    let obligation = setup_obligation(lending_market, id);
    cvlm_assume_msg(no_deposit_no_borrow(obligation), b"Assume invariant in pre-state");


    invoke(target, lending_market, id);

    
    lending_market.refresh_obligation_health(id, clock);
    let obligation = lending_market.obligation_mut(id);

    cvlm_assert_msg(no_deposit_no_borrow(obligation), b"Assert invariant in post-state");
}