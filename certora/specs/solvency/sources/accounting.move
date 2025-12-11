module solvency::accounting;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule};
use pyth::price_info::PriceInfoObject;
use dummy_pool::dummy_pool::DummyPool;
use sui::clock::Clock;
use suilend::lending_market::LendingMarket;
use suilend::reserve::{Reserve, create_reserve};
use suilend::reserve_config::ReserveConfig;
use sui::sui::SUI;

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

    rule(b"available_balance_correct_base");
    rule(b"available_balance_correct_step");
}

native fun invoke(target: Function, lending_market: &mut LendingMarket<DummyPool>);


/// Returns whether given reserve is solvent, i.e., whether the total supply of assets is equal to or greater than the amount of cTokens.
public fun available_balance_accounting_correct(reserve: &Reserve<DummyPool>): bool {
    let internal = reserve.available_amount();
    let onchain = reserve.balances<DummyPool, SUI>().available_amount().value();
    // This is <= because lending operations can return a liquidity request.
    // In that case, the internal balance is decreased but a second call to fulfill the request is required to decrease the on-chain balance.
    // Since such requests are not storable and have to redeemed in the same tx, the value in practice should be equal.
    internal <= onchain
}

/// The base case for the induction.
/// Asserts that in the initial state, i.e. right after creating a new reserve, the solvency property holds.
public fun available_balance_correct_base(
    lending_market_id: ID,
    config: ReserveConfig,
    array_index: u64,
    mint_decimals: u8,
    price_info_obj: &PriceInfoObject,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let reserve: Reserve<DummyPool> = create_reserve<DummyPool, SUI>(
        lending_market_id,
        config,
        array_index,
        mint_decimals,
        price_info_obj,
        clock,
        ctx,
    );
    cvlm_assert(available_balance_accounting_correct(&reserve));
    ghost_destroy(reserve);
}

/// The induction steps for the solvency invariant.
/// Assumes an arbitrary reserve, identified by its index in the lending market, that is in a solvent state,
/// and assert that every function that can modify the state preserves the solvency.
public fun available_balance_correct_step(lending_market: &mut LendingMarket<DummyPool>, i: u64, target: Function) {
    cvlm_assume_msg(i < lending_market.reserves().length(), b"Index is in range");

    {
        let reserve = &lending_market.reserves()[i];
        cvlm_assume_msg(available_balance_accounting_correct(reserve), b"Assume reserve is solvent pre-state");
    };

    invoke(target, lending_market);

    {
        let reserve = &lending_market.reserves()[i];
        cvlm_assert_msg(available_balance_accounting_correct(reserve), b"Assume reserve is solvent pre-state");
    };
}


