module dummy_pool::obligation;

use dummy_pool::dummy_pool::DummyPool;
use sui::balance::Balance;
use sui::clock::Clock;
use suilend::decimal::Decimal;
use suilend::liquidity_mining::PoolRewardManager;
use suilend::obligation::{Self, Obligation, ExistStaleOracles};
use suilend::reserve::Reserve;

public fun create_obligation(lending_market_id: ID, ctx: &mut TxContext): Obligation<DummyPool> {
    obligation::create_obligation(lending_market_id, ctx)
}

public fun refresh(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
): Option<ExistStaleOracles> {
    obligation::refresh(obligation, reserves, clock)
}

public fun deposit(
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    clock: &Clock,
    ctoken_amount: u64,
) {
    obligation::deposit(obligation, reserve, clock, ctoken_amount)
}

public fun borrow(
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    clock: &Clock,
    amount: u64,
) {
    obligation::borrow(obligation, reserve, clock, amount)
}

public fun repay(
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    clock: &Clock,
    max_repay_amount: Decimal,
): Decimal {
    obligation::repay(obligation, reserve, clock, max_repay_amount)
}

public fun withdraw(
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    clock: &Clock,
    ctoken_amount: u64,
    stale_oracles: Option<ExistStaleOracles>,
) {
    obligation::withdraw(obligation, reserve, clock, ctoken_amount, stale_oracles)
}

public fun liquidate(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    repay_reserve_array_index: u64,
    withdraw_reserve_array_index: u64,
    clock: &Clock,
    repay_amount: u64,
): (u64, Decimal) {
    obligation::liquidate(
        obligation,
        reserves,
        repay_reserve_array_index,
        withdraw_reserve_array_index,
        clock,
        repay_amount,
    )
}

public fun forgive(
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    clock: &Clock,
    max_forgive_amount: Decimal,
): Decimal {
    obligation::forgive(obligation, reserve, clock, max_forgive_amount)
}

public fun claim_rewards<T>(
    obligation: &mut Obligation<DummyPool>,
    pool_reward_manager: &mut PoolRewardManager,
    clock: &Clock,
    reward_index: u64,
): Balance<T> {
    obligation::claim_rewards(obligation, pool_reward_manager, clock, reward_index)
}
