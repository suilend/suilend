module obligation_spec::obligation_integrity;

use cvlm::asserts::{cvlm_assert, cvlm_assume_msg};
use cvlm::function::Function;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{rule};
use dummy_pool::dummy_pool::DummyPool;
use suilend::obligation::Obligation;
use suilend::reserve::Reserve;
use sui::clock::Clock;
use dummy_pool::obligation::create_obligation;
use cvlm::asserts::cvlm_assert_msg;
use suilend::obligation::compound_debt;
use suilend::obligation::find_borrow_index;
use suilend::decimal::Decimal;
use suilend::obligation::ExistStaleOracles;
use suilend::liquidity_mining::PoolRewardManager;
use obligation_spec::state::liquidatable_implies_unhealthy;


public fun cvlm_manifest() {

    rule(b"obligation_health_base");


    rule(b"obligation_health_step_refresh");
    rule(b"obligation_health_step_deposit");
    rule(b"obligation_health_step_borrow");
    rule(b"obligation_health_step_repay");
    rule(b"obligation_health_step_withdraw");
    rule(b"obligation_health_step_liquidate");
    rule(b"obligation_health_step_forgive");
    rule(b"obligation_health_step_claim_rewards");
}

native fun invoke(target: Function, obligation: &mut Obligation<DummyPool>, reserve: &mut Reserve<DummyPool>, clock: &Clock);


/// The base case for the induction.
/// Asserts that in the initial state, i.e. right after creating a new obligation, it is healthy.
public fun obligation_health_base(
    lending_market_id: ID,
    ctx: &mut TxContext,
) {
    let obligation = create_obligation(lending_market_id, ctx);

    cvlm_assert(obligation.is_healthy());

    ghost_destroy(obligation);
}

/// The step cases for the induction.
/// Asserts that if obligation is in a healthy state, no lending operation can make it unhealthy, unless enough interest is accrued.
public fun obligation_health_step(
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    clock: &Clock,
    target: Function,
) {
    
    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");

    // assume not debt compounds 
    let borrow_index = find_borrow_index(obligation, reserve);
    let borrow = vector::borrow_mut(obligation.borrows_mut(), borrow_index);
    compound_debt(borrow, reserve);


    invoke(target, obligation,  reserve, clock);

    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}


// TODO: Assume freshenss of all reservers in pre-state like done in _refresh.

public fun obligation_health_step_refresh(
    obligation: &mut Obligation<DummyPool>,
    reserves: &mut vector<Reserve<DummyPool>>,
    clock: &Clock,
) { 
    cvlm_assume_msg(reserves.length() <= 3, b"At most three reserves");

    let cur_time_s = clock.timestamp_ms() / 1000;

    // Fresh prices + no interest accrues during the refresh steps
    let mut i = 0;
    while (i < reserves.length()) {
        reserves[i].assert_price_is_fresh(clock);
        cvlm_assume_msg(
            reserves[i].interest_last_update_timestamp_s() == cur_time_s,
            b"No interest accrues during refresh"
        );
        i = i + 1;
    };

    // 1st refresh: bring obligation into a fully refreshed snapshot
    let ret1 = obligation.refresh(reserves, clock);
    ret1.destroy_none();

    cvlm_assume_msg(
        obligation.is_healthy(),
        b"Assume obligation is healthy in refreshed pre-state"
    );

    // 2nd refresh: prove that refreshing a already-refreshed healthy obligation preserves health
    let ret2 = obligation.refresh(reserves, clock);
    ret2.destroy_none();    

    cvlm_assert_msg(
        obligation.is_healthy(),
        b"Assert obligation is healthy in post-state"
    );
}

public fun obligation_health_step_deposit(
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    clock: &Clock,
    ctoken_amount: u64,
) { 
    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");
    reserve.assert_price_is_fresh(clock);
    obligation.deposit(reserve, clock, ctoken_amount);
    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}

public fun obligation_health_step_borrow(
    obligation: &mut Obligation<DummyPool>,
    reserve: &mut Reserve<DummyPool>,
    clock: &Clock,
    amount: u64,
) { 
    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");
    reserve.assert_price_is_fresh(clock);
    obligation.borrow(reserve, clock, amount);
    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}


/// This is a stronger version of what we want to proof:
/// We assume that all interest has be compounded and all prices are fresh for *this particular* reserve.
/// Instead, we would need make sure this holds for *all* reserves.
/// However, calling refresh on a vector or reserves an then repay on a reserve in that list is infeasible.
public fun obligation_health_step_repay(
        obligation: &mut Obligation<DummyPool>,
        reserve: &mut Reserve<DummyPool>,
        clock: &Clock,
        max_repay_amount: Decimal,
){ 
    
    reserve.assert_price_is_fresh(clock);
    
    let borrow = obligation.find_borrow_mut(reserve);
    borrow.compound_debt(reserve);

    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");


    obligation.repay(reserve, clock, max_repay_amount);
    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}

public fun obligation_health_step_withdraw(
        obligation: &mut Obligation<DummyPool>,
        reserve: &mut Reserve<DummyPool>,
        clock: &Clock,
        ctoken_amount: u64,
        stale_oracles: Option<ExistStaleOracles>,
    ) { 
    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");
    reserve.assert_price_is_fresh(clock);
    obligation.withdraw(reserve, clock, ctoken_amount, stale_oracles);
    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}

public fun obligation_health_step_liquidate(
        obligation: &mut Obligation<DummyPool>,
        reserves: &mut vector<Reserve<DummyPool>>,
        repay_reserve_array_index: u64,
        withdraw_reserve_array_index: u64,
        clock: &Clock,
        repay_amount: u64,
    ){ 
    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");
    cvlm_assume_msg(reserves.length() <= 3, b"At most three reserves");

    cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"Require invaraint");
    
    // fresh prices
    let mut i = 0;
    while (i < 4) {
        reserves[i].assert_price_is_fresh(clock);
        i = i+1;
    };        

    obligation.liquidate(reserves, repay_reserve_array_index, withdraw_reserve_array_index, clock, repay_amount);

    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}

public fun obligation_health_step_forgive(
        obligation: &mut Obligation<DummyPool>,
        reserve: &mut Reserve<DummyPool>,
        clock: &Clock,
        max_forgive_amount: Decimal,
    ) { 
    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");
    reserve.assert_price_is_fresh(clock);
    obligation.forgive(reserve, clock, max_forgive_amount);
    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");
}

public fun obligation_health_step_claim_rewards<T>(
        obligation: &mut Obligation<DummyPool>,
        pool_reward_manager: &mut PoolRewardManager,
        clock: &Clock,
        reward_index: u64,
    ) { 
    cvlm_assume_msg(obligation.is_healthy(), b"Assume obligation is healthy in pre-state");
    let rew = obligation.claim_rewards<DummyPool, T>(pool_reward_manager, clock, reward_index);
    cvlm_assert_msg(obligation.is_healthy(), b"Assert obligation is healthy in post-state");

    ghost_destroy(rew);
}