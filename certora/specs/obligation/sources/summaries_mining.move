// Mining summaries
module obligation::summaries_mining;

use cvlm::manifest::summary;
use sui::clock::Clock;
use suilend::liquidity_mining::{PoolRewardManager, UserRewardManager};

public fun cvlm_manifest() {
    // No-op reward share updates: Rewards don't affect the properties.
    summary(
        b"mining_change_user_reward_manager_share",
        @suilend,
        b"liquidity_mining",
        b"change_user_reward_manager_share",
    );
}

/// No-op reward share update.
public fun mining_change_user_reward_manager_share(
    _pool_reward_manager: &mut PoolRewardManager,
    _user_reward_manager: &mut UserRewardManager,
    _new_share: u64,
    _clock: &Clock,
) {}
