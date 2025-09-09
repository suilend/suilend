module vaults::vault;

use sui::{balance::{Self, Balance}, clock::{Self, Clock}, coin::{Self, TreasuryCap, Coin}, event};
use suilend::{
    decimal,
    lending_market::{Self, ObligationOwnerCap, LendingMarket},
    obligation::Obligation,
    reserve
};

// === Errors ===
const EIncorrectVersion: u64 = 1;
const EInvalidManager: u64 = 2;
const EInvalidDepositFeeBps: u64 = 6;
const EInvalidWithdrawalFeeBps: u64 = 7;
const EInvalidPerformanceFeeBps: u64 = 8;
const EInvalidManagementFeeBps: u64 = 9;
const EInvalidDeposit: u64 = 10;
const EInsufficientShares: u64 = 12;
const EInsufficientLiquidity: u64 = 13;
const ENoReserveForAsset: u64 = 15;

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

// === Structs ===
public struct Vault<phantom P> has key, store {
    id: object::UID,
    version: u64,
    obligations: vector<ObligationOwnerCap<P>>,
    treasury_cap: TreasuryCap<VaultShare<P>>,
    deposit_asset: Balance<P>,
    total_shares: u64,
    fee_receiver: address,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
    utilization_rate_bps: u64, // Current utilization rate in basis points
    // Fee accrual state
    last_nav_per_share: u64, // For tracking performance fee base
    fee_last_update_timestamp_s: u64,
}

public struct VaultShare<phantom P> has drop, store {}

public struct VaultManagerCap<phantom P> has key, store {
    id: object::UID,
    vault_id: object::ID,
}

// === Events ===
public struct VaultCreated has copy, drop {
    vault_id: object::ID,
    fee_receiver: address,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
}

public struct Deposit has copy, drop {
    vault_id: object::ID,
    user: address,
    deposit_amount: u64,
    shares_minted: u64,
    timestamp_ms: u64,
}

public struct Withdraw has copy, drop {
    vault_id: object::ID,
    user: address,
    amount: u64,
    shares_burned: u64,
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
    fee_amount: u64,
    fee_receiver: address,
    timestamp_ms: u64,
}

// === Functions ===
public fun create_vault<P>(
    fee_receiver: address,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
    treasury_cap: TreasuryCap<VaultShare<P>>,
    clock: &Clock,
    ctx: &mut tx_context::TxContext,
): (Vault<P>, VaultManagerCap<P>) {
    assert!(management_fee_bps <= MAX_MANAGEMENT_FEE_BPS, EInvalidManagementFeeBps);
    assert!(performance_fee_bps <= MAX_PERFORMANCE_FEE_BPS, EInvalidPerformanceFeeBps);
    assert!(deposit_fee_bps <= MAX_DEPOSIT_FEE_BPS, EInvalidDepositFeeBps);
    assert!(withdrawal_fee_bps <= MAX_WITHDRAWAL_FEE_BPS, EInvalidWithdrawalFeeBps);

    let current_time_s = clock.timestamp_ms() / 1000;

    // Create vault
    let vault = Vault {
        id: object::new(ctx),
        version: CURRENT_VERSION,
        obligations: vector::empty(),
        treasury_cap,
        deposit_asset: balance::zero<P>(),
        total_shares: 0,
        fee_receiver,
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
        fee_receiver,
        management_fee_bps,
        performance_fee_bps,
        deposit_fee_bps,
        withdrawal_fee_bps,
    });

    (vault, vault_manager_cap)
}

public fun deposit<P>(
    vault: &mut Vault<P>,
    mut deposit: Coin<P>,
    lending_market: &LendingMarket<P>,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<VaultShare<P>> {
    assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
    assert!(coin::value(&deposit) >= MIN_DEPOSIT, EInvalidDeposit);

    let deposit_amount = coin::value(&deposit);
    let current_time = clock::timestamp_ms(clock);
    let user = ctx.sender();

    // Calculate deposit fee
    let deposit_fee = (deposit_amount * vault.deposit_fee_bps) / BASIS_POINTS;
    let net_deposit_amount = deposit_amount - deposit_fee;

    // Split out fee
    let fee_coins = coin::split(&mut deposit, deposit_fee, ctx);

    // Send fee to collector
    sui::transfer::public_transfer(fee_coins, vault.fee_receiver);

    // Add deposited coins to vault's asset balance
    balance::join(&mut vault.deposit_asset, coin::into_balance(deposit));

    // Calculate shares to mint based on current USD NAV
    let nav_per_share = apply_management_fee_to_nav(vault, lending_market, clock);
    let deposit_usd_value = decimal::mul(
        decimal::from(net_deposit_amount),
        get_usd_price_for_asset<P>(lending_market),
    ).floor();
    let shares_to_mint =
        (((deposit_usd_value as u128) * NAV_PRECISION) / (nav_per_share as u128)) as u64;

    assert!(shares_to_mint > 0, EInvalidDeposit);

    // Mint vault shares to user
    let vault_shares = coin::mint(&mut vault.treasury_cap, shares_to_mint, ctx);
    vault.total_shares = vault.total_shares + shares_to_mint;
    vault.utilization_rate_bps = calculate_utilization_rate(vault, lending_market);

    // Emit fee collection event
    if (deposit_fee > 0) {
        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::DepositFee,
            fee_amount: deposit_fee,
            fee_receiver: vault.fee_receiver,
            timestamp_ms: current_time,
        });
    };

    // Emit deposit event
    event::emit(Deposit {
        vault_id: object::id(vault),
        user: user,
        deposit_amount: deposit_amount,
        shares_minted: shares_to_mint,
        timestamp_ms: current_time,
    });

    vault_shares
}

/// User burns shares and withdraws proportional assets with performance fees on realized gains
public fun withdraw<P>(
    vault: &mut Vault<P>,
    shares: Coin<VaultShare<P>>,
    lending_market: &LendingMarket<P>,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<P> {
    assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
    assert!(coin::value(&shares) > 0, EInsufficientShares);

    let shares_amount = coin::value(&shares);
    let user = ctx.sender();
    let current_time = clock::timestamp_ms(clock);

    assert!(vault.total_shares >= shares_amount, EInsufficientShares);

    let current_nav_per_share = apply_management_fee_to_nav(vault, lending_market, clock);
    // Calculate withdrawal amount based on current USD NAV
    let withdraw_usd_value = (
        ((shares_amount as u128) * (current_nav_per_share as u128)) / NAV_PRECISION,
    );
    let usd_price = get_usd_price_for_asset<P>(lending_market);
    let withdraw_amount = decimal::div(decimal::from(withdraw_usd_value as u64), usd_price).floor();

    // Calculate withdrawal fee on the gross amount
    let withdrawal_fee = (withdraw_amount * vault.withdrawal_fee_bps) / BASIS_POINTS;

    // Check if vault has sufficient liquidity for withdrawal
    let available_amount = vault.deposit_asset.value();
    assert!(withdraw_amount <= available_amount, EInsufficientLiquidity);

    // Net withdrawal amount after withdrawal fee
    let net_withdraw_amount = withdraw_amount - withdrawal_fee;

    // Burn the shares
    coin::burn(&mut vault.treasury_cap, shares);
    vault.total_shares = vault.total_shares - shares_amount;
    vault.utilization_rate_bps = calculate_utilization_rate(vault, lending_market);

    // Withdraw full amount from vault's asset balance
    let mut withdrawn_balance = balance::split(&mut vault.deposit_asset, withdraw_amount);

    // Split out withdrawal fee
    if (withdrawal_fee > 0) {
        let fee_balance = balance::split(&mut withdrawn_balance, withdrawal_fee);
        let fee_coins = coin::from_balance(fee_balance, ctx);

        // Send fees to collector
        sui::transfer::public_transfer(fee_coins, vault.fee_receiver);
    };

    // Return net amount to user
    let coins = coin::from_balance(withdrawn_balance, ctx);

    // Emit withdrawal fee event
    if (withdrawal_fee > 0) {
        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::WithdrawalFee,
            fee_amount: withdrawal_fee,
            fee_receiver: vault.fee_receiver,
            timestamp_ms: current_time,
        });
    };

    // Emit withdrawal event
    event::emit(Withdraw {
        vault_id: object::id(vault),
        user: user,
        amount: net_withdraw_amount,
        shares_burned: shares_amount,
        timestamp_ms: current_time,
    });

    coins
}

public fun calculate_shares_to_mint<P>(
    vault: &Vault<P>,
    deposit_amount: u64,
    lending_market: &LendingMarket<P>,
): u64 {
    let nav_per_share = calculate_nav_per_share(vault, lending_market);
    let deposit_usd_value = decimal::mul(
        decimal::from(deposit_amount),
        get_usd_price_for_asset<P>(lending_market),
    ).floor();
    (((deposit_usd_value as u128) * NAV_PRECISION) / (nav_per_share as u128)) as u64
}

public fun calculate_shares_to_burn<P>(
    vault: &Vault<P>,
    withdraw_amount: u64,
    lending_market: &LendingMarket<P>,
): u64 {
    if (vault.total_shares == 0) {
        0
    } else {
        let nav_per_share = calculate_nav_per_share(vault, lending_market);
        let withdraw_usd_value = decimal::mul(
            decimal::from(withdraw_amount),
            get_usd_price_for_asset<P>(lending_market),
        ).floor();
        (((withdraw_usd_value as u128) * NAV_PRECISION) / (nav_per_share as u128)) as u64
    }
}

public fun calculate_withdraw_amount<P>(
    vault: &Vault<P>,
    shares_amount: u64,
    lending_market: &LendingMarket<P>,
): u64 {
    if (vault.total_shares == 0) {
        0
    } else {
        let nav_per_share = calculate_nav_per_share(vault, lending_market);
        let withdraw_usd_value = (
            ((shares_amount as u128) * (nav_per_share as u128)) / NAV_PRECISION,
        );
        let usd_price = get_usd_price_for_asset<P>(lending_market);
        decimal::div(decimal::from(withdraw_usd_value as u64), usd_price).floor()
    }
}

public fun calculate_deposit_amount<P>(
    vault: &Vault<P>,
    shares_amount: u64,
    lending_market: &LendingMarket<P>,
): u64 {
    let nav_per_share = calculate_nav_per_share(vault, lending_market);
    let deposit_usd_value = (((shares_amount as u128) * (nav_per_share as u128)) / NAV_PRECISION);
    let usd_price = get_usd_price_for_asset<P>(lending_market);
    decimal::div(decimal::from(deposit_usd_value as u64), usd_price).floor()
}

/// Check if vault can deploy more funds (under 70% utilization)
public fun can_deploy_funds<P>(
    vault: &Vault<P>,
    lending_market: &LendingMarket<P>,
    amount: u64,
): bool {
    let liquid_asset_value = balance::value(&vault.deposit_asset);
    let usd_price = get_usd_price_for_asset<P>(lending_market);
    let liquid_value = decimal::mul(decimal::from(liquid_asset_value), usd_price).floor();

    if (amount > liquid_value) {
        false
    } else {
        let new_liquid_value = liquid_value - amount;
        let total_value = calculate_total_vault_value(vault, lending_market);
        if (total_value == 0) {
            true
        } else {
            let new_deployed = total_value - new_liquid_value;
            let new_utilization = (new_deployed * BASIS_POINTS) / total_value;
            new_utilization <= MAX_UTILIZATION_RATE_BPS
        }
    }
}

/// Total supply of shares
public fun total_supply<P>(vault: &Vault<P>): u64 {
    vault.total_shares
}

/// Calculate total vault value
/// Returns total assets under management in USD
public fun calculate_total_vault_value<P>(
    vault: &Vault<P>,
    lending_market: &LendingMarket<P>,
): u64 {
    let mut total_asset_value = vault.deposit_asset.value();

    // Add value from all lending positions
    vault.obligations.do_ref!(|obligation_cap| {
        let obligation_id = obligation_cap.obligation_id();
        let obligation = lending_market.obligation(obligation_id);

        // Get net value from this obligation (deposits - borrows in asset terms)
        let net_value = calculate_obligation_net_value<P>(obligation, lending_market);
        total_asset_value = total_asset_value + net_value;
    });

    // Convert to USD
    let usd_price = get_usd_price_for_asset<P>(lending_market);
    decimal::mul(decimal::from(total_asset_value), usd_price).floor()
}

/// Calculate net value of an obligation in asset-native terms
/// This converts all positions back to the base asset P
fun calculate_obligation_net_value<P>(
    obligation: &Obligation<P>,
    lending_market: &LendingMarket<P>,
): u64 {
    let mut net_value = 0;

    // Add collateral deposits (converted from cTokens to underlying)
    let deposits = obligation.deposits();
    deposits.do_ref!(|deposit| {
        let reserve_index = deposit.reserve_array_index();
        let reserves = lending_market.reserves();
        let reserve = reserves.borrow(reserve_index);

        // Check if this deposit is in our base asset P
        // TODO: Should handle all assets?
        if (reserve.coin_type() == std::type_name::get<P>()) {
            let ctoken_amount = deposit.deposited_ctoken_amount();
            let ctoken_ratio = reserve.ctoken_ratio();
            // Convert cTokens to underlying asset amount
            let underlying_amount = decimal::mul(
                decimal::from(ctoken_amount),
                ctoken_ratio,
            ).floor();
            net_value = net_value + underlying_amount;
        };
    });

    // Subtract borrowed amounts (if borrowed in base asset P)
    let borrows = obligation.borrows();
    borrows.do_ref!(|borrow| {
        let reserve_index = borrow.reserve_array_index();
        let reserves = lending_market.reserves();
        let reserve = reserves.borrow(reserve_index);

        // Check if this borrow is in our base asset P
        if (reserve.coin_type() == std::type_name::get<P>()) {
            let borrowed_amount = borrow.borrowed_amount().floor();
            net_value = if (net_value >= borrowed_amount) {
                net_value - borrowed_amount
            } else {
                0
            };
        };
    });

    net_value
}

/// Get the reserve for the base asset P
fun get_reserve_for_asset<P>(lending_market: &LendingMarket<P>): &reserve::Reserve<P> {
    let reserves = lending_market.reserves();
    let asset_type = std::type_name::get<P>();
    let reserve_index = reserves.find_index!(|reserve| {
        reserve.coin_type() == asset_type
    });
    if (reserve_index.is_some()) {
        reserves.borrow(*reserve_index.borrow())
    } else {
        abort ENoReserveForAsset
    }
}

/// Get USD price for asset P (using lower bound for conservative pricing)
fun get_usd_price_for_asset<P>(lending_market: &LendingMarket<P>): decimal::Decimal {
    let reserve = get_reserve_for_asset<P>(lending_market);
    reserve.price_lower_bound()
}

fun calculate_nav_per_share<P>(vault: &Vault<P>, lending_market: &LendingMarket<P>): u64 {
    if (vault.total_shares == 0) {
        NAV_PRECISION as u64 // 1.0 scaled
    } else {
        let total_usd_value = calculate_total_vault_value(vault, lending_market);
        (((total_usd_value as u128) * NAV_PRECISION) / (vault.total_shares as u128)) as u64
    }
}

/// Apply management fee to NAV based on time elapsed
/// Returns the fee-adjusted NAV per share
fun apply_management_fee_to_nav<P>(
    vault: &mut Vault<P>,
    lending_market: &LendingMarket<P>,
    clock: &Clock,
): u64 {
    let base_nav_per_share = calculate_nav_per_share(vault, lending_market);

    if (vault.management_fee_bps == 0) {
        return base_nav_per_share
    };

    let current_time_s = clock::timestamp_ms(clock) / 1000;

    let time_elapsed_s = current_time_s - vault.fee_last_update_timestamp_s;
    if (time_elapsed_s == 0) {
        return base_nav_per_share
    };

    // Calculate management fee reduction factor
    // Annual fee rate as decimal (e.g., 100 bps = 0.01)
    let annual_fee_rate = decimal::from_bps(vault.management_fee_bps);

    // Convert to per-second rate: annual_rate / seconds_per_year
    let per_second_rate = decimal::div(annual_fee_rate, decimal::from(SECONDS_PER_YEAR));

    // Fee factor for the elapsed time: elapsed_seconds * per_second_rate
    let fee_factor = decimal::mul(decimal::from(time_elapsed_s), per_second_rate);

    // Ensure fee factor doesn't exceed 100% (shouldn't happen with reasonable rates)
    let fee_factor = if (decimal::gt(fee_factor, decimal::from(1))) {
        decimal::from(1)
    } else {
        fee_factor
    };

    // Apply fee: nav_after_fee = nav_before_fee * (1 - fee_factor)
    let reduction_factor = decimal::sub(decimal::from(1), fee_factor);
    let adjusted_nav = decimal::mul(decimal::from(base_nav_per_share), reduction_factor);

    // Update timestamp
    vault.fee_last_update_timestamp_s = current_time_s;

    decimal::floor(adjusted_nav)
}

/// Calculate utilization rate in basis points
public fun calculate_utilization_rate<P>(vault: &Vault<P>, lending_market: &LendingMarket<P>): u64 {
    let total_value = calculate_total_vault_value(vault, lending_market);
    let liquid_asset_value = balance::value(&vault.deposit_asset);
    let usd_price = get_usd_price_for_asset<P>(lending_market);
    let liquid_value = decimal::mul(decimal::from(liquid_asset_value), usd_price).floor();

    if (total_value == 0) {
        0
    } else {
        let deployed_value = total_value - liquid_value;
        (deployed_value * BASIS_POINTS) / total_value
    }
}

/// Applies performance fees based on NAV growth
public fun compound_performance_fees<P>(
    vault: &mut Vault<P>,
    lending_market: &LendingMarket<P>,
    clock: &Clock,
) {
    if (vault.performance_fee_bps == 0 || vault.total_shares == 0) {
        vault.last_nav_per_share = calculate_nav_per_share(vault, lending_market);
        return
    };

    let current_nav_per_share = calculate_nav_per_share(vault, lending_market);

    // Apply performance fee only on NAV growth
    if (current_nav_per_share > vault.last_nav_per_share) {
        let nav_growth = current_nav_per_share - vault.last_nav_per_share;
        let nav_growth_decimal = decimal::from(nav_growth);
        let total_shares_decimal = decimal::from(vault.total_shares);

        // Calculate total value of the NAV growth
        let total_growth_value = decimal::mul(
            nav_growth_decimal,
            decimal::div(total_shares_decimal, decimal::from(NAV_PRECISION as u64)),
        );

        // Apply performance fee by reducing NAV per share
        let performance_fee = decimal::mul(
            total_growth_value,
            decimal::from_bps(vault.performance_fee_bps),
        );

        // Calculate fee per share and reduce NAV
        let fee_per_share = decimal::div(
            decimal::mul(performance_fee, decimal::from(NAV_PRECISION as u64)),
            total_shares_decimal,
        );
        let adjusted_nav = decimal::sub(decimal::from(current_nav_per_share), fee_per_share);
        vault.last_nav_per_share = decimal::floor(adjusted_nav);

        // Emit performance fee event
        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::PerformanceFee,
            fee_amount: decimal::floor(performance_fee),
            fee_receiver: vault.fee_receiver,
            timestamp_ms: clock::timestamp_ms(clock),
        });
    } else {
        vault.last_nav_per_share = current_nav_per_share;
    };
}

// === Vault Manager Functions ===

/// Validate that a manager cap belongs to a specific vault
public fun validate_manager_cap<P>(vault: &Vault<P>, manager_cap: &VaultManagerCap<P>) {
    assert!(manager_cap.vault_id == object::id(vault), EInvalidManager);
}

/// Create a new obligation for the vault
public fun create_obligation<P>(
    vault_manager_cap: &VaultManagerCap<P>,
    vault: &mut Vault<P>,
    lending_market: &mut LendingMarket<P>,
    ctx: &mut TxContext,
): u64 {
    assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
    validate_manager_cap(vault, vault_manager_cap);

    let obligation_cap = lending_market::create_obligation<P>(lending_market, ctx);
    vector::push_back(&mut vault.obligations, obligation_cap);

    // Return the index of the newly created obligation
    vector::length(&vault.obligations) - 1
}

/// Get obligation cap at index (read-only)
public fun get_obligation_cap<P>(vault: &Vault<P>, index: u64): &ObligationOwnerCap<P> {
    vector::borrow(&vault.obligations, index)
}

/// Get mutable obligation cap at index (manager only)
public fun get_obligation_cap_mut<P>(
    vault_manager_cap: &VaultManagerCap<P>,
    vault: &mut Vault<P>,
    index: u64,
): &mut ObligationOwnerCap<P> {
    validate_manager_cap(vault, vault_manager_cap);
    vector::borrow_mut(&mut vault.obligations, index)
}

/// Get number of obligations in vault
public fun obligation_count<P>(vault: &Vault<P>): u64 {
    vector::length(&vault.obligations)
}

// === Test Functions ===
#[test_only]
public fun deposit_for_testing<P>(
    vault: &mut Vault<P>,
    deposit: Coin<P>,
    _clock: &Clock,
    ctx: &mut TxContext,
): Coin<VaultShare<P>> {
    assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
    assert!(coin::value(&deposit) >= MIN_DEPOSIT, EInvalidDeposit);

    let deposit_amount = coin::value(&deposit);

    let deposit_fee = (deposit_amount * vault.deposit_fee_bps) / BASIS_POINTS;
    let net_deposit_amount = deposit_amount - deposit_fee;

    let mut deposit = deposit;
    let fee_coins = coin::split(&mut deposit, deposit_fee, ctx);
    sui::transfer::public_transfer(fee_coins, vault.fee_receiver);

    balance::join(&mut vault.deposit_asset, coin::into_balance(deposit));

    let shares_to_mint = if (vault.total_shares == 0) {
        net_deposit_amount
    } else {
        // Simple proportional calculation for testing
        (net_deposit_amount * vault.total_shares) / balance::value(&vault.deposit_asset)
    };

    let vault_shares = coin::mint(&mut vault.treasury_cap, shares_to_mint, ctx);
    vault.total_shares = vault.total_shares + shares_to_mint;
    vault.utilization_rate_bps = 0;

    vault_shares
}

#[test_only]
public fun withdraw_for_testing<P>(
    vault: &mut Vault<P>,
    shares: Coin<VaultShare<P>>,
    _clock: &Clock,
    ctx: &mut TxContext,
): Coin<P> {
    assert!(vault.version == CURRENT_VERSION, EIncorrectVersion);
    assert!(coin::value(&shares) > 0, EInsufficientShares);

    let shares_amount = coin::value(&shares);

    assert!(vault.total_shares >= shares_amount, EInsufficientShares);
    assert!(vault.total_shares > 0, EInsufficientShares);

    // Calculate withdrawal amount BEFORE burning shares
    let total_assets = balance::value(&vault.deposit_asset);
    let withdraw_amount = (shares_amount * total_assets) / vault.total_shares;

    // Now burn the shares
    coin::burn(&mut vault.treasury_cap, shares);
    vault.total_shares = vault.total_shares - shares_amount;

    let withdrawal_fee = (withdraw_amount * vault.withdrawal_fee_bps) / BASIS_POINTS;
    let mut withdrawn_balance = balance::split(&mut vault.deposit_asset, withdraw_amount);

    if (withdrawal_fee > 0) {
        let fee_balance = balance::split(&mut withdrawn_balance, withdrawal_fee);
        let fee_coins = coin::from_balance(fee_balance, ctx);
        sui::transfer::public_transfer(fee_coins, vault.fee_receiver);
    };

    vault.utilization_rate_bps = 0;
    coin::from_balance(withdrawn_balance, ctx)
}

#[test_only]
public fun create_vault_for_testing<P>(
    fee_receiver: address,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): (Vault<P>, VaultManagerCap<P>) {
    let share_treasury_cap = coin::create_treasury_cap_for_testing<VaultShare<P>>(ctx);

    create_vault(
        fee_receiver,
        management_fee_bps,
        performance_fee_bps,
        deposit_fee_bps,
        withdrawal_fee_bps,
        share_treasury_cap,
        clock,
        ctx,
    )
}
