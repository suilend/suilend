// Obligation summaries for solvency specs
//
// This module provides simplified or no-op implementations for obligation operations.
// For solvency verification, we only care about reserve accounting (total liquidity,
// borrowed amounts, available balance) and NOT about individual obligation states or health.
// Therefore, most obligation operations are abstracted as no-ops or return nondet values.
// Individual obligation tracking (deposits, borrows, health values) is irrelevant for
// these global reserve invariants, allowing aggressive simplification.
module solvency::summaries_obligation;

use cvlm::manifest::summary;
use cvlm::manifest::ghost;
use cvlm::nondet::nondet;
use cvlm::asserts::cvlm_assume_msg;
use sui::clock::Clock;
use suilend::reserve::Reserve;
use suilend::obligation::Obligation;
use suilend::decimal::Decimal;
use suilend::liquidity_mining::PoolRewardManager;
use suilend::liquidity_mining::UserRewardManager;
use sui::balance::Balance;
use cvlm::ghost::ghost_destroy;

public fun cvlm_manifest() {
    // Prover-friendly deposit/borrow indexing: Uses ghost functions to simplify
    // the search for deposit and borrow indices in the obligation's vectors.
    ghost(b"deposit_index");
    ghost(b"borrow_index");
    summary(b"obligation_find_borrow_index", @suilend, b"obligation", b"find_borrow_index");
    summary(b"obligation_find_deposit_index", @suilend, b"obligation", b"find_deposit_index");

    // Obligation state management: These operations are irrelevant for solvency verification
    // as solvency only depends on reserve-level accounting, not individual obligation states.
    // All operations are no-ops or return nondet values.
    summary(b"obligation_refresh", @suilend, b"obligation", b"refresh");
    summary(b"obligation_deposit", @suilend, b"obligation", b"deposit");
    summary(b"obligation_borrow", @suilend, b"obligation", b"borrow");
    summary(b"obligation_repay", @suilend, b"obligation", b"repay");
    summary(b"obligation_withdraw", @suilend, b"obligation", b"withdraw");
    summary(b"obligation_liquidate", @suilend, b"obligation", b"liquidate");

    // Nondeterministic functions: These functions are abstracted using nondet() as they
    // don't affect solvency (rewards management and logging).
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
}

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

/// Nondeterministic repay that returns an arbitrary repayment amount.
///
/// For solvency verification, the exact repayment amount doesn't matter - only that
/// reserve accounting remains consistent. Returns nondet() to allow any valid repayment.
public fun obligation_repay<DummyPool>(
    _: &mut Obligation<DummyPool>,
    _: &mut Reserve<DummyPool>,
    _: &Clock,
    _: Decimal,
): Decimal {
    nondet()
}

/// No-op refresh function that returns a nondeterministic result.
///
/// For solvency verification, refreshing obligation state (compounding interest, updating
/// health values) is irrelevant as we only care about reserve-level accounting invariants.
public fun obligation_refresh<DummyPool>(
    _: &mut Obligation<DummyPool>,
    _: &mut vector<Reserve<DummyPool>>,
    _: &Clock,
): Option<suilend::obligation::ExistStaleOracles> {
    nondet()
}

/// No-op deposit that ignores the deposit operation.
///
/// For solvency verification, individual obligation deposits are irrelevant - we only
/// verify that reserve liquidity accounting remains correct at the reserve level.
public(package) fun obligation_deposit<P>(
    _obligation: &mut Obligation<P>,
    _reserve: &mut Reserve<P>,
    _clock: &Clock,
    _ctoken_amount: u64,
) {}

/// No-op borrow that ignores the borrow operation.
///
/// For solvency verification, individual obligation borrows are irrelevant - we only
/// verify that reserve borrowed amounts and available liquidity remain correct.
public(package) fun obligation_borrow<P>(
    _obligation: &mut Obligation<P>,
    _reserve: &mut Reserve<P>,
    _clock: &Clock,
    _amount: u64,
) {}

/// Nondeterministic liquidate that returns arbitrary values.
///
/// For solvency verification, liquidation details don't matter - only that reserves
/// maintain correct accounting after the operation. Returns nondet values for
/// withdrawn amount and bonus rate.
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

/// No-op withdraw that destroys stale oracle option.
///
/// For solvency verification, individual obligation withdrawals are irrelevant - we only
/// verify that reserve liquidity accounting remains correct. Destroys the stale_oracles
/// option to satisfy Move's resource handling requirements.
public(package) fun obligation_withdraw<P>(
    _obligation: &mut Obligation<P>,
    _reserve: &mut Reserve<P>,
    _clock: &Clock,
    _ctoken_amount: u64,
    stale_oracles: Option<suilend::obligation::ExistStaleOracles>,
) {
    ghost_destroy(stale_oracles)
}

/// No-op rewards zeroing function.
///
/// Rewards don't affect solvency, so this is a complete no-op.
public(package) fun obligation_zero_out_rewards_if_looped<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
) {}

/// No-op logging function.
public fun obligation_log_obligation_data<P>(_obligation: &Obligation<P>) {}

/// Nondeterministic user reward manager lookup.
///
/// Returns an arbitrary index and reward manager. Rewards don't affect solvency verification.
public fun obligation_find_or_add_user_reward_manager<P>(
    _obligation: &mut Obligation<P>,
    _pool_reward_manager: &mut PoolRewardManager,
    _clock: &Clock,
): (u64, &mut UserRewardManager) {
    let i = nondet();
    let mnrg = vector::borrow_mut(_obligation.user_reward_managers_mut(), i);
    (i, mnrg)
}

/// No-op reward share update.
///
/// Rewards don't affect solvency, so this is a complete no-op.
public fun mining_change_user_reward_manager_share(
    _pool_reward_manager: &mut PoolRewardManager,
    _user_reward_manager: &mut UserRewardManager,
    _new_share: u64,
    _clock: &Clock,
) {}

/// Nondeterministic rewards claim.
///
/// Returns arbitrary reward balance. Rewards don't affect solvency verification.
public(package) fun mining_claim_rewards<T>(
    _pool_reward_manager: &mut PoolRewardManager,
    _user_reward_manager: &mut UserRewardManager,
    _clock: &Clock,
    _reward_index: u64,
): Balance<T> {
    nondet()
}
