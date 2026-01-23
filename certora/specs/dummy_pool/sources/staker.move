module dummy_pool::staker;

use dummy_pool::dummy_pool::DummyPool;
use sui::balance::Balance;
use sui::sui::SUI;
use sui_system::sui_system::SuiSystemState;
use suilend::staker::{Self, Staker};

public fun deposit(staker: &mut Staker<DummyPool>, sui: Balance<SUI>) {
    staker::deposit(staker, sui)
}

public fun withdraw(
    staker: &mut Staker<DummyPool>,
    withdraw_amount: u64,
    system_state: &mut SuiSystemState,
    ctx: &mut TxContext,
): Balance<SUI> {
    staker::withdraw(staker, withdraw_amount, system_state, ctx)
}

public(package) fun rebalance(
    staker: &mut Staker<DummyPool>,
    system_state: &mut SuiSystemState,
    ctx: &mut TxContext,
) {
    staker::rebalance(staker, system_state, ctx)
}

public fun claim_fees(
    staker: &mut Staker<DummyPool>,
    system_state: &mut SuiSystemState,
    ctx: &mut TxContext,
): Balance<SUI> {
    staker::claim_fees(staker, system_state, ctx)
}
