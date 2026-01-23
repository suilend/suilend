// Mining summaries for obligation health specs
//
// This module provides no-op implementations for all mining and liquidity rewards functionality.
// For the purposes of obligation health verification, we ignore all mining-related operations
// since they do not affect the core health calculations (borrow/deposit values and liquidation logic).
module health::summaries;

use cvlm::ghost::ghost_destroy;
use cvlm::manifest::summary;
use cvlm::nondet::nondet;
use sui::balance::Balance;
use sui::clock::Clock;
use suilend::liquidity_mining::{PoolRewardManager, UserRewardManager};

public fun cvlm_manifest() {
    summary(
        b"change_user_reward_manager_share",
        @suilend,
        b"liquidity_mining",
        b"change_user_reward_manager_share",
    );
    summary(b"claim_rewards", @suilend, b"liquidity_mining", b"claim_rewards");
    summary(b"add_pool_reward", @suilend, b"liquidity_mining", b"add_pool_reward");
    summary(b"cancel_pool_reward", @suilend, b"liquidity_mining", b"cancel_pool_reward");
    summary(b"close_pool_reward", @suilend, b"liquidity_mining", b"close_pool_reward");
}

public fun change_user_reward_manager_share(
    _pool_reward_manager: &mut PoolRewardManager,
    _user_reward_manager: &mut UserRewardManager,
    _new_share: u64,
    _clock: &Clock,
) {}

public(package) fun add_pool_reward<T>(
    _pool_reward_manager: &mut PoolRewardManager,
    rewards: Balance<T>,
    _start_time_ms: u64,
    _end_time_ms: u64,
    _clock: &Clock,
    _ctx: &mut TxContext,
) {
    ghost_destroy(rewards);
}

public(package) fun cancel_pool_reward<T>(
    _pool_reward_manager: &mut PoolRewardManager,
    _index: u64,
    _clock: &Clock,
): Balance<T> {
    nondet()
}

public(package) fun close_pool_reward<T>(
    _pool_reward_manager: &mut PoolRewardManager,
    _index: u64,
    _clock: &Clock,
): Balance<T> {
    nondet()
}

public(package) fun claim_rewards<T>(
    _pool_reward_manager: &mut PoolRewardManager,
    _user_reward_manager: &mut UserRewardManager,
    _clock: &Clock,
    _reward_index: u64,
): Balance<T> {
    nondet()
}

