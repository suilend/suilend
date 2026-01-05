module liquidation::summaries;

use cvlm::asserts::{cvlm_assume_msg};
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{summary, ghost};
use cvlm::nondet::{nondet_with, nondet};
use sui::balance::{Balance};
use sui::clock::Clock;
use suilend::decimal::{Self, Decimal, div, ceil, mul, lt, floor, min, le};
use suilend::liquidity_mining::{PoolRewardManager, UserRewardManager};
use suilend::obligation::{Obligation, Borrow, Deposit, ExistStaleOracles};
use suilend::reserve::{Reserve, CToken, config};
use suilend::reserve_config::{protocol_liquidation_fee, ReserveConfig};
use suilend::reserve::market_value;
use suilend::reserve::total_supply;
use cvlm::asserts::cvlm_assert;
use suilend::decimal::gt;

public fun cvlm_manifest() {
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
    summary(b"obligation_compound_debt", @suilend, b"obligation", b"compound_debt");

    summary(b"reserve_market_value", @suilend, b"reserve", b"market_value");
    summary(b"reserve_market_value_upper_bound", @suilend, b"reserve", b"market_value_upper_bound");
    summary(b"reserve_market_value_lower_bound", @suilend, b"reserve", b"market_value_lower_bound");
    summary(b"reserve_ctoken_market_value", @suilend, b"reserve", b"ctoken_market_value");
    summary(b"reserve_borrow_weight", @suilend, b"reserve_config", b"borrow_weight");

    summary(b"reserve_mint_decimals", @suilend, b"reserve", b"mint_decimals");
    summary(b"reserve_withdraw_ctokens", @suilend, b"reserve", b"withdraw_ctokens");

    summary(b"reserve_repay_liquidity", @suilend, b"reserve", b"repay_liquidity");
    summary(b"reserve_deduct_liquidation_fee", @suilend, b"reserve", b"deduct_liquidation_fee");

    summary(b"liquidation_amounts", @suilend, b"obligation", b"liquidation_amounts");
}

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

native fun mint_decimals(id: &UID): u8;
public fun reserve_mint_decimals<P>(r: &Reserve<P>): u8 {
    // let id = r.id();
    // let dec = mint_decimals(id);
    // cvlm_assume_msg(dec == 18, b"");
    // dec
    //18
    0
}

fun mv<P>(_reserve: &Reserve<P>, liquidity_amount: Decimal): Decimal {
    //liquidity_amount.div(decimal::from(1000000000))
    liquidity_amount
    //liquidity_amount.div(decimal::from(1000000000000000000))

    //Assume dec is one of the common values to avoid general division
    // let dec = mint_decimals(_reserve.id());
    // cvlm_assume_msg(dec == 6 || dec == 8 || dec == 9, b"common decimals");
    // if (dec == 6) {
    //     liquidity_amount.div(decimal::from(1000000))
    // } else if (dec == 8) {
    //     liquidity_amount.div(decimal::from(100000000))
    // } else {
    //     // dec == 9
    //     liquidity_amount.div(decimal::from(1000000000))
    // }
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

fun liquidation_amounts<P>(
    obligation: &Obligation<P>,
    repay_amount: u64,
    withdraw_reserve: &Reserve<P>,
    repay_reserve: &Reserve<P>,
    borrow: &Borrow,
    deposit: &Deposit,
): (Decimal, u64) {
    // invariant: repay_amount <= borrow.borrowed_amount
    // let repay_amount = if (le(borrow.market_value(), decimal::from(1))) {
    //     // full liquidation
    //     min(
    //         borrow.borrowed_amount(),
    //         decimal::from(repay_amount),
    //     )
    // } else {
        // partial liquidation
        // let max_repay_value = min(
        //     mul(
        //         obligation.weighted_borrowed_value_usd(),
        //         decimal::from_percent(20),
        //     ),
        //     borrow.market_value(),
        // );

    cvlm_assume_msg(gt(borrow.market_value(), decimal::from(1)), b"");

        // // Since weighted_borrowed_value_usd == borrow.market_value(), we can skip the min()
        // let max_repay_value = mul(
        //     obligation.weighted_borrowed_value_usd(),
        //     decimal::from_percent(20),
        // );

        //let max_repay_value = obligation.weighted_borrowed_value_usd();

        // Compute max_repay directly without intermediate percentage
        // This avoids: mul(div(max_repay_value, borrow.market_value), borrow.borrowed_amount)
        // let max_repay = div(
        //     mul(max_repay_value, borrow.borrowed_amount()),
        //     borrow.market_value(),
        // );

        let max_repay = borrow.borrowed_amount();

        // Allow full liquidation
        //let max_repay = borrow.borrowed_amount();

        let repay_amount = min(max_repay, decimal::from(repay_amount));
    //};

    let repay_value = repay_reserve.market_value(repay_amount);

    cvlm_assert(repay_value.le(borrow.market_value()));

    // let bonus = add(
    //     liquidation_bonus(config(withdraw_reserve)),
    //     protocol_liquidation_fee(config(withdraw_reserve)),
    // );

    let withdraw_value = repay_value;
    // mul(
    //     repay_value,
    //     add(decimal::from(1), bonus),
    // );

    // repay amount, but in decimals. called settle amount to keep logic in line with
    // spl-lending
    let final_settle_amount: Decimal;
    let final_withdraw_amount;

    if (lt(deposit.market_value(), withdraw_value)) {
        // Compute final_settle_amount directly without intermediate percentage
        // This avoids: mul(repay_amount, div(deposit.market_value(), withdraw_value))
        final_settle_amount =
            div(
                mul(repay_amount, deposit.market_value()),
                withdraw_value,
            );
        final_withdraw_amount = deposit.deposited_ctoken_amount();
    } else {
        // Compute final_withdraw_amount directly without intermediate percentage
        // This avoids: mul(deposit.deposited_ctoken_amount, div(withdraw_value, deposit.market_value()))
        final_settle_amount = repay_amount;
        final_withdraw_amount =
            floor(
                div(
                    mul(decimal::from(deposit.deposited_ctoken_amount()), withdraw_value),
                    deposit.market_value(),
                ),
            );
    };

    cvlm_assert(final_settle_amount.le(borrow.market_value()));
    cvlm_assert(final_withdraw_amount <= (deposit.market_value().ceil()));

     

    (final_settle_amount, final_withdraw_amount)
}

public fun obligation_refresh<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
): Option<ExistStaleOracles> {
    nondet()
}

public fun reserve_repay_liquidity<P, T>(
    reserve: &mut Reserve<P>,
    liquidity: Balance<T>,
    settle_amount: Decimal,
) {
    ghost_destroy(liquidity);
}

public fun reserve_withdraw_ctokens<P, T>(
    reserve: &mut Reserve<P>,
    amount: u64,
): Balance<CToken<P, T>> {
    let bal: Balance<CToken<P, T>> = nondet();
    cvlm_assume_msg(bal.value() == amount, b"");
    bal
}

public fun reserve_deduct_liquidation_fee<P, T>(
    reserve: &mut Reserve<P>,
    ctokens: &mut Balance<CToken<P, T>>,
): (u64, u64) {
    let pf = protocol_liquidation_fee(config(reserve));
    
    //let bonus = liquidation_bonus(config(reserve));

    // cvlm_assume_msg(pf.eq(decimal::from(0)), b"");
    // cvlm_assume_msg(bonus.eq(decimal::from(0)), b"");
     (0, 0)

    // let bonus = liquidation_bonus(config(reserve));
    // let denom = add(add(decimal::from(1), bonus), pf);

    // let protocol_fee_amount = ceil(mul(div(pf, denom), decimal::from(balance::value(ctokens))));
    // ghost_destroy(balance::split(ctokens, protocol_fee_amount));

    // (protocol_fee_amount, nondet())
}

public fun obligation_compound_debt<P>(_borrow: &mut Borrow, _reserve: &Reserve<P>) {}


public fun reserve_ctoken_market_value<P>(
        reserve: &Reserve<P>, 
        ctoken_amount: u64
    ): Decimal {
        // Original:
        // let liquidity_amount = mul(
        //     decimal::from(ctoken_amount),
        //     ctoken_ratio(reserve)
        // );
        // This is mul(decimal::from(ctoken_amount), div(total_supply(reserve), decimal::from(reserve.ctoken_supply())))
        // -> ctoken_amount * (total_supply/ctoken_supply)
        // This leads to rounding errors
        // Better is: (ctoken_amount * total_supply)/ctoken_supply

        let total_supply = total_supply(reserve);
        let total_ctokens = decimal::from(reserve.ctoken_supply());

        let liquidity_amount = mul(total_supply, decimal::from(ctoken_amount)).div(total_ctokens);

        market_value(reserve, liquidity_amount)
    }