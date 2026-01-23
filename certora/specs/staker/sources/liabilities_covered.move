/// property: Staker Supply Covers Liabilities
/// description: Verifies that the staker's total SUI supply always covers its liabilities,
/// with an additional buffer requirement of at least 1 SUI maintained throughout operations
module staker::liabilities_covered;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule};
use dummy_pool::dummy_pool::DummyPool;
use staker::fees::sound_fee_state;
use sui::coin::TreasuryCap;
use suilend::staker::{Staker, create_staker};

public fun cvlm_manifest() {
    // Public mut functions
    target(@dummy_pool, b"staker", b"deposit");
    target(@dummy_pool, b"staker", b"withdraw");
    target(@dummy_pool, b"staker", b"rebalance");
    target(@dummy_pool, b"staker", b"claim_fees");

    invoker(b"invoke");

    rule(b"supply_covers_liabilities_base");
    rule(b"supply_covers_liabilities_step");

    rule(b"one_sui_in_buffer");
}

native fun invoke(target: Function, staker: &mut Staker<DummyPool>);

/// Returns whether given reserve is solvent, i.e., whether the total supply of assets is equal to or greater than the amount of cTokens.
public fun supply_covers_liabilities<P>(staker: &Staker<P>): bool {
    staker.liabilities() <= staker.total_sui_supply()
}

/// Verifies that newly created stakers have total SUI supply that covers their liabilities
public fun supply_covers_liabilities_base(
    treasury_cap: TreasuryCap<DummyPool>,
    ctx: &mut TxContext,
) {
    let staker = create_staker<DummyPool>(treasury_cap, ctx);
    cvlm_assert(supply_covers_liabilities(&staker));
    ghost_destroy(staker);
}

/// Verifies that staker operations maintain the property that
/// total SUI supply covers all liabilities.
/// This ensures the staker remains solvent through all operations
public fun supply_covers_liabilities_step(staker: &mut Staker<DummyPool>, target: Function) {
    cvlm_assume_msg(sound_fee_state(staker), b"Correct fee accrual");
    cvlm_assume_msg(supply_covers_liabilities(staker), b"Assume invariant in pre state");

    invoke(target, staker);

    cvlm_assert(supply_covers_liabilities(staker))
}

const MIST_PER_SUI: u64 = 1_000_000_000;

/// Verifies that the staker maintains a minimum buffer of at least 1 SUI
/// (total_sui_supply - liabilities >= 1 SUI) throughout all operations.
/// This buffer provides a safety margin beyond basic solvency
public fun one_sui_in_buffer(staker: &mut Staker<DummyPool>, target: Function) {
    cvlm_assume_msg(sound_fee_state(staker), b"Correct fee accrual");
    cvlm_assume_msg(supply_covers_liabilities(staker), b"Require invariant");

    cvlm_assume_msg(
        staker.total_sui_supply() - staker.liabilities() >= MIST_PER_SUI,
        b"At least 1 SUI in buffer",
    );

    invoke(target, staker);

    cvlm_assert(staker.total_sui_supply() - staker.liabilities() >= MIST_PER_SUI);
}
