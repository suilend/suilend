module liquidation::summaries;

use cvlm::asserts::cvlm_assume_msg;
use cvlm::manifest::{summary, ghost};
use cvlm::nondet::nondet_with;
use sui::clock::Clock;
use suilend::decimal::Decimal;
use suilend::liquidity_mining::{PoolRewardManager, UserRewardManager};
use suilend::obligation::Obligation;
use suilend::reserve::Reserve;
use suilend::obligation::Borrow;
use suilend::obligation::Deposit;
use cvlm::nondet::nondet;
use suilend::obligation::ExistStaleOracles;
use suilend::decimal;


public fun cvlm_manifest() {
    // Obligation Summaries

    summary(
        b"obligation_zero_out_rewards_if_looped",
        @suilend,
        b"obligation",
        b"zero_out_rewards_if_looped",
    );
    // Reserve Summaries
    summary(b"reserve_compound_interest", @suilend, b"reserve", b"compound_interest");
    summary(b"reserve_compound_borrow_rate", @suilend, b"reserve", b"compound_borrow_rate");
    summary(b"reserve_log_reserve_data", @suilend, b"reserve", b"log_reserve_data");

    summary(b"obligation_log_obligation_data", @suilend, b"obligation", b"log_obligation_data");
    summary(b"obligation_refresh", @suilend, b"obligation", b"refresh");

    summary(
        b"mining_change_user_reward_manager_share",
        @suilend,
        b"liquidity_mining",
        b"change_user_reward_manager_share",
    );

    ghost(b"deposit_index");
    ghost(b"borrow_index");
    summary(b"obligation_find_borrow_index", @suilend, b"obligation", b"find_borrow_index");
    summary(b"obligation_find_deposit_index", @suilend, b"obligation", b"find_deposit_index");

    summary(b"reserve_market_value", @suilend, b"reserve", b"market_value");
    summary(b"reserve_market_value_upper_bound", @suilend, b"reserve", b"market_value_upper_bound");
    summary(b"reserve_market_value_lower_bound", @suilend, b"reserve", b"market_value_lower_bound");
    summary(b"reserve_mint_decimals", @suilend, b"reserve", b"mint_decimals");

    //summary(b"liquidation_amounts", @suilend, b"obligation", b"liquidation_amounts");
}

const MINT_DECIMALS: u8 = 9;
const MINT_DECIMALS_POW: u256 = 1000000000;

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

public fun mining_change_user_reward_manager_share(
    _pool_reward_manager: &mut PoolRewardManager,
    _user_reward_manager: &mut UserRewardManager,
    _new_share: u64,
    _clock: &Clock,
) {}

public fun obligation_log_obligation_data<P>(_obligation: &Obligation<P>) {} // no-op

public fun reserve_compound_interest<P>(_: &mut Reserve<P>, _: &Clock) {}

public fun reserve_mint_decimals<P>(_: &Reserve<P>): u8 {
 MINT_DECIMALS
}

public fun reserve_market_value<P>(_reserve: &Reserve<P>, liquidity_amount: Decimal): Decimal {
    let mint_dec = decimal::from_scaled_val(MINT_DECIMALS_POW);
    liquidity_amount.div(mint_dec)
}

public fun reserve_market_value_upper_bound<P>(
    _reserve: &Reserve<P>,
    liquidity_amount: Decimal,
): Decimal {
    let mint_dec = decimal::from_scaled_val(MINT_DECIMALS_POW);
    liquidity_amount.div(mint_dec)
}

public fun reserve_market_value_lower_bound<P>(
    _reserve: &Reserve<P>,
    liquidity_amount: Decimal,
): Decimal {
    let mint_dec = decimal::from_scaled_val(MINT_DECIMALS_POW);
    liquidity_amount.div(mint_dec)
}

public fun reserve_log_reserve_data<P>(_reserve: &Reserve<P>) {}

fun liquidation_amounts<P>(
    obligation: &Obligation<P>,
    repay_amount: u64,
    withdraw_reserve: &Reserve<P>,
    repay_reserve: &Reserve<P>,
    borrow: &Borrow,
    deposit: &Deposit,
): (Decimal, u64) {
    let x = nondet();
    let y = nondet();

    (x, y)

}


public fun obligation_refresh<P>(
        _obligation: &mut Obligation<P>,
        _reserves: &mut vector<Reserve<P>>,
        _clock: &Clock,
    ): Option<ExistStaleOracles> {
        nondet()
    }