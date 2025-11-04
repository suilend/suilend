module vaults::vault;

use std::type_name::{Self, TypeName};
use steamm::{cpmm::{Self, CpQuoter}, pool::Pool};
use sui::{
    bag,
    balance::{Self, Balance},
    clock::Clock,
    coin::{Self, TreasuryCap, Coin},
    event,
    vec_map
};
use suilend::{decimal, lending_market::{ObligationOwnerCap, LendingMarket}};

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
//#[error]
//const EMetadataCapExists: vector<u8> = b"Vault currency MetadataCap hasn't been burned";

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
//const VAULT_SHARE_NAME: vector<u8> = b"Vault Shares";
//const VAULT_SHARE_SYMBOL: vector<u8> = b"VSHARES";

// === Structs ===
public struct Vault<phantom P, phantom T> has key, store {
    id: object::UID,
    version: vaults::version::Version,
    // Keyed by 'L' from LendingMarket<L>
    obligations: vec_map::VecMap<TypeName, vector<ObligationData>>,
    treasury_cap: TreasuryCap<P>,
    deposit_asset: Balance<T>,
    manager_fees: Balance<P>,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
    slippage_bps: u64,
    nav_high_water_mark: decimal::Decimal, // Highest NAV per share achieved (for performance fees)
    last_cranked_ms: u64, // timestamp_ms when rewards were last compounded and fees were last accrued
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
    vault_id: ID,
    // Keyed by 'L' from LendingMarket<L>
    obligation_ids: vec_map::VecMap<TypeName, vector<ID>>,
    lending_market_allocations: vec_map::VecMap<TypeName, LendingMarketAllocation>,
}

/// Created from a VaultValueAccumulator once it has been fully processed
public struct VaultValueAggregate has drop {
    vault_id: ID,
    liquid_asset_value_usd: decimal::Decimal,
    total_obligation_value_usd: decimal::Decimal,
    lending_market_allocations: vec_map::VecMap<TypeName, LendingMarketAllocation>,
}

/// Accumulator for vault crank operations (rewards + fees)
/// Processes all lending markets in the vault
/// Must be consumed in PTB by calling finalize_vault_crank
public struct VaultCrankAccumulator {
    vault_id: ID,
    // Keyed by LM TypeName -> obligation IDs (removed as each LM is processed)
    pending_lending_markets: vec_map::VecMap<TypeName, vector<ID>>,
    // Accumulated obligation valuations (built up as LMs processed)
    lending_market_allocations: vec_map::VecMap<TypeName, LendingMarketAllocation>,
}

public struct LendingMarketAllocation has copy, drop, store {
    deposited_value_usd: decimal::Decimal,
    borrowed_value_usd: decimal::Decimal,
    net_value_usd: decimal::Decimal,
    obligations: vector<ObligationAllocation>,
}

public struct ObligationAllocation has copy, drop, store {
    obligation_id: ID,
    deposited_value_usd: decimal::Decimal,
    borrowed_value_usd: decimal::Decimal,
    net_value_usd: decimal::Decimal,
}

public struct FeeAccrual has drop {
    management_fee_shares: u64,
    performance_fee_shares: u64,
    total_fee_shares: u64,
    new_nav_per_share: decimal::Decimal,
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

// === Vault Manager Functions ===

public fun create_vault<P, T>(
    vault_share_treasury_cap: TreasuryCap<P>,
    //vault_share_currency: &coin_registry::Currency<P>,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
    slippage_bps: u64,
    clock: &Clock,
    ctx: &mut tx_context::TxContext,
): VaultManagerCap<P> {
    // TODO: temporarily disabled
    //assert!(vault_share_currency.is_metadata_cap_deleted() || true, EMetadataCapExists);
    //assert!(vault_share_currency.decimals() == VAULT_SHARE_DECIMALS, EInvalidShareCurrency);
    //assert!(vault_share_currency.name() == VAULT_SHARE_NAME.to_string(), EInvalidShareCurrency);
    //assert!(
    //vault_share_currency.description() == VAULT_SHARE_NAME.to_string(),
    //EInvalidShareCurrency,
    //);
    //assert!(vault_share_currency.symbol() == VAULT_SHARE_SYMBOL.to_string(), EInvalidShareCurrency);
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
        treasury_cap: vault_share_treasury_cap,
        obligations: vec_map::empty(),
        deposit_asset: balance::zero<T>(),
        manager_fees: balance::zero<P>(),
        management_fee_bps,
        performance_fee_bps,
        deposit_fee_bps,
        withdrawal_fee_bps,
        slippage_bps,
        nav_high_water_mark: decimal::from_u128(NAV_PRECISION),
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
public fun deploy_funds<P, L, T>(
    vault: &mut Vault<P, T>,
    vault_manager_cap: &VaultManagerCap<P>,
    lending_market: &mut LendingMarket<L>, // Must contain reserve for T (price source)
    obligation_index: u64,
    amount: u64,
    clock: &Clock,
    agg: VaultValueAggregate,
    ctx: &mut TxContext,
): u64 {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.validate_manager_cap(vault_manager_cap);
    vault.assert_vault_state_fresh<P, T>(clock);
    assert!(amount > 0, EInvalidDeposit);

    // Check if vault has sufficient liquid assets
    let available_amount = vault.deposit_asset.value();
    assert!(available_amount >= amount, EInsufficientLiquidity);

    let usd_to_deploy = get_usd_value_for_token_amount<_, T>(lending_market, amount, clock);

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
        let updated_obligation_value_usd = decimal::add(
            agg.total_obligation_value_usd,
            usd_to_deploy,
        );

        // Update the obligation allocations for this lending market
        let lm_type = type_name::with_defining_ids<L>();
        let mut updated_allocations = agg.lending_market_allocations;

        if (updated_allocations.contains(&lm_type)) {
            let allocation = updated_allocations.get_mut(&lm_type);
            // Increase deposited value and net value by the deployed amount
            allocation.deposited_value_usd =
                decimal::add(allocation.deposited_value_usd, usd_to_deploy);
            allocation.net_value_usd = decimal::add(allocation.net_value_usd, usd_to_deploy);
        };

        let updated_agg = VaultValueAggregate {
            vault_id: agg.vault_id,
            liquid_asset_value_usd: updated_liquid_asset_value_usd,
            total_obligation_value_usd: updated_obligation_value_usd,
            lending_market_allocations: updated_allocations,
        };
        vault.emit_stats_event(&updated_agg);
    };

    ctokens_amount
}

/// Withdraw funds from lending market obligation back to vault
public fun withdraw_deployed_funds<P, L, T>(
    vault: &mut Vault<P, T>,
    vault_manager_cap: &VaultManagerCap<P>,
    lending_market: &mut LendingMarket<L>, // Must contain reserve for T (price source)
    obligation_index: u64,
    ctoken_amount: u64,
    clock: &Clock,
    agg: VaultValueAggregate,
    ctx: &mut TxContext,
) {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.validate_manager_cap(vault_manager_cap);
    vault.assert_vault_state_fresh<P, T>(clock);
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
        let usd_withdrawn = get_usd_value_for_token_amount<_, T>(
            lending_market,
            withdrawn_amount,
            clock,
        );
        let updated_obligation_value_usd = decimal::saturating_sub(
            agg.total_obligation_value_usd,
            usd_withdrawn,
        );

        // Update the obligation allocations for this lending market
        let lm_type = type_name::with_defining_ids<L>();
        let mut updated_allocations = agg.lending_market_allocations;

        if (updated_allocations.contains(&lm_type)) {
            let allocation = updated_allocations.get_mut(&lm_type);
            // Decrease deposited value and net value by the withdrawn amount
            allocation.deposited_value_usd =
                decimal::saturating_sub(allocation.deposited_value_usd, usd_withdrawn);
            allocation.net_value_usd =
                decimal::saturating_sub(allocation.net_value_usd, usd_withdrawn);
        };

        let updated_agg = VaultValueAggregate {
            vault_id: agg.vault_id,
            liquid_asset_value_usd: updated_liquid_asset_value_usd,
            total_obligation_value_usd: updated_obligation_value_usd,
            lending_market_allocations: updated_allocations,
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

/// Validate that a VaultValueAggregate belongs to a specific vault
fun validate_aggregate<P, T>(vault: &Vault<P, T>, agg: &VaultValueAggregate) {
    assert!(agg.vault_id == object::id(vault), EVaultMismatch);
}

/// Check that vault was cranked within MAX_REWARDS_STALENESS_MS
fun assert_vault_state_fresh<P, T>(vault: &Vault<P, T>, clock: &Clock) {
    let current_time = clock.timestamp_ms();

    assert!(current_time - vault.last_cranked_ms <= MAX_REWARDS_STALENESS_MS, ERewardsStale);
}

// === User Functions ===

public fun deposit<P, L, T>(
    vault: &mut Vault<P, T>,
    deposit: Coin<T>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
    agg: VaultValueAggregate,
    ctx: &mut TxContext,
): Coin<P> {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.validate_aggregate(&agg);
    vault.assert_vault_state_fresh<P, T>(clock);

    let deposit_amount = deposit.value();
    let current_time = clock.timestamp_ms();
    let user = ctx.sender();

    // Calculate deposit fee
    let deposit_fee = (deposit_amount * vault.deposit_fee_bps) / BASIS_POINTS;
    let net_deposit_amount = deposit_amount - deposit_fee;

    // Check minimum deposit in USD terms
    let net_deposit_usd_value = get_usd_value_for_token_amount<_, T>(
        lending_market,
        net_deposit_amount,
        clock,
    );
    assert!(
        decimal::from_scaled_val(MIN_DEPOSIT_USD_SCALED).le(net_deposit_usd_value),
        EInvalidDeposit,
    );

    // Calculate shares BEFORE adding deposit to vault or minting any shares
    let fee_shares = if (deposit_fee > 0) {
        calculate_shares_to_mint(vault, deposit_fee, lending_market, &agg, clock)
    } else {
        0
    };

    let shares_to_mint = calculate_shares_to_mint(
        vault,
        net_deposit_amount,
        lending_market,
        &agg,
        clock,
    );

    assert!(shares_to_mint > 0, EInvalidDeposit);

    // Add deposited coins to vault
    vault.deposit_asset.join(coin::into_balance(deposit));

    // Mint shares for deposit fee
    if (fee_shares > 0) {
        let fee_balance = vault.treasury_cap.mint_balance(fee_shares);
        vault.manager_fees.join(fee_balance);

        event::emit(FeesAccrued {
            vault_id: object::id(vault),
            fee_type: FeeType::DepositFee,
            fee_shares: fee_shares,
            timestamp_ms: current_time,
        });
    };

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
            get_usd_value_for_token_amount<_, T>(lending_market, liquid_asset_value, clock)
        };
        let updated_agg = VaultValueAggregate {
            vault_id: agg.vault_id,
            liquid_asset_value_usd: updated_liquid_asset_value_usd,
            total_obligation_value_usd: agg.total_obligation_value_usd,
            lending_market_allocations: agg.lending_market_allocations,
        };
        vault.emit_stats_event(&updated_agg);
    };

    vault_shares
}

/// User burns shares and withdraws proportional assets with performance fees on realized gains
public fun withdraw<P, L, T>(
    vault: &mut Vault<P, T>,
    shares: Coin<P>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
    agg: VaultValueAggregate,
    ctx: &mut TxContext,
): Coin<T> {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.validate_aggregate(&agg);
    vault.assert_vault_state_fresh<P, T>(clock);
    assert!(shares.value() > 0, EInsufficientShares);

    let shares_amount = shares.value();
    let user = ctx.sender();
    let current_time = clock.timestamp_ms();

    // Calculate withdrawal fee in shares
    let withdrawal_fee_shares = (shares_amount * vault.withdrawal_fee_bps) / BASIS_POINTS;
    let net_shares = shares_amount - withdrawal_fee_shares;

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
        let updated_agg = VaultValueAggregate {
            vault_id: agg.vault_id,
            liquid_asset_value_usd: updated_liquid_asset_value_usd,
            total_obligation_value_usd: agg.total_obligation_value_usd,
            lending_market_allocations: agg.lending_market_allocations,
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
    lending_market: &mut LendingMarket<L>, // Must contain reserves for R + T (price sources)
    swap_pool: &mut Pool<R, T, CpQuoter, LpType>,
    obligation_index: u64,
    reward_reserve_index: u64,
    reward_index: u64,
    is_deposit_reward: bool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    vault.version.assert_version(CURRENT_VERSION);
    vault.validate_manager_cap(vault_manager_cap);

    // Ensure reward is not base token
    assert!(
        type_name::with_defining_ids<T>() != type_name::with_defining_ids<R>(),
        EBaseTokenReward,
    );

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

    let reward_reserve = lending_market.reserve<_, R>();
    let deposit_reserve = lending_market.reserve<_, T>();
    let deposit_reserve_index = lending_market.reserve_array_index<_, T>();

    // Calculate min_amount_out using slippage_bps and reserve prices for R + T
    let min_amount_out = {
        let reward_usd_value = reward_reserve.market_value(decimal::from(reward_amount));

        // TODO: should use market price
        let expected_base_token_amount = deposit_reserve.usd_to_token_amount_upper_bound(
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
/// Tracks all LMs and obligations that need processing
public fun create_vault_crank_accumulator<P, T>(vault: &Vault<P, T>): VaultCrankAccumulator {
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

/// Process a lending market into the crank accumulator after rewards have been compounded
/// This gathers fresh obligation valuations that include compounded rewards
/// Removes the LM from pending_lending_markets
public fun process_lending_market_for_crank<L>(
    acc: &mut VaultCrankAccumulator,
    lending_market: &LendingMarket<L>,
) {
    let lending_market_type = type_name::with_defining_ids<L>();

    let (_, obligation_ids) = acc.pending_lending_markets.remove(&lending_market_type);

    let obligation_allocations = calculate_obligation_values(obligation_ids, lending_market);

    let mut total_deposited = decimal::from(0);
    let mut total_borrowed = decimal::from(0);
    let mut total_net = decimal::from(0);

    obligation_allocations.do_ref!(|alloc| {
        total_deposited = decimal::add(total_deposited, alloc.deposited_value_usd);
        total_borrowed = decimal::add(total_borrowed, alloc.borrowed_value_usd);
        total_net = decimal::add(total_net, alloc.net_value_usd);
    });

    let lending_market_allocation = LendingMarketAllocation {
        deposited_value_usd: total_deposited,
        borrowed_value_usd: total_borrowed,
        net_value_usd: total_net,
        obligations: obligation_allocations,
    };

    acc.lending_market_allocations.insert(lending_market_type, lending_market_allocation);
}

/// Finalize vault crank: creates aggregate, accrues fees, updates timestamp
/// Confirms all lending markets have been processed
public fun finalize_vault_crank<P, L, T>(
    vault: &mut Vault<P, T>,
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
        decimal::add(acc, allocation.net_value_usd)
    });

    // Create aggregate with fresh post-compound state
    let agg = VaultValueAggregate {
        vault_id: object::id(vault),
        liquid_asset_value_usd,
        total_obligation_value_usd,
        lending_market_allocations,
    };

    // Accrue fees based on post-compound NAV (includes newly compounded rewards)
    vault.accrue_all_fees(&agg, clock);

    vault.last_cranked_ms = clock.timestamp_ms();
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

    if (accrual.new_nav_per_share.gt(vault.nav_high_water_mark)) {
        vault.nav_high_water_mark = accrual.new_nav_per_share;
    };
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
        let total_value = shares_to_usd(decimal::from(current_shares), base_nav);
        calculate_nav_from_shares_and_value(
            decimal::from(current_shares + total_fee_shares),
            total_value,
        )
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
    current_nav_per_share: decimal::Decimal,
    current_shares: u64,
    mgmt_shares_to_mint: u64,
): u64 {
    if (vault.performance_fee_bps == 0 || current_shares == 0) {
        return 0
    };

    // Apply performance fee only when NAV exceeds high water mark
    if (current_nav_per_share.le(vault.nav_high_water_mark)) {
        return 0
    };

    // Total value at current NAV
    let total_value =
        shares_to_usd(decimal::from(current_shares), current_nav_per_share).floor() as u128;

    // Total value at high water mark (baseline for performance)
    let baseline_value =
        shares_to_usd(decimal::from(current_shares), vault.nav_high_water_mark).floor() as u128;

    // Gain = total_value - baseline_value
    let gain = total_value - baseline_value;

    // Performance fee on the gain
    let perf_fee_value = decimal::mul(
        decimal::from_u128(gain),
        decimal::from_bps(vault.performance_fee_bps),
    );

    // Calculate shares accounting for management fee dilution
    // NAV after mgmt fees = total_value / (current_shares + mgmt_shares)
    let shares_after_mgmt = (current_shares as u128) + (mgmt_shares_to_mint as u128);
    let nav_after_mgmt = calculate_nav_from_shares_and_value(
        decimal::from_u128(shares_after_mgmt),
        decimal::from_u128(total_value),
    );

    // Convert performance fee value to shares at post-mgmt NAV
    calculate_shares_from_usd_and_nav(
        perf_fee_value,
        nav_after_mgmt,
    ).floor()
}

fun calculate_management_fee_shares<P, T>(vault: &Vault<P, T>, clock: &Clock): u64 {
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

public fun create_vault_value_accumulator<P, T>(vault: &Vault<P, T>): VaultValueAccumulator {
    let keys = vault.obligations.keys();
    let obligation_ids = keys.map_ref!(|k| {
        let obligations = vault.obligations.get(k);
        obligations.map_ref!(|bg| {
            bg.obligation_id
        })
    });
    VaultValueAccumulator {
        vault_id: object::id(vault),
        obligation_ids: vec_map::from_keys_values(keys, obligation_ids),
        lending_market_allocations: vec_map::empty(),
    }
}

public fun process_lending_market_for_value_accumulator<L>(
    acc: &mut VaultValueAccumulator,
    lending_market: &LendingMarket<L>,
) {
    let lending_market_type = type_name::with_defining_ids<L>();
    let (_, obligation_ids) = acc.obligation_ids.remove(&lending_market_type);
    let obligation_allocations = calculate_obligation_values(obligation_ids, lending_market);

    // Calculate aggregated values for this lending market
    let mut total_deposited = decimal::from(0);
    let mut total_borrowed = decimal::from(0);
    let mut total_net = decimal::from(0);

    obligation_allocations.do_ref!(|alloc| {
        total_deposited = decimal::add(total_deposited, alloc.deposited_value_usd);
        total_borrowed = decimal::add(total_borrowed, alloc.borrowed_value_usd);
        total_net = decimal::add(total_net, alloc.net_value_usd);
    });

    let lending_market_allocation = LendingMarketAllocation {
        deposited_value_usd: total_deposited,
        borrowed_value_usd: total_borrowed,
        net_value_usd: total_net,
        obligations: obligation_allocations,
    };

    acc.lending_market_allocations.insert(lending_market_type, lending_market_allocation);
}

public fun create_vault_value_aggregate<P, L, T>(
    acc: VaultValueAccumulator,
    vault: &Vault<P, T>,
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
public fun calculate_shares_to_mint<P, L, T>(
    vault: &Vault<P, T>,
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
public fun calculate_shares_to_burn<P, L, T>(
    vault: &Vault<P, T>,
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
public fun calculate_withdraw_amount<P, L, T>(
    vault: &Vault<P, T>,
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
public fun calculate_deposit_amount<P, L, T>(
    vault: &Vault<P, T>,
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

    if (decimal::eq(total_vault_value, decimal::from(0))) {
        // TODO: should panic?
        return 0
    };

    let utilization_decimal = decimal::div(
        decimal::mul(agg.total_obligation_value_usd, decimal::from(BASIS_POINTS)),
        total_vault_value,
    );

    decimal::floor(utilization_decimal)
}

public fun calculate_nav_per_share<P, T>(
    vault: &Vault<P, T>,
    agg: &VaultValueAggregate,
): decimal::Decimal {
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
public fun get_obligation_ids_for_market<P, L, T>(vault: &Vault<P, T>): vector<ID> {
    let lending_market_type = type_name::with_defining_ids<L>();
    if (vault.obligations.contains(&lending_market_type)) {
        let obligations = vault.obligations.get(&lending_market_type);
        obligations.map_ref!(|obl| obl.obligation_id)
    } else {
        vector::empty()
    }
}

/// Get obligation count for a specific lending market
public fun get_obligation_count_for_market<P, L, T>(vault: &Vault<P, T>): u64 {
    let lending_market_type = type_name::with_defining_ids<L>();
    if (vault.obligations.contains(&lending_market_type)) {
        let obligations = vault.obligations.get(&lending_market_type);
        obligations.length()
    } else {
        0
    }
}

/// Get all lending market types that have obligations
public fun get_lending_market_types<P, T>(vault: &Vault<P, T>): vector<TypeName> {
    vault.obligations.keys()
}

/// Total supply of shares
public fun total_supply<P, T>(vault: &Vault<P, T>): u64 {
    vault.treasury_cap.total_supply()
}

// === Private Helpers ===

/// Returns the share decimals factor as a Decimal for decimal calculations
fun share_decimals_factor_decimal(): decimal::Decimal {
    decimal::from(10u64.pow(VAULT_SHARE_DECIMALS))
}

/// Convert shares (in base units) to USD value using NAV per share
fun shares_to_usd(shares: decimal::Decimal, nav_per_share: decimal::Decimal): decimal::Decimal {
    shares
        .mul(nav_per_share)
        .div(decimal::from_u128(NAV_PRECISION).mul(share_decimals_factor_decimal()))
}

/// Calculates NAV per share from total shares and total USD value
/// NAV = (vault_value * NAV_PRECISION * 10^SHARE_DECIMALS) / shares
fun calculate_nav_from_shares_and_value(
    total_shares: decimal::Decimal,
    total_value_usd: decimal::Decimal,
): decimal::Decimal {
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
fun calculate_shares_from_usd_and_nav(
    usd_amount: decimal::Decimal,
    nav_per_share: decimal::Decimal,
): decimal::Decimal {
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

        let net_value_decimal = deposited_value_usd_decimal.sub(
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
    amount: decimal::Decimal,
    clock: &Clock,
): decimal::Decimal {
    let reserve = lending_market.reserve<_, T>();
    reserve.assert_price_is_fresh(clock);
    // TODO: use market price
    reserve.usd_to_token_amount_lower_bound(amount)
}

/// Get USD amount from T amount
fun get_usd_value_for_token_amount<L, T>(
    lending_market: &LendingMarket<L>,
    amount: u64,
    clock: &Clock,
): decimal::Decimal {
    let reserve = lending_market.reserve<_, T>();
    reserve.assert_price_is_fresh(clock);
    reserve.market_value(decimal::from(amount))
}

fun emit_stats_event<P, T>(vault: &Vault<P, T>, agg: &VaultValueAggregate) {
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
public fun accrue_fees_for_testing<P, T>(
    vault: &mut Vault<P, T>,
    agg: &VaultValueAggregate,
    clock: &Clock,
) {
    accrue_all_fees(vault, agg, clock)
}
