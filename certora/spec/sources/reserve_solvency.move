module spec::reserve_solvency;

use cvlm::asserts::{cvlm_assume_msg, cvlm_assert_msg};
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::rule;
use cvlm::nondet::nondet;
use pyth::price_info::PriceInfoObject;
use spec::utils::log;
use sui::balance::Balance;
use sui::clock::Clock;
use sui::coin::TreasuryCap;
use sui_system::sui_system::SuiSystemState;
use suilend::decimal::Decimal;
use suilend::reserve::{Reserve, create_reserve, CToken, LiquidityRequest};
use suilend::reserve_config::ReserveConfig;

public fun cvlm_manifest() {
    // target(@suilend, b"reserve", b"deduct_liquidation_fee");
    // target(@suilend, b"reserve", b"join_fees");
    // target(@suilend, b"reserve", b"update_reserve_config");
    // target(@suilend, b"reserve", b"update_price");
    // target(@suilend, b"reserve", b"compound_interest");
    // target(@suilend, b"reserve", b"simulated_compound_interest");
    // target(@suilend, b"reserve", b"claim_fees");
    // target(@suilend, b"reserve", b"deposit_liquidity_and_mint_ctokens");
    // target(@suilend, b"reserve", b"redeem_ctokens");
    // target(@suilend, b"reserve", b"fulfill_liquidity_request");
    // target(@suilend, b"reserve", b"init_staker");
    // target(@suilend, b"reserve", b"rebalance_staker");
    // target(@suilend, b"reserve", b"unstake_sui_from_staker");
    // target(@suilend, b"reserve", b"borrow_liquidity");
    // target(@suilend, b"reserve", b"repay_liquidity");
    // target(@suilend, b"reserve", b"forgive_debt");
    // target(@suilend, b"reserve", b"deposit_ctokens");
    // target(@suilend, b"reserve", b"withdraw_ctokens");
    // target(@suilend, b"reserve", b"change_price_feed");
    //invoker(b"invoke");

    rule(b"solvency_base");
    rule(b"solvency_step_deduct_liquidation_fee");
    rule(b"solvency_step_join_fees");
    rule(b"solvency_step_update_reserve_config");
    rule(b"solvency_step_update_price");
    rule(b"solvency_step_compound_interest");
    rule(b"solvency_step_claim_fees");
    rule(b"solvency_step_deposit_liquidity_and_mint_ctokens");
    rule(b"solvency_step_redeem_ctokens");
    rule(b"solvency_step_fulfill_liquidity_request");
    rule(b"solvency_step_init_staker");
    rule(b"solvency_step_rebalance_staker");
    rule(b"solvency_step_unstake_sui_from_staker");
    rule(b"solvency_step_borrow_liquidity");
    rule(b"solvency_step_repay_liquidity");
    rule(b"solvency_step_deposit_ctokens");
    rule(b"solvency_step_withdraw_ctokens");
    rule(b"solvency_step_change_price_feed");
}

public enum ReserveInvariant has copy {
    /// Solvency expresses that `reserve.total_supply().floor() >= reserve.ctoken_supply()`
    /// This can be violated by `forgive_debt(..)` if the debt amount to be forgive is larger than
    /// |reserve.total_supply().floor() - reserve.ctoken_supply()|.
    /// We therefore exclude the `forgive_debt(..)`.
    Solvency,
}

/// Requires that the reserve is in a state where the given invariant holds
public fun require_invariant<P>(inv: ReserveInvariant, reserve: &Reserve<P>) {
    match (inv) {
        ReserveInvariant::Solvency => {
            log(&reserve.total_supply().floor());
            log(&reserve.ctoken_supply());
            cvlm_assume_msg(inv.invariant_statement(reserve), b"Require reserve is solvent")
        },
    }
}

/// Asserts that the reserve is in a state where the given invariant holds
public fun assert_invariant<P>(inv: ReserveInvariant, reserve: &Reserve<P>) {
    match (inv) {
        ReserveInvariant::Solvency => {
            log(&reserve.total_supply().floor());
            log(&reserve.ctoken_supply());
            cvlm_assert_msg(inv.invariant_statement(reserve), b"Require reserve is solvent")
        },
    }
}

/// The actual invariant statement for the given invariant
fun invariant_statement<P>(inv: ReserveInvariant, reserve: &Reserve<P>): bool {
    match (inv) {
        ReserveInvariant::Solvency => reserve.total_supply().floor() >= reserve.ctoken_supply(),
    }
}

/// Base case for reserve invariants: constructs an arbitrary reserve and checks the invariant holds
/// before any actions are applied.
public(package) fun reserve_base<P, T>(inv: ReserveInvariant) {
    let lending_market_id: ID = nondet();
    let config: ReserveConfig = nondet();
    let array_index: u64 = nondet();
    let mint_decimals: u8 = nondet();
    let price_info_obj: PriceInfoObject = nondet();
    let clock: Clock = nondet();
    let mut ctx: TxContext = nondet();

    let reserve: Reserve<P> = create_reserve<P, T>(
        lending_market_id,
        config,
        array_index,
        mint_decimals,
        &price_info_obj,
        &clock,
        &mut ctx,
    );
    inv.assert_invariant(&reserve);

    ghost_destroy(reserve);
    ghost_destroy(price_info_obj);
    ghost_destroy(clock);
}

/// Induction step for the reserve invariants: deduct_liquidation_fee.
/// Applies the action to an arbitrary reserve in a state where the invariant holds,
/// and checks that the invariant still holds afterwards.
public fun reserve_step_deduct_liquidation_fee<P, T>(
    inv: ReserveInvariant,
    reserve: &mut Reserve<P>,
) {
    let mut ctokens: Balance<CToken<P, T>> = nondet();

    inv.require_invariant(reserve);
    reserve.deduct_liquidation_fee(&mut ctokens);
    inv.assert_invariant(reserve);

    ghost_destroy(ctokens);
}

/// Induction step for the reserve invariants: join_fees.
/// Applies the action to an arbitrary reserve in a state where the invariant holds,
/// and checks that the invariant still holds afterwards.
public fun reserve_step_join_fees<P, T>(inv: ReserveInvariant, reserve: &mut Reserve<P>) {
    let fees: Balance<T> = nondet();

    inv.require_invariant(reserve);
    reserve.join_fees(fees);
    inv.assert_invariant(reserve);
}

/// Induction step for the reserve invariants: update_reserve_config.
/// Applies the action to an arbitrary reserve in a state where the invariant holds,
/// and checks that the invariant still holds afterwards.
public fun reserve_step_update_reserve_config<P>(inv: ReserveInvariant, reserve: &mut Reserve<P>) {
    let config: ReserveConfig = nondet();

    inv.require_invariant(reserve);
    reserve.update_reserve_config(config);
    inv.assert_invariant(reserve);
}

/// Induction step for the reserve invariants: update_price.
/// Applies the action to an arbitrary reserve in a state where the invariant holds,
/// and checks that the invariant still holds afterwards.
public fun reserve_step_update_price<P>(
    inv: ReserveInvariant,
    reserve: &mut Reserve<P>,
    clock: &Clock,
    price_info_obj: &PriceInfoObject,
) {
    inv.require_invariant(reserve);
    reserve.update_price(clock, price_info_obj);
    inv.assert_invariant(reserve);
}

/// Induction step for the reserve invariants: compound_interest.
/// Applies the action to an arbitrary reserve in a state where the invariant holds,
/// and checks that the invariant still holds afterwards.
public fun reserve_step_compound_interest<P>(inv: ReserveInvariant, reserve: &mut Reserve<P>) {
    let clock = nondet();

    inv.require_invariant(reserve);
    reserve.compound_interest(&clock);
    inv.assert_invariant(reserve);

    ghost_destroy(clock);
}

/// Induction step for the reserve invariants: claim_fees.
/// Applies the action to an arbitrary reserve in a state where the invariant holds,
/// and checks that the invariant still holds afterwards.
public fun reserve_step_claim_fees<P, T>(inv: ReserveInvariant, reserve: &mut Reserve<P>) {
    let mut system_state: SuiSystemState = nondet();
    let mut ctx: TxContext = nondet();

    inv.require_invariant(reserve);
    let (f1, f2): (Balance<CToken<P, T>>, Balance<T>) = reserve.claim_fees(
        &mut system_state,
        &mut ctx,
    );
    inv.assert_invariant(reserve);

    ghost_destroy(f1);
    ghost_destroy(f2);
    ghost_destroy(ctx);
    ghost_destroy(system_state);
}

/// Induction step for the reserve invariants: deposit_liquidity_and_mint_ctokens.
public fun reserve_step_deposit_liquidity_and_mint_ctokens<P, T>(
    inv: ReserveInvariant,
    reserve: &mut Reserve<P>,
) {
    let liquidity: Balance<T> = nondet();
    inv.require_invariant(reserve);
    ghost_destroy(reserve.deposit_liquidity_and_mint_ctokens(liquidity));
    inv.assert_invariant(reserve);
}

/// Induction step for the reserve invariants: redeem_ctokens.
public fun reserve_step_redeem_ctokens<P, T>(inv: ReserveInvariant, reserve: &mut Reserve<P>) {
    let ctokens: Balance<CToken<P, T>> = nondet();
    inv.require_invariant(reserve);
    ghost_destroy(reserve.redeem_ctokens(ctokens));
    inv.assert_invariant(reserve);
}

/// Induction step for the reserve invariants: fulfill_liquidity_request.
public fun reserve_step_fulfill_liquidity_request<P, T>(
    inv: ReserveInvariant,
    reserve: &mut Reserve<P>,
) {
    let request: LiquidityRequest<P, T> = nondet();
    inv.require_invariant(reserve);
    ghost_destroy(reserve.fulfill_liquidity_request(request));
    inv.assert_invariant(reserve);
}

/// Induction step for the reserve invariants: init_staker.
public fun reserve_step_init_staker<P, S: drop>(inv: ReserveInvariant, reserve: &mut Reserve<P>) {
    let treasury_cap: TreasuryCap<S> = nondet();
    let mut ctx: TxContext = nondet();
    inv.require_invariant(reserve);
    reserve.init_staker(treasury_cap, &mut ctx);
    inv.assert_invariant(reserve);
}

/// Induction step for the reserve invariants: rebalance_staker.
public fun reserve_step_rebalance_staker<P>(inv: ReserveInvariant, reserve: &mut Reserve<P>) {
    let mut system_state: SuiSystemState = nondet();
    let mut ctx: TxContext = nondet();
    inv.require_invariant(reserve);
    reserve.rebalance_staker(&mut system_state, &mut ctx);
    inv.assert_invariant(reserve);
    ghost_destroy(system_state);
    ghost_destroy(ctx);
}

/// Induction step for the reserve invariants: unstake_sui_from_staker.
public fun reserve_step_unstake_sui_from_staker<P, T>(
    inv: ReserveInvariant,
    reserve: &mut Reserve<P>,
) {
    let liquidity_request: LiquidityRequest<P, T> = nondet();
    let mut system_state: SuiSystemState = nondet();
    let mut ctx: TxContext = nondet();
    inv.require_invariant(reserve);
    reserve.unstake_sui_from_staker(&liquidity_request, &mut system_state, &mut ctx);
    inv.assert_invariant(reserve);
    ghost_destroy(system_state);
    ghost_destroy(ctx);
    ghost_destroy(liquidity_request);
}

/// Induction step for the reserve invariants: borrow_liquidity.
public fun reserve_step_borrow_liquidity<P, T>(inv: ReserveInvariant, reserve: &mut Reserve<P>) {
    let amount: u64 = nondet();
    inv.require_invariant(reserve);
    let x: LiquidityRequest<P, T> = reserve.borrow_liquidity(amount);
    ghost_destroy(x);
    inv.assert_invariant(reserve);
}

/// Induction step for the reserve invariants: repay_liquidity.
public fun reserve_step_repay_liquidity<P, T>(inv: ReserveInvariant, reserve: &mut Reserve<P>) {
    let liquidity: Balance<T> = nondet();
    let settle_amount: Decimal = nondet();
    inv.require_invariant(reserve);
    reserve.repay_liquidity(liquidity, settle_amount);
    inv.assert_invariant(reserve);
}

/// Induction step for the reserve invariants: forgive_debt.
public fun reserve_step_forgive_debt<P>(inv: ReserveInvariant, reserve: &mut Reserve<P>) {
    let forgive_amount: Decimal = nondet();

    inv.require_invariant(reserve);
    reserve.forgive_debt(forgive_amount);
    inv.assert_invariant(reserve);
}

/// Induction step for the reserve invariants: deposit_ctokens.
public fun reserve_step_deposit_ctokens<P, T>(inv: ReserveInvariant, reserve: &mut Reserve<P>) {
    let ctokens: Balance<CToken<P, T>> = nondet();

    inv.require_invariant(reserve);
    reserve.deposit_ctokens(ctokens);
    inv.assert_invariant(reserve);
}

/// Induction step for the reserve invariants: withdraw_ctokens.
public fun reserve_step_withdraw_ctokens<P, T>(inv: ReserveInvariant, reserve: &mut Reserve<P>) {
    let amount: u64 = nondet();

    inv.require_invariant(reserve);
    let r: Balance<CToken<P, T>> = reserve.withdraw_ctokens(amount);
    ghost_destroy(r);
    inv.assert_invariant(reserve);
}

/// Induction step for the reserve invariants: change_price_feed.
public fun reserve_step_change_price_feed<P>(inv: ReserveInvariant, reserve: &mut Reserve<P>) {
    let price_info_obj: PriceInfoObject = nondet();
    let clock: Clock = nondet();

    inv.require_invariant(reserve);
    reserve.change_price_feed(&price_info_obj, &clock);
    inv.assert_invariant(reserve);

    ghost_destroy(price_info_obj);
    ghost_destroy(clock);
}

/* --- SOLVENCY –-- */

/// Base case for the solvency invariant
public fun solvency_base<P, T>() {
    reserve_base<P, T>(ReserveInvariant::Solvency);
}

/* Induction steps for the solvency invariant */

public fun solvency_step_deduct_liquidation_fee<P, T>(reserve: &mut Reserve<P>) {
    reserve_step_deduct_liquidation_fee<P, T>(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_join_fees<P, T>(reserve: &mut Reserve<P>) {
    reserve_step_join_fees<P, T>(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_update_reserve_config<P>(reserve: &mut Reserve<P>) {
    reserve_step_update_reserve_config(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_update_price<P>(
    reserve: &mut Reserve<P>,
    clock: &Clock,
    price_info_obj: &PriceInfoObject,
) {
    reserve_step_update_price(ReserveInvariant::Solvency, reserve, clock, price_info_obj)
}

public fun solvency_step_compound_interest<P>(reserve: &mut Reserve<P>) {
    reserve_step_compound_interest(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_claim_fees<P, T>(reserve: &mut Reserve<P>) {
    reserve_step_claim_fees<P, T>(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_deposit_liquidity_and_mint_ctokens<P, T>(reserve: &mut Reserve<P>) {
    reserve_step_deposit_liquidity_and_mint_ctokens<P, T>(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_redeem_ctokens<P, T>(reserve: &mut Reserve<P>) {
    reserve_step_redeem_ctokens<P, T>(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_fulfill_liquidity_request<P, T>(reserve: &mut Reserve<P>) {
    reserve_step_fulfill_liquidity_request<P, T>(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_init_staker<P, S: drop>(reserve: &mut Reserve<P>) {
    reserve_step_init_staker<P, S>(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_rebalance_staker<P>(reserve: &mut Reserve<P>) {
    reserve_step_rebalance_staker(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_unstake_sui_from_staker<P, T>(reserve: &mut Reserve<P>) {
    reserve_step_unstake_sui_from_staker<P, T>(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_borrow_liquidity<P, T>(reserve: &mut Reserve<P>) {
    reserve_step_borrow_liquidity<P, T>(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_repay_liquidity<P, T>(reserve: &mut Reserve<P>) {
    reserve_step_repay_liquidity<P, T>(ReserveInvariant::Solvency, reserve)
}


public fun solvency_step_deposit_ctokens<P, T>(reserve: &mut Reserve<P>) {
    reserve_step_deposit_ctokens<P, T>(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_withdraw_ctokens<P, T>(reserve: &mut Reserve<P>) {
    reserve_step_withdraw_ctokens<P, T>(ReserveInvariant::Solvency, reserve)
}

public fun solvency_step_change_price_feed<P>(reserve: &mut Reserve<P>) {
    reserve_step_change_price_feed(ReserveInvariant::Solvency, reserve)
}

/* Below is not working because the invoker cannot take params with generics */

//native fun invoke<P>(target: Function, reserve: &mut Reserve<P>);

// public fun solvency_base<P,T>() {
//   let reserve = create_reser
// }

// The induction steps for the solvency invariant
// public fun solvency_step<P>(reserve: &mut Reserve<P>, target: Function) {
//   let inv = ReserveSolvency{};
//   inv.require_solvency(reserve);
//   invoke(target, reserve);
//   inv.assert_solvency(reserve);
// }
