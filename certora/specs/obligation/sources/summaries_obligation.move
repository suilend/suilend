// Obligation summaries
module obligation::summaries_obligation;

use cvlm::asserts::cvlm_assume_msg;
use cvlm::manifest::{summary, ghost};
use cvlm::nondet::nondet;
use sui::clock::Clock;
use suilend::liquidity_mining::{PoolRewardManager, UserRewardManager};
use suilend::obligation::Obligation;
use suilend::reserve::Reserve;

public fun cvlm_manifest() {
    // Nondeterministic functions: These functions are abstracted using nondet() or no-ops
    summary(
        b"obligation_zero_out_rewards_if_looped",
        @suilend,
        b"obligation",
        b"zero_out_rewards_if_looped",
    );
    summary(b"obligation_log_obligation_data", @suilend, b"obligation", b"log_obligation_data");

    // Reward manager lookup: Uses ghost functions to simplify reward manager access.
    ghost(b"reward_managers");
    summary(
        b"obligation_find_or_add_user_reward_manager",
        @suilend,
        b"obligation",
        b"find_or_add_user_reward_manager",
    );
}

/// No-op rewards zeroing function.
///
/// This function zeros out rewards for looped positions (where an asset is both borrowed
/// and deposited). For verification purposes, rewards don't affect core properties,
/// so this is abstracted as a no-op.
public(package) fun obligation_zero_out_rewards_if_looped<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
) {}

/// No-op logging function.
public fun obligation_log_obligation_data<P>(_obligation: &Obligation<P>) {}

/// Ghost functions for deposit and borrow index lookup.
native fun deposit_index(ob_id: &UID, reserve_id: &UID): u64;
native fun borrow_index(ob_id: &UID, reserve_id: &UID): u64;

/// Simplified borrow index finder using ghost function.
///
/// Unlike the real implementation which iterates through the borrows vector to find a matching
/// reserve, this uses a ghost function that directly returns the index.
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

/// Simplified deposit index finder using ghost function.
///
/// Unlike the real implementation which iterates through the deposits vector to find a matching
/// reserve, this uses a ghost function that directly returns the index.
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

/// Ghost function returning a nondeterministic user reward manager.
native fun reward_managers<P>(
    _: &mut Obligation<P>,
    _: &mut PoolRewardManager,
): &mut UserRewardManager;

/// Nondeterministic user reward manager lookup.
///
/// Returns an arbitrary index and reward manager using ghost functions. Rewards don't
/// affect the core verification properties, so the exact index is not important.
public fun obligation_find_or_add_user_reward_manager<P>(
    obligation: &mut Obligation<P>,
    pool_reward_manager: &mut PoolRewardManager,
    _clock: &Clock,
): (u64, &mut UserRewardManager) {
    let i = nondet();
    let urm = reward_managers(obligation, pool_reward_manager);
    (i, urm)
}
