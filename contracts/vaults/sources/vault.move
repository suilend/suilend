module vaults::vault;

use std::type_name::{Self, TypeName};
use sui::{bag, balance::{Self, Balance}, clock::Clock, coin::{Self, Coin}, event};
use suilend::{decimal, lending_market::{ObligationOwnerCap, LendingMarket}, reserve};

// === Errors ===
const EIncorrectVersion: u64 = 1;
const EInvalidManager: u64 = 2;
const EInvalidDepositFeeBps: u64 = 3;
const EInvalidWithdrawalFeeBps: u64 = 4;
const EInvalidPerformanceFeeBps: u64 = 5;
const EInvalidManagementFeeBps: u64 = 6;
const EInvalidDeposit: u64 = 7;
const EInsufficientShares: u64 = 8;
const EInsufficientLiquidity: u64 = 9;
const ENoReserveForAsset: u64 = 10;
const EIncompleteAccumulation: u64 = 11;

// === Constants ===
const CURRENT_VERSION: u64 = 1;
const MAX_DEPOSIT_FEE_BPS: u64 = 1000; // 10% max deposit fee
const MAX_WITHDRAWAL_FEE_BPS: u64 = 1000; // 10% max withdrawal fee
const MAX_PERFORMANCE_FEE_BPS: u64 = 5000; // 50% max performance fee
const MAX_MANAGEMENT_FEE_BPS: u64 = 1000; // 10% max management fee
const MIN_DEPOSIT: u64 = 1000000; // Minimum deposit 0.001 SUI to prevent dust
const BASIS_POINTS: u64 = 10000; // 100%
const NAV_PRECISION: u128 = 1_000_000_000; // 1e9 for NAV per share calculations
const MAX_UTILIZATION_RATE_BPS: u64 = 7000; // 70% max utilization
const SECONDS_PER_YEAR: u64 = 31_536_000; // 365 * 24 * 60 * 60
const OBLIGATION_CAP_BAG_KEY: u8 = 0;

// === Structs ===
public struct Vault<phantom P, phantom T> has key, store {
    id: object::UID,
    version: u64,
    // Keyed by 'L' from LendingMarket<L>
    obligations: sui::vec_map::VecMap<TypeName, vector<ObligationData>>,
    share_supply: balance::Supply<P>,
    deposit_asset: Balance<T>,
    manager_fees: Balance<P>,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
    utilization_rate_bps: u64, // Current utilization rate in basis points
    // Fee accrual state
    last_nav_per_share: u64, // For tracking performance fee base
    fee_last_update_timestamp_s: u64,
}

public struct ObligationData has store {
    // bag.OBLIGATION_CAP_BAG_KEY = ObligationOwnerCap<L>
    obligation_cap: bag::Bag,
    obligation_id: ID,
}

public struct VaultShare has drop, store {
    vault_id: ID,
}

public struct VaultManagerCap<phantom P> has key, store {
    id: object::UID,
    vault_id: object::ID,
}

/// Used to aggregate the obligation values from all live LendingMarkets
/// Must be consumed in PTB
public struct VaultValueAccumulator {
    // Keyed by 'L' from LendingMarket<L>
    obligation_ids: sui::vec_map::VecMap<TypeName, vector<ID>>,
    lending_market_values: sui::vec_map::VecMap<TypeName, u64>,
}

/// Created from a VaultValueAggregate once it has been fully processed
public struct VaultValueAggregate has drop {
    liquid_asset_value_usd: u64,
    total_obligation_value_usd: u64,
    lending_market_values: sui::vec_map::VecMap<TypeName, u64>,
}

public struct FeeAccrual has drop {
    management_fee_shares: u64,
    performance_fee_shares: u64,
    total_fee_shares: u64,
    new_nav_per_share: u64,
}

// === Events ===
public struct VaultCreated has copy, drop {
    vault_id: object::ID,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
}

public struct VaultDeposit has copy, drop {
    vault_id: object::ID,
    user: address,
    deposit_amount: u64,
    shares_minted: u64,
    timestamp_ms: u64,
}

public struct VaultWithdraw has copy, drop {
    vault_id: object::ID,
    user: address,
    amount: u64,
    shares_burned: u64,
    timestamp_ms: u64,
}

public struct ManagerAllocate has copy, drop {
    vault_id: object::ID,
    user: address,
    deposit_amount: u64,
    timestamp_ms: u64,
}

public struct ManagerDivest has copy, drop {
    vault_id: object::ID,
    user: address,
    amount: u64,
    timestamp_ms: u64,
}

public enum FeeType has copy, drop {
    DepositFee,
    WithdrawalFee,
    PerformanceFee,
    ManagementFee,
}

public struct FeesAccrued has copy, drop {
    vault_id: object::ID,
    fee_type: FeeType,
    fee_shares: u64,
    timestamp_ms: u64,
}

// === Functions ===
public fun create_vault<T>(
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
    clock: &Clock,
    ctx: &mut tx_context::TxContext,
): VaultManagerCap<VaultShare> {
    assert!(management_fee_bps <= MAX_MANAGEMENT_FEE_BPS, EInvalidManagementFeeBps);
    assert!(performance_fee_bps <= MAX_PERFORMANCE_FEE_BPS, EInvalidPerformanceFeeBps);
    assert!(deposit_fee_bps <= MAX_DEPOSIT_FEE_BPS, EInvalidDepositFeeBps);
    assert!(withdrawal_fee_bps <= MAX_WITHDRAWAL_FEE_BPS, EInvalidWithdrawalFeeBps);

    let vault_id = object::new(ctx);

    let shares_witness = VaultShare { vault_id: vault_id.uid_to_inner() };

    let supply_obj = balance::create_supply(shares_witness);

    let current_time_s = clock.timestamp_ms() / 1000;

    // Create vault
    let vault = Vault {
        id: vault_id,
        version: CURRENT_VERSION,
        obligations: sui::vec_map::empty(),
        share_supply: supply_obj,
        deposit_asset: balance::zero<T>(),
        manager_fees: balance::zero(),
        management_fee_bps,
        performance_fee_bps,
        deposit_fee_bps,
        withdrawal_fee_bps,
        utilization_rate_bps: 0,
        // Initialize fee accrual state
        last_nav_per_share: NAV_PRECISION as u64,
        fee_last_update_timestamp_s: current_time_s,
    };

    let vault_manager_cap = VaultManagerCap {
        id: object::new(ctx),
        vault_id: object::id(&vault),
    };

    event::emit(VaultCreated {
        vault_id: object::id(&vault),
        management_fee_bps,
        performance_fee_bps,
        deposit_fee_bps,
        withdrawal_fee_bps,
    });

    transfer::public_share_object(vault);

    vault_manager_cap
}

public fun deposit<P, L, T>(
    vault: &mut Vault<P, T>,
    deposit: Coin<T>,
    lending_market: &LendingMarket<L>,
    clock: &Clock,
    agg: VaultValueAggregate,
    ctx: &mut TxContext,
): Coin<P> {
    assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
    assert!(deposit.value() >= MIN_DEPOSIT, EInvalidDeposit);

    vault.accrue_all_fees(&agg, clock);

    let deposit_amount = deposit.value();
    let current_time = clock.timestamp_ms();
    let user = ctx.sender();

    // Calculate deposit fee
    let deposit_fee = (deposit_amount * vault.deposit_fee_bps) / BASIS_POINTS;
    let net_deposit_amount = deposit_amount - deposit_fee;

    // Add deposited coins to vault's asset balance
    vault.deposit_asset.join(coin::into_balance(deposit));

    // Mint shares for deposit fee
    if (deposit_fee > 0) {
        let fee_shares = calculate_shares_to_mint(vault, deposit_fee, lending_market, &agg);
        let fee_balance = balance::increase_supply(&mut vault.share_supply, fee_shares);
        vault.manager_fees.join(fee_balance);

        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::DepositFee,
            fee_shares: fee_shares,
            timestamp_ms: current_time,
        });
    };

    // Calculate shares to mint based on current USD NAV
    let shares_to_mint = calculate_shares_to_mint(vault, net_deposit_amount, lending_market, &agg);

    assert!(shares_to_mint > 0, EInvalidDeposit);

    // Mint vault shares
    let vault_shares_balance = balance::increase_supply(&mut vault.share_supply, shares_to_mint);
    let vault_shares = coin::from_balance(vault_shares_balance, ctx);

    vault.utilization_rate_bps = agg.calculate_utilization_rate_bps();

    // Emit deposit event
    event::emit(VaultDeposit {
        vault_id: object::id(vault),
        user: user,
        deposit_amount: deposit_amount,
        shares_minted: shares_to_mint,
        timestamp_ms: current_time,
    });

    vault_shares
}

/// User burns shares and withdraws proportional assets with performance fees on realized gains
public fun withdraw<P, L, T>(
    vault: &mut Vault<P, T>,
    shares: Coin<P>,
    lending_market: &LendingMarket<L>,
    clock: &Clock,
    agg: VaultValueAggregate,
    ctx: &mut TxContext,
): Coin<T> {
    assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
    assert!(shares.value() > 0, EInsufficientShares);

    let shares_amount = shares.value();
    let user = ctx.sender();
    let current_time = clock.timestamp_ms();

    vault.accrue_all_fees(&agg, clock);

    // Calculate total USD value of shares being redeemed
    let current_nav_per_share = vault.calculate_nav_per_share(&agg);
    let total_usd_value = (
        ((shares_amount as u128) * (current_nav_per_share as u128)) / NAV_PRECISION,
    ) as u64;

    // Calculate withdrawal fee in USD
    let fee_usd_value = (total_usd_value * vault.withdrawal_fee_bps) / BASIS_POINTS;
    let net_usd_value = total_usd_value - fee_usd_value;

    // Convert net USD value to token amount
    let withdraw_amount = get_token_amount_from_usd<_, T>(
        lending_market,
        net_usd_value,
    ).floor();

    // Check if vault has sufficient liquidity for withdrawal
    let available_amount = vault.deposit_asset.value();
    assert!(withdraw_amount <= available_amount, EInsufficientLiquidity);

    assert!(withdraw_amount > 0, EInsufficientShares);

    // Burn user shares
    let shares_balance = shares.into_balance();
    balance::decrease_supply(&mut vault.share_supply, shares_balance);

    // Mint fee shares to manager (representing the fee USD value)
    let fee_shares = calculate_shares_from_usd(current_nav_per_share, fee_usd_value);
    if (fee_shares > 0) {
        let fee_balance = balance::increase_supply(&mut vault.share_supply, fee_shares);
        vault.manager_fees.join(fee_balance);

        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::WithdrawalFee,
            fee_shares: fee_shares,
            timestamp_ms: current_time,
        });
    };

    vault.utilization_rate_bps = agg.calculate_utilization_rate_bps();

    let withdrawn_balance = vault.deposit_asset.split(withdraw_amount);

    let coins = coin::from_balance(withdrawn_balance, ctx);

    event::emit(VaultWithdraw {
        vault_id: object::id(vault),
        user: user,
        amount: withdraw_amount,
        shares_burned: shares_amount,
        timestamp_ms: current_time,
    });

    coins
}

/// Calculates the amount of shares that will be minted for deposit_amount of T
public fun calculate_shares_to_mint<P, L, T>(
    vault: &Vault<P, T>,
    deposit_amount: u64,
    lending_market: &LendingMarket<L>,
    agg: &VaultValueAggregate,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(agg);
    let deposit_usd_value = get_usd_value_for_token_amount<_, T>(
        lending_market,
        deposit_amount,
    ).floor();
    calculate_shares_from_usd(nav_per_share, deposit_usd_value)
}

/// Calculates vault shares from USD amount
fun calculate_shares_from_usd(nav_per_share: u64, usd_amount: u64): u64 {
    (((usd_amount as u128) * NAV_PRECISION) / (nav_per_share as u128)) as u64
}

/// Calculates the amount of shares that must be burned to redeem withdraw_amount of T
public fun calculate_shares_to_burn<P, L, T>(
    vault: &Vault<P, T>,
    withdraw_amount: u64,
    lending_market: &LendingMarket<L>,
    agg: VaultValueAggregate,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(&agg);
    let withdraw_usd_value = get_usd_value_for_token_amount<_, T>(
        lending_market,
        withdraw_amount,
    ).floor();
    calculate_shares_from_usd(nav_per_share, withdraw_usd_value)
}

/// Calculates the amount of T that can be redeemed for shares_amount
public fun calculate_withdraw_amount<P, L, T>(
    vault: &Vault<P, T>,
    shares_amount: u64,
    lending_market: &LendingMarket<L>,
    agg: VaultValueAggregate,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(&agg);
    let withdraw_usd_value = (((shares_amount as u128) * (nav_per_share as u128)) / NAV_PRECISION);
    get_token_amount_from_usd<_, T>(lending_market, withdraw_usd_value as u64).floor()
}

/// Calculates the amount of T that shares_amount will cost
public fun calculate_deposit_amount<P, L, T>(
    vault: &Vault<P, T>,
    shares_amount: u64,
    lending_market: &LendingMarket<L>,
    agg: VaultValueAggregate,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(&agg);
    let deposit_usd_value = (((shares_amount as u128) * (nav_per_share as u128)) / NAV_PRECISION);
    get_token_amount_from_usd<_, T>(lending_market, deposit_usd_value as u64).floor()
}

/// Check if vault can deploy an amount of T (and vault remains under MAX_UTILIZATION_RATE_BPS)
public fun can_deploy_funds<L, T>(
    lending_market: &LendingMarket<L>,
    agg: &VaultValueAggregate,
    amount: u64,
): bool {
    let liquid_asset_value = agg.liquid_asset_value_usd;
    let obligations_value_usd = agg.total_obligation_value_usd;
    let usd_to_deploy = get_usd_value_for_token_amount<_, T>(lending_market, amount).floor();

    // Check if we have enough liquid assets to deploy
    if (usd_to_deploy > liquid_asset_value) {
        return false
    };

    // Calculate new values after deployment
    let new_liquid_value = liquid_asset_value - usd_to_deploy;
    let new_obligations_value = obligations_value_usd + usd_to_deploy;
    let total_vault_value = new_liquid_value + new_obligations_value;

    // If total value is zero, cannot deploy
    if (total_vault_value == 0) {
        return false
    };

    // Calculate new utilization rate: (obligations / total_value) * BASIS_POINTS
    let new_utilization = (new_obligations_value * BASIS_POINTS) / total_vault_value;

    new_utilization <= MAX_UTILIZATION_RATE_BPS
}

/// Total supply of shares
public fun total_supply<P, T>(vault: &Vault<P, T>): u64 {
    vault.share_supply.supply_value()
}

/// Calculate total obligation value within one Lending Market in USD
public fun calculate_obligation_values_usd<L>(
    obligation_ids: vector<ID>,
    lending_market: &LendingMarket<L>,
): u64 {
    let mut total_asset_value = 0;

    // Add value from all lending positions
    obligation_ids.do!(|obligation_id| {
        let obligation = lending_market.obligation(obligation_id);

        let deposited_value_usd = obligation.deposited_value_usd().floor();
        let unweighted_borrowed_value_usd = obligation.unweighted_borrowed_value_usd().floor();

        let net_value = deposited_value_usd - unweighted_borrowed_value_usd;

        total_asset_value = total_asset_value + net_value;
    });

    total_asset_value
}

/// Get the reserve for the base asset T
fun get_reserve_for_asset<L, T>(lending_market: &LendingMarket<L>): &reserve::Reserve<L> {
    let reserves = lending_market.reserves();
    let asset_type = type_name::with_defining_ids<T>();
    let reserve_index = reserves.find_index!(|reserve| {
        reserve.coin_type() == asset_type
    });
    if (reserve_index.is_some()) {
        reserves.borrow(*reserve_index.borrow())
    } else {
        abort ENoReserveForAsset
    }
}

/// Get T amount from USD amount
fun get_token_amount_from_usd<L, T>(
    lending_market: &LendingMarket<L>,
    amount: u64,
): decimal::Decimal {
    let reserve = get_reserve_for_asset<L, T>(lending_market);
    // TODO
    //reserve.assert_price_is_fresh(clock);
    reserve.usd_to_token_amount_lower_bound(decimal::from(amount))
}

/// Get USD amount from T amount
fun get_usd_value_for_token_amount<L, T>(
    lending_market: &LendingMarket<L>,
    amount: u64,
): decimal::Decimal {
    let reserve = get_reserve_for_asset<L, T>(lending_market);
    // TODO
    //reserve.assert_price_is_fresh(clock);
    reserve.market_value_lower_bound(decimal::from(amount))
}

public(package) fun calculate_nav_per_share<P, T>(
    vault: &Vault<P, T>,
    agg: &VaultValueAggregate,
): u64 {
    let current_shares = vault.share_supply.supply_value();
    let vault_value = agg.total_obligation_value_usd + agg.liquid_asset_value_usd;
    if (current_shares == 0 || vault_value == 0) {
        NAV_PRECISION as u64 // 1.0 scaled
    } else {
        (((vault_value as u128) * NAV_PRECISION) / (current_shares as u128)) as u64
    }
}

/// Apply calculated fees to the vault, minting shares and updating state
fun apply_fee_accrual<P, T>(
    vault: &mut Vault<P, T>,
    accrual: FeeAccrual,
    clock: &Clock,
) {
    let current_time = clock.timestamp_ms();

    // Mint management fee shares if any
    if (accrual.management_fee_shares > 0) {
        let fee_balance = balance::increase_supply(&mut vault.share_supply, accrual.management_fee_shares);
        vault.manager_fees.join(fee_balance);

        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::ManagementFee,
            fee_shares: accrual.management_fee_shares,
            timestamp_ms: current_time,
        });
    };

    // Mint performance fee shares if any
    if (accrual.performance_fee_shares > 0) {
        let fee_balance = balance::increase_supply(&mut vault.share_supply, accrual.performance_fee_shares);
        vault.manager_fees.join(fee_balance);

        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::PerformanceFee,
            fee_shares: accrual.performance_fee_shares,
            timestamp_ms: current_time,
        });
    };

    vault.last_nav_per_share = accrual.new_nav_per_share;
    vault.fee_last_update_timestamp_s = clock.timestamp_ms() / 1000;
}

/// Unified fee accrual function - calculates and applies all fees atomically
/// This replaces the deprecated apply_management_fee_to_nav function
public(package) fun accrue_all_fees<P, T>(
    vault: &mut Vault<P, T>,
    agg: &VaultValueAggregate,
    clock: &Clock,
) {
    let accrual = calculate_all_fees(vault, agg, clock);
    apply_fee_accrual(vault, accrual, clock);
}

/// Calculate all fees to be accrued (management + performance) atomically
fun calculate_all_fees<P, T>(
    vault: &Vault<P, T>,
    agg: &VaultValueAggregate,
    clock: &Clock,
): FeeAccrual {
    // 1. Get base NAV before any fees
    let base_nav = vault.calculate_nav_per_share(agg);
    let current_shares = vault.share_supply.supply_value();

    // 2. Calculate management fee shares
    let management_fee_shares = calculate_management_fee_shares(vault, clock);

    // 3. Calculate performance fee accounting for management fee dilution
    let performance_fee_shares = calculate_performance_fee_shares(
        vault,
        base_nav,
        current_shares,
        management_fee_shares
    );

    // 4. Calculate final NAV after both fees
    let total_fee_shares = management_fee_shares + performance_fee_shares;
    let new_nav = if (total_fee_shares == 0) {
        base_nav
    } else {
        let total_value = ((base_nav as u128) * (current_shares as u128)) / NAV_PRECISION;
        ((total_value * NAV_PRECISION) / ((current_shares + total_fee_shares) as u128)) as u64
    };

    FeeAccrual {
        management_fee_shares,
        performance_fee_shares,
        total_fee_shares,
        new_nav_per_share: new_nav,
    }
}

/// Calculate performance fee shares based on NAV growth
fun calculate_performance_fee_shares<P, T>(
    vault: &Vault<P, T>,
    current_nav_per_share: u64,
    current_shares: u64,
    mgmt_shares_to_mint: u64,
): u64 {
    if (vault.performance_fee_bps == 0 || current_shares == 0) {
        return 0
    };

    // Apply performance fee only on NAV growth
    if (current_nav_per_share <= vault.last_nav_per_share) {
        return 0
    };

    // Total value at current NAV
    let total_value = ((current_nav_per_share as u128) * (current_shares as u128)) / NAV_PRECISION;

    // Total value at last NAV (baseline for performance)
    let baseline_value = ((vault.last_nav_per_share as u128) * (current_shares as u128)) / NAV_PRECISION;

    // Gain = total_value - baseline_value
    let gain = total_value - baseline_value;

    // Performance fee on the gain
    let perf_fee_value = (gain * (vault.performance_fee_bps as u128)) / (BASIS_POINTS as u128);

    // Calculate shares accounting for management fee dilution
    // NAV after mgmt fees = total_value / (current_shares + mgmt_shares)
    let shares_after_mgmt = current_shares + mgmt_shares_to_mint;
    let nav_after_mgmt = (total_value * NAV_PRECISION) / (shares_after_mgmt as u128);

    // Convert performance fee value to shares at post-mgmt NAV
    ((perf_fee_value * NAV_PRECISION) / nav_after_mgmt) as u64
}

fun calculate_management_fee_shares<P, T>(
    vault: &Vault<P, T>,
    clock: &Clock,
): u64 {
    if (vault.management_fee_bps == 0) {
        return 0
    };

    let current_time_s = clock.timestamp_ms() / 1000;
    let time_elapsed_s = current_time_s - vault.fee_last_update_timestamp_s;

    if (time_elapsed_s == 0) {
        return 0
    };

    // Calculate management fee reduction factor
    let annual_fee_rate = decimal::from_bps(vault.management_fee_bps);

    // Convert to per-second rate: annual_rate / seconds_per_year
    let per_second_rate = decimal::div(annual_fee_rate, decimal::from(SECONDS_PER_YEAR));

    let fee_factor = decimal::mul(decimal::from(time_elapsed_s), per_second_rate);

    // Ensure fee factor doesn't exceed 100%
    let fee_factor = if (decimal::gt(fee_factor, decimal::from(1))) {
        decimal::from(1)
    } else {
        fee_factor
    };

    let circulating_shares = vault.share_supply.supply_value();

    // Ensures fees represent exactly the correct percentage of total vault value
    let one_minus_fee = decimal::sub(decimal::from(1), fee_factor);
    let shares_to_mint = decimal::div(
        decimal::mul(decimal::from(circulating_shares), fee_factor),
        one_minus_fee
    );

    decimal::floor(shares_to_mint)
}

/// Calculate utilization rate in basis points
public fun calculate_utilization_rate_bps(agg: &VaultValueAggregate): u64 {
    let deployed_value = agg.total_obligation_value_usd;
    let liquid_value = agg.liquid_asset_value_usd;

    if (deployed_value == 0) {
        // zero utilization
        0
    } else if (liquid_value == 0) {
        // 100% utilization (shouldn't happen)
        BASIS_POINTS
    } else {
        let total_value = deployed_value + liquid_value;
        ((deployed_value as u128) * (BASIS_POINTS as u128) / (total_value as u128)) as u64
    }
}

// === Vault Manager Functions ===

/// Validate that a manager cap belongs to a specific vault
public fun validate_manager_cap<P, T>(vault: &Vault<P, T>, manager_cap: &VaultManagerCap<P>) {
    assert!(manager_cap.vault_id == object::id(vault), EInvalidManager);
}

/// Claim accumulated manager fees
public fun claim_manager_fees<P, T>(
    vault: &mut Vault<P, T>,
    vault_manager_cap: &VaultManagerCap<P>,
    amount: u64,
    ctx: &mut TxContext,
): Coin<P> {
    assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
    vault.validate_manager_cap(vault_manager_cap);

    let accrued_fees = vault.manager_fees.value();
    assert!(accrued_fees >= amount, EInsufficientShares);

    let fee_balance = vault.manager_fees.split(amount);
    let fee_coin = coin::from_balance(fee_balance, ctx);

    fee_coin
}

/// Create a new obligation for the vault
public fun create_obligation<P, L, T>(
    vault: &mut Vault<P, T>,
    vault_manager_cap: &VaultManagerCap<P>,
    lending_market: &mut LendingMarket<L>,
    ctx: &mut TxContext,
) {
    assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
    vault.validate_manager_cap(vault_manager_cap);

    let obligation_cap = lending_market.create_obligation(ctx);
    let obligation_id = obligation_cap.obligation_id();
    let mut obl_bag = bag::new(ctx);
    obl_bag.add(OBLIGATION_CAP_BAG_KEY, obligation_cap);
    let lending_market_type = type_name::with_defining_ids<L>();
    let obl = ObligationData {
        obligation_cap: obl_bag,
        obligation_id,
    };
    if (vault.obligations.contains(&lending_market_type)) {
        let obls = vault.obligations.get_mut(&lending_market_type);
        obls.push_back(obl);
    } else {
        let obls = vector::singleton(obl);
        vault.obligations.insert(lending_market_type, obls);
    };
}

/// Get obligation cap at lending_market_type + index (read-only)
public fun get_obligation_cap<P, L, T>(
    vault: &Vault<P, T>,
    lending_market_type: &TypeName,
    index: u64,
): &ObligationOwnerCap<L> {
    // TODO: access checks + error codes
    let obligations = vault.obligations.get(lending_market_type);
    let obl = obligations.borrow(index);
    obl.obligation_cap.borrow(OBLIGATION_CAP_BAG_KEY)
}

/// Get mutable obligation cap at lending_market_type + index (manager only)
public fun get_obligation_cap_mut<P, L, T>(
    vault_manager_cap: &VaultManagerCap<P>,
    vault: &mut Vault<P, T>,
    lending_market_type: &TypeName,
    index: u64,
): &mut ObligationOwnerCap<L> {
    // TODO: access checks + error codes
    vault.validate_manager_cap(vault_manager_cap);
    let obligations = vault.obligations.get_mut(lending_market_type);
    let obl = obligations.borrow_mut(index);
    obl.obligation_cap.borrow_mut(OBLIGATION_CAP_BAG_KEY)
}

/// Get number of obligations in vault
public fun obligation_count<P, T>(vault: &Vault<P, T>): u64 {
    let keys = vault.obligations.keys();
    let count = keys.fold!(0, |acc, k| {
        let obligations = vault.obligations.get(&k);
        acc + obligations.length()
    });
    count
}

/// Deploy funds from vault to lending market obligation
public fun deploy_funds<P, L, T>(
    vault: &mut Vault<P, T>,
    vault_manager_cap: &VaultManagerCap<P>,
    lending_market: &mut LendingMarket<L>,
    obligation_index: u64,
    amount: u64,
    clock: &Clock,
    agg: VaultValueAggregate,
    ctx: &mut TxContext,
): u64 {
    assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
    vault.validate_manager_cap(vault_manager_cap);
    assert!(amount > 0, EInvalidDeposit);

    vault.accrue_all_fees(&agg, clock);

    // Check if vault has sufficient liquid assets
    let available_amount = vault.deposit_asset.value();
    assert!(available_amount >= amount, EInsufficientLiquidity);

    // Check if deployment would exceed utilization limits
    assert!(can_deploy_funds<_, T>(lending_market, &agg, amount), EInsufficientLiquidity);

    // Split funds from vault's deposit asset
    let deploy_balance = vault.deposit_asset.split(amount);
    let deploy_coin = coin::from_balance(deploy_balance, ctx);

    // Get reserve index for the asset type T
    let reserves = lending_market.reserves();
    let reserve_index_opt = reserves.find_index!(|reserve: &reserve::Reserve<L>| {
        reserve.coin_type() == type_name::with_defining_ids<T>()
    });
    assert!(option::is_some(&reserve_index_opt), ENoReserveForAsset);
    let reserve_array_index = *option::borrow(&reserve_index_opt);

    // Deposit liquidity and mint cTokens
    let ctokens = lending_market.deposit_liquidity_and_mint_ctokens<L, T>(
        reserve_array_index,
        clock,
        deploy_coin,
        ctx,
    );

    let ctokens_amount = ctokens.value();

    let lm_type = type_name::with_defining_ids<L>();
    let obligation_cap = vault.get_obligation_cap(&lm_type, obligation_index);

    // Deposit cTokens into the obligation
    lending_market.deposit_ctokens_into_obligation<L, T>(
        reserve_array_index,
        obligation_cap,
        clock,
        ctokens,
        ctx,
    );

    // Update vault utilization
    vault.utilization_rate_bps = agg.calculate_utilization_rate_bps();

    event::emit(ManagerAllocate {
        vault_id: object::id(vault),
        user: ctx.sender(),
        deposit_amount: amount,
        timestamp_ms: clock.timestamp_ms(),
    });

    ctokens_amount
}

/// Withdraw funds from lending market obligation back to vault
public fun withdraw_deployed_funds<P, L, T>(
    vault: &mut Vault<P, T>,
    vault_manager_cap: &VaultManagerCap<P>,
    lending_market: &mut LendingMarket<L>,
    obligation_index: u64,
    ctoken_amount: u64,
    clock: &Clock,
    agg: VaultValueAggregate,
    ctx: &mut TxContext,
) {
    assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
    vault.validate_manager_cap(vault_manager_cap);
    assert!(ctoken_amount > 0, EInsufficientShares);

    vault.accrue_all_fees(&agg, clock);

    let lm_type = type_name::with_defining_ids<L>();
    let obligation_cap = vault.get_obligation_cap(&lm_type, obligation_index);

    // Get reserve index for the asset type T
    let reserves = lending_market.reserves();
    let reserve_index_opt = reserves.find_index!(|reserve: &reserve::Reserve<L>| {
        reserve.coin_type() == type_name::with_defining_ids<T>()
    });
    assert!(option::is_some(&reserve_index_opt), ENoReserveForAsset);
    let reserve_array_index = *option::borrow(&reserve_index_opt);

    // Withdraw cTokens from obligation
    let ctokens = lending_market.withdraw_ctokens<L, T>(
        reserve_array_index,
        obligation_cap,
        clock,
        ctoken_amount,
        ctx,
    );

    // Redeem cTokens for underlying liquidity
    let withdrawn_coin = lending_market.redeem_ctokens_and_withdraw_liquidity<L, T>(
        reserve_array_index,
        clock,
        ctokens,
        option::none(), // No rate limiter exemption
        ctx,
    );

    let withdrawn_amount = withdrawn_coin.value();

    // Add withdrawn funds back to vault's deposit asset
    vault.deposit_asset.join(coin::into_balance(withdrawn_coin));

    // Update vault utilization
    vault.utilization_rate_bps = agg.calculate_utilization_rate_bps();

    event::emit(ManagerDivest {
        vault_id: object::id(vault),
        user: ctx.sender(),
        amount: withdrawn_amount,
        timestamp_ms: clock.timestamp_ms(),
    });
}

// === Vault Value Aggregation ===

public fun create_vault_value_accumulator<P, T>(vault: &Vault<P, T>): VaultValueAccumulator {
    let keys = vault.obligations.keys();
    let obligation_ids = keys.map_ref!(|k| {
        let obligations = vault.obligations.get(k);
        obligations.map_ref!(|bg| {
            bg.obligation_id
        })
    });
    VaultValueAccumulator {
        obligation_ids: sui::vec_map::from_keys_values(keys, obligation_ids),
        lending_market_values: sui::vec_map::empty(),
    }
}

public fun process_lending_market<L>(
    acc: &mut VaultValueAccumulator,
    lending_market: &LendingMarket<L>,
) {
    let lending_market_type = type_name::with_defining_ids<L>();
    let (_, obligation_ids) = acc.obligation_ids.remove(&lending_market_type);
    let obligation_values_usd = calculate_obligation_values_usd(obligation_ids, lending_market);

    acc.lending_market_values.insert(lending_market_type, obligation_values_usd);
}

public fun create_vault_value_aggregate<P, L, T>(
    acc: VaultValueAccumulator,
    vault: &Vault<P, T>,
    lending_market: &LendingMarket<L>,
): VaultValueAggregate {
    assert!(acc.obligation_ids.is_empty(), EIncompleteAccumulation);

    let liquid_asset_value_usd = {
        let liquid_asset_value = vault.deposit_asset.value();
        get_usd_value_for_token_amount<L, T>(lending_market, liquid_asset_value).floor()
    };

    let VaultValueAccumulator {
        obligation_ids: _,
        lending_market_values,
    } = acc;
    let ks = lending_market_values.keys();
    let total_obligation_value_usd = ks.fold!(0, |acc, k| {
        let val = *lending_market_values.get(&k);
        acc + val
    });
    VaultValueAggregate {
        liquid_asset_value_usd,
        total_obligation_value_usd,
        lending_market_values,
    }
}

// === Test Functions ===

#[test_only]
public fun create_vault_value_aggregate_for_testing<P, L, T>(
    vault: &Vault<P, T>,
    lending_market: &LendingMarket<L>,
): VaultValueAggregate {
    let mut acc = vault.create_vault_value_accumulator();
    if (!vault.obligations.is_empty()) {
        acc.process_lending_market(lending_market);
    };
    let agg = acc.create_vault_value_aggregate(vault, lending_market);
    agg
}
