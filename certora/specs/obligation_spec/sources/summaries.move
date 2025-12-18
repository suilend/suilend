module obligation_spec::summaries;

use cvlm::asserts::cvlm_assume_msg;
use cvlm::manifest::summary;
use cvlm::nondet::{nondet_with, nondet};
use sui::clock::Clock;
use suilend::decimal::Decimal;
use suilend::liquidity_mining::{PoolRewardManager, UserRewardManager};
use suilend::obligation::Obligation;
use suilend::reserve::Reserve;
use suilend::reserve_config::ReserveConfig;
use cvlm::manifest::ghost;
use dummy_pool::obligation;
use suilend::reserve;


public fun cvlm_manifest() {
    // Summaries
    summary(b"reserve_compound_borrow_rate", @suilend, b"reserve", b"compound_borrow_rate");
    summary(
        b"obligation_zero_out_rewards_if_looped",
        @suilend,
        b"obligation",
        b"zero_out_rewards_if_looped",
    );
    summary(b"obligation_log_obligation_data", @suilend, b"obligation", b"log_obligation_data");
    summary(
        b"mining_change_user_reward_manager_share",
        @suilend,
        b"liquidity_mining",
        b"change_user_reward_manager_share",
    );
    ghost(b"reward_managers");
    summary(
        b"obligation_find_or_add_user_reward_manager",
        @suilend,
        b"obligation",
        b"find_or_add_user_reward_manager",
    );

    //summary(b"reserve_borrow_weight", @suilend, b"reserve_config", b"borrow_weight");
    summary(b"reserve_market_value", @suilend, b"reserve", b"market_value");
    summary(b"reserve_market_value_upper_bound", @suilend, b"reserve", b"market_value_upper_bound");
    summary(b"reserve_market_value_lower_bound", @suilend, b"reserve", b"market_value_lower_bound");

    
    ghost(b"deposit_index");
    ghost(b"borrow_index");
    summary(b"obligation_find_borrow_index", @suilend, b"obligation", b"find_borrow_index");
    summary(b"obligation_find_deposit_index", @suilend, b"obligation", b"find_deposit_index");
}

public fun reserve_compound_borrow_rate<DummyPool>(_: &mut Reserve<DummyPool>, _: u64): Decimal {
    let val = nondet_with!(b"Borrow rate", |r| 1 <= r && r < 2);
    suilend::decimal::from(val)
}

public(package) fun obligation_zero_out_rewards_if_looped<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
) {} //noop

public fun mining_change_user_reward_manager_share(
    _pool_reward_manager: &mut PoolRewardManager,
    _user_reward_manager: &mut UserRewardManager,
    _new_share: u64,
    _clock: &Clock,
) {}

public fun obligation_log_obligation_data<P>(_obligation: &Obligation<P>) {} // no-op

public fun reserve_borrow_weight(_config: &ReserveConfig): Decimal {
    suilend::decimal::from(1)
}

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

native fun reward_managers<P>(
    _: &mut Obligation<P>,
    _: &mut PoolRewardManager,
): &mut UserRewardManager;

public fun obligation_find_or_add_user_reward_manager<P>(
    obligation: &mut Obligation<P>,
    pool_reward_manager: &mut PoolRewardManager,
    _clock: &Clock,
): (u64, &mut UserRewardManager) {
    let i = nondet();
    let urm = reward_managers(obligation, pool_reward_manager);
    (i, urm)
}



public fun reserve_market_value<P>(
        _reserve: &Reserve<P>, 
        liquidity_amount: Decimal
    ): Decimal {
       liquidity_amount
    }


public fun reserve_market_value_upper_bound<P>(
        _reserve: &Reserve<P>, 
        liquidity_amount: Decimal
    ): Decimal {
        liquidity_amount
    }

 public fun reserve_market_value_lower_bound<P>(
        _reserve: &Reserve<P>, 
        liquidity_amount: Decimal
    ): Decimal {
       liquidity_amount
    }

