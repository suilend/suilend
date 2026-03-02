module liquidation::summaries;

use commons::helper::one;
use cvlm::asserts::{cvlm_assume_msg, cvlm_assert};
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{summary, ghost};
use cvlm::nondet::{nondet_with, nondet};
use sui::balance::Balance;
use sui::clock::Clock;
use suilend::decimal::{Self, Decimal, min};
use suilend::liquidity_mining::{PoolRewardManager, UserRewardManager};
use suilend::obligation::{Obligation, Borrow, ExistStaleOracles};
use suilend::reserve::{Reserve, CToken, market_value};
use suilend::reserve_config::ReserveConfig;

public fun cvlm_manifest() {
    /* Obligation Summaries */

    summary(b"obligation_log_obligation_data", @suilend, b"obligation", b"log_obligation_data");
    summary(b"obligation_refresh", @suilend, b"obligation", b"refresh");

    ghost(b"deposit_index");
    ghost(b"borrow_index");
    summary(b"obligation_find_borrow_index", @suilend, b"obligation", b"find_borrow_index");
    summary(b"obligation_find_deposit_index", @suilend, b"obligation", b"find_deposit_index");
    summary(b"obligation_compound_debt", @suilend, b"obligation", b"compound_debt");
    summary(b"obligation_repay", @suilend, b"obligation", b"repay");
    summary(b"obligation_withdraw_unchecked", @suilend, b"obligation", b"withdraw_unchecked");

    summary(
        b"obligation_zero_out_rewards_if_looped",
        @suilend,
        b"obligation",
        b"zero_out_rewards_if_looped",
    );
    summary(
        b"mining_change_user_reward_manager_share",
        @suilend,
        b"liquidity_mining",
        b"change_user_reward_manager_share",
    );

    /*  Reserve Summaries */
    summary(b"reserve_compound_interest", @suilend, b"reserve", b"compound_interest");
    summary(b"reserve_compound_borrow_rate", @suilend, b"reserve", b"compound_borrow_rate");
    summary(b"reserve_log_reserve_data", @suilend, b"reserve", b"log_reserve_data");
    summary(b"reserve_borrow_weight", @suilend, b"reserve_config", b"borrow_weight");
    summary(b"reserve_mint_decimals", @suilend, b"reserve", b"mint_decimals");
    summary(b"reserve_withdraw_ctokens", @suilend, b"reserve", b"withdraw_ctokens");
    summary(b"reserve_repay_liquidity", @suilend, b"reserve", b"repay_liquidity");
    summary(b"ctoken_ratio", @suilend, b"reserve", b"ctoken_ratio");

    summary(b"reserve_market_value", @suilend, b"reserve", b"market_value");
    summary(b"reserve_market_value_upper_bound", @suilend, b"reserve", b"market_value_upper_bound");
    summary(b"reserve_market_value_lower_bound", @suilend, b"reserve", b"market_value_lower_bound");
    summary(b"ctoken_market_value", @suilend, b"reserve", b"ctoken_market_value");
    summary(
        b"ctoken_market_value_lower_bound",
        @suilend,
        b"reserve",
        b"ctoken_market_value_lower_bound",
    );
    summary(
        b"ctoken_market_value_upper_bound",
        @suilend,
        b"reserve",
        b"ctoken_market_value_upper_bound",
    );
}

public fun reserve_mint_decimals<P>(_: &Reserve<P>): u8 { 0 }

public(package) fun obligation_zero_out_rewards_if_looped<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
) {} //noop

public fun reserve_compound_borrow_rate<DummyPool>(_: &mut Reserve<DummyPool>, _: u64): Decimal {
    let val = nondet_with!(b"Borrow rate", |r| 1 <= r && r < 2);
    suilend::decimal::from(val)
}

native fun deposit_index(ob_id: &UID, reserve_id: &UID): u64;
native fun borrow_index(ob_id: &UID, reserve_id: &UID): u64;

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

public fun reserve_borrow_weight(_config: &ReserveConfig): Decimal {
    suilend::decimal::from(1)
}

public fun mining_change_user_reward_manager_share(
    _pool_reward_manager: &mut PoolRewardManager,
    _user_reward_manager: &mut UserRewardManager,
    _new_share: u64,
    _clock: &Clock,
) {}

public fun obligation_log_obligation_data<P>(_obligation: &Obligation<P>) {} // no-op

public fun reserve_compound_interest<P>(_: &mut Reserve<P>, _: &Clock) {}

fun mv<P>(r: &Reserve<P>, liquidity_amount: Decimal): Decimal {
    cvlm_assert(r.mint_decimals() == 0);
    liquidity_amount
}

public fun reserve_market_value<P>(_reserve: &Reserve<P>, liquidity_amount: Decimal): Decimal {
    mv(_reserve, liquidity_amount)
}

public fun reserve_market_value_upper_bound<P>(
    _reserve: &Reserve<P>,
    liquidity_amount: Decimal,
): Decimal {
    mv(_reserve, liquidity_amount)
}

public fun reserve_market_value_lower_bound<P>(
    _reserve: &Reserve<P>,
    liquidity_amount: Decimal,
): Decimal {
    mv(_reserve, liquidity_amount)
}

public fun reserve_log_reserve_data<P>(_reserve: &Reserve<P>) {}

public fun obligation_refresh<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
): Option<ExistStaleOracles> {
    nondet()
}

public fun reserve_repay_liquidity<P, T>(
    _reserve: &mut Reserve<P>,
    liquidity: Balance<T>,
    _settle_amount: Decimal,
) {
    ghost_destroy(liquidity);
}

public fun reserve_withdraw_ctokens<P, T>(
    _reserve: &mut Reserve<P>,
    amount: u64,
): Balance<CToken<P, T>> {
    let bal: Balance<CToken<P, T>> = nondet();
    cvlm_assume_msg(bal.value() == amount, b"");
    bal
}

// no nothing
public fun obligation_compound_debt<P>(_borrow: &mut Borrow, _reserve: &Reserve<P>) {}

public fun obligation_repay<P>(
    obligation: &mut Obligation<P>,
    reserve: &mut Reserve<P>,
    _clock: &Clock,
    max_repay_amount: Decimal,
): Decimal {
    let borrow_index = obligation.find_borrow_index(reserve);
    cvlm_assert(borrow_index < obligation.borrows().length()); // sanity
    let borrow = &mut obligation.borrows_mut()[borrow_index];
    let repay_amount = min(max_repay_amount, borrow.borrowed_amount());
    *(borrow.borrowed_amount_mut()) = borrow.borrowed_amount().sub(repay_amount);
    repay_amount
}

public fun obligation_withdraw_unchecked<P>(
    obligation: &mut Obligation<P>,
    reserve: &mut Reserve<P>,
    _clock: &Clock,
    ctoken_amount: u64,
) {
    let deposit_index = obligation.find_deposit_index(reserve);
    cvlm_assert(deposit_index < obligation.deposits().length()); // sanity
    let deposit = &mut obligation.deposits_mut()[deposit_index];
    let new_deposited_amount = deposit.deposited_ctoken_amount() - ctoken_amount;
    *deposit.deposited_ctoken_amount_mut() = new_deposited_amount;
}

public fun assert_price_is_fresh<P>(_reserve: &Reserve<P>, _clock: &Clock) {}

public fun ctoken_market_value<P>(reserve: &Reserve<P>, ctoken_amount: u64): Decimal {
    cvlm_assert(reserve.ctoken_ratio().eq(decimal::from(1)));
    let liquidity_amount = decimal::from(ctoken_amount);
    reserve.market_value(liquidity_amount)
}

public fun ctoken_market_value_lower_bound<P>(reserve: &Reserve<P>, ctoken_amount: u64): Decimal {
    cvlm_assert(reserve.ctoken_ratio().eq(decimal::from(1)));
    let liquidity_amount = decimal::from(ctoken_amount);
    reserve.market_value_lower_bound(liquidity_amount)
}

public fun ctoken_market_value_upper_bound<P>(reserve: &Reserve<P>, ctoken_amount: u64): Decimal {
    cvlm_assert(reserve.ctoken_ratio().eq(decimal::from(1)));
    let liquidity_amount = decimal::from(ctoken_amount);
    reserve.market_value_upper_bound(liquidity_amount)
}

public fun ctoken_ratio<P>(_reserve: &Reserve<P>): Decimal {
    one()
}
