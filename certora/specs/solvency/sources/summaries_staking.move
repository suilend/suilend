// Staking summaries for solvency specs
//
// Most staker internal operations are simplified, but deposit tracking is maintained
// via ghost state to ensure correct liquidity accounting.
module solvency::summaries_staking;

use cvlm::manifest::summary;
use cvlm::manifest::ghost;
use cvlm::ghost::ghost_destroy;
use cvlm::nondet::nondet;
use sui::balance::Balance;
use sui::sui::SUI;
use sui_system::sui_system::SuiSystemState;
use suilend::staker::Staker;

public fun cvlm_manifest() {
    // Staking operations: Simplified implementations that track staked amounts via ghost state
    // while abstracting the actual Sui system interactions.
    summary(b"staker_deposit", @suilend, b"staker", b"deposit");
    summary(b"staker_rebalance", @suilend, b"staker", b"rebalance");
    summary(b"staker_withdraw", @suilend, b"staker", b"withdraw");
    summary(b"staker_claim_fees", @suilend, b"staker", b"claim_fees");

    // Ghost state for tracking total staked SUI amount across all stakers.
    ghost(b"staked_sui");
}

/// Ghost function tracking total staked SUI across all stakers.
///
/// Returns a mutable reference to allow tracking staked amount changes.
public native fun staked_sui(): &mut u64;

/// Simplified staker deposit that tracks the staked amount via ghost state.
///
/// Unlike the real implementation which stakes SUI with validators, this summary:
/// 1. Updates the ghost staked_sui counter to reflect the deposit
/// 2. Destroys the deposited balance to satisfy Move's resource handling
///
/// This tracking is important for solvency because staked SUI is part of the reserve's
/// total assets (available_amount + staked_amount = total_liquidity).
public(package) fun staker_deposit<P>(_staker: &mut Staker<P>, sui: Balance<SUI>) {
    let v = sui.value();

    let staked_pre = staked_sui();
    *staked_pre = *staked_pre + v;

    ghost_destroy(sui);
}

/// No-op staker rebalance.
///
/// Rebalancing between validators doesn't affect total staked amount or solvency,
/// so this is simplified to a no-op.
public(package) fun staker_rebalance<P: drop>(
    _staker: &mut Staker<P>,
    _system_state: &mut SuiSystemState,
    _ctx: &mut TxContext,
) {}

/// Nondeterministic staker withdrawal.
///
/// Returns an arbitrary SUI balance. The exact withdrawal mechanics are abstracted
/// since solvency verification focuses on reserve-level liquidity totals rather than
/// the specific staking pool management.
public(package) fun staker_withdraw<P: drop>(
    _staker: &mut Staker<P>,
    _withdraw_amount: u64,
    _system_state: &mut SuiSystemState,
    _ctx: &mut TxContext,
): Balance<SUI> {
    nondet()
}

/// Nondeterministic fee claim.
///
/// Returns an arbitrary SUI balance representing staking rewards. While fees affect
/// total reserve value, the exact staking reward calculation is abstracted for
/// simplification in solvency verification.
public(package) fun staker_claim_fees<P: drop>(
    _staker: &mut Staker<P>,
    _system_state: &mut SuiSystemState,
    _ctx: &mut TxContext,
): Balance<SUI> {
    nondet()
}
