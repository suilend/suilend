module staker::liabilities_covered;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule};
use dummy_pool::dummy_pool::DummyPool;
use sui::coin::TreasuryCap;
use suilend::staker::{Staker, create_staker};
use staker::fees::sound_fee_state;


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

public fun supply_covers_liabilities_base(
    treasury_cap: TreasuryCap<DummyPool>,
    ctx: &mut TxContext,
) {
    let staker = create_staker<DummyPool>(treasury_cap, ctx);
    cvlm_assert(supply_covers_liabilities(&staker));
    ghost_destroy(staker);
}

public fun supply_covers_liabilities_step(staker: &mut Staker<DummyPool>, target: Function) {
    cvlm_assume_msg(sound_fee_state(staker), b"Correct fee accrual");
    cvlm_assume_msg(supply_covers_liabilities(staker), b"Assume invariant in pre state");

    invoke(target, staker);

    cvlm_assert(supply_covers_liabilities(staker))
}


const MIST_PER_SUI: u64 = 1_000_000_000;

public fun one_sui_in_buffer(staker: &mut Staker<DummyPool>, target: Function) {
    cvlm_assume_msg(sound_fee_state(staker), b"Correct fee accrual");
    cvlm_assume_msg(supply_covers_liabilities(staker), b"Require invariant");

    cvlm_assume_msg(staker.total_sui_supply() - staker.liabilities() >= MIST_PER_SUI, b"At least 1 SUI in buffer");

    invoke(target, staker);

    cvlm_assert(staker.total_sui_supply() - staker.liabilities() >= MIST_PER_SUI);
}
