module staker::fees;

use cvlm::asserts::{cvlm_assert};

use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule};
use dummy_pool::dummy_pool::DummyPool;

use suilend::staker::{Staker};
use cvlm::function::Function;
use sui::coin::TreasuryCap;
use suilend::staker::create_staker;
use cvlm::asserts::cvlm_assume_msg;
use staker::summaries_staking::total_fees;
use cvlm::math_int::MathInt;
use sui::object::id;
use cvlm::nondet::nondet;


public fun cvlm_manifest() {
    // Public mut functions
    target(@dummy_pool, b"staker", b"deposit");
    target(@dummy_pool, b"staker", b"withdraw");
    target(@dummy_pool, b"staker", b"rebalance");
    target(@dummy_pool, b"staker", b"claim_fees");

    invoker(b"invoke");

    rule(b"zero_fee_rates_base");
    rule(b"zero_fee_rates_step");
    
    rule(b"zero_accrued_internal_fees_base");
    rule(b"zero_accrued_internal_fees_step");
    
    rule(b"fees_grow_monotonically");

    
    
}

native fun invoke(target: Function, staker: &mut Staker<DummyPool>);

public fun sound_fee_state<P>(staker: &Staker<P>): bool {
    zero_fee_rates(staker) && zero_accrued_internal_fees(staker)
}

fun zero_fee_rates<P>(staker: &Staker<P>): bool {
     staker.liquid_staking_info().fee_config().redeem_fee_bps() == 0 && 
     staker.liquid_staking_info().fee_config().sui_mint_fee_bps() == 0 &&
     staker.liquid_staking_info().fee_config().spread_fee_bps() == 0
}

fun accrued_internal_fees<P>(staker: &Staker<P>): MathInt {
    *total_fees(id(staker.liquid_staking_info()))
}

fun zero_accrued_internal_fees<P>(staker: &Staker<P>): bool {
    accrued_internal_fees(staker).to_u128() == 0
}


public fun zero_fee_rates_base(
    treasury_cap: TreasuryCap<DummyPool>,
    ctx: &mut TxContext,
) {
    let staker = create_staker<DummyPool>(treasury_cap, ctx);
    cvlm_assert(zero_fee_rates(&staker));
    ghost_destroy(staker);
}

public fun zero_fee_rates_step(staker: &mut Staker<DummyPool>, target: Function) {
    cvlm_assume_msg(zero_fee_rates(staker), b"Assume invariant in pre state");

    invoke(target, staker);

    cvlm_assert(zero_fee_rates(staker))
}


public fun zero_accrued_internal_fees_base(
    treasury_cap: TreasuryCap<DummyPool>,
    ctx: &mut TxContext,
) {
    let id = nondet();
    // This rule is kind of redundant because we do not have initial state axioms for ghosts.
    // Keeping it for completeness.
    cvlm_assume_msg((*total_fees(id)).to_u128() == 0, b"Assume no fees on fresh staker");
    let staker = create_staker<DummyPool>(treasury_cap, ctx);
    cvlm_assume_msg(id(staker.liquid_staking_info()) == id, b"Assume id matches");
    
    cvlm_assert(zero_accrued_internal_fees(&staker));
    ghost_destroy(staker);
}

public fun zero_accrued_internal_fees_step(staker: &mut Staker<DummyPool>, target: Function) {
    cvlm_assume_msg(zero_accrued_internal_fees(staker), b"Assume invariant in pre state");
    cvlm_assume_msg(zero_fee_rates(staker), b"Require invariant");

    invoke(target, staker);

    cvlm_assert(zero_accrued_internal_fees(staker))
}


public fun fees_grow_monotonically(staker: &mut Staker<DummyPool>, target: Function) {
    cvlm_assume_msg(sound_fee_state(staker), b"Correct fee accrual");

    // it is not necessary to assume staker.total_sui_supply() > staker.liabilities() here,
    // underflows will abort anyways
    let fees_pre = staker.total_sui_supply() - staker.liabilities();

    invoke(target, staker);

    let fees_post = staker.total_sui_supply() - staker.liabilities();

    let claimed = target.name() == b"claim_fees";

    cvlm_assert(claimed || fees_post >= fees_pre);
}