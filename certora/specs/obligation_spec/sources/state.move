module obligation_spec::state;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg, cvlm_assert_msg};
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{rule};
use cvlm::nondet::nondet;
use dummy_pool::dummy_pool::DummyPool;
use dummy_pool::obligation::create_obligation;
use sui::clock::Clock;
use suilend::decimal::{Self};
use suilend::obligation::{Obligation};
use suilend::reserve::{Reserve};
use suilend::reserve_config::open_ltv;
use sui::sui::SUI;

public fun cvlm_manifest() {
    rule(b"liquidatable_implies_unhealthy_step_deposit");
    rule(b"liquidatable_implies_unhealthy_step_borrow");
    rule(b"liquidatable_implies_unhealthy_step_repay"); 
    rule(b"liquidatable_implies_unhealthy_step_withdraw");
    rule(b"liquidatable_implies_unhealthy_step_liquidate");
    rule(b"liquidatable_implies_unhealthy_step_forgive");
    rule(b"liquidatable_implies_unhealthy_step_claim_rewards");

    rule(b"forgivable_only_if_unhealthy_or_debt_step_deposit");
    rule(b"forgivable_only_if_unhealthy_or_debt_step_borrow");
    rule(b"forgivable_only_if_unhealthy_or_debt_step_repay"); 
    rule(b"forgivable_only_if_unhealthy_or_debt_step_withdraw");
    rule(b"forgivable_only_if_unhealthy_or_debt_step_liquidate");
    rule(b"forgivable_only_if_unhealthy_or_debt_step_forgive");
    rule(b"forgivable_only_if_unhealthy_or_debt_step_claim_rewards");

}

public fun weighted_borrow_leq_weighted_borrow_upper_bound(
    obligation: &Obligation<DummyPool>,
): bool {
    let weighted = obligation.weighted_borrowed_value_usd();
    let weighted_ub = obligation.weighted_borrowed_value_upper_bound_usd();
    weighted.le(weighted_ub)
}

public fun allowed_borrow_value_leq_unhealthy_borrow_value(
    obligation: &Obligation<DummyPool>,
): bool {
    let allowed = obligation.allowed_borrow_value_usd();
    let unhealthy = obligation.unhealthy_borrow_value_usd();
    allowed.le(unhealthy)
}

public fun open_ltv_lt_close_ltv(reserve: &Reserve<DummyPool>): bool {
    reserve.config().open_ltv().lt(reserve.config().close_ltv())
}

public fun close_ltv_lt_one(reserve: &Reserve<DummyPool>): bool {
    let one = decimal::from_percent(100);
    reserve.config().close_ltv().lt(one)
}


fun sound_reserve_state(reserve: &Reserve<DummyPool>){
    let one = decimal::from(1);
    let zero = decimal::from(0);
    let open_ltv = reserve.config().open_ltv();
    let close_ltv = reserve.config().close_ltv();
    cvlm_assume_msg(open_ltv.lt(close_ltv), b"");
    cvlm_assume_msg(close_ltv.lt(one), b"");

    // otherwise we get spurious ces due to imprecisions.
    // todo: check if a larger value works (18)
    cvlm_assume_msg(reserve.mint_decimals() <= 5, b"bound decimals");
    
    // prices
    // 0 < lower_bound <= spot <= upper_bound
    cvlm_assume_msg(zero.lt(reserve.price_lower_bound()), b"0 < lb");
    cvlm_assume_msg(reserve.price_lower_bound().le(reserve.price()), b"lb<=p");
    cvlm_assume_msg(reserve.price().le(reserve.price_upper_bound()), b"p<=ub");

}

/* INVARIANT: liquidatable implies unhealthy */

public fun liquidatable_implies_unhealthy_base(lending_market_id: ID, ctx: &mut TxContext) {
    let obligation = create_obligation(lending_market_id, ctx);
    cvlm_assert(liquidatable_implies_unhealthy(&obligation));
    ghost_destroy(obligation);
}

/// If an obligation is liquidatable, then is also unhealthy.
/// In other words, only unhealthy obligations may be liquidated.
public fun liquidatable_implies_unhealthy(obligation: &Obligation<DummyPool>): bool {
    let healthy = obligation.is_healthy();
    let liquidatable = obligation.is_liquidatable();
    // liquidatable -> unhealthy  <==> !liquidatable || unhealthy
    return !liquidatable || !healthy
}

public fun liquidatable_implies_unhealthy_step_deposit(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"");

    // Perform action
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");
    let amount = nondet();
    obligation.deposit(reserve, clock, amount);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(liquidatable_implies_unhealthy(obligation), b"");
}

public fun liquidatable_implies_unhealthy_step_borrow(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"");

    // Perform action
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");
    let amount = nondet();
    obligation.borrow(reserve, clock, amount);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(liquidatable_implies_unhealthy(obligation), b"");
}

public fun liquidatable_implies_unhealthy_step_repay(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"");

    // Perform action
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");
    let amount = nondet();
    obligation.repay(reserve, clock, amount);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(liquidatable_implies_unhealthy(obligation), b"");
}

public fun liquidatable_implies_unhealthy_step_withdraw(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"");

    // Perform action
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");
    let ctoken_amount = nondet();
    let stale_oracles = nondet();
    obligation.withdraw(reserve, clock, ctoken_amount, stale_oracles);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(liquidatable_implies_unhealthy(obligation), b"");
}

public fun liquidatable_implies_unhealthy_step_liquidate(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"");

    // Perform action
    let repay_reserve_array_index = nondet();
    let withdraw_reserve_array_index = nondet();
    cvlm_assume_msg(repay_reserve_array_index < reserves.length(), b"Index in range");
    cvlm_assume_msg(withdraw_reserve_array_index < reserves.length(), b"Index in range");
    cvlm_assume_msg(repay_reserve_array_index != withdraw_reserve_array_index, b"Distinct reserves");
    let repay_amount = nondet();
    
    obligation.liquidate(reserves, repay_reserve_array_index, withdraw_reserve_array_index, clock, repay_amount);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(liquidatable_implies_unhealthy(obligation), b"");
}


public fun liquidatable_implies_unhealthy_step_forgive(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"");

    // Perform action
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");
    let max_forgive_amount = nondet();
    
    obligation.forgive(reserve, clock, max_forgive_amount);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(liquidatable_implies_unhealthy(obligation), b"");
}


public fun liquidatable_implies_unhealthy_step_claim_rewards(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"");

    // Perform action
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");
    
    let mut pool_reward_manager = nondet();
    let reward_index = nondet();
    
    let ret = obligation.claim_rewards<DummyPool, SUI>(&mut pool_reward_manager, clock, reward_index);
    ghost_destroy(ret);
    ghost_destroy(pool_reward_manager);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(liquidatable_implies_unhealthy(obligation), b"");
}

/* INVARIANT: Forgivable implies unhealthy or debt free */

/// If an obligation is forgivable, then it either has no borrows or it is unhealthy.
public fun forgivable_only_if_unhealthy_or_debt_free(obligation: &Obligation<DummyPool>): bool {
    let unhealthy = !obligation.is_healthy();
    let debt_free = obligation.borrows().length() == 0;

    let deposits = obligation.deposits().length();

    !(deposits == 0) || (unhealthy || debt_free)
}

public fun forgivable_only_if_unhealthy_or_debt_base(lending_market_id: ID, ctx: &mut TxContext) {
    let obligation = create_obligation(lending_market_id, ctx);
    cvlm_assert(forgivable_only_if_unhealthy_or_debt(&obligation));
    ghost_destroy(obligation);
}

/// If an obligation is liquidatable, then is also unhealthy.
/// In other words, only unhealthy obligations may be liquidated.
public fun forgivable_only_if_unhealthy_or_debt(obligation: &Obligation<DummyPool>): bool {
    let healthy = obligation.is_healthy();
    let liquidatable = obligation.is_liquidatable();
    // liquidatable -> unhealthy  <==> !liquidatable || unhealthy
    return !liquidatable || !healthy
}

public fun forgivable_only_if_unhealthy_or_debt_step_deposit(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");

    // Perform action
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");
    let amount = nondet();
    obligation.deposit(reserve, clock, amount);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");
}

public fun forgivable_only_if_unhealthy_or_debt_step_borrow(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");

    // Perform action
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");
    let amount = nondet();
    obligation.borrow(reserve, clock, amount);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");
}

public fun forgivable_only_if_unhealthy_or_debt_step_repay(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");

    // Perform action
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");
    let amount = nondet();
    obligation.repay(reserve, clock, amount);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");
}

public fun forgivable_only_if_unhealthy_or_debt_step_withdraw(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");

    // Perform action
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");
    let ctoken_amount = nondet();
    let stale_oracles = nondet();
    obligation.withdraw(reserve, clock, ctoken_amount, stale_oracles);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");
}

public fun forgivable_only_if_unhealthy_or_debt_step_liquidate(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");

    // Perform action
    let repay_reserve_array_index = nondet();
    let withdraw_reserve_array_index = nondet();
    cvlm_assume_msg(repay_reserve_array_index < reserves.length(), b"Index in range");
    cvlm_assume_msg(withdraw_reserve_array_index < reserves.length(), b"Index in range");
    cvlm_assume_msg(repay_reserve_array_index != withdraw_reserve_array_index, b"Distinct reserves");
    let repay_amount = nondet();
    
    obligation.liquidate(reserves, repay_reserve_array_index, withdraw_reserve_array_index, clock, repay_amount);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");
}


public fun forgivable_only_if_unhealthy_or_debt_step_forgive(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");

    // Perform action
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");
    let max_forgive_amount = nondet();
    
    obligation.forgive(reserve, clock, max_forgive_amount);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");
}


public fun forgivable_only_if_unhealthy_or_debt_step_claim_rewards(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) {

    /* Restrict model size */
    let n = 2;
    cvlm_assume_msg(reserves.length() <= n, b"");
    cvlm_assume_msg(obligation.borrows().length() <= n, b"");
    cvlm_assume_msg(obligation.deposits().length() <= n, b"");

    /* Reserve State */
    let mut i = 0;
    while (i < reserves.length()) {
        let reserve = vector::borrow_mut(reserves, i);
        sound_reserve_state(reserve);
        i=i+1;
    };
    
    // Assume fresh state
    obligation.refresh(reserves, clock).destroy_none();

    //  Require invariant in pre state 
    cvlm_assume_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");

    // Perform action
    let i = nondet();
    cvlm_assume_msg(i < reserves.length(), b"");
    let reserve = vector::borrow_mut(reserves, i);
    cvlm_assume_msg(reserve.array_index() == i, b"array_index == position");
    
    let mut pool_reward_manager = nondet();
    let reward_index = nondet();
    
    let ret = obligation.claim_rewards<DummyPool, SUI>(&mut pool_reward_manager, clock, reward_index);
    ghost_destroy(ret);
    ghost_destroy(pool_reward_manager);

    // Assume fresh state again
    obligation.refresh(reserves, clock).destroy_none();

    // Assert invariant in post state 
    cvlm_assert_msg(forgivable_only_if_unhealthy_or_debt(obligation), b"");
}