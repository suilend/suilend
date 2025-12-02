module spec::dummy_pool_lending_market;

use pyth::price_info::PriceInfoObject;
use sui::clock::Clock;
use sui::coin::{Coin, CoinMetadata, TreasuryCap};
use sui::sui::SUI;
use sui_system::sui_system::SuiSystemState;
use suilend::rate_limiter::RateLimiterConfig;
use suilend::reserve::{CToken, LiquidityRequest};
use suilend::reserve_config::ReserveConfig;
use suilend::lending_market::{LendingMarket, ObligationOwnerCap, RateLimiterExemption, LendingMarketOwnerCap};

public struct DummyPool has drop {}

// Wrap all `lending_market` functions, only allowing DummyPool as the pool type

public fun refresh_reserve_price(
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    clock: &Clock,
    price_info: &PriceInfoObject,
) {
    suilend::lending_market::refresh_reserve_price<DummyPool>(lending_market, reserve_array_index, clock, price_info)
}

public fun create_obligation(
    lending_market: &mut LendingMarket<DummyPool>,
    ctx: &mut TxContext,
): ObligationOwnerCap<DummyPool> {
    suilend::lending_market::create_obligation<DummyPool>(lending_market, ctx)
}

public fun deposit_liquidity_and_mint_ctokens<T>(
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    clock: &Clock,
    deposit: Coin<T>,
    ctx: &mut TxContext,
): Coin<CToken<DummyPool, T>> {
    suilend::lending_market::deposit_liquidity_and_mint_ctokens<DummyPool, T>(lending_market, reserve_array_index, clock, deposit, ctx)
}

public fun redeem_ctokens_and_withdraw_liquidity<T>(
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    clock: &Clock,
    ctokens: Coin<CToken<DummyPool, T>>,
    rate_limiter_exemption: Option<RateLimiterExemption<DummyPool, T>>,
    ctx: &mut TxContext,
): Coin<T> {
    suilend::lending_market::redeem_ctokens_and_withdraw_liquidity<DummyPool, T>(lending_market, reserve_array_index, clock, ctokens, rate_limiter_exemption, ctx)
}

public fun redeem_ctokens_and_withdraw_liquidity_request<T>(
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    clock: &Clock,
    ctokens: Coin<CToken<DummyPool, T>>,
    rate_limiter_exemption: Option<RateLimiterExemption<DummyPool, T>>,
    _ctx: &mut TxContext,
): LiquidityRequest<DummyPool, T> {
    suilend::lending_market::redeem_ctokens_and_withdraw_liquidity_request<DummyPool, T>(lending_market, reserve_array_index, clock, ctokens, rate_limiter_exemption, _ctx)
}

public fun deposit_ctokens_into_obligation<T>(
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    obligation_owner_cap: &ObligationOwnerCap<DummyPool>,
    clock: &Clock,
    deposit: Coin<CToken<DummyPool, T>>,
    ctx: &mut TxContext,
) {
    suilend::lending_market::deposit_ctokens_into_obligation<DummyPool, T>(lending_market, reserve_array_index, obligation_owner_cap, clock, deposit, ctx)
}

public fun borrow<T>(
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    obligation_owner_cap: &ObligationOwnerCap<DummyPool>,
    clock: &Clock,
    amount: u64,
    ctx: &mut TxContext,
): Coin<T> {
    suilend::lending_market::borrow<DummyPool, T>(lending_market, reserve_array_index, obligation_owner_cap, clock, amount, ctx)
}

public fun compound_interest(
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    clock: &Clock,
) {
    suilend::lending_market::compound_interest<DummyPool>(lending_market, reserve_array_index, clock)
}

public fun borrow_request<T>(
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    obligation_owner_cap: &ObligationOwnerCap<DummyPool>,
    clock: &Clock,
    amount: u64,
): LiquidityRequest<DummyPool, T> {
    suilend::lending_market::borrow_request<DummyPool, T>(lending_market, reserve_array_index, obligation_owner_cap, clock, amount)
}

public fun fulfill_liquidity_request<T>(
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    liquidity_request: LiquidityRequest<DummyPool, T>,
    ctx: &mut TxContext,
): Coin<T> {
    suilend::lending_market::fulfill_liquidity_request<DummyPool, T>(lending_market, reserve_array_index, liquidity_request, ctx)
}

public fun withdraw_ctokens<T>(
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    obligation_owner_cap: &ObligationOwnerCap<DummyPool>,
    clock: &Clock,
    amount: u64,
    ctx: &mut TxContext,
): Coin<CToken<DummyPool, T>> {
    suilend::lending_market::withdraw_ctokens<DummyPool, T>(lending_market, reserve_array_index, obligation_owner_cap, clock, amount, ctx)
}

public fun liquidate<Repay, Withdraw>(
    lending_market: &mut LendingMarket<DummyPool>,
    obligation_id: ID,
    repay_reserve_array_index: u64,
    withdraw_reserve_array_index: u64,
    clock: &Clock,
    repay_coins: &mut Coin<Repay>, // mut because we probably won't use all of it
    ctx: &mut TxContext,
): (Coin<CToken<DummyPool, Withdraw>>, RateLimiterExemption<DummyPool, Withdraw>) {
    suilend::lending_market::liquidate<DummyPool, Repay, Withdraw>(lending_market, obligation_id, repay_reserve_array_index, withdraw_reserve_array_index, clock, repay_coins, ctx)
}

public fun repay<T>(
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    obligation_id: ID,
    clock: &Clock,
    // mut because we might not use all of it and the amount we want to use is
    // hard to determine beforehand
    max_repay_coins: &mut Coin<T>,
    ctx: &mut TxContext,
) {
    suilend::lending_market::repay<DummyPool, T>(lending_market, reserve_array_index, obligation_id, clock, max_repay_coins, ctx)
}

public fun forgive<T>(
    cap: &LendingMarketOwnerCap<DummyPool>,
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    obligation_id: ID,
    clock: &Clock,
    max_forgive_amount: u64,
) {
    suilend::lending_market::forgive<DummyPool, T>(cap, lending_market, reserve_array_index, obligation_id, clock, max_forgive_amount)
}

public fun claim_rewards<RewardType>(
    lending_market: &mut LendingMarket<DummyPool>,
    cap: &ObligationOwnerCap<DummyPool>,
    clock: &Clock,
    reserve_id: u64,
    reward_index: u64,
    is_deposit_reward: bool,
    ctx: &mut TxContext,
): Coin<RewardType> {
    suilend::lending_market::claim_rewards<DummyPool, RewardType>(lending_market, cap, clock, reserve_id, reward_index, is_deposit_reward, ctx)
}

public fun claim_rewards_and_deposit<RewardType>(
    lending_market: &mut LendingMarket<DummyPool>,
    obligation_id: ID,
    clock: &Clock,
    // array index of reserve that is giving out the rewards
    reward_reserve_id: u64,
    reward_index: u64,
    is_deposit_reward: bool,
    // array index of reserve with type RewardType
    deposit_reserve_id: u64,
    ctx: &mut TxContext,
) {
    suilend::lending_market::claim_rewards_and_deposit<DummyPool, RewardType>(lending_market, obligation_id, clock, reward_reserve_id, reward_index, is_deposit_reward, deposit_reserve_id, ctx)
}

public fun init_staker<S: drop>(
    lending_market: &mut LendingMarket<DummyPool>,
    cap: &LendingMarketOwnerCap<DummyPool>,
    sui_reserve_array_index: u64,
    treasury_cap: TreasuryCap<S>,
    ctx: &mut TxContext,
) {
    suilend::lending_market::init_staker<DummyPool, S>(lending_market, cap, sui_reserve_array_index, treasury_cap, ctx)
}

public fun rebalance_staker(
    lending_market: &mut LendingMarket<DummyPool>,
    sui_reserve_array_index: u64,
    system_state: &mut SuiSystemState,
    ctx: &mut TxContext,
) {
    suilend::lending_market::rebalance_staker<DummyPool>(lending_market, sui_reserve_array_index, system_state, ctx)
}

public fun unstake_sui_from_staker(
    lending_market: &mut LendingMarket<DummyPool>,
    sui_reserve_array_index: u64,
    liquidity_request: &LiquidityRequest<DummyPool, SUI>,
    system_state: &mut SuiSystemState,
    ctx: &mut TxContext,
) {
    suilend::lending_market::unstake_sui_from_staker<DummyPool>(lending_market, sui_reserve_array_index, liquidity_request, system_state, ctx)
}

public fun add_reserve<T>(
    cap: &LendingMarketOwnerCap<DummyPool>,
    lending_market: &mut LendingMarket<DummyPool>,
    price_info: &PriceInfoObject,
    config: ReserveConfig,
    coin_metadata: &CoinMetadata<T>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    suilend::lending_market::add_reserve<DummyPool, T>(cap, lending_market, price_info, config, coin_metadata, clock, ctx)
}

public fun update_reserve_config<T>(
    cap: &LendingMarketOwnerCap<DummyPool>,
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    config: ReserveConfig,
) {
    suilend::lending_market::update_reserve_config<DummyPool, T>(cap, lending_market, reserve_array_index, config)
}

public fun change_reserve_price_feed<T>(
    cap: &LendingMarketOwnerCap<DummyPool>,
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    price_info_obj: &PriceInfoObject,
    clock: &Clock,
) {
    suilend::lending_market::change_reserve_price_feed<DummyPool, T>(cap, lending_market, reserve_array_index, price_info_obj, clock)
}

public fun add_pool_reward<RewardType>(
    cap: &LendingMarketOwnerCap<DummyPool>,
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    is_deposit_reward: bool,
    rewards: Coin<RewardType>,
    start_time_ms: u64,
    end_time_ms: u64,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    suilend::lending_market::add_pool_reward<DummyPool, RewardType>(cap, lending_market, reserve_array_index, is_deposit_reward, rewards, start_time_ms, end_time_ms, clock, ctx)
}

public fun cancel_pool_reward<RewardType>(
    cap: &LendingMarketOwnerCap<DummyPool>,
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    is_deposit_reward: bool,
    reward_index: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<RewardType> {
    suilend::lending_market::cancel_pool_reward<DummyPool, RewardType>(cap, lending_market, reserve_array_index, is_deposit_reward, reward_index, clock, ctx)
}

public fun close_pool_reward<RewardType>(
    cap: &LendingMarketOwnerCap<DummyPool>,
    lending_market: &mut LendingMarket<DummyPool>,
    reserve_array_index: u64,
    is_deposit_reward: bool,
    reward_index: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<RewardType> {
    suilend::lending_market::close_pool_reward<DummyPool, RewardType>(cap, lending_market, reserve_array_index, is_deposit_reward, reward_index, clock, ctx)
}

public fun update_rate_limiter_config(
    cap: &LendingMarketOwnerCap<DummyPool>,
    lending_market: &mut LendingMarket<DummyPool>,
    clock: &Clock,
    config: RateLimiterConfig,
) {
    suilend::lending_market::update_rate_limiter_config<DummyPool>(cap, lending_market, clock, config)
}

public fun set_fee_receivers(
    cap: &LendingMarketOwnerCap<DummyPool>,
    lending_market: &mut LendingMarket<DummyPool>,
    receivers: vector<address>,
    weights: vector<u64>,
) {
    suilend::lending_market::set_fee_receivers<DummyPool>(cap, lending_market, receivers, weights)
}

public fun new_obligation_owner_cap(
    cap: &LendingMarketOwnerCap<DummyPool>,
    lending_market: &LendingMarket<DummyPool>,
    obligation_id: ID,
    ctx: &mut TxContext,
): ObligationOwnerCap<DummyPool> {
    suilend::lending_market::new_obligation_owner_cap<DummyPool>(cap, lending_market, obligation_id, ctx)
}
    
