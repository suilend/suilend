module spec::solvency;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule};
use cvlm::nondet::nondet;
use pyth::price_info::PriceInfoObject;
use std::type_name;
use sui::clock::Clock;
use sui::sui::{SUI};
use suilend::lending_market::LendingMarket;
use suilend::obligation::{Obligation};
use suilend::reserve::{Reserve, create_reserve};
use suilend::reserve_config::ReserveConfig;
use suilend::lending_market;
use suilend::lending_market::LendingMarketOwnerCap;
use spec::dummy_pool_lending_market::DummyPool;

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

    invoker(b"invoke");

    rule(b"solvency_base");
    rule(b"solvency_step");
    rule(b"solvency_step_forgive");


    rule(b"obligation_col_increase_implies_reserve_asset_increase");
}


native fun invoke(target: Function, lending_market: &mut LendingMarket<DummyPool>);

/* -- Solvency -- */

/// Returns whether given reserve is solvent, i.e., whether the total supply of assets is equal to or greater than the amount of cTokens.
fun solvency(reserve: &Reserve<DummyPool>): bool {
    reserve.total_supply().floor() >= reserve.ctoken_supply()
}

/// The base case for the induction.
/// Asserts that in the initial state, i.e. right after creating a new reserve, the solvency property holds.
public fun solvency_base<T>(
    lending_market_id: ID,
    config: ReserveConfig,
    array_index: u64,
    mint_decimals: u8,
    price_info_obj: &PriceInfoObject,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let reserve: Reserve<DummyPool> = create_reserve<DummyPool, T>(
        lending_market_id,
        config,
        array_index,
        mint_decimals,
        price_info_obj,
        clock,
        ctx,
    );
    cvlm_assert(solvency(&reserve));
    ghost_destroy(reserve);
}

/// The induction steps for the solvency invariant.
/// Assumes an arbitrary reserve in a solvent state, and assert that every function that can modify the state preserves the solvency.
/// !This should fail for target `forgive` but it passes
public fun solvency_step(
    lending_market: &mut LendingMarket<DummyPool>,
    i: u64,
    target: Function,
) {
    cvlm_assume_msg(i < lending_market.reserves().length(), b"..");

    {
        let reserve = &lending_market.reserves()[i];
        cvlm_assume_msg(solvency(reserve), b"pre");
    };

    invoke(target, lending_market);

    {
        let reserve = &lending_market.reserves()[i];
        cvlm_assert_msg(solvency(reserve), b"post");
    };
}

public fun solvency_step_forgive<T>(lmarket: &mut LendingMarket<DummyPool>, i: u64) {
    cvlm_assume_msg(i < lmarket.reserves().length(), b"..");

    {
        let reserve = &lmarket.reserves()[i];
        cvlm_assume_msg(solvency(reserve), b"pre");
    };

    // invoke forgive manually
    let ob_id = nondet();
    let clock = nondet();
    let max_forgive_amount = nondet();
    let cap: LendingMarketOwnerCap<DummyPool> = nondet();

    lending_market::forgive<DummyPool, T>(&cap, lmarket, i, ob_id, &clock, max_forgive_amount);
    ghost_destroy(cap);
    ghost_destroy(clock);

    {
        let reserve = &lmarket.reserves()[i];
        cvlm_assert_msg(solvency(reserve), b"post");
    };

}


/// "An internal Prover error occurred: N/A" 
/// https://prover.certora.com/output/8195906/e80e66f203b14b6dae55878de98bffe8?anonymousKey=b56fc438b4cb4b39487b6949b90aeb6510f60e75
public fun obligation_col_increase_implies_reserve_asset_increase(
    lending_market: &mut LendingMarket<DummyPool>,
    reserve: &Reserve<DummyPool>,
    obligation: &Obligation<DummyPool>,
    target: Function,
) {
    cvlm_assume_msg(reserve.coin_type() == type_name::get<SUI>(), b"Assume SUI reserve");
    let obligation_ctoken_pre = obligation.deposited_ctoken_amount<DummyPool, SUI>();
    let reserve_ctokens_pre = reserve.balances().deposited_ctoken_amount<DummyPool, SUI>().value();

    let i: u64 = nondet();
    cvlm_assume_msg(vector::borrow_mut(lending_market.reserves_mut(), i) == reserve, b"test");
    cvlm_assume_msg(i < lending_market.reserves().length(), b"test");
    cvlm_assume_msg(&lending_market.reserves()[i] == reserve, b"test");

    invoke(target, lending_market);

    let obligation_ctoken_post = obligation.deposited_ctoken_amount<DummyPool, SUI>();
    let reserve_ctokens_post = reserve.balances().deposited_ctoken_amount<DummyPool, SUI>().value();

    if (obligation_ctoken_post > obligation_ctoken_pre) {
        let obligation_diff = obligation_ctoken_post - obligation_ctoken_pre;
        cvlm_assert(reserve_ctokens_post > reserve_ctokens_pre);
        let reserve_diff = reserve_ctokens_post - reserve_ctokens_pre;
        cvlm_assert(obligation_diff == reserve_diff);
    }
}
