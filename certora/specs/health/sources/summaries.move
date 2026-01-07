module health::summaries;

use cvlm::asserts::cvlm_assume_msg;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{summary, ghost};
use cvlm::nondet::{nondet_with, nondet};
use dummy_pool::dummy_pool::DummyPool;
use sui::balance::Balance;
use sui::clock::Clock;
use sui::coin::{TreasuryCap, Coin};
use sui_system::sui_system::SuiSystemState;
use suilend::decimal::{Self, Decimal, min, sub};
use suilend::lending_market::LendingMarket;
use suilend::liquidity_mining::{PoolRewardManager, UserRewardManager};
use suilend::obligation::{Obligation, ExistStaleOracles, Borrow, is_healthy};
use suilend::rate_limiter::RateLimiter;
use suilend::reserve::{Reserve, LiquidityRequest, config, CToken};
use suilend::reserve_config::{isolated, open_ltv, ReserveConfig};

public fun cvlm_manifest() {
    /* obligation summaries */
    ghost(b"debt_factor");
    summary(b"obligation_compound_debt", @suilend, b"obligation", b"compound_debt");
    summary(b"deposit", @suilend, b"obligation", b"deposit");
    summary(b"repay", @suilend, b"obligation", b"repay");
    summary(b"withdraw_unchecked", @suilend, b"obligation", b"withdraw_unchecked");
    summary(b"borrow", @suilend, b"obligation", b"borrow");
    summary(b"obligation_refresh", @suilend, b"obligation", b"refresh");
    // Simpler deposit/borrow indexing
    ghost(b"deposit_index");
    ghost(b"borrow_index");
    summary(b"obligation_find_borrow_index", @suilend, b"obligation", b"find_borrow_index");
    summary(b"obligation_find_deposit_index", @suilend, b"obligation", b"find_deposit_index");
    summary(b"obligation_log_obligation_data", @suilend, b"obligation", b"log_obligation_data");
    // Nondet / noops
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

    /* Reserve Summaries */
    summary(b"reserve_compound_interest", @suilend, b"reserve", b"compound_interest");
    summary(b"reserve_borrow_liquidity", @suilend, b"reserve", b"borrow_liquidity");
    summary(b"reserve_unstake_sui_from_staker", @suilend, b"reserve", b"unstake_sui_from_staker");
    summary(b"reserve_rebalance_staker", @suilend, b"reserve", b"rebalance_staker");
    summary(b"reserve_repay_liquidity", @suilend, b"reserve", b"repay_liquidity");
    summary(b"reserve_deposit_ctokens", @suilend, b"reserve", b"deposit_ctokens");
    summary(b"reserve_init_staker", @suilend, b"reserve", b"init_staker");
    summary(b"reserve_log_reserve_data", @suilend, b"reserve", b"log_reserve_data");
    summary(b"assert_price_is_fresh", @suilend, b"reserve", b"assert_price_is_fresh");

    // Pricing / Market Value: Enabling these (fixing price = 1) simplifies a lot but masks violations
    // https://prover.certora.com/output/8195906/847f354fbfc14a81b6af1e81d8889e97?anonymousKey=5731c150853bb7d2a3f766372ede4bfe392d9a63
    // summary(b"market_value", @suilend, b"reserve", b"market_value");
    // summary(b"market_value_upper_bound", @suilend, b"reserve", b"market_value_upper_bound");
    // summary(b"market_value_lower_bound", @suilend, b"reserve", b"market_value_lower_bound");

    summary(b"reserve_mint_decimals", @suilend, b"reserve", b"mint_decimals");
    summary(b"borrow_weight", @suilend, b"reserve_config", b"borrow_weight");
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

    /* Misc */

    // Ignore the rate limiter
    summary(b"rate_limiter_process_qty", @suilend, b"rate_limiter", b"process_qty");
    // Nondet the max borrow amount
    summary(b"max_borrow_amount", @suilend, b"lending_market", b"max_borrow_amount");

    // Ignore mining and rewards (all nondet no-ops)
    summary(
        b"mining_change_user_reward_manager_share",
        @suilend,
        b"liquidity_mining",
        b"change_user_reward_manager_share",
    );
    summary(b"mining_claim_rewards", @suilend, b"liquidity_mining", b"claim_rewards");
    summary(b"mining_add_pool_reward", @suilend, b"liquidity_mining", b"add_pool_reward");
    summary(b"mining_cancel_pool_reward", @suilend, b"liquidity_mining", b"cancel_pool_reward");
    summary(b"mining_close_pool_reward", @suilend, b"liquidity_mining", b"close_pool_reward");
    summary(
        b"claim_rewards_by_obligation_id",
        @suilend,
        b"lending_market",
        b"claim_rewards_by_obligation_id",
    )
}

const MAX_DEPOSITS: u64 = 1;
const MAX_BORROWS: u64 = 1;

public fun reserve_mint_decimals<P>(_reserve: &Reserve<P>): u8 {
    18
}

public fun borrow_weight(_config: &ReserveConfig): Decimal {
    decimal::from_bps(10000)
}

public fun reserve_compound_borrow_rate(_: &mut Reserve<DummyPool>, _: u64): Decimal {
    let val = nondet_with!(b"Borrow rate", |r| 1 <= r && r < 2);
    suilend::decimal::from(val)
}

public fun reserve_compound_interest<P>(_: &mut Reserve<P>, _: &Clock) {}

public fun reserve_borrow_liquidity<P, T>(
    _reserve: &mut Reserve<P>,
    _amount: u64,
): LiquidityRequest<P, T> {
    let lq: LiquidityRequest<P, T> = nondet();

    let amount: u64 = lq.liquidity_request_amount();
    let fees: u64 = lq.liquidity_request_fee();
    cvlm_assume_msg(amount == _amount + fees, b"");
    lq
}

public fun reserve_unstake_sui_from_staker<P, T>(
    _reserve: &mut Reserve<P>,
    _liquidity_request: &LiquidityRequest<P, T>,
    _system_state: &mut SuiSystemState,
    _ctx: &mut TxContext,
) {}

public fun reserve_rebalance_staker<P>(
    _reserve: &mut Reserve<P>,
    _system_state: &mut SuiSystemState,
    _ctx: &mut TxContext,
) {}

public fun reserve_deposit_ctokens<P, T>(
    _reserve: &mut Reserve<P>,
    ctokens: Balance<CToken<P, T>>,
) {
    ghost_destroy(ctokens);
}

public fun reserve_init_staker<P, S: drop>(
    _reserve: &mut Reserve<P>,
    treasury_cap: TreasuryCap<S>,
    _ctx: &mut TxContext,
) {
    ghost_destroy(treasury_cap)
}

public fun rate_limiter_process_qty(
    _rate_limiter: &mut RateLimiter,
    _cur_time: u64,
    _qty: Decimal,
) {} // noop

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

public fun obligation_refresh<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
): Option<ExistStaleOracles> {
    nondet()
}

public fun max_borrow_amount<P>(
    mut _rate_limiter: RateLimiter,
    _obligation: &Obligation<P>,
    _reserve: &Reserve<P>,
    _clock: &Clock,
): u64 {
    nondet()
}

public fun mining_change_user_reward_manager_share(
    _pool_reward_manager: &mut PoolRewardManager,
    _user_reward_manager: &mut UserRewardManager,
    _new_share: u64,
    _clock: &Clock,
) {}

public(package) fun mining_add_pool_reward<T>(
    _pool_reward_manager: &mut PoolRewardManager,
    rewards: Balance<T>,
    _start_time_ms: u64,
    _end_time_ms: u64,
    _clock: &Clock,
    _ctx: &mut TxContext,
) {
    ghost_destroy(rewards);
}

public(package) fun mining_cancel_pool_reward<T>(
    _pool_reward_manager: &mut PoolRewardManager,
    _index: u64,
    _clock: &Clock,
): Balance<T> {
    nondet()
}

public(package) fun mining_close_pool_reward<T>(
    _pool_reward_manager: &mut PoolRewardManager,
    _index: u64,
    _clock: &Clock,
): Balance<T> {
    nondet()
}

public fun obligation_log_obligation_data<P>(_obligation: &Obligation<P>) {} // no-op

public(package) fun obligation_zero_out_rewards_if_looped<P>(
    _obligation: &mut Obligation<P>,
    _reserves: &mut vector<Reserve<P>>,
    _clock: &Clock,
) {} //noop

public fun obligation_find_or_add_user_reward_manager<P>(
    _obligation: &mut Obligation<P>,
    _pool_reward_manager: &mut PoolRewardManager,
    _clock: &Clock,
): (u64, &mut UserRewardManager) {
    let i = nondet();
    let mnrg = vector::borrow_mut(_obligation.user_reward_managers_mut(), i);
    (i, mnrg)
}

public fun reserve_log_reserve_data<P>(_reserve: &Reserve<P>) {}

public(package) fun mining_claim_rewards<T>(
    _pool_reward_manager: &mut PoolRewardManager,
    _user_reward_manager: &mut UserRewardManager,
    _clock: &Clock,
    _reward_index: u64,
): Balance<T> {
    nondet()
}

public(package) fun claim_rewards_by_obligation_id<P, RewardType>(
    _lending_market: &mut LendingMarket<P>,
    _obligation_id: ID,
    _clock: &Clock,
    _reserve_id: u64,
    _reward_index: u64,
    _is_deposit_reward: bool,
    _fail_if_reward_period_not_over: bool,
    _ctx: &mut TxContext,
): Coin<RewardType> {
    nondet()
}

public fun reserve_repay_liquidity<P, T>(
    _reserve: &mut Reserve<P>,
    liquidity: Balance<T>,
    settle_amount: Decimal,
) {
    cvlm_assume_msg(liquidity.value() == settle_amount.ceil(), b"");
    ghost_destroy(liquidity);
}

/* Obligation summaries */

public native fun debt_factor(): Decimal;
public fun obligation_compound_debt<P>(borrow: &mut Borrow, _reserve: &Reserve<P>) {
    let f = debt_factor();
    let one = decimal::from(1);
    let two = decimal::from(1);
    cvlm_assume_msg(f.ge(one), b">= 1");
    cvlm_assume_msg(f.le(two), b"<= 2");

    if (f.gt(one)) {
        *borrow.borrowed_amount_mut() = borrow.borrowed_amount().mul(f);
    }
}

public fun deposit<P>(
    obligation: &mut Obligation<P>,
    reserve: &mut Reserve<P>,
    clock: &Clock,
    ctoken_amount: u64,
) {
    let deposit_index = obligation.find_or_add_deposit(reserve, clock);
    cvlm_assume_msg(obligation.deposits().length() <= MAX_DEPOSITS, b"");

    let borrow_index = obligation.find_borrow_index(reserve);

    cvlm_assume_msg(borrow_index == obligation.borrows().length(), b"");

    let deposit = &mut obligation.deposits_mut()[deposit_index];

    *deposit.deposited_ctoken_amount_mut() = deposit.deposited_ctoken_amount() + ctoken_amount;

    // Skip intermediate health value update
}

public fun borrow<P>(
    obligation: &mut Obligation<P>,
    reserve: &mut Reserve<P>,
    clock: &Clock,
    amount: u64,
) {
    let borrow_index = obligation.find_or_add_borrow(reserve, clock);
    cvlm_assume_msg(obligation.borrows().length() <= MAX_BORROWS, b"");

    let deposit_index = obligation.find_deposit_index(reserve);
    cvlm_assume_msg(deposit_index == obligation.deposits().length(), b"");

    let borrow = &mut obligation.borrows_mut()[borrow_index];
    *borrow.borrowed_amount_mut() = borrow.borrowed_amount().add(suilend::decimal::from(amount));

    // update only relevant health values
    //let borrow_market_value = reserve.market_value(decimal::from(amount));

    // *borrow.market_value_mut() = borrow.market_value().add(borrow_market_value);
    // *obligation.unweighted_borrowed_value_usd_mut() =
    //     obligation.unweighted_borrowed_value_usd().add(borrow_market_value);
    // *obligation.weighted_borrowed_value_usd_mut() =
    //     obligation
    //         .weighted_borrowed_value_usd()
    //         .add(borrow_market_value.mul(borrow_weight(config(reserve))));

    // weighted_borrowed_value_upper_bound_usd = weighted_borrowed_value_upper_bound_usd(pre) + weighted_borrowed_value_upper_bound_usd(new) <

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

    // skip health updates

    // if (borrow.borrowed_amount().eq(decimal::from(0))) {
    //     let b = vector::remove(obligation.borrows_mut(), borrow_index);
    //     ghost_destroy(b);
    // };

    repay_amount
}

public fun withdraw_unchecked<P>(
    obligation: &mut Obligation<P>,
    reserve: &mut Reserve<P>,
    _clock: &Clock,
    ctoken_amount: u64,
) {
    let deposit_index = obligation.find_deposit_index(reserve);
    cvlm_assume_msg(deposit_index < obligation.deposits().length(), b"Deposit exists");
    let deposit = vector::borrow_mut(obligation.deposits_mut(), deposit_index);

    //let withdraw_market_value = reserve.ctoken_market_value(ctoken_amount);

    *deposit.deposited_ctoken_amount_mut() = deposit.deposited_ctoken_amount() - ctoken_amount;
    // if (deposit.deposited_ctoken_amount() == 0) {
    //     let d = vector::remove(obligation.deposits_mut(), deposit_index);
    //     ghost_destroy(d);
    // };

    // update only relevant health value

    // *deposit.market_value_mut() = deposit.market_value().sub(withdraw_market_value);
    // let new_deposit_value_usd = obligation.deposited_value_usd().sub(withdraw_market_value);
    // *obligation.deposited_value_usd_mut() = new_deposit_value_usd;

    // This value is larger than the "true" value:
    // floor(pre) - floor(new) >= floor(pre - new)
    *obligation.allowed_borrow_value_usd_mut() =
        obligation
            .allowed_borrow_value_usd()
            .sub(reserve
                .ctoken_market_value_lower_bound(ctoken_amount)
                .mul(
                    open_ltv(config(reserve)),
                ));
    // *obligation.unhealthy_borrow_value_usd_mut() =
    //     obligation
    //         .unhealthy_borrow_value_usd()
    //         .sub(withdraw_market_value.mul(close_ltv(config(reserve))));
}

public fun market_value<P>(reserve: &Reserve<P>, liquidity_amount: Decimal): Decimal {
    liquidity_amount.div(decimal::from(std::u64::pow(10, reserve.mint_decimals())))
}

public fun market_value_upper_bound<P>(reserve: &Reserve<P>, liquidity_amount: Decimal): Decimal {
    liquidity_amount.div(decimal::from(std::u64::pow(10, reserve.mint_decimals())))
}

public fun market_value_lower_bound<P>(reserve: &Reserve<P>, liquidity_amount: Decimal): Decimal {
    liquidity_amount.div(decimal::from(std::u64::pow(10, reserve.mint_decimals())))
}

public fun assert_price_is_fresh<P>(_reserve: &Reserve<P>, _clock: &Clock) {}

public fun ctoken_market_value<P>(reserve: &Reserve<P>, ctoken_amount: u64): Decimal {
    // TODO should i floor here?
    let liquidity_amount = decimal::from(ctoken_amount);
    reserve.market_value(liquidity_amount)
}

public fun ctoken_market_value_lower_bound<P>(reserve: &Reserve<P>, ctoken_amount: u64): Decimal {
    // TODO should i floor here?
    let liquidity_amount = decimal::from(ctoken_amount);
    reserve.market_value(liquidity_amount)
}

public fun ctoken_market_value_upper_bound<P>(reserve: &Reserve<P>, ctoken_amount: u64): Decimal {
    // TODO should i floor here?
    let liquidity_amount = decimal::from(ctoken_amount);
    reserve.market_value(liquidity_amount)
}
