module solvency::summaries;


use cvlm::manifest::summary;
use sui::clock::Clock;
use suilend::reserve::Reserve;
use suilend::obligation::Obligation;
use suilend::decimal::{Decimal};
use cvlm::nondet::nondet;
use cvlm::nondet::nondet_with;
use suilend::rate_limiter::RateLimiter;
use cvlm::ghost::ghost_destroy;
use suilend::staker::Staker;
use sui::balance::Balance;
use sui::sui::SUI;
use sui_system::sui_system::SuiSystemState;
use cvlm::manifest::ghost;
use cvlm::asserts::cvlm_assume_msg;
use suilend::liquidity_mining::PoolRewardManager;
use suilend::liquidity_mining::UserRewardManager;

public fun cvlm_manifest() {

    // Obligation Summaries
    

    ghost(b"deposit_index");
    ghost(b"borrow_index");
    summary(b"obligation_find_borrow_index", @suilend, b"obligation", b"find_borrow_index");
    summary(b"obligation_find_deposit_index", @suilend, b"obligation", b"find_deposit_index");
    summary(b"obligation_refresh", @suilend, b"obligation", b"refresh");
    // Reserve Summaries
    summary(b"reserve_compound_borrow_rate", @suilend, b"reserve", b"compound_borrow_rate");
    summary(b"reserve_log_reserve_data", @suilend, b"reserve", b"log_reserve_data");
    // Rate Limiter
    summary(b"rate_limiter_process_qty", @suilend, b"rate_limiter", b"process_qty");
    // Staker
    summary(b"staker_deposit", @suilend, b"staker", b"deposit");
    summary(b"staker_rebalance", @suilend, b"staker", b"rebalance");
    summary(b"staker_withdraw", @suilend, b"staker", b"withdraw");
    summary(b"staker_claim_fees", @suilend, b"staker", b"claim_fees");

    ghost(b"staked_sui");
    
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
    summary(b"mining_claim_rewards", @suilend, b"liquidity_mining", b"claim_rewards");
    

    
}

native public fun staked_sui(): &mut u64;

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

public fun obligation_repay<DummyPool>(
    _: &mut Obligation<DummyPool>,
    _: &mut Reserve<DummyPool>,
    _: &Clock,
    _: Decimal,
): Decimal {
    // let borrow_index = nondet();// find_borrow_index<DummyPool>(obligation, reserve);
    // let borrow = vector::borrow( obligation.borrows(), borrow_index);
    // return min(max_repay_amount, borrow.borrowed_amount())
    return nondet()
}

public fun obligation_refresh<DummyPool>(
    _: &mut Obligation<DummyPool>,
    _: &mut vector<Reserve<DummyPool>>,
    _: &Clock,
): Option<suilend::obligation::ExistStaleOracles> {
    return nondet()
}

public(package) fun obligation_deposit<P>(
    _obligation: &mut Obligation<P>,
    _reserve: &mut Reserve<P>,
    _clock: &Clock,
    _ctoken_amount: u64,
) {} //no-op

public(package) fun obligation_borrow<P>(
    _obligation: &mut Obligation<P>,
    _reserve: &mut Reserve<P>,
    _clock: &Clock,
    _amount: u64,
) {} // no-op

public(package) fun obligation_liquidate<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _repay_reserve_array_index: u64,
    _withdraw_reserve_array_index: u64,
    _clock: &Clock,
    _repay_amount: u64,
): (u64, Decimal) {
    (nondet(), nondet())
}

public(package) fun obligation_zero_out_rewards_if_looped<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
) {} //noop

public fun reserve_compound_borrow_rate<DummyPool>(_: &mut Reserve<DummyPool>, _: u64): Decimal {
    let val = nondet_with!(b"Borrow rate", |r| 1 <= r && r < 2);
    suilend::decimal::from(val)
}

public fun rate_limiter_process_qty(
    _rate_limiter: &mut RateLimiter,
    _cur_time: u64,
    _qty: Decimal,
) {} // noop


public(package) fun staker_deposit<P>(_staker: &mut Staker<P>, sui: Balance<SUI>) {
    let v = sui.value();
    
    let staked_pre = staked_sui();
    
    //ghost_write(&mut staked_sui(), staked_pre + v);
    *staked_pre = *staked_pre + v;

    ghost_destroy(sui);
} // noop
public(package) fun staker_rebalance<P: drop>(_staker: &mut Staker<P>, _system_state: &mut SuiSystemState, _ctx: &mut TxContext) {} // noop
public(package) fun staker_withdraw<P: drop>(_staker: &mut Staker<P>, _withdraw_amount: u64, _system_state: &mut SuiSystemState, _ctx: &mut TxContext): Balance<SUI> {
    nondet()
}

public(package) fun staker_claim_fees<P: drop>(
        _staker: &mut Staker<P>,
        _system_state: &mut SuiSystemState,
        _ctx: &mut TxContext,
    ): Balance<SUI> {
    nondet()
}


public fun reserve_log_reserve_data<P>(_reserve: &Reserve<P>) {}


public fun mining_change_user_reward_manager_share(
    _pool_reward_manager: &mut PoolRewardManager,
    _user_reward_manager: &mut UserRewardManager,
    _new_share: u64,
    _clock: &Clock,
) {}

public(package) fun mining_claim_rewards<T>(
    pool_reward_manager: &mut PoolRewardManager,
    user_reward_manager: &mut UserRewardManager,
    clock: &Clock,
    reward_index: u64,
): Balance<T> {
    nondet()
}

public fun obligation_log_obligation_data<P>(_obligation: &Obligation<P>) {} // no-op


public fun obligation_find_or_add_user_reward_manager<P>(
    _obligation: &mut Obligation<P>,
    _pool_reward_manager: &mut PoolRewardManager,
    _clock: &Clock,
): (u64, &mut UserRewardManager) {
    let i = nondet();
    let mnrg = vector::borrow_mut(_obligation.user_reward_managers_mut(), i);
    (i, mnrg)
}
