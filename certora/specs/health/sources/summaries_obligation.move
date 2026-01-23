// Obligation summaries for health specs
module health::summaries_obligation;

use commons::helper::{max_deposits, max_borrows};
use cvlm::asserts::{cvlm_assume_msg};
use cvlm::manifest::{summary, ghost};
use cvlm::nondet::nondet;
use sui::clock::Clock;
use suilend::decimal::{Self, Decimal, min, sub};
use suilend::liquidity_mining::{PoolRewardManager, UserRewardManager};
use suilend::obligation::{Obligation, ExistStaleOracles, Borrow, is_healthy};
use suilend::reserve::{Reserve, config};
use suilend::reserve_config::{isolated, open_ltv, borrow_weight};

public fun cvlm_manifest() {
    // Debt compounding: Debt is compounded by multiplying the current borrowed amount
    // using a nondeterministic debt factor in the range [1, 2].
    ghost(b"debt_factor");
    summary(b"obligation_compound_debt", @suilend, b"obligation", b"compound_debt");

    // Main entrypoints: For efficiency, the core obligation operations (deposit, borrow, repay, withdraw)
    // are simplified such that they do not perform intermediate health updates.
    // The `refresh` function is summarized to do nothing. Instead, health related values are computed in the specs.
    summary(b"deposit", @suilend, b"obligation", b"deposit");
    summary(b"repay", @suilend, b"obligation", b"repay");
    summary(b"withdraw_unchecked", @suilend, b"obligation", b"withdraw_unchecked");
    summary(b"withdraw", @suilend, b"obligation", b"withdraw");
    summary(b"borrow", @suilend, b"obligation", b"borrow");
    summary(b"obligation_refresh", @suilend, b"obligation", b"refresh");

    // Prover-friendly deposit/borrow indexing: Uses native ghost functions to simplify
    // the search for deposit and borrow indices in the obligation's vectors.
    ghost(b"deposit_index");
    ghost(b"borrow_index");
    summary(b"obligation_find_borrow_index", @suilend, b"obligation", b"find_borrow_index");
    summary(b"obligation_find_deposit_index", @suilend, b"obligation", b"find_deposit_index");

    // Nondeterministic functions: These functions are abstracted using nondet() as they
    // don't affect health calculations (rewards management and logging).
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
    summary(b"obligation_log_obligation_data", @suilend, b"obligation", b"log_obligation_data");
}

/// Ghost function returning a nondeterministic debt factor.
/// This abstracts the actual compound interest calculation from the reserve's cumulative borrow rate.
public native fun debt_factor(): Decimal;

/// Simplified debt compounding that multiplies borrowed amount by a nondet factor.
///
/// Unlike the real implementation which uses `reserve.cumulative_borrow_rate()` and the borrow's
/// `cumulative_borrow_rate` to compute exact compounded interest, this summary uses a
/// nondeterministic factor constrained to [1, 2] to model arbitrary but bounded debt growth.
public fun obligation_compound_debt<P>(borrow: &mut Borrow, _reserve: &Reserve<P>) {
    let f = debt_factor();
    let one = decimal::from(1);
    let two = decimal::from(2);
    cvlm_assume_msg(f.ge(one), b">= 1");
    cvlm_assume_msg(f.le(two), b"<= 2");

    if (f.gt(one)) {
        *borrow.borrowed_amount_mut() = borrow.borrowed_amount().mul(f);
    }
}

/// Simplified deposit that only updates the deposited ctoken amount.
///
/// Unlike the real implementation, this does NOT update health-related values like
/// `deposited_value_usd`, `allowed_borrow_value_usd`, or `unhealthy_borrow_value_usd`.
/// Instead, health values are computed from scratch in the specs when needed.
public fun deposit<P>(
    obligation: &mut Obligation<P>,
    reserve: &mut Reserve<P>,
    clock: &Clock,
    ctoken_amount: u64,
) {
    let deposit_index = obligation.find_or_add_deposit(reserve, clock);
    cvlm_assume_msg(obligation.deposits().length() <= max_deposits(), b"");

    let borrow_index = obligation.find_borrow_index(reserve);

    cvlm_assume_msg(borrow_index == obligation.borrows().length(), b"");

    let deposit = &mut obligation.deposits_mut()[deposit_index];

    *deposit.deposited_ctoken_amount_mut() = deposit.deposited_ctoken_amount() + ctoken_amount;
}

/// Simplified borrow that updates borrowed amount and weighted borrow value upper bound.
///
/// Unlike the real implementation, this does NOT update all health-related values like
/// `unweighted_borrowed_value_usd`, `weighted_borrowed_value_usd`, or `borrow.market_value`.
/// It only updates `weighted_borrowed_value_upper_bound_usd` which is needed for the
/// `is_healthy` check. Other health values are computed from scratch in the specs.
public fun borrow<P>(
    obligation: &mut Obligation<P>,
    reserve: &mut Reserve<P>,
    clock: &Clock,
    amount: u64,
) {
    let borrow_index = obligation.find_or_add_borrow(reserve, clock);
    cvlm_assume_msg(obligation.borrows().length() <= max_borrows(), b"");

    let deposit_index = obligation.find_deposit_index(reserve);
    cvlm_assume_msg(deposit_index == obligation.deposits().length(), b"");

    let borrow = &mut obligation.borrows_mut()[borrow_index];
    *borrow.borrowed_amount_mut() = borrow.borrowed_amount().add(suilend::decimal::from(amount));

    let borrow_market_value_upper_bound = reserve.market_value_upper_bound(
        decimal::from(amount),
    );
    *obligation.weighted_borrowed_value_upper_bound_usd_mut() =
        obligation
            .weighted_borrowed_value_upper_bound_usd()
            .add(borrow_market_value_upper_bound.mul(borrow_weight(config(reserve))));

    assert!(is_healthy(obligation));

    if (isolated(config(reserve)) || obligation.borrowing_isolated_asset()) {
        assert!(obligation.borrows().length() == 1);
    };
}

/// Simplified repay that compounds debt and reduces borrowed amount.
///
/// Unlike the real implementation, this does NOT update health-related values like
/// `unweighted_borrowed_value_usd`, `weighted_borrowed_value_usd`,
/// `weighted_borrowed_value_upper_bound_usd`, or `borrow.market_value`.
/// Instead, health values are computed from scratch in the specs when needed.
public fun repay<P>(
    obligation: &mut Obligation<P>,
    reserve: &mut Reserve<P>,
    _clock: &Clock,
    max_repay_amount: Decimal,
): Decimal {
    let borrow_index = obligation.find_borrow_index(reserve);
    cvlm_assume_msg(borrow_index < obligation.borrows().length(), b"Borrow exists");
    let borrow = vector::borrow_mut(obligation.borrows_mut(), borrow_index);

    borrow.compound_debt(reserve);

    let repay_amount = min(max_repay_amount, borrow.borrowed_amount());

    *borrow.borrowed_amount_mut() = borrow.borrowed_amount().sub(repay_amount);
    repay_amount
}

/// Simplified withdraw that updates deposited ctoken amount and checks health.
///
/// Unlike the real implementation, this skips the stale oracle conditional logic by assuming
/// no stale oracles exist (via destroy_none()). This is safe because refresh() is already
/// summarized to return nondet, and oracle freshness is controlled in the test setup.
/// The function still performs the critical health check that other rules depend on.
public fun withdraw<P>(
    obligation: &mut Obligation<P>,
    reserve: &mut Reserve<P>,
    clock: &Clock,
    ctoken_amount: u64,
    stale_oracles: Option<ExistStaleOracles>,
) {
    stale_oracles.destroy_none();
    withdraw_unchecked(obligation, reserve, clock, ctoken_amount);
    assert!(is_healthy(obligation));
}

/// Simplified withdraw that updates deposited ctoken amount and allowed borrow value.
///
/// Unlike the real implementation, this does NOT update all health-related values like
/// `deposited_value_usd`, `unhealthy_borrow_value_usd`, or `deposit.market_value`.
/// It only updates `allowed_borrow_value_usd` which is needed for health checks.
/// Other health values are computed from scratch in the specs when needed.
public fun withdraw_unchecked<P>(
    obligation: &mut Obligation<P>,
    reserve: &mut Reserve<P>,
    _clock: &Clock,
    ctoken_amount: u64,
) {
    let deposit_index = obligation.find_deposit_index(reserve);
    cvlm_assume_msg(deposit_index < obligation.deposits().length(), b"Deposit exists");
    let deposit = vector::borrow_mut(obligation.deposits_mut(), deposit_index);

    *deposit.deposited_ctoken_amount_mut() = deposit.deposited_ctoken_amount() - ctoken_amount;

    *obligation.allowed_borrow_value_usd_mut() =
        obligation
            .allowed_borrow_value_usd()
            .sub(reserve
                .ctoken_market_value_lower_bound(ctoken_amount)
                .mul(
                    open_ltv(config(reserve)),
                ));
}

/// No-op refresh function that returns a nondeterministic result.
///
/// This summary does nothing. Health values are instead computed from scratch in the specs
/// when needed, making the refresh operation unnecessary for verification purposes.
public fun obligation_refresh<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
): Option<ExistStaleOracles> {
    nondet()
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
/// reserve, this uses a native ghost function that directly returns the index.
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

public fun obligation_find_or_add_user_reward_manager<P>(
    _obligation: &mut Obligation<P>,
    _pool_reward_manager: &mut PoolRewardManager,
    _clock: &Clock,
): (u64, &mut UserRewardManager) {
    let i = nondet();
    let mnrg = vector::borrow_mut(_obligation.user_reward_managers_mut(), i);
    (i, mnrg)
}

public(package) fun obligation_zero_out_rewards_if_looped<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
) {} //noop

public fun obligation_log_obligation_data<P>(_obligation: &Obligation<P>) {} // no-op
