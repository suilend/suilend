module staker::summaries_staking;

use cvlm::asserts::cvlm_assume_msg;
use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{summary, ghost};
use cvlm::math_int::{Self, MathInt};
use cvlm::nondet::nondet;
use liquid_staking::liquid_staking::{LiquidStakingInfo, AdminCap};
use sui::coin::Coin;
use sui::object::id;
use sui::sui::SUI;
use sui_system::sui_system::SuiSystemState;

public fun cvlm_manifest() {
    ghost(b"total_sui");
    ghost(b"total_lst");
    ghost(b"last_refresh");
    ghost(b"total_fees");

    summary(b"total_sui_supply", @liquid_staking, b"liquid_staking", b"total_sui_supply");
    summary(b"total_lst_supply", @liquid_staking, b"liquid_staking", b"total_lst_supply");
    summary(b"refresh", @liquid_staking, b"liquid_staking", b"refresh");
    summary(
        b"increase_validator_stake",
        @liquid_staking,
        b"liquid_staking",
        b"increase_validator_stake",
    );
    summary(b"mint", @liquid_staking, b"liquid_staking", b"mint");
    summary(b"redeem", @liquid_staking, b"liquid_staking", b"redeem");
}

const MAX_BPS: u128 = 10_000;

public native fun total_fees(lsi: ID): &mut MathInt;

public native fun total_sui(lsi: ID): &mut MathInt;
public fun total_sui_supply<P>(lsi: &LiquidStakingInfo<P>): u64 {
    (*total_sui(id(lsi))).to_u64()
}

public native fun total_lst(lsi: ID): &mut MathInt;
public fun total_lst_supply<P>(lsi: &LiquidStakingInfo<P>): u64 {
    (*total_lst(id(lsi))).to_u64()
}

/// The latest epoch for which refresh was called.
public native fun last_refresh<P>(lsi: &LiquidStakingInfo<P>): &mut u64;

/// Refreshes the total sui supply by applying the exchange rate.
/// This is simplified by increasing the total sui supply by a nondet factor in [1,2].
/// This factor is only applied once per epoch.
///
/// Over-approximation: The real implementation increases supply based on staking rewards
/// (typically 0.01-0.05% per epoch), but we allow up to 100% increase per epoch.
public fun refresh<P>(
    lsi: &mut LiquidStakingInfo<P>,
    _system_state: &mut SuiSystemState,
    ctx: &mut TxContext,
): bool {
    let id = id(lsi);
    let epoch = ctx.epoch();
    let last_refresh = last_refresh(lsi);
    cvlm_assume_msg(epoch >= *last_refresh, b"Not going back in time");
    if (epoch > *last_refresh) {
        let supply = total_sui(id);
        let old_supply = *supply;
        let new_supply: MathInt = nondet();

        let two = math_int::from_u8(2);
        // old_supply <= new_supply < 2*old_supply
        cvlm_assume_msg(old_supply.le(new_supply), b"Positive exchange rate");
        cvlm_assume_msg(new_supply.le(old_supply.mul(two)), b"Bounded exchange rate");

        let diff = new_supply.sub(old_supply).to_u128();
        let fee_rate = lsi.fee_config().spread_fee_bps() as u128;
        cvlm_assume_msg(fee_rate <= MAX_BPS, b"Sound fees");

        let spread_fee = math_int::from_u128((diff*fee_rate)/10_000);
        *total_fees(id) = (*total_fees(id)).add(spread_fee);

        // subtract fees
        *supply = new_supply.sub(spread_fee);

        *last_refresh = epoch;
        true
    } else {
        false
    }
}

/// Mints LST coins worth the given SUI, using the underlying SUI to LST ratio.
/// Performs a refresh before, appreciating the LST value.
/// Increases both the total SUI and total LST supply accordingly.
///
/// Models mint fees that are collected by the protocol.
public fun mint<P: drop>(
    lsi: &mut LiquidStakingInfo<P>,
    system_state: &mut SuiSystemState,
    sui: Coin<SUI>,
    ctx: &mut TxContext,
): Coin<P> {
    refresh(lsi, system_state, ctx);
    let id = id(lsi);
    let lsts_pre = *total_lst(id);
    let sui_pre = *total_sui(id);
    // Assuming sui_pre >= lsts_pre for solvency. The real system allows the exchange rate
    // to vary, but this assumption is safe for verification purposes.
    cvlm_assume_msg((sui_pre).ge(lsts_pre), b"Solvency");

    let sui_val = math_int::from_u64(sui.value());

    // Calculate and collect mint fee
    let mint_fee_rate = lsi.fee_config().sui_mint_fee_bps() as u128;
    cvlm_assume_msg(mint_fee_rate <= MAX_BPS, b"Sound fees");
    let mint_fee_amount = ((sui_val.to_u128() * mint_fee_rate) / 10_000);

    let mint_fee = math_int::from_u128(mint_fee_amount);

    *total_fees(id) = (*total_fees(id)).add(mint_fee);

    // Mint LST based on SUI amount after fees
    let sui_after_fee = sui_val.sub(mint_fee);
    let to_mint = lsts_pre.mul(sui_after_fee).div(sui_pre);

    let coin: Coin<P> = nondet();
    cvlm_assume_msg(coin.value() == to_mint.to_u64(), b"Correct value");

    *total_lst(id) = lsts_pre.add(to_mint);
    *total_sui(id) = sui_pre.add(sui_after_fee);

    ghost_destroy(sui);
    coin
}

/// Redeems LST coins and returns the SUI amount worth, using the underlying SUI to LST ratio.
/// Performs a refresh before, appreciating the LST value.
/// Decreases both the total SUI and total LST supply accordingly.
///
/// Models redemption fees that are collected by the protocol.
public fun redeem<P: drop>(
    lsi: &mut LiquidStakingInfo<P>,
    lst: Coin<P>,
    system_state: &mut SuiSystemState,
    ctx: &mut TxContext,
): Coin<SUI> {
    refresh(lsi, system_state, ctx);
    let id = id(lsi);
    let lsts_pre = *total_lst(id);
    let sui_pre = *total_sui(id);
    // Assuming sui_pre > lsts_pre for solvency (stricter than mint which uses >=).
    // This ensures there's always sufficient SUI backing for redemptions.
    cvlm_assume_msg((sui_pre).gt(lsts_pre), b"Solvency");

    let lst_val = math_int::from_u64(lst.value());
    cvlm_assume_msg(lst_val.le(lsts_pre), b"Cannot redeem more than exists");

    let to_redeem = sui_pre.mul(lst_val).div(lsts_pre);

    // Calculate and collect redeem fee
    let redeem_fee_rate = (lsi.fee_config().redeem_fee_bps() as u128);
    cvlm_assume_msg(redeem_fee_rate <= MAX_BPS, b"Sound fees");
    let redeem_fee_amount = ((to_redeem.to_u128() * redeem_fee_rate) / 10_000);
    let redeem_fee = math_int::from_u128(redeem_fee_amount);
    *total_fees(id) = (*total_fees(id)).add(redeem_fee);

    // Return SUI amount after fees
    let sui_after_fee = to_redeem.sub(redeem_fee);

    let coin: Coin<SUI> = nondet();
    cvlm_assume_msg(coin.value() == sui_after_fee.to_u64(), b"Correct value");

    *total_lst(id) = lsts_pre.sub(lst_val);
    *total_sui(id) = sui_pre.sub(to_redeem);

    ghost_destroy(lst);
    coin
}

/// No-op: We consider that all SUI deposited using `mint` to be staked.
/// Returns a nondeterministic value to model various possible outcomes based on
/// available SUI in the pool and minimum stake requirements.
public fun increase_validator_stake<P>(
    _self: &mut LiquidStakingInfo<P>,
    _: &AdminCap<P>,
    _system_state: &mut SuiSystemState,
    _validator_address: address,
    _sui_amount: u64,
    _ctx: &mut TxContext,
): u64 {
    nondet()
}
