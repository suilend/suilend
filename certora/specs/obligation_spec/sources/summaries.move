
module obligation_spec::summaries;

use sui::clock::Clock;
use suilend::decimal::Decimal;
use suilend::liquidity_mining::PoolRewardManager;
use suilend::obligation::{Obligation};
use suilend::reserve::Reserve;
use cvlm::nondet::nondet_with;
use cvlm::manifest::summary;
use suilend::liquidity_mining::UserRewardManager;
use suilend::reserve_config::ReserveConfig;

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
    summary(b"reserve_borrow_weight", @suilend, b"reserve_config", b"borrow_weight");
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