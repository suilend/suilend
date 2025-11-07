module vaults::vault;

use std::type_name::{Self, TypeName};
use steamm::{cpmm::{Self, CpQuoter}, pool::Pool};
use sui::{
    bag,
    balance::{Self, Balance},
    clock::Clock,
    coin::{Self, TreasuryCap, Coin},
    coin_registry,
    event,
    vec_map
};
use suilend::{
    decimal::{Self, Decimal},
    lending_market::{ObligationOwnerCap, LendingMarket},
    liquidity_mining
};

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
const EVaultMismatch: vector<u8> = b"Vault ID mismatch";
#[error]
const ERewardsStale: vector<u8> = b"Rewards must be compounded";
#[error]
const EBaseTokenReward: vector<u8> = b"Base token rewards should not be swapped";
#[error]
const EUnclaimedRewards: vector<u8> = b"All rewards must be claimed before cranking";
#[error]
const EUnwindNotNeeded: vector<u8> = b"Enough liquidity exists to redeem shares";
#[error]
const EIncorrectOrder: vector<u8> = b"LendingMarket processed out of order";
#[error]
const EInsufficientLiquidityForUnwind: vector<u8> =
    b"Enough liquidity to redeem shares was not found";
#[error]
const EMetadataCapExists: vector<u8> = b"Vault currency MetadataCap hasn't been burned";

// === Constants ===
const CURRENT_VERSION: u16 = 1;
const MAX_DEPOSIT_FEE_BPS: u64 = 1000; // 10% max deposit fee
const MAX_WITHDRAWAL_FEE_BPS: u64 = 1000; // 10% max withdrawal fee
const MAX_PERFORMANCE_FEE_BPS: u64 = 5000; // 50% max performance fee
const MAX_MANAGEMENT_FEE_BPS: u64 = 1000; // 10% max management fee
const MIN_DEPOSIT_USD_SCALED: u256 = 100_000_000_000_000_000; // Minimum deposit 0.1 USD (0.1 * 1e18)
const BASIS_POINTS: u64 = 10000; // 100%
const NAV_PRECISION: u128 = 1_000_000_000; // 1e9 for NAV per share calculations
const MAX_REWARDS_STALENESS_MS: u64 = 3_600_000; // 1 hour in ms
const SECONDS_PER_YEAR: u64 = 31_536_000; // 365 * 24 * 60 * 60
const OBLIGATION_CAP_BAG_KEY: u8 = 0;
const VAULT_SHARE_DECIMALS: u8 = 6;
const VAULT_SHARE_SYMBOL: vector<u8> = b"VSHARES";
const VAULT_SHARE_NAME: vector<u8> = b"Vault Shares";

// === Structs ===

// V = Unique currency to represent vault shares, T = Base token which vault manages for users
public struct Vault<phantom V, phantom T> has key, store {
    id: object::UID,
    version: vaults::version::Version,
    metadata: vec_map::VecMap<std::string::String, std::string::String>,
    // Keyed by 'L' from LendingMarket<L>
    obligations: vec_map::VecMap<TypeName, vector<ObligationData>>,
    treasury_cap: TreasuryCap<V>,
    deposit_asset: Balance<T>,
    manager_fees: Balance<V>,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
    slippage_bps: u64,
    redemption_ratio_high_water_mark: Decimal, // Highest redemption ratio achieved (vault_value_in_base_asset / shares) for performance fees
    last_cranked_ms: u64, // timestamp_ms when rewards were last compounded and fees were last accrued
}

public struct ObligationData has store {
    // bag.OBLIGATION_CAP_BAG_KEY = ObligationOwnerCap<L>
    obligation_cap: bag::Bag,
    obligation_id: ID,
}

public struct VaultManagerCap<phantom V> has key, store {
    id: object::UID,
    vault_id: object::ID,
}

/// Used to aggregate the obligation values from all live LendingMarkets
/// Must be consumed in PTB
public struct VaultValueAccumulator {
    vault_id: ID,
    // Keyed by 'L' from LendingMarket<L>
    obligation_ids: vec_map::VecMap<TypeName, vector<ID>>,
    lending_market_allocations: vec_map::VecMap<TypeName, LendingMarketAllocation>,
}

/// Created from a VaultValueAccumulator once it has been fully processed
public struct VaultValueAggregate {
    vault_id: ID,
    liquid_asset_value_usd: Decimal,
    total_obligation_value_usd: Decimal,
    lending_market_allocations: vec_map::VecMap<TypeName, LendingMarketAllocation>,
}

/// Accumulator for vault crank operations (rewards + fees)
/// Processes all lending markets in the vault
/// Must be consumed in PTB by calling finalize_vault_crank
public struct VaultCrankAccumulator {
    vault_id: ID,
    // Keyed by LM TypeName -> obligation IDs (removed as each LM is scanned for outstanding rewards)
    pending_lending_markets: vec_map::VecMap<TypeName, vector<ID>>,
    // Keyed by LM TypeName -> allocation data (added as each LM is processed)
    lending_market_allocations: vec_map::VecMap<TypeName, LendingMarketAllocation>,
}

public struct LendingMarketAllocation has copy, drop, store {
    deposited_value_usd: Decimal,
    borrowed_value_usd: Decimal,
    net_value_usd: Decimal,
    obligations: vector<ObligationAllocation>,
}

public struct ObligationAllocation has copy, drop, store {
    obligation_id: ID,
    deposited_value_usd: Decimal,
    borrowed_value_usd: Decimal,
    net_value_usd: Decimal,
}

/// For tracking obligation unwinds needed to satisfy a withdrawal
/// Must be consumed by withdraw_with_unwind()
public struct VaultUnwindAccumulator<phantom V> {
    vault_id: ID,
    // base token
    target_withdraw_amount: u64,
    shares: balance::Balance<V>,
    // Keyed by lending market type -> vector of unwind targets in FIFO order
    pending_unwinds: vec_map::VecMap<TypeName, vector<UnwindTarget>>,
    agg: VaultValueAggregate,
}

/// Specifies an obligation position that needs to be unwound
public struct UnwindTarget has drop {
    obligation_index: u64,
    usd_to_recover: Decimal,
}

// === Events ===
public struct VaultCreated has copy, drop {
    vault_id: object::ID,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
    slippage_bps: u64,
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
    lending_market_id: object::ID,
    reserve_index: u64,
    obligation_index: u64,
    user: address,
    deposit_amount: u64,
    timestamp_ms: u64,
}

public struct ManagerDivest has copy, drop {
    vault_id: object::ID,
    lending_market_id: object::ID,
    reserve_index: u64,
    obligation_index: u64,
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
    base_token_type: type_name::TypeName,
    nav_per_share_usd: u64,
    utilization_rate_bps: u64,
    aum_usd: u64,
    total_shares: u64,
    lending_market_allocations: vec_map::VecMap<TypeName, LendingMarketAllocation>,
}

public struct ObligationUnwind has copy, drop {
    vault_id: object::ID,
    lending_market_id: object::ID,
    obligation_index: u64,
    reserve_index: u64,
    ctoken_amount: u64,
    token_amount: u64,
    timestamp_ms: u64,
}

// === Vault Manager Functions ===

public fun create_vault<V, T>(
    vault_share_treasury_cap: TreasuryCap<V>,
    vault_share_currency: &coin_registry::Currency<V>,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
    slippage_bps: u64,
    clock: &Clock,
    ctx: &mut tx_context::TxContext,
): VaultManagerCap<V> {
    assert!(vault_share_currency.is_metadata_cap_deleted(), EMetadataCapExists);
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

    let current_time_ms = clock.timestamp_ms();

    // Create vault
    let vault = Vault {
        id: vault_id,
        version: vaults::version::new(CURRENT_VERSION),
        metadata: vec_map::empty(),
        treasury_cap: vault_share_treasury_cap,
        obligations: vec_map::empty(),
        deposit_asset: balance::zero<T>(),
        manager_fees: balance::zero<V>(),
        management_fee_bps,
        performance_fee_bps,
        deposit_fee_bps,
        withdrawal_fee_bps,
        slippage_bps,
        redemption_ratio_high_water_mark: decimal::from(1), // Initial ratio is 1.0 (1 share = 1 base asset)
        last_cranked_ms: current_time_ms,
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
        slippage_bps,
    });

    transfer::public_share_object(vault);

    vault_manager_cap
}

/// Deploy funds from vault to lending market obligation
public fun deploy_funds<V, T, L>(
    vault: &mut Vault<V, T>,
    vault_manager_cap: &VaultManagerCap<V>,
    lending_market: &mut LendingMarket<L>, // Must contain reserve for T (price source)
    obligation_index: u64,
    amount: u64,
    clock: &Clock,
    mut agg: VaultValueAggregate,
    ctx: &mut TxContext,
): u64 {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.validate_manager_cap(vault_manager_cap);
    vault.assert_vault_state_fresh<V, T>(clock);
    assert!(amount > 0, EInvalidDeposit);

    // Check if vault has sufficient liquid assets
    let available_amount = vault.deposit_asset.value();
    assert!(available_amount >= amount, EInsufficientLiquidity);

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
        lending_market_id: object::id(lending_market),
        reserve_index: reserve_array_index,
        obligation_index,
        user: ctx.sender(),
        deposit_amount: amount,
        timestamp_ms: clock.timestamp_ms(),
    });

    {
        let updated_liquid_asset_value_usd = {
            let liquid_asset_value = vault.deposit_asset.value();
            get_usd_value_for_token_amount<_, T>(lending_market, liquid_asset_value, clock)
        };
        agg.liquid_asset_value_usd = updated_liquid_asset_value_usd;

        // Recalculate obligation allocations
        agg.refresh_aggregate_for_lending_market(vault, lending_market);

        vault.emit_stats_event(&agg);
        agg.destroy_vault_value_aggregate();
    };

    ctokens_amount
}

/// Withdraw funds from lending market obligation back to vault
public fun withdraw_deployed_funds<V, T, L>(
    vault: &mut Vault<V, T>,
    vault_manager_cap: &VaultManagerCap<V>,
    lending_market: &mut LendingMarket<L>, // Must contain reserve for T (price source)
    obligation_index: u64,
    ctoken_amount: u64,
    clock: &Clock,
    mut agg: VaultValueAggregate,
    ctx: &mut TxContext,
) {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.validate_manager_cap(vault_manager_cap);
    vault.assert_vault_state_fresh<V, T>(clock);
    assert!(ctoken_amount > 0, EInsufficientShares);

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
        lending_market_id: object::id(lending_market),
        reserve_index: reserve_array_index,
        obligation_index,
        user: ctx.sender(),
        amount: withdrawn_amount,
        timestamp_ms: clock.timestamp_ms(),
    });

    {
        let updated_liquid_asset_value_usd = {
            let liquid_asset_value = vault.deposit_asset.value();
            get_usd_value_for_token_amount<_, T>(lending_market, liquid_asset_value, clock)
        };
        agg.liquid_asset_value_usd = updated_liquid_asset_value_usd;

        // Recalculate obligation allocations
        agg.refresh_aggregate_for_lending_market(vault, lending_market);

        vault.emit_stats_event(&agg);
        agg.destroy_vault_value_aggregate();
    };
}

/// Claim accumulated manager fees
public fun claim_manager_fees<V, T>(
    vault: &mut Vault<V, T>,
    vault_manager_cap: &VaultManagerCap<V>,
    amount: u64,
    ctx: &mut TxContext,
): Coin<V> {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.validate_manager_cap(vault_manager_cap);

    let accrued_fees = vault.manager_fees.value();
    assert!(accrued_fees >= amount, EInsufficientShares);

    let fee_balance = vault.manager_fees.split(amount);
    let fee_coin = coin::from_balance(fee_balance, ctx);

    fee_coin
}

/// Create a new obligation for the vault
public fun create_obligation<V, T, L>(
    vault: &mut Vault<V, T>,
    vault_manager_cap: &VaultManagerCap<V>,
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

public fun set_metadata<V, T>(
    vault: &mut Vault<V, T>,
    vault_manager_cap: &VaultManagerCap<V>,
    key: std::string::String,
    value: std::string::String,
    _ctx: &mut TxContext,
) {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.validate_manager_cap(vault_manager_cap);

    if (vault.metadata.contains(&key)) {
        vault.metadata.remove(&key);
    };

    vault.metadata.insert(key, value);
}

public fun unset_metadata<V, T>(
    vault: &mut Vault<V, T>,
    vault_manager_cap: &VaultManagerCap<V>,
    key: std::string::String,
    _ctx: &mut TxContext,
) {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.validate_manager_cap(vault_manager_cap);

    if (vault.metadata.contains(&key)) {
        vault.metadata.remove(&key);
    };
}

// === User Functions ===

public fun deposit<V, T, L>(
    vault: &mut Vault<V, T>,
    deposit: Coin<T>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
    mut agg: VaultValueAggregate,
    ctx: &mut TxContext,
): Coin<V> {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.validate_aggregate(&agg);
    vault.assert_vault_state_fresh<V, T>(clock);

    let deposit_amount = deposit.value();
    let current_time = clock.timestamp_ms();
    let user = ctx.sender();

    // Check minimum deposit in USD terms
    {
        let deposit_usd_value = get_usd_value_for_token_amount<_, T>(
            lending_market,
            deposit_amount,
            clock,
        );
        assert!(
            decimal::from_scaled_val(MIN_DEPOSIT_USD_SCALED).le(deposit_usd_value),
            EInvalidDeposit,
        );
    };

    // Calculate shares for the entire deposit amount
    let total_shares_to_mint = calculate_shares_to_mint(
        vault,
        deposit_amount,
        lending_market,
        &agg,
        clock,
    );

    // Add deposited coins to vault
    vault.deposit_asset.join(deposit.into_balance());

    // Mint total shares
    let mut user_shares = vault.treasury_cap.mint(total_shares_to_mint, ctx);
    let total_shares = user_shares.value();

    let (user_share_allocation, fee_shares) = split_amount(total_shares, vault.deposit_fee_bps);
    assert!(user_share_allocation > 0, EInvalidDeposit);

    // Extract fees
    if (fee_shares > 0) {
        let fee_coin = user_shares.split(fee_shares, ctx);
        vault.manager_fees.join(fee_coin.into_balance());

        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::DepositFee,
            fee_shares,
            timestamp_ms: current_time,
        });
    };

    // Emit deposit event
    event::emit(VaultDeposit {
        vault_id: object::id(vault),
        user: user,
        deposit_amount: deposit_amount,
        shares_minted: total_shares,
        timestamp_ms: current_time,
    });

    {
        let updated_liquid_asset_value_usd = {
            let liquid_asset_value = vault.deposit_asset.value();
            get_usd_value_for_token_amount<_, T>(lending_market, liquid_asset_value, clock)
        };

        agg.liquid_asset_value_usd = updated_liquid_asset_value_usd;

        vault.emit_stats_event(&agg);
        agg.destroy_vault_value_aggregate();
    };

    user_shares
}

/// User burns shares and withdraws proportional assets with performance fees on realized gains
public fun withdraw<V, T, L>(
    vault: &mut Vault<V, T>,
    shares: Coin<V>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
    mut agg: VaultValueAggregate,
    ctx: &mut TxContext,
): Coin<T> {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.validate_aggregate(&agg);
    vault.assert_vault_state_fresh<V, T>(clock);
    assert!(shares.value() > 0, EInsufficientShares);

    let shares_amount = shares.value();
    let user = ctx.sender();
    let current_time = clock.timestamp_ms();

    // Calculate withdrawal fee in shares
    let (net_shares, withdrawal_fee_shares) = split_amount(shares_amount, vault.withdrawal_fee_bps);

    // Calculate total USD value of net shares being redeemed
    let current_nav_per_share = vault.calculate_nav_per_share(&agg);
    let net_usd_value = shares_to_usd(decimal::from(net_shares), current_nav_per_share);

    // Convert net USD value to token amount
    let withdraw_amount = get_token_amount_from_usd<_, T>(
        lending_market,
        net_usd_value,
        clock,
    ).floor();

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
            get_usd_value_for_token_amount<_, T>(lending_market, liquid_asset_value, clock)
        };

        agg.liquid_asset_value_usd = updated_liquid_asset_value_usd;

        vault.emit_stats_event(&agg);
        agg.destroy_vault_value_aggregate();
    };

    coins
}

/// For withdrawals requiring obligation unwinding:
///   1. Call create_unwind_accumulator() to calculate unwind plan
///   2. Call process_unwinds_for_lending_market() for each LM
///   3. Call withdraw_with_unwind()
/// All pending unwinds must be processed before calling
public fun withdraw_with_unwind<V, T, L>(
    vault: &mut Vault<V, T>,
    acc: VaultUnwindAccumulator<V>,
    lending_market: &LendingMarket<L>,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<T> {
    vault.version.assert_version(CURRENT_VERSION);
    assert!(acc.vault_id == object::id(vault), EVaultMismatch);
    assert!(acc.pending_unwinds.is_empty(), EIncompleteAccumulation);

    let VaultUnwindAccumulator {
        vault_id: _,
        target_withdraw_amount,
        pending_unwinds: _,
        shares,
        mut agg,
    } = acc;

    // Check if vault now has sufficient liquidity after unwinds
    let available_amount = vault.deposit_asset.value();
    assert!(available_amount >= target_withdraw_amount, EInsufficientLiquidity);

    let updated_liquid_asset_value_usd = {
        let liquid_asset_value = vault.deposit_asset.value();
        get_usd_value_for_token_amount<_, T>(lending_market, liquid_asset_value, clock)
    };
    agg.liquid_asset_value_usd = updated_liquid_asset_value_usd;

    withdraw(vault, coin::from_balance(shares, ctx), lending_market, clock, agg, ctx)
}

// === Unwind Functions ===

/// Create an unwind accumulator for withdrawals that require unwinding obligations
/// Calculate which obligations need to be unwound to satisfy withdrawal liquidity needs
/// Each LendingMarket must be processed by process_unwinds_for_lending_market()
/// A VaultValueAggregate must first be created
public fun create_unwind_accumulator<V, T, L>(
    vault: &Vault<V, T>,
    shares: Coin<V>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    agg: VaultValueAggregate,
    clock: &Clock,
): VaultUnwindAccumulator<V> {
    vault.version.assert_version(CURRENT_VERSION);
    vault.validate_aggregate(&agg);

    let shares_amount = shares.value();
    assert!(shares_amount > 0, EInsufficientShares);

    let (net_shares, _withdrawal_fee_shares) = split_amount(
        shares_amount,
        vault.withdrawal_fee_bps,
    );

    // Calculate total USD value of net shares being redeemed
    let current_nav_per_share = vault.calculate_nav_per_share(&agg);
    let net_usd_value = shares_to_usd(decimal::from(net_shares), current_nav_per_share);

    // Convert net USD value to base token amount
    let target_withdraw_amount = get_token_amount_from_usd<_, T>(
        lending_market,
        net_usd_value,
        clock,
    ).floor();

    assert!(target_withdraw_amount > 0, EInsufficientShares);

    // Check if vault has sufficient liquidity for withdrawal
    let available_amount = vault.deposit_asset.value();

    assert!(available_amount < target_withdraw_amount, EUnwindNotNeeded);

    // Calculate shortfall in USD terms
    let shortfall_tokens = target_withdraw_amount - available_amount;
    let shortfall_usd = get_usd_value_for_token_amount<_, T>(
        lending_market,
        shortfall_tokens,
        clock,
    );

    let pending_unwinds = agg.calculate_unwind_plan(shortfall_usd);

    VaultUnwindAccumulator {
        vault_id: object::id(vault),
        target_withdraw_amount,
        pending_unwinds,
        shares: shares.into_balance(),
        agg,
    }
}

/// Process unwinding for a specific lending market
/// Withdraws and redeems ctokens from obligations, adding funds to vault.deposit_asset
/// Removes the lending market from pending_unwinds
public fun process_unwinds_for_lending_market<V, T, L>(
    vault: &mut Vault<V, T>,
    acc: &mut VaultUnwindAccumulator<V>,
    lending_market: &mut LendingMarket<L>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    vault.version.assert_version(CURRENT_VERSION);
    assert!(acc.vault_id == object::id(vault), EVaultMismatch);

    let lending_market_type = type_name::with_defining_ids<L>();
    let reserve_index = lending_market.reserve_array_index<_, T>();

    let unwind_targets = {
        // Ensure order is maintained
        let (lm_type, unwind_targets) = acc.pending_unwinds.remove_entry_by_idx(0);
        assert!(lm_type == lending_market_type, EIncorrectOrder);
        unwind_targets
    };

    // Process each unwind target
    unwind_targets.do!(|target| {
        // Calculate ctoken amount needed
        let ctoken_amount = calculate_ctoken_amount_for_usd_value<L, T>(
            lending_market,
            target.usd_to_recover,
            clock,
        ).ceil();

        let lm_type = type_name::with_defining_ids<L>();
        let obligation_cap = vault.get_obligation_cap(&lm_type, target.obligation_index);

        let ctokens = lending_market.withdraw_ctokens<L, T>(
            reserve_index,
            obligation_cap,
            clock,
            ctoken_amount,
            ctx,
        );

        // Redeem cTokens for underlying liquidity
        let withdrawn_coin = lending_market.redeem_ctokens_and_withdraw_liquidity<L, T>(
            reserve_index,
            clock,
            ctokens,
            option::none(), // No rate limiter exemption
            ctx,
        );

        let withdrawn_amount = withdrawn_coin.value();

        // Add withdrawn funds directly to vault's deposit asset
        vault.deposit_asset.join(coin::into_balance(withdrawn_coin));

        // Emit unwind event
        event::emit(ObligationUnwind {
            vault_id: object::id(vault),
            lending_market_id: object::id(lending_market),
            obligation_index: target.obligation_index,
            reserve_index,
            ctoken_amount,
            token_amount: withdrawn_amount,
            timestamp_ms: clock.timestamp_ms(),
        });
    });

    acc.agg.refresh_aggregate_for_lending_market(vault, lending_market);
}

// === Vault Rewards Functions ===

/// Compound rewards of same type as deposit asset
/// Permissionless
public fun compound_rewards<V, T, L>(
    vault: &Vault<V, T>,
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
    let obligation_cap = vault.get_obligation_cap<_, _, L>(&lm_type, obligation_index);
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
/// min_amount_out is determined by vault.slippage_bps
/// Permissionless
public fun compound_rewards_with_swap<V, T, L, RewardType, LpType: drop>(
    vault: &Vault<V, T>,
    lending_market: &mut LendingMarket<L>, // Must contain reserves for R + T (price sources)
    swap_pool: &mut Pool<RewardType, T, CpQuoter, LpType>,
    obligation_index: u64,
    reward_reserve_index: u64,
    reward_index: u64,
    is_deposit_reward: bool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    vault.version.assert_version(CURRENT_VERSION);

    // Ensure reward is not base token
    assert!(
        type_name::with_defining_ids<T>() != type_name::with_defining_ids<RewardType>(),
        EBaseTokenReward,
    );

    let lm_type = type_name::with_defining_ids<L>();
    let obligation_cap = vault.get_obligation_cap<_, _, L>(&lm_type, obligation_index);

    // Claim rewards of type R
    let mut reward_coin = lending_market.claim_rewards<L, RewardType>(
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

    let reward_reserve = lending_market.reserve<_, RewardType>();
    let deposit_reserve = lending_market.reserve<_, T>();
    let deposit_reserve_index = lending_market.reserve_array_index<_, T>();

    // Calculate min_amount_out using slippage_bps and reserve prices for R + T
    let min_amount_out = {
        deposit_reserve.assert_price_is_fresh(clock);
        reward_reserve.assert_price_is_fresh(clock);

        let reward_usd_value = reward_reserve.market_value(decimal::from(reward_amount));

        let expected_base_token_amount = deposit_reserve.usd_to_token_amount(
            reward_usd_value,
        );

        // Apply slippage: min_amount_out = expected_amount * (1 - slippage_bps / BASIS_POINTS)
        expected_base_token_amount
            .mul(decimal::from(BASIS_POINTS)
                .sub(
                    decimal::from(vault.slippage_bps),
                )
                .div(decimal::from(BASIS_POINTS)))
            .floor()
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

// === Vault Crank Functions ===

/// Create a vault crank accumulator for processing all lending markets
/// Tracks all LMs and obligations that need to be processed by process_lending_market_for_crank()
public fun create_vault_crank_accumulator<V, T>(vault: &Vault<V, T>): VaultCrankAccumulator {
    vault.version.assert_version(CURRENT_VERSION);

    // Get all lending market types and their obligation IDs
    let keys = vault.obligations.keys();
    let obligation_ids = keys.map_ref!(|k| {
        let obligations = vault.obligations.get(k);
        obligations.map_ref!(|obl_data| {
            obl_data.obligation_id
        })
    });

    VaultCrankAccumulator {
        vault_id: object::id(vault),
        pending_lending_markets: vec_map::from_keys_values(keys, obligation_ids),
        lending_market_allocations: vec_map::empty(),
    }
}

/// This verifies none of the obligations for this LendingMarket have outstanding rewards to be compounded
/// It also calculates the overall value of the positions to be used to calculate manager fees in finalize_vault_crank()
/// Removes the LendingMarket from acc.pending_lending_markets
public fun process_lending_market_for_crank<L>(
    acc: &mut VaultCrankAccumulator,
    lending_market: &LendingMarket<L>,
) {
    let lending_market_type = type_name::with_defining_ids<L>();

    // Enforce that this lending market is in the pending list and remove it
    let (_, obligation_ids) = acc.pending_lending_markets.remove(&lending_market_type);

    obligation_ids.do!(|obligation_id| {
        assert_no_claimable_rewards(lending_market, obligation_id);
    });

    let obligation_allocations = calculate_obligation_values(obligation_ids, lending_market);

    let lending_market_allocation = aggregate_allocation_data(
        obligation_allocations,
    );

    acc.lending_market_allocations.insert(lending_market_type, lending_market_allocation);
}

/// Ensures all LendingMarkets were processed, accrues fees, updates last_cranked_ms timestamp
public fun finalize_vault_crank<V, T, L>(
    vault: &mut Vault<V, T>,
    acc: VaultCrankAccumulator,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
) {
    vault.version.assert_version(CURRENT_VERSION);
    assert!(acc.vault_id == object::id(vault), EVaultMismatch);

    let VaultCrankAccumulator {
        vault_id: _,
        pending_lending_markets,
        lending_market_allocations,
    } = acc;

    assert!(pending_lending_markets.is_empty(), EIncompleteAccumulation);

    let liquid_asset_value_usd = {
        let liquid_asset_value = vault.deposit_asset.value();
        get_usd_value_for_token_amount<L, T>(lending_market, liquid_asset_value, clock)
    };

    let ks = lending_market_allocations.keys();
    let total_obligation_value_usd = ks.fold!(decimal::from(0), |acc, k| {
        let allocation = lending_market_allocations.get(&k);
        acc.add(allocation.net_value_usd)
    });

    let agg = VaultValueAggregate {
        vault_id: object::id(vault),
        liquid_asset_value_usd,
        total_obligation_value_usd,
        lending_market_allocations,
    };

    vault.accrue_all_fees(&agg, lending_market, clock);

    agg.destroy_vault_value_aggregate();

    vault.last_cranked_ms = clock.timestamp_ms();
}

// === Fee Management Functions ===

/// Unified fee accrual function - calculates and applies performance and management fees
fun accrue_all_fees<V, T, L>(
    vault: &mut Vault<V, T>,
    agg: &VaultValueAggregate,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
) {
    let current_shares = vault.treasury_cap.total_supply();
    let total_value_usd = decimal::add(agg.total_obligation_value_usd, agg.liquid_asset_value_usd);

    // Calculate management fee shares
    let management_fee_shares = calculate_management_fee_shares(vault, clock);

    // Calculate performance fee accounting for management fee dilution
    let performance_fee_shares = calculate_performance_fee_shares(
        vault,
        total_value_usd,
        current_shares,
        management_fee_shares,
        lending_market,
        clock,
    );

    // Calculate redemption ratio after management fees but before performance fees
    // This is the new high water mark if it exceeds the previous one
    let redemption_ratio_after_mgmt_fees = calculate_redemption_ratio<L, T>(
        total_value_usd,
        current_shares + management_fee_shares,
        lending_market,
        clock,
    );

    let current_time = clock.timestamp_ms();

    // Mint management fee shares if any
    if (management_fee_shares > 0) {
        let fee_balance = vault.treasury_cap.mint_balance(management_fee_shares);
        vault.manager_fees.join(fee_balance);

        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::ManagementFee,
            fee_shares: management_fee_shares,
            timestamp_ms: current_time,
        });
    };

    // Mint performance fee shares if any
    if (performance_fee_shares > 0) {
        let fee_balance = vault.treasury_cap.mint_balance(performance_fee_shares);
        vault.manager_fees.join(fee_balance);

        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::PerformanceFee,
            fee_shares: performance_fee_shares,
            timestamp_ms: current_time,
        });
    };

    // Update high water mark to ratio after management fees (before performance fees)
    if (redemption_ratio_after_mgmt_fees.gt(vault.redemption_ratio_high_water_mark)) {
        vault.redemption_ratio_high_water_mark = redemption_ratio_after_mgmt_fees;
    };
}

/// Calculate performance fee shares based on redemption ratio growth
/// ratio = vault_value_in_base_asset / shares
fun calculate_performance_fee_shares<V, T, L>(
    vault: &Vault<V, T>,
    total_value_usd: Decimal,
    current_shares: u64,
    mgmt_shares_to_mint: u64,
    lending_market: &LendingMarket<L>,
    clock: &Clock,
): u64 {
    if (vault.performance_fee_bps == 0 || current_shares == 0) {
        return 0
    };

    // Calculate current redemption ratio
    let current_ratio = calculate_redemption_ratio<L, T>(
        total_value_usd,
        current_shares,
        lending_market,
        clock,
    );

    // Apply performance fee only when ratio exceeds high water mark
    if (current_ratio.le(vault.redemption_ratio_high_water_mark)) {
        return 0
    };

    // Calculate gain in base asset terms per share
    let gain_ratio = current_ratio.sub(vault.redemption_ratio_high_water_mark);

    // Calculate total gain using shares after management fees
    let shares_after_mgmt_decimal = decimal::from_u128(
        (current_shares as u128) + (mgmt_shares_to_mint as u128),
    );
    let total_gain_in_base_asset = gain_ratio.mul(shares_after_mgmt_decimal);

    // Convert gain to USD for fee calculation
    let gain_usd = get_usd_value_for_token_amount<L, T>(
        lending_market,
        total_gain_in_base_asset.floor(),
        clock,
    );

    // Performance fee on the gain
    let perf_fee_value = gain_usd.mul(decimal::from_bps(vault.performance_fee_bps));

    // Calculate shares accounting for management fee dilution
    // NAV after mgmt fees = total_value / (current_shares + mgmt_shares)
    let shares_after_mgmt = (current_shares as u128) + (mgmt_shares_to_mint as u128);
    let nav_after_mgmt = calculate_nav_from_shares_and_value(
        decimal::from_u128(shares_after_mgmt),
        total_value_usd,
    );

    // Convert performance fee value to shares at post-mgmt NAV
    calculate_shares_from_usd_and_nav(
        perf_fee_value,
        nav_after_mgmt,
    ).floor()
}

fun calculate_management_fee_shares<V, T>(vault: &Vault<V, T>, clock: &Clock): u64 {
    if (vault.management_fee_bps == 0) {
        return 0
    };

    let current_time_ms = clock.timestamp_ms();
    let time_elapsed_ms = current_time_ms - vault.last_cranked_ms;

    if (time_elapsed_ms == 0) {
        return 0
    };

    let time_elapsed_s = time_elapsed_ms / 1000;

    // Calculate management fee reduction factor
    let annual_fee_rate = decimal::from_bps(vault.management_fee_bps);

    // Convert to per-second rate: annual_rate / seconds_per_year
    let per_second_rate = decimal::div(annual_fee_rate, decimal::from(SECONDS_PER_YEAR));

    let mut fee_factor = decimal::mul(decimal::from(time_elapsed_s), per_second_rate);

    // TODO - potentially change
    // Cap the fee factor at 30%
    let max_fee_factor = decimal::from_bps(3000);
    if (decimal::gt(fee_factor, max_fee_factor)) {
        fee_factor = max_fee_factor;
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

public fun create_vault_value_accumulator<V, T>(vault: &Vault<V, T>): VaultValueAccumulator {
    let lm_keys = vault.obligations.keys();
    let obligation_ids = lm_keys.map_ref!(|k| {
        let obligations = vault.obligations.get(k);
        obligations.map_ref!(|bg| {
            bg.obligation_id
        })
    });
    VaultValueAccumulator {
        vault_id: object::id(vault),
        obligation_ids: vec_map::from_keys_values(lm_keys, obligation_ids),
        lending_market_allocations: vec_map::empty(),
    }
}

public fun process_lending_market_for_value_accumulator<L>(
    acc: &mut VaultValueAccumulator,
    lending_market: &LendingMarket<L>,
) {
    let lending_market_type = type_name::with_defining_ids<L>();

    let obligation_ids = {
        // Ensure order is maintained
        let (lm_type, obligation_ids) = acc.obligation_ids.remove_entry_by_idx(0);
        assert!(lm_type == lending_market_type, EIncorrectOrder);
        obligation_ids
    };

    let obligation_allocations = calculate_obligation_values(obligation_ids, lending_market);

    let lending_market_allocation = aggregate_allocation_data(
        obligation_allocations,
    );

    acc.lending_market_allocations.insert(lending_market_type, lending_market_allocation);
}

public fun create_vault_value_aggregate<V, T, L>(
    acc: VaultValueAccumulator,
    vault: &Vault<V, T>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
): VaultValueAggregate {
    assert!(acc.vault_id == object::id(vault), EVaultMismatch);
    assert!(acc.obligation_ids.is_empty(), EIncompleteAccumulation);

    let liquid_asset_value_usd = {
        let liquid_asset_value = vault.deposit_asset.value();
        get_usd_value_for_token_amount<L, T>(lending_market, liquid_asset_value, clock)
    };

    let VaultValueAccumulator {
        vault_id: _,
        obligation_ids: _,
        lending_market_allocations,
    } = acc;

    // Calculate total obligation value from all lending markets
    let ks = lending_market_allocations.keys();
    let total_obligation_value_usd = ks.fold!(decimal::from(0), |acc, k| {
        let allocation = lending_market_allocations.get(&k);
        decimal::add(acc, allocation.net_value_usd)
    });

    VaultValueAggregate {
        vault_id: object::id(vault),
        liquid_asset_value_usd,
        total_obligation_value_usd,
        lending_market_allocations,
    }
}

// === Public Helpers ===

/// Calculates the amount of shares that will be minted for deposit_amount of T
public fun calculate_shares_to_mint<V, T, L>(
    vault: &Vault<V, T>,
    deposit_amount: u64,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    agg: &VaultValueAggregate,
    clock: &Clock,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(agg);
    let deposit_usd_value = get_usd_value_for_token_amount<_, T>(
        lending_market,
        deposit_amount,
        clock,
    );
    calculate_shares_from_usd_and_nav(deposit_usd_value, nav_per_share).floor()
}

/// Calculates the amount of shares that must be burned to redeem withdraw_amount of T
public fun calculate_shares_to_burn<V, T, L>(
    vault: &Vault<V, T>,
    withdraw_amount: u64,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    agg: &VaultValueAggregate,
    clock: &Clock,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(agg);
    let withdraw_usd_value = get_usd_value_for_token_amount<_, T>(
        lending_market,
        withdraw_amount,
        clock,
    );
    calculate_shares_from_usd_and_nav(withdraw_usd_value, nav_per_share).floor()
}

/// Calculates the amount of T that can be redeemed for shares_amount
public fun calculate_withdraw_amount<V, T, L>(
    vault: &Vault<V, T>,
    shares_amount: u64,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    agg: &VaultValueAggregate,
    clock: &Clock,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(agg);
    let withdraw_usd_value = shares_to_usd(decimal::from(shares_amount), nav_per_share);
    get_token_amount_from_usd<_, T>(lending_market, withdraw_usd_value, clock).floor()
}

/// Calculates the amount of T that shares_amount will cost
public fun calculate_deposit_amount<V, T, L>(
    vault: &Vault<V, T>,
    shares_amount: u64,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    agg: &VaultValueAggregate,
    clock: &Clock,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(agg);
    let deposit_usd_value = shares_to_usd(decimal::from(shares_amount), nav_per_share);
    get_token_amount_from_usd<_, T>(lending_market, deposit_usd_value, clock).floor()
}

public fun calculate_utilization_rate(agg: &VaultValueAggregate): u64 {
    let total_vault_value = decimal::add(
        agg.liquid_asset_value_usd,
        agg.total_obligation_value_usd,
    );

    if (total_vault_value.eq(decimal::from(0))) {
        return 0
    };

    let utilization_decimal = decimal::div(
        decimal::mul(agg.total_obligation_value_usd, decimal::from(BASIS_POINTS)),
        total_vault_value,
    );

    decimal::floor(utilization_decimal)
}

public fun calculate_nav_per_share<V, T>(vault: &Vault<V, T>, agg: &VaultValueAggregate): Decimal {
    let current_shares = vault.treasury_cap.total_supply();
    let vault_value = decimal::add(agg.total_obligation_value_usd, agg.liquid_asset_value_usd);
    if (current_shares == 0 || decimal::eq(vault_value, decimal::from(0))) {
        decimal::from_u128(NAV_PRECISION) // 1.0 scaled
    } else {
        calculate_nav_from_shares_and_value(
            decimal::from(current_shares),
            vault_value,
        )
    }
}

/// Get all obligation IDs for a specific lending market
public fun get_obligation_ids_for_market<V, T, L>(vault: &Vault<V, T>): vector<ID> {
    let lending_market_type = type_name::with_defining_ids<L>();
    if (vault.obligations.contains(&lending_market_type)) {
        let obligations = vault.obligations.get(&lending_market_type);
        obligations.map_ref!(|obl| obl.obligation_id)
    } else {
        vector::empty()
    }
}

/// Get obligation count for a specific lending market
public fun get_obligation_count_for_market<V, T, L>(vault: &Vault<V, T>): u64 {
    let lending_market_type = type_name::with_defining_ids<L>();
    if (vault.obligations.contains(&lending_market_type)) {
        let obligations = vault.obligations.get(&lending_market_type);
        obligations.length()
    } else {
        0
    }
}

/// Get all lending market types that have obligations
public fun get_lending_market_types<V, T>(vault: &Vault<V, T>): vector<TypeName> {
    vault.obligations.keys()
}

/// Total supply of shares
public fun total_supply<V, T>(vault: &Vault<V, T>): u64 {
    vault.treasury_cap.total_supply()
}

// === Private Helpers ===

/// Returns the share decimals factor as a Decimal for decimal calculations
fun share_decimals_factor_decimal(): Decimal {
    decimal::from(10u64.pow(VAULT_SHARE_DECIMALS))
}

/// Calculate redemption ratio: vault value in base asset terms per share
/// This is the key metric for performance fees
/// ratio = total_vault_value_usd / base_asset_price / total_shares
fun calculate_redemption_ratio<L, T>(
    total_value_usd: Decimal,
    total_shares: u64,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
): Decimal {
    if (total_shares == 0) {
        decimal::from(1) // Initial ratio when vault is empty
    } else {
        let vault_value_in_base_asset = get_token_amount_from_usd<L, T>(
            lending_market,
            total_value_usd,
            clock,
        );

        vault_value_in_base_asset.div(decimal::from(total_shares))
    }
}

/// Convert shares (in base units) to USD value using NAV per share
fun shares_to_usd(shares: Decimal, nav_per_share: Decimal): Decimal {
    shares
        .mul(nav_per_share)
        .div(decimal::from_u128(NAV_PRECISION).mul(share_decimals_factor_decimal()))
}

/// Calculates NAV per share from total shares and total USD value
/// NAV = (vault_value * NAV_PRECISION * 10^SHARE_DECIMALS) / shares
fun calculate_nav_from_shares_and_value(total_shares: Decimal, total_value_usd: Decimal): Decimal {
    if (total_shares.eq(decimal::from(0))) {
        decimal::from_u128(NAV_PRECISION)
    } else {
        total_value_usd
            .mul(decimal::from_u128(NAV_PRECISION))
            .mul(share_decimals_factor_decimal())
            .div(total_shares)
    }
}

// shares = (usd * NAV_PRECISION * 10^SHARE_DECIMALS) / nav_per_share
fun calculate_shares_from_usd_and_nav(usd_amount: Decimal, nav_per_share: Decimal): Decimal {
    usd_amount
        .mul(decimal::from_u128(NAV_PRECISION))
        .mul(
            share_decimals_factor_decimal(),
        )
        .div(nav_per_share)
}

/// Calculate obligations state within one Lending Market
fun calculate_obligation_values<L>(
    obligation_ids: vector<ID>,
    lending_market: &LendingMarket<L>,
): vector<ObligationAllocation> {
    let mut allocations = vector::empty<ObligationAllocation>();

    // Add value from all lending positions
    obligation_ids.do!(|obligation_id| {
        let obligation = lending_market.obligation(obligation_id);

        let deposited_value_usd_decimal = obligation.deposited_value_usd();
        let unweighted_borrowed_value_usd_decimal = obligation.unweighted_borrowed_value_usd();

        // TODO: could be negative?
        let net_value_decimal = deposited_value_usd_decimal.saturating_sub(
            unweighted_borrowed_value_usd_decimal,
        );

        allocations.push_back(ObligationAllocation {
            obligation_id,
            deposited_value_usd: deposited_value_usd_decimal,
            borrowed_value_usd: unweighted_borrowed_value_usd_decimal,
            net_value_usd: net_value_decimal,
        });
    });

    allocations
}

/// Get T amount from USD amount
fun get_token_amount_from_usd<L, T>(
    lending_market: &LendingMarket<L>,
    amount: Decimal,
    clock: &Clock,
): Decimal {
    let reserve = lending_market.reserve<_, T>();
    reserve.assert_price_is_fresh(clock);
    reserve.usd_to_token_amount(amount)
}

/// Get USD amount from T amount
fun get_usd_value_for_token_amount<L, T>(
    lending_market: &LendingMarket<L>,
    amount: u64,
    clock: &Clock,
): Decimal {
    let reserve = lending_market.reserve<_, T>();
    reserve.assert_price_is_fresh(clock);
    reserve.market_value(decimal::from(amount))
}

fun emit_stats_event<V, T>(vault: &Vault<V, T>, agg: &VaultValueAggregate) {
    let nav_per_share_usd = vault.calculate_nav_per_share(agg).floor();
    let aum_usd = agg.total_obligation_value_usd.add(agg.liquid_asset_value_usd);
    let utilization_rate_bps = calculate_utilization_rate(agg);
    event::emit(VaultStats {
        vault_id: object::id(vault),
        base_token_type: type_name::with_defining_ids<T>(),
        nav_per_share_usd,
        utilization_rate_bps,
        aum_usd: aum_usd.floor(),
        total_shares: vault.total_supply(),
        lending_market_allocations: agg.lending_market_allocations,
    });
}

/// Calculate the ctoken amount needed to unwind for a given USD value
/// Uses reserve exchange rate to convert USD -> token amount -> ctoken amount
fun calculate_ctoken_amount_for_usd_value<L, T>(
    lending_market: &LendingMarket<L>,
    usd_value: Decimal,
    clock: &Clock,
): Decimal {
    let reserve = lending_market.reserve<_, T>();
    reserve.assert_price_is_fresh(clock);

    let token_amount = reserve.usd_to_token_amount(usd_value);

    // Get ctoken exchange rate and calculate ctokens needed
    // ctoken_amount = token_amount / exchange_rate
    let ctoken_ratio = reserve.ctoken_ratio();
    let ctoken_amount = token_amount.div(ctoken_ratio);

    ctoken_amount
}

/// Calculate which obligations need to be unwound to cover a shortfall
/// Uses FIFO strategy: processes obligations in order of creation (by LM type, then index)
/// Returns a map of lending market type -> vector of UnwindTargets
fun calculate_unwind_plan(
    agg: &VaultValueAggregate,
    shortfall_usd: Decimal,
): vec_map::VecMap<TypeName, vector<UnwindTarget>> {
    let mut unwind_map = vec_map::empty<TypeName, vector<UnwindTarget>>();
    let mut remaining_shortfall = shortfall_usd;

    // Iterate through lending markets in order
    let lm_keys = agg.lending_market_allocations.keys();

    let mut i = 0;
    while (i < lm_keys.length() && remaining_shortfall.gt(decimal::from(0))) {
        let lm_type = lm_keys.borrow(i);
        let mut unwind_targets = vector::empty<UnwindTarget>();

        let lm_allocation = agg.lending_market_allocations.get(lm_type);
        let obl_allocations = &lm_allocation.obligations;

        // Process obligations in FIFO order (index 0, 1, 2, ...)
        let mut obl_idx = 0;
        while (
            obl_idx < obl_allocations.length()
                && remaining_shortfall.gt(decimal::from(0))
        ) {
            // Find corresponding obligation allocation
            let obl_data = obl_allocations.borrow(obl_idx);
            let obl_net_value = obl_data.net_value_usd;

            if (obl_net_value.gt(decimal::from(0))) {
                // Calculate how much to unwind from this obligation
                // Take minimum of remaining shortfall and obligation's net value
                let unwind_usd = remaining_shortfall.min(obl_net_value);

                unwind_targets.push_back(UnwindTarget {
                    obligation_index: obl_idx,
                    usd_to_recover: unwind_usd,
                });

                remaining_shortfall = remaining_shortfall.saturating_sub(unwind_usd);
            };

            obl_idx = obl_idx + 1;
        };

        if (!unwind_targets.is_empty()) {
            unwind_map.insert(*lm_type, unwind_targets);
        };

        i = i + 1;
    };

    assert!(remaining_shortfall.eq(decimal::from(0)), EInsufficientLiquidityForUnwind);

    unwind_map
}

fun split_amount(amount: u64, fee_bps: u64): (u64, u64) {
    let fee_amount = (amount * fee_bps) / BASIS_POINTS;
    (amount - fee_amount, fee_amount)
}

fun aggregate_allocation_data(
    obligation_allocations: vector<ObligationAllocation>,
): LendingMarketAllocation {
    let mut total_deposited = decimal::from(0);
    let mut total_borrowed = decimal::from(0);
    let mut total_net = decimal::from(0);

    obligation_allocations.do_ref!(|alloc| {
        total_deposited = total_deposited.add(alloc.deposited_value_usd);
        total_borrowed = total_borrowed.add(alloc.borrowed_value_usd);
        total_net = total_net.add(alloc.net_value_usd);
    });

    LendingMarketAllocation {
        deposited_value_usd: total_deposited,
        borrowed_value_usd: total_borrowed,
        net_value_usd: total_net,
        obligations: obligation_allocations,
    }
}

/// Recalculates aggregate values for a specific lending
/// Updates both the lending market allocation and the total obligation value
fun refresh_aggregate_for_lending_market<V, T, L>(
    agg: &mut VaultValueAggregate,
    vault: &Vault<V, T>,
    lending_market: &LendingMarket<L>,
) {
    let lending_market_type = type_name::with_defining_ids<L>();
    let obligations = vault.obligations.get(&lending_market_type);
    let obligation_ids = obligations.map_ref!(|obl| obl.obligation_id);
    let obligation_allocations = calculate_obligation_values(obligation_ids, lending_market);

    let updated_lm_allocation = aggregate_allocation_data(obligation_allocations);

    let alloc = agg.lending_market_allocations.get_mut(&lending_market_type);
    *alloc = updated_lm_allocation;

    // Recalculate total obligation value from all lending markets
    let ks = agg.lending_market_allocations.keys();
    let total_obligation_value_usd = ks.fold!(decimal::from(0), |acc_val, k| {
        let allocation = agg.lending_market_allocations.get(&k);
        acc_val.add(allocation.net_value_usd)
    });
    agg.total_obligation_value_usd = total_obligation_value_usd;
}

fun assert_no_claimable_rewards<V>(lending_market: &LendingMarket<V>, obligation_id: ID) {
    let reserves = lending_market.reserves();
    let obligation = lending_market.obligation(obligation_id);

    // Process deposit rewards
    obligation.deposits().do_ref!(|deposit| {
        let reserve_index = deposit.reserve_array_index();
        let reserve = reserves.borrow(reserve_index);
        let pool_reward_manager = reserve.deposits_pool_reward_manager();
        let user_reward_manager_index = deposit.user_reward_manager_index();
        let user_reward_manager = obligation
            .user_reward_managers()
            .borrow(user_reward_manager_index);

        let claimable_rewards = get_claimable_reward_indexes(
            user_reward_manager,
            pool_reward_manager,
        );

        assert!(claimable_rewards.is_empty(), EUnclaimedRewards);
    });

    // Process borrow rewards
    obligation.borrows().do_ref!(|borrow| {
        let reserve_index = borrow.reserve_array_index();
        let reserve = reserves.borrow(reserve_index);
        let pool_reward_manager = reserve.borrows_pool_reward_manager();
        let user_reward_manager_index = borrow.user_reward_manager_index();
        let user_reward_manager = obligation
            .user_reward_managers()
            .borrow(user_reward_manager_index);

        let claimable_rewards = get_claimable_reward_indexes(
            user_reward_manager,
            pool_reward_manager,
        );

        assert!(claimable_rewards.is_empty(), EUnclaimedRewards);
    });
}

fun get_claimable_reward_indexes(
    user_reward_manager: &liquidity_mining::UserRewardManager,
    pool_reward_manager: &liquidity_mining::PoolRewardManager,
): vector<u64> {
    let user_rewards = user_reward_manager.rewards();
    let pool_rewards = pool_reward_manager.pool_rewards();

    let mut result = vector::empty();
    user_rewards.length().do!(|reward_index| {
        let optional_user_reward = user_rewards.borrow(reward_index);

        if (optional_user_reward.is_some()) {
            let user_reward = optional_user_reward.borrow();

            // Only include rewards with non-zero earnings
            if (user_reward.earned_rewards().gt(decimal::from(0))) {
                let optional_pool_reward = pool_rewards.borrow(reward_index);
                if (optional_pool_reward.is_some()) {
                    result.push_back(reward_index);
                };
            };
        };
    });

    result
}

fun destroy_vault_value_aggregate(agg: VaultValueAggregate) {
    let VaultValueAggregate {
        vault_id: _,
        liquid_asset_value_usd: _,
        total_obligation_value_usd: _,
        lending_market_allocations: _,
    } = agg;
}

/// Get obligation cap at lending_market_type + index (read-only)
fun get_obligation_cap<V, T, L>(
    vault: &Vault<V, T>,
    // Necessary because borrowing using type_name::with_defining_ids<L> causes lifetime issues
    lending_market_type: &TypeName,
    index: u64,
): &ObligationOwnerCap<L> {
    assert!(&type_name::with_defining_ids<L>() == lending_market_type);
    let obligations = vault.obligations.get(lending_market_type);
    let obl = obligations.borrow(index);
    obl.obligation_cap.borrow(OBLIGATION_CAP_BAG_KEY)
}

/// Validate that a manager cap belongs to a specific vault
fun validate_manager_cap<V, T>(vault: &Vault<V, T>, manager_cap: &VaultManagerCap<V>) {
    assert!(manager_cap.vault_id == object::id(vault), EInvalidManager);
}

/// Validate that a VaultValueAggregate belongs to a specific vault
fun validate_aggregate<V, T>(vault: &Vault<V, T>, agg: &VaultValueAggregate) {
    assert!(agg.vault_id == object::id(vault), EVaultMismatch);
}

/// Check that vault was cranked within MAX_REWARDS_STALENESS_MS
fun assert_vault_state_fresh<V, T>(vault: &Vault<V, T>, clock: &Clock) {
    let current_time = clock.timestamp_ms();

    assert!(current_time - vault.last_cranked_ms <= MAX_REWARDS_STALENESS_MS, ERewardsStale);
}

// === Test Functions ===

#[test_only]
public fun create_vault_value_aggregate_for_testing<V, T, L>(
    vault: &Vault<V, T>,
    lending_market: &LendingMarket<L>,
    clock: &Clock,
): VaultValueAggregate {
    let mut acc = vault.create_vault_value_accumulator();
    if (!vault.obligations.is_empty()) {
        acc.process_lending_market_for_value_accumulator(lending_market);
    };
    let agg = acc.create_vault_value_aggregate(vault, lending_market, clock);
    agg
}

#[test_only]
public fun accrue_fees_for_testing<V, T, L>(
    vault: &mut Vault<V, T>,
    agg: &VaultValueAggregate,
    lending_market: &LendingMarket<L>,
    clock: &Clock,
) {
    accrue_all_fees(vault, agg, lending_market, clock)
}

#[test_only]
public fun get_usd_value_for_token_amount_for_testing<L, T>(
    lending_market: &LendingMarket<L>,
    amount: u64,
    clock: &Clock,
): Decimal {
    get_usd_value_for_token_amount<_, T>(lending_market, amount, clock)
}

#[test_only]
public fun get_token_amount_from_usd_for_testing<L, T>(
    lending_market: &LendingMarket<L>,
    amount: Decimal,
    clock: &Clock,
): Decimal {
    get_token_amount_from_usd<_, T>(lending_market, amount, clock)
}

#[test_only]
public fun get_obligation_cap_for_testing<V, T, L>(
    vault: &Vault<V, T>,
    lending_market_type: &TypeName,
    index: u64,
): &ObligationOwnerCap<L> {
    get_obligation_cap(vault, lending_market_type, index)
}

#[test_only]
public fun get_manager_fees_for_testing<V, T>(vault: &Vault<V, T>): u64 {
    vault.manager_fees.value()
}

#[test_only]
public fun get_aggregate_liquid_value_for_testing(agg: &VaultValueAggregate): Decimal {
    agg.liquid_asset_value_usd
}

#[test_only]
public fun get_aggregate_obligation_value_for_testing(agg: &VaultValueAggregate): Decimal {
    agg.total_obligation_value_usd
}
