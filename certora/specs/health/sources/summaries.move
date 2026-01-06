module health::summaries;

use cvlm::asserts::cvlm_assume_msg;
use cvlm::manifest::summary;
use cvlm::nondet::{nondet_with, nondet};
use dummy_pool::dummy_pool::DummyPool;
use sui::balance::Balance;
use sui::clock::Clock;
use sui_system::sui_system::SuiSystemState;
use suilend::decimal::Decimal;
use suilend::liquidity_mining::{PoolRewardManager, UserRewardManager};
use suilend::obligation::{Obligation, ExistStaleOracles};
use suilend::rate_limiter::RateLimiter;
use suilend::reserve::{Reserve, LiquidityRequest};
use cvlm::manifest::ghost;

public fun cvlm_manifest() {
    //summary(b"reserve_compound_borrow_rate", @suilend, b"reserve", b"compound_borrow_rate");
    summary(b"reserve_compound_interest", @suilend, b"reserve", b"compound_interest");
    summary(b"reserve_borrow_liquidity", @suilend, b"reserve", b"borrow_liquidity");
    summary(b"reserve_unstake_sui_from_staker", @suilend, b"reserve", b"unstake_sui_from_staker");
    summary(b"reserve_rebalance_staker", @suilend, b"reserve", b"rebalance_staker");
    summary(b"reserve_log_reserve_data", @suilend, b"reserve", b"log_reserve_data");

    summary(b"rate_limiter_process_qty", @suilend, b"rate_limiter", b"process_qty");

    summary(b"max_borrow_amount", @suilend, b"lending_market", b"max_borrow_amount");

    // summary(b"obligation_refresh", @suilend, b"obligation", b"refresh");
    ghost(b"deposit_index");
    ghost(b"borrow_index");
    summary(b"obligation_find_borrow_index", @suilend, b"obligation", b"find_borrow_index");
    summary(b"obligation_find_deposit_index", @suilend, b"obligation", b"find_deposit_index");
    summary(b"obligation_log_obligation_data", @suilend, b"obligation", b"log_obligation_data");
    summary(
        b"obligation_find_or_add_user_reward_manager",
        @suilend,
        b"obligation",
        b"find_or_add_user_reward_manager",
    );
    summary(
        b"obligation_zero_out_rewards_if_looped",
        @suilend,
        b"obligation",
        b"zero_out_rewards_if_looped",
    );

    summary(
        b"mining_change_user_reward_manager_share",
        @suilend,
        b"liquidity_mining",
        b"change_user_reward_manager_share",
    );

    summary(b"reserve_mint_decimals", @suilend, b"reserve", b"mint_decimals");

    summary(b"mining_claim_rewards", @suilend, b"liquidity_mining", b"claim_rewards");
}

public fun reserve_mint_decimals<P>(_reserve: &Reserve<P>): u8 {
    9
}

public fun reserve_compound_borrow_rate(_: &mut Reserve<DummyPool>, _: u64): Decimal {
    let val = nondet_with!(b"Borrow rate", |r| 1 <= r && r < 2);
    suilend::decimal::from(val)
}

public fun reserve_compound_interest<P>(_: &mut Reserve<P>, _: &Clock) {}

public fun reserve_borrow_liquidity<P, T>(
    _reserve: &mut Reserve<P>,
    _amount: u64,
): LiquidityRequest<P, T> {
    let lq: LiquidityRequest<P, T> = nondet();

    let amount: u64 = lq.liquidity_request_amount();
    let fees: u64 = lq.liquidity_request_fee();
    cvlm_assume_msg(amount == _amount + fees, b"");
    lq
}

public fun reserve_unstake_sui_from_staker<P, T>(
    _reserve: &mut Reserve<P>,
    _liquidity_request: &LiquidityRequest<P, T>,
    _system_state: &mut SuiSystemState,
    _ctx: &mut TxContext,
) {}

public fun reserve_rebalance_staker<P>(
    _reserve: &mut Reserve<P>,
    _system_state: &mut SuiSystemState,
    _ctx: &mut TxContext,
) {}

public fun rate_limiter_process_qty(
    _rate_limiter: &mut RateLimiter,
    _cur_time: u64,
    _qty: Decimal,
) {} // noop

native fun deposit_index(ob_id: &UID, reserve_id: &UID): u64;
native fun borrow_index(ob_id: &UID, reserve_id: &UID): u64;

public fun obligation_find_borrow_index<P>(obligation: &Obligation<P>, reserve: &Reserve<P>): u64 {
    let oid = obligation.id();
    let rid = reserve.id();

    let i = borrow_index(oid, rid);
    cvlm_assume_msg(i <= obligation.borrows().length(), b"");

    if (i < obligation.borrows().length()) {
        let borrow = &obligation.borrows()[i];
        cvlm_assume_msg(borrow.reserve_array_index() == reserve.array_index(), b"");
    };

    i
}

public fun obligation_find_deposit_index<P>(obligation: &Obligation<P>, reserve: &Reserve<P>): u64 {
    let oid = obligation.id();
    let rid = reserve.id();

    let i = deposit_index(oid, rid);
    cvlm_assume_msg(i <= obligation.deposits().length(), b"");

    if (i < obligation.deposits().length()) {
        let deposit = &obligation.deposits()[i];
        cvlm_assume_msg(deposit.reserve_array_index() == reserve.array_index(), b"");
    };

    i
}

public fun obligation_refresh<P>(
    obligation: &mut Obligation<P>,
    reserves: &mut vector<Reserve<P>>,
    clock: &Clock,
): Option<ExistStaleOracles> {
    nondet()
}

public fun max_borrow_amount<P>(
    mut _rate_limiter: RateLimiter,
    _obligation: &Obligation<P>,
    _reserve: &Reserve<P>,
    _clock: &Clock,
): u64 {
    nondet()
}

public fun mining_change_user_reward_manager_share(
    _pool_reward_manager: &mut PoolRewardManager,
    _user_reward_manager: &mut UserRewardManager,
    _new_share: u64,
    _clock: &Clock,
) {}

public fun obligation_log_obligation_data<P>(_obligation: &Obligation<P>) {} // no-op

public(package) fun obligation_zero_out_rewards_if_looped<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
) {} //noop

public fun obligation_find_or_add_user_reward_manager<P>(
    _obligation: &mut Obligation<P>,
    _pool_reward_manager: &mut PoolRewardManager,
    _clock: &Clock,
): (u64, &mut UserRewardManager) {
    let i = nondet();
    let mnrg = vector::borrow_mut(_obligation.user_reward_managers_mut(), i);
    (i, mnrg)
}

public fun reserve_log_reserve_data<P>(_reserve: &Reserve<P>) {}

public(package) fun mining_claim_rewards<T>(
    pool_reward_manager: &mut PoolRewardManager,
    user_reward_manager: &mut UserRewardManager,
    clock: &Clock,
    reward_index: u64,
): Balance<T> {
    nondet()
}
