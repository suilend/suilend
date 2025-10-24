module vaults::vault;

use pyth::{price_identifier::PriceIdentifier, price_info::PriceInfoObject};
use std::type_name::{Self, TypeName};
use steamm::{cpmm::{Self, CpQuoter}, pool::Pool};
use sui::{
    bag,
    balance::{Self, Balance},
    clock::Clock,
    coin::{Self, TreasuryCap, Coin},
    coin_registry,
    event
};
use suilend::{decimal, lending_market::{ObligationOwnerCap, LendingMarket}, oracles};

// === Errors ===
#[error]
const EInvalidManager: vector<u8> = b"Unauthorised VaultManagerCap";
#[error]
const EInvalidDepositFeeBps: vector<u8> = b"MAX_DEPOSIT_FEE_BPS exceeded";
#[error]
const EInvalidWithdrawalFeeBps: vector<u8> = b"MAX_WITHDRAWAL_FEE_BPS exceeded";
#[error]
const EInvalidPerformanceFeeBps: vector<u8> = b"MAX_PERFORMANCE_FEE_BPS exceeded";
#[error]
const EInvalidManagementFeeBps: vector<u8> = b"MAX_MANAGEMENT_FEE_BPS exceeded";
#[error]
const EInvalidDeposit: vector<u8> = b"Invalid deposit amount";
#[error]
const EInsufficientShares: vector<u8> = b"Invalid shares amount";
#[error]
const EInsufficientLiquidity: vector<u8> = b"Insufficient liquidity available";
#[error]
const EIncompleteAccumulation: vector<u8> = b"VaultValueAccumulator processing incomplete";
#[error]
const EInvalidShareCurrency: vector<u8> = b"Vault currency metadata is invalid";
#[error]
const EMetadataCapExists: vector<u8> = b"Vault currency MetadataCap hasn't been burned";
#[error]
const EInvalidPrice: vector<u8> = b"Invalid PriceInfoObject supplied";

// === Constants ===
const CURRENT_VERSION: u16 = 1;
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
const VAULT_SHARE_DECIMALS: u8 = 6;
const VAULT_SHARE_NAME: vector<u8> = b"Vault Shares";
const VAULT_SHARE_SYMBOL: vector<u8> = b"VSHARES";

// === Structs ===
public struct Vault<phantom P, phantom T> has key, store {
    id: object::UID,
    version: vaults::version::Version,
    // Keyed by 'L' from LendingMarket<L>
    obligations: sui::vec_map::VecMap<TypeName, vector<ObligationData>>,
    treasury_cap: TreasuryCap<P>,
    price_identifier: PriceIdentifier,
    base_token_decimals: u8,
    deposit_asset: Balance<T>,
    manager_fees: Balance<P>,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
    // Fee accrual state
    nav_high_water_mark: u64, // Highest NAV per share achieved (for performance fees)
    fee_last_update_timestamp_s: u64,
}

public struct ObligationData has store {
    // bag.OBLIGATION_CAP_BAG_KEY = ObligationOwnerCap<L>
    obligation_cap: bag::Bag,
    obligation_id: ID,
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

public struct VaultStats has copy, drop {
    vault_id: object::ID,
    nav_per_share_usd: u64,
    utilization_rate_bps: u64,
    aum_usd: u64,
    total_shares: u64,
}

// === Vault Manager Functions ===

public fun create_vault<P, L, T>(
    vault_share_treasury_cap: TreasuryCap<P>,
    vault_share_currency: &coin_registry::Currency<P>,
    lending_market: &LendingMarket<L>,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
    clock: &Clock,
    ctx: &mut tx_context::TxContext,
): VaultManagerCap<P> {
    // TODO: temporarily disabled
    assert!(vault_share_currency.is_metadata_cap_deleted() || true, EMetadataCapExists);
    assert!(vault_share_currency.decimals() == VAULT_SHARE_DECIMALS, EInvalidShareCurrency);
    assert!(vault_share_currency.name() == VAULT_SHARE_NAME.to_string(), EInvalidShareCurrency);
    assert!(
        vault_share_currency.description() == VAULT_SHARE_NAME.to_string(),
        EInvalidShareCurrency,
    );
    assert!(vault_share_currency.symbol() == VAULT_SHARE_SYMBOL.to_string(), EInvalidShareCurrency);
    assert!(vault_share_treasury_cap.total_supply() == 0, EInvalidShareCurrency);

    assert!(management_fee_bps <= MAX_MANAGEMENT_FEE_BPS, EInvalidManagementFeeBps);
    assert!(performance_fee_bps <= MAX_PERFORMANCE_FEE_BPS, EInvalidPerformanceFeeBps);
    assert!(deposit_fee_bps <= MAX_DEPOSIT_FEE_BPS, EInvalidDepositFeeBps);
    assert!(withdrawal_fee_bps <= MAX_WITHDRAWAL_FEE_BPS, EInvalidWithdrawalFeeBps);

    let vault_id = object::new(ctx);

    let reserve = lending_market.reserve<_, T>();
    let base_token_decimals = get_mint_decimals(reserve);
    let price_identifier = *reserve.price_identifier();

    let current_time_s = clock.timestamp_ms() / 1000;

    // Create vault
    let vault = Vault {
        id: vault_id,
        version: vaults::version::new(CURRENT_VERSION),
        treasury_cap: vault_share_treasury_cap,
        obligations: sui::vec_map::empty(),
        deposit_asset: balance::zero<T>(),
        manager_fees: balance::zero<P>(),
        base_token_decimals,
        management_fee_bps,
        performance_fee_bps,
        deposit_fee_bps,
        withdrawal_fee_bps,
        price_identifier,
        // Initialize fee accrual state
        nav_high_water_mark: NAV_PRECISION as u64,
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
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.validate_manager_cap(vault_manager_cap);
    assert!(amount > 0, EInvalidDeposit);

    vault.accrue_all_fees(&agg, clock);

    // Check if vault has sufficient liquid assets
    let available_amount = vault.deposit_asset.value();
    assert!(available_amount >= amount, EInsufficientLiquidity);

    // Check if deployment would exceed utilization limits
    let usd_to_deploy = get_usd_value_for_token_amount_from_lending_market<_, T>(
        lending_market,
        amount,
    );
    assert!(can_deploy_funds(&agg, usd_to_deploy), EInsufficientLiquidity);

    // Split funds from vault's deposit asset
    let deploy_balance = vault.deposit_asset.split(amount);
    let deploy_coin = coin::from_balance(deploy_balance, ctx);

    // Get reserve index for the asset type T
    let reserve_array_index = lending_market.reserve_array_index<_, T>();

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

    event::emit(ManagerAllocate {
        vault_id: object::id(vault),
        user: ctx.sender(),
        deposit_amount: amount,
        timestamp_ms: clock.timestamp_ms(),
    });

    {
        let updated_liquid_asset_value_usd = {
            let liquid_asset_value = vault.deposit_asset.value();
            get_usd_value_for_token_amount_from_lending_market<_, T>(
                lending_market,
                liquid_asset_value,
            ).floor()
        };
        let updated_obligation_value_usd = agg.total_obligation_value_usd + usd_to_deploy.floor();
        let updated_agg = VaultValueAggregate {
            liquid_asset_value_usd: updated_liquid_asset_value_usd,
            total_obligation_value_usd: updated_obligation_value_usd,
            lending_market_values: agg.lending_market_values,
        };
        vault.emit_stats_event(&updated_agg);
    };

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
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.validate_manager_cap(vault_manager_cap);
    assert!(ctoken_amount > 0, EInsufficientShares);

    vault.accrue_all_fees(&agg, clock);

    let lm_type = type_name::with_defining_ids<L>();
    let obligation_cap = vault.get_obligation_cap(&lm_type, obligation_index);

    // Get reserve index for the asset type T
    let reserve_array_index = lending_market.reserve_array_index<_, T>();

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

    event::emit(ManagerDivest {
        vault_id: object::id(vault),
        user: ctx.sender(),
        amount: withdrawn_amount,
        timestamp_ms: clock.timestamp_ms(),
    });

    {
        let updated_liquid_asset_value_usd = {
            let liquid_asset_value = vault.deposit_asset.value();
            get_usd_value_for_token_amount_from_lending_market<_, T>(
                lending_market,
                liquid_asset_value,
            ).floor()
        };
        let usd_withdrawn = get_usd_value_for_token_amount_from_lending_market<_, T>(
            lending_market,
            withdrawn_amount,
        ).floor();
        let updated_obligation_value_usd = if (agg.total_obligation_value_usd >= usd_withdrawn) {
            agg.total_obligation_value_usd - usd_withdrawn
        } else {
            0
        };
        let updated_agg = VaultValueAggregate {
            liquid_asset_value_usd: updated_liquid_asset_value_usd,
            total_obligation_value_usd: updated_obligation_value_usd,
            lending_market_values: agg.lending_market_values,
        };
        vault.emit_stats_event(&updated_agg);
    };
}

/// Claim accumulated manager fees
public fun claim_manager_fees<P, T>(
    vault: &mut Vault<P, T>,
    vault_manager_cap: &VaultManagerCap<P>,
    amount: u64,
    ctx: &mut TxContext,
): Coin<P> {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
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
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
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

/// Validate that a manager cap belongs to a specific vault
fun validate_manager_cap<P, T>(vault: &Vault<P, T>, manager_cap: &VaultManagerCap<P>) {
    assert!(manager_cap.vault_id == object::id(vault), EInvalidManager);
}

// === User Functions ===

public fun deposit<P, T>(
    vault: &mut Vault<P, T>,
    deposit: Coin<T>,
    price_info: &PriceInfoObject,
    clock: &Clock,
    agg: VaultValueAggregate,
    ctx: &mut TxContext,
): Coin<P> {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
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
        let fee_shares = vault.calculate_shares_to_mint(deposit_fee, price_info, clock, &agg);
        let fee_balance = vault.treasury_cap.mint_balance(fee_shares);
        vault.manager_fees.join(fee_balance);

        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::DepositFee,
            fee_shares: fee_shares,
            timestamp_ms: current_time,
        });
    };

    // Calculate shares to mint based on current USD NAV
    let shares_to_mint = vault.calculate_shares_to_mint(
        net_deposit_amount,
        price_info,
        clock,
        &agg,
    );

    assert!(shares_to_mint > 0, EInvalidDeposit);

    // Mint vault shares
    let vault_shares = vault.treasury_cap.mint(shares_to_mint, ctx);

    // Emit deposit event
    event::emit(VaultDeposit {
        vault_id: object::id(vault),
        user: user,
        deposit_amount: deposit_amount,
        shares_minted: shares_to_mint,
        timestamp_ms: current_time,
    });

    {
        let updated_liquid_asset_value_usd = {
            let liquid_asset_value = vault.deposit_asset.value();
            vault
                .get_usd_value_for_token_amount<_, T>(
                    price_info,
                    clock,
                    liquid_asset_value,
                )
                .floor()
        };
        let updated_agg = VaultValueAggregate {
            liquid_asset_value_usd: updated_liquid_asset_value_usd,
            total_obligation_value_usd: agg.total_obligation_value_usd,
            lending_market_values: agg.lending_market_values,
        };
        vault.emit_stats_event(&updated_agg);
    };

    vault_shares
}

/// User burns shares and withdraws proportional assets with performance fees on realized gains
public fun withdraw<P, T>(
    vault: &mut Vault<P, T>,
    shares: Coin<P>,
    price_info: &PriceInfoObject,
    clock: &Clock,
    agg: VaultValueAggregate,
    ctx: &mut TxContext,
): Coin<T> {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    assert!(shares.value() > 0, EInsufficientShares);

    let shares_amount = shares.value();
    let user = ctx.sender();
    let current_time = clock.timestamp_ms();

    vault.accrue_all_fees(&agg, clock);

    // Calculate withdrawal fee in shares
    let withdrawal_fee_shares = (shares_amount * vault.withdrawal_fee_bps) / BASIS_POINTS;
    let net_shares = shares_amount - withdrawal_fee_shares;

    // Calculate total USD value of net shares being redeemed
    let current_nav_per_share = vault.calculate_nav_per_share(&agg);
    let net_usd_value =
        (((net_shares as u128) * (current_nav_per_share as u128)) / NAV_PRECISION) as u64;

    // Convert net USD value to token amount
    let withdraw_amount = vault
        .get_token_amount_from_usd(
            price_info,
            clock,
            net_usd_value,
        )
        .floor();

    // Check if vault has sufficient liquidity for withdrawal
    let available_amount = vault.deposit_asset.value();
    assert!(withdraw_amount <= available_amount, EInsufficientLiquidity);

    assert!(withdraw_amount > 0, EInsufficientShares);

    // Split shares into user portion (to burn) and fee portion (to manager)
    let mut shares_balance = shares.into_balance();
    let fee_balance = shares_balance.split(withdrawal_fee_shares);

    // Burn user's shares
    vault.treasury_cap.burn(coin::from_balance(shares_balance, ctx));

    // Transfer fee shares to manager
    vault.manager_fees.join(fee_balance);

    if (withdrawal_fee_shares > 0) {
        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::WithdrawalFee,
            fee_shares: withdrawal_fee_shares,
            timestamp_ms: current_time,
        });
    };

    let withdrawn_balance = vault.deposit_asset.split(withdraw_amount);

    let coins = coin::from_balance(withdrawn_balance, ctx);

    event::emit(VaultWithdraw {
        vault_id: object::id(vault),
        user: user,
        amount: withdraw_amount,
        shares_burned: shares_amount,
        timestamp_ms: current_time,
    });

    {
        let updated_liquid_asset_value_usd = {
            let liquid_asset_value = vault.deposit_asset.value();
            vault
                .get_usd_value_for_token_amount<_, T>(
                    price_info,
                    clock,
                    liquid_asset_value,
                )
                .floor()
        };
        let updated_agg = VaultValueAggregate {
            liquid_asset_value_usd: updated_liquid_asset_value_usd,
            total_obligation_value_usd: agg.total_obligation_value_usd,
            lending_market_values: agg.lending_market_values,
        };
        vault.emit_stats_event(&updated_agg);
    };

    coins
}

// === Vault Rewards Functions ===

/// Compound rewards of same type as deposit asset
/// Permissionless
public fun compound_rewards<P, L, T>(
    vault: &Vault<P, T>,
    lending_market: &mut LendingMarket<L>,
    obligation_index: u64,
    reward_reserve_index: u64,
    reward_index: u64,
    is_deposit_reward: bool,
    deposit_reserve_index: u64,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    vault.version.assert_version(CURRENT_VERSION);

    let lm_type = type_name::with_defining_ids<L>();
    let obligation_cap = vault.get_obligation_cap<_, L, _>(&lm_type, obligation_index);
    let obligation_id = obligation_cap.obligation_id();

    // Claim rewards and deposit them back into the obligation
    lending_market.claim_rewards_and_deposit<L, T>(
        obligation_id,
        clock,
        reward_reserve_index,
        reward_index,
        is_deposit_reward,
        deposit_reserve_index,
        ctx,
    );
}

/// Compound rewards of a different token type by swapping through a Steamm pool
/// This allows compounding rewards that don't match the vault's base asset type
/// Manager restricted
public fun compound_rewards_with_swap<P, L, T, R, LpType: drop>(
    vault: &Vault<P, T>,
    vault_manager_cap: &VaultManagerCap<P>,
    lending_market: &mut LendingMarket<L>,
    swap_pool: &mut Pool<R, T, CpQuoter, LpType>,
    obligation_index: u64,
    reward_reserve_index: u64,
    reward_index: u64,
    is_deposit_reward: bool,
    deposit_reserve_index: u64,
    min_amount_out: u64,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    vault.version.assert_version(CURRENT_VERSION);
    vault.validate_manager_cap(vault_manager_cap);

    let lm_type = type_name::with_defining_ids<L>();
    let obligation_cap = vault.get_obligation_cap<_, L, _>(&lm_type, obligation_index);

    // Claim rewards of type R
    let mut reward_coin = lending_market.claim_rewards<L, R>(
        obligation_cap,
        clock,
        reward_reserve_index,
        reward_index,
        is_deposit_reward,
        ctx,
    );

    let reward_amount = reward_coin.value();

    if (reward_amount == 0) {
        coin::destroy_zero(reward_coin);
        return
    };

    // Swap R -> T
    // Create an empty coin of type T to receive the swapped amount
    let mut t_coin = coin::zero<T>(ctx);

    let _swap_result = cpmm::swap(
        swap_pool,
        &mut reward_coin,
        &mut t_coin,
        true, // swap R -> T
        reward_amount,
        min_amount_out,
        ctx,
    );

    // Reward coin should now be empty, destroy it
    coin::destroy_zero(reward_coin);

    // Convert swapped T into cTokens
    let ctokens = lending_market.deposit_liquidity_and_mint_ctokens<L, T>(
        deposit_reserve_index,
        clock,
        t_coin,
        ctx,
    );

    // Deposit cTokens into the obligation
    lending_market.deposit_ctokens_into_obligation<L, T>(
        deposit_reserve_index,
        obligation_cap,
        clock,
        ctokens,
        ctx,
    );
}

// === Fee Management Functions ===

/// Apply calculated fees to the vault, minting shares and updating state
fun apply_fee_accrual<P, T>(vault: &mut Vault<P, T>, accrual: FeeAccrual, clock: &Clock) {
    let current_time = clock.timestamp_ms();

    // Mint management fee shares if any
    if (accrual.management_fee_shares > 0) {
        let fee_balance = vault.treasury_cap.mint_balance(accrual.management_fee_shares);
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
        let fee_balance = vault.treasury_cap.mint_balance(accrual.performance_fee_shares);
        vault.manager_fees.join(fee_balance);

        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::PerformanceFee,
            fee_shares: accrual.performance_fee_shares,
            timestamp_ms: current_time,
        });
    };

    if (accrual.new_nav_per_share > vault.nav_high_water_mark) {
        vault.nav_high_water_mark = accrual.new_nav_per_share;
    };

    vault.fee_last_update_timestamp_s = clock.timestamp_ms() / 1000;
}

/// Unified fee accrual function - calculates and applies all fees atomically
/// This replaces the deprecated apply_management_fee_to_nav function
fun accrue_all_fees<P, T>(vault: &mut Vault<P, T>, agg: &VaultValueAggregate, clock: &Clock) {
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
    let current_shares = vault.treasury_cap.total_supply();

    // 2. Calculate management fee shares
    let management_fee_shares = calculate_management_fee_shares(vault, clock);

    // 3. Calculate performance fee accounting for management fee dilution
    let performance_fee_shares = calculate_performance_fee_shares(
        vault,
        base_nav,
        current_shares,
        management_fee_shares,
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

    // Apply performance fee only when NAV exceeds high water mark
    if (current_nav_per_share <= vault.nav_high_water_mark) {
        return 0
    };

    // Total value at current NAV
    let total_value = ((current_nav_per_share as u128) * (current_shares as u128)) / NAV_PRECISION;

    // Total value at high water mark (baseline for performance)
    let baseline_value =
        ((vault.nav_high_water_mark as u128) * (current_shares as u128)) / NAV_PRECISION;

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

fun calculate_management_fee_shares<P, T>(vault: &Vault<P, T>, clock: &Clock): u64 {
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

    let circulating_shares = vault.treasury_cap.total_supply();

    // Ensures fees represent exactly the correct percentage of total vault value
    let one_minus_fee = decimal::sub(decimal::from(1), fee_factor);
    let shares_to_mint = decimal::div(
        decimal::mul(decimal::from(circulating_shares), fee_factor),
        one_minus_fee,
    );

    decimal::floor(shares_to_mint)
}

// === Vault Value Aggregation ===
// Required in order to accomodate conflicting LendingMarket type parameters

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
        get_usd_value_for_token_amount_from_lending_market<L, T>(
            lending_market,
            liquid_asset_value,
        ).floor()
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

// === Public Helpers ===

/// Calculates the amount of shares that will be minted for deposit_amount of T
public fun calculate_shares_to_mint<P, T>(
    vault: &Vault<P, T>,
    deposit_amount: u64,
    price_info: &PriceInfoObject,
    clock: &Clock,
    agg: &VaultValueAggregate,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(agg);
    let deposit_usd_value = vault
        .get_usd_value_for_token_amount<_, T>(
            price_info,
            clock,
            deposit_amount,
        )
        .floor();
    calculate_shares_from_usd(nav_per_share, deposit_usd_value)
}

/// Calculates the amount of shares that must be burned to redeem withdraw_amount of T
public fun calculate_shares_to_burn<P, L, T>(
    vault: &Vault<P, T>,
    withdraw_amount: u64,
    lending_market: &LendingMarket<L>,
    agg: VaultValueAggregate,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(&agg);
    let withdraw_usd_value = get_usd_value_for_token_amount_from_lending_market<_, T>(
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
    get_token_amount_from_usd_from_lending_market<_, T>(
        lending_market,
        withdraw_usd_value as u64,
    ).floor()
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
    get_token_amount_from_usd_from_lending_market<_, T>(
        lending_market,
        deposit_usd_value as u64,
    ).floor()
}

public fun calculate_utilization_rate(agg: &VaultValueAggregate): u64 {
    let total_vault_value = agg.liquid_asset_value_usd + agg.total_obligation_value_usd;

    if (total_vault_value == 0) {
        // TODO: should panic?
        return 0
    };

    let utilization = (agg.total_obligation_value_usd * BASIS_POINTS) / total_vault_value;

    utilization
}

/// Check if vault can deploy a USD amount of liquid assets (and vault remains under MAX_UTILIZATION_RATE_BPS)
public fun can_deploy_funds(agg: &VaultValueAggregate, usd_amount: decimal::Decimal): bool {
    let liquid_asset_value = agg.liquid_asset_value_usd;
    let usd_to_deploy = usd_amount.floor();

    // Check if there is enough liquid assets to deploy
    if (usd_to_deploy > liquid_asset_value) {
        return false
    };

    let updated_agg = VaultValueAggregate {
        liquid_asset_value_usd: liquid_asset_value - usd_to_deploy,
        total_obligation_value_usd: agg.total_obligation_value_usd + usd_to_deploy,
        lending_market_values: agg.lending_market_values,
    };

    let new_utilization = updated_agg.calculate_utilization_rate();

    new_utilization <= MAX_UTILIZATION_RATE_BPS
}

public fun calculate_nav_per_share<P, T>(vault: &Vault<P, T>, agg: &VaultValueAggregate): u64 {
    let current_shares = vault.treasury_cap.total_supply();
    let vault_value = agg.total_obligation_value_usd + agg.liquid_asset_value_usd;
    if (current_shares == 0 || vault_value == 0) {
        NAV_PRECISION as u64 // 1.0 scaled
    } else {
        (((vault_value as u128) * NAV_PRECISION) / (current_shares as u128)) as u64
    }
}

/// Total supply of shares
public fun total_supply<P, T>(vault: &Vault<P, T>): u64 {
    vault.treasury_cap.total_supply()
}

// === Private Helpers ===

/// Calculates vault shares from USD amount
/// TODO: Check for truncation
fun calculate_shares_from_usd(nav_per_share: u64, usd_amount: u64): u64 {
    (((usd_amount as u128) * NAV_PRECISION) / (nav_per_share as u128)) as u64
}

// Temporary
// reserve.mint_decimals is not exposed
fun get_mint_decimals<L>(reserve: &suilend::reserve::Reserve<L>): u8 {
    let price_upper = reserve.price_upper_bound();

    // usd_to_token_amount_lower_bound returns (10^decimals * usd_amount) / price_upper
    // If we pass usd_amount = price_upper, we get 10^decimals
    let power_of_ten = reserve.usd_to_token_amount_lower_bound(price_upper);

    let mut decimals = 0;
    while (decimals <= 18) {
        let test_power = decimal::from(10u64.pow(decimals));
        if (test_power.eq(power_of_ten)) {
            return decimals
        };
        decimals = decimals + 1;
    };

    // If exact match not found, find closest
    let mut best_decimals = 0;
    let mut best_diff = decimal::from(10u64.pow(18));

    decimals = 0;
    while (decimals <= 18) {
        let test_power = decimal::from(10u64.pow(decimals));
        let diff = if (test_power.le(power_of_ten)) {
            power_of_ten.sub(test_power)
        } else {
            test_power.sub(power_of_ten)
        };

        if (diff.le(best_diff)) {
            best_diff = diff;
            best_decimals = decimals;
        };

        decimals = decimals + 1;
    };

    best_decimals
}

/// Calculate total obligation value within one Lending Market in USD
fun calculate_obligation_values_usd<L>(
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

/// Get T amount from USD amount
fun get_token_amount_from_usd_from_lending_market<L, T>(
    lending_market: &LendingMarket<L>,
    amount: u64,
): decimal::Decimal {
    let reserve = lending_market.reserve<_, T>();
    // TODO
    //reserve.assert_price_is_fresh(clock);
    reserve.usd_to_token_amount_lower_bound(decimal::from(amount))
}

/// Get T amount from USD amount
fun get_token_amount_from_usd<P, T>(
    vault: &Vault<P, T>,
    price_info: &PriceInfoObject,
    clock: &Clock,
    amount: u64,
): decimal::Decimal {
    // TODO: check freshness
    let (
        mut price_decimal,
        smoothed_price_decimal,
        price_identifier,
    ) = oracles::get_pyth_price_and_identifier(price_info, clock);
    assert!(price_identifier == vault.price_identifier, EInvalidPrice);
    assert!(price_decimal.is_some(), EInvalidPrice);

    let price = price_decimal.extract();

    decimal::from(amount)
        .mul(decimal::from(10u64.pow(vault.base_token_decimals)))
        .div(price.max(smoothed_price_decimal))
}

/// Get USD amount from T amount
fun get_usd_value_for_token_amount_from_lending_market<L, T>(
    lending_market: &LendingMarket<L>,
    amount: u64,
): decimal::Decimal {
    let reserve = lending_market.reserve<_, T>();
    // TODO
    //reserve.assert_price_is_fresh(clock);
    reserve.market_value_lower_bound(decimal::from(amount))
}

/// Get USD amount from T amount
fun get_usd_value_for_token_amount<P, T>(
    vault: &Vault<P, T>,
    price_info: &PriceInfoObject,
    clock: &Clock,
    amount: u64,
): decimal::Decimal {
    // TODO: check freshness
    let (
        mut price_decimal,
        smoothed_price_decimal,
        price_identifier,
    ) = oracles::get_pyth_price_and_identifier(price_info, clock);
    assert!(price_identifier == vault.price_identifier, EInvalidPrice);
    assert!(price_decimal.is_some(), EInvalidPrice);

    let price = price_decimal.extract();

    price
        .min(smoothed_price_decimal)
        .mul(decimal::from(amount))
        .div(
            decimal::from(10u64.pow(vault.base_token_decimals)),
        )
}

fun emit_stats_event<P, T>(vault: &Vault<P, T>, agg: &VaultValueAggregate) {
    let nav_per_share_usd = vault.calculate_nav_per_share(agg);
    let aum_usd = agg.total_obligation_value_usd + agg.liquid_asset_value_usd;
    let utilization_rate_bps = calculate_utilization_rate(agg);
    event::emit(VaultStats {
        vault_id: object::id(vault),
        nav_per_share_usd,
        utilization_rate_bps,
        aum_usd,
        total_shares: vault.total_supply(),
    });
}

/// Get obligation cap at lending_market_type + index (read-only)
public(package) fun get_obligation_cap<P, L, T>(
    vault: &Vault<P, T>,
    // TODO: remove
    lending_market_type: &TypeName,
    index: u64,
): &ObligationOwnerCap<L> {
    // TODO: access checks + error codes
    let obligations = vault.obligations.get(lending_market_type);
    let obl = obligations.borrow(index);
    obl.obligation_cap.borrow(OBLIGATION_CAP_BAG_KEY)
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

#[test_only]
public fun accrue_fees_for_testing<P, T>(
    vault: &mut Vault<P, T>,
    agg: &VaultValueAggregate,
    clock: &Clock,
) {
    accrue_all_fees(vault, agg, clock)
}
