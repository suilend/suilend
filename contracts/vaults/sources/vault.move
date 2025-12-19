module vaults::vault;

use std::type_name::{Self, TypeName};
use sui::{
    bag,
    balance::{Self, Balance},
    clock::Clock,
    coin::{Self, TreasuryCap, Coin},
    coin_registry,
    event,
    sui::SUI,
    vec_map
};
use sui_system::sui_system::SuiSystemState;
use suilend::{
    decimal::{Self, Decimal},
    lending_market::{ObligationOwnerCap, LendingMarket},
    suilend::MAIN_POOL
};
use vaults::{
    accumulator::{
        Self,
        AccumulatorCap,
        VaultValueAccumulator,
        VaultValueAggregate,
        LendingMarketAllocation,
        VaultCrankAccumulator,
        VaultUnwindAccumulator
    },
    utils::{usd_to_token_amount, token_amount_to_usd}
};

// === Errors ===

#[error]
const EFeeLimitExceeded: vector<u8> = b"Fee setting provided exceeeds limit";
#[error]
const EInvalidDeposit: vector<u8> = b"Invalid deposit amount";
#[error]
const EInsufficientShares: vector<u8> = b"Invalid shares amount";
#[error]
const EInsufficientLiquidity: vector<u8> = b"Insufficient liquidity available";
#[error]
const EInvalidShareCurrency: vector<u8> = b"Vault currency metadata is invalid";
#[error]
const ERewardsStale: vector<u8> = b"Rewards must be compounded";
#[error]
const EBaseTokenReward: vector<u8> = b"Base token rewards should not be swapped";
#[error]
const EUnwindNotNeeded: vector<u8> = b"Enough liquidity exists to redeem shares";
#[error]
const EMetadataCapExists: vector<u8> = b"Vault currency MetadataCap hasn't been burned";
#[error]
const EAccumulationInProgress: vector<u8> = b"AccumulatorCap must be returned";
#[error]
const ERecentCrank: vector<u8> = b"Vault was cranked recently";
#[error]
const EMissingReserve: vector<u8> =
    b"A Reserve for specified TypeName is not present in the LendingMarket";
#[error]
const EInsufficientRewardSwap: vector<u8> =
    b"An insufficent amount of base token was returned for swapped reward";
#[error]
const EReserveExists: vector<u8> = b"A reserve exists for this type, so oracle swap must be used";

// === Constants ===

const CURRENT_VERSION: u16 = 1;

const BASIS_POINTS: u64 = 10_000; // 100%
const U64_MAX: u64 = 18_446_744_073_709_551_615;
const SECONDS_PER_YEAR: u64 = 31_536_000;

const MAX_DEPOSIT_FEE_BPS: u64 = 500; // 5% max deposit fee
const MAX_WITHDRAWAL_FEE_BPS: u64 = 500; // 5% max withdrawal fee
const MAX_PERFORMANCE_FEE_BPS: u64 = 5000; // 50% max performance fee
const MAX_MANAGEMENT_FEE_BPS: u64 = 500; // 5% max management fee
const MIN_DEPOSIT_USD_SCALED: u256 = 100_000_000_000_000_000; // Minimum deposit 0.1 USD (0.1 * 1e18)
const NAV_PRECISION: u128 = 1_000_000_000; // 1e9 for NAV per share calculations
const MAX_REWARDS_STALENESS_MS: u64 = 3_600_000; // 1 hour in ms
const MIN_REWARDS_STALENESS_MS: u64 = 60_000; // 1 min in ms
const SLIPPAGE_BPS: u64 = 10; // For use in permissionless reward swap

const VAULT_SHARE_DECIMALS: u8 = 6;
const VAULT_SHARE_SYMBOL: vector<u8> = b"vSHARES";
const VAULT_SHARE_NAME: vector<u8> = b"Suilend Vault Shares";

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
    accumulator_cap: Option<AccumulatorCap<V>>,
    redemption_ratio_high_water_mark: Decimal, // Highest redemption ratio achieved (vault_value_in_base_asset / shares) for performance fees
    last_cranked_ms: u64, // timestamp_ms when rewards were last compounded and fees were last accrued
}

/// Capability to manage vault operations
public struct VaultManagerCap<phantom V> has key, store {
    id: object::UID,
    // Informational: access control is handled by V type param
    vault_id: object::ID,
}

/// Key for storing obligation caps in bags
public struct ObligationCapKey has copy, drop, store {}

// Accompanies a withdrawn reward and optionally validates swapped amount
public struct SwapTicket<phantom V, phantom T> { min_amount_out: option::Option<u64> }

// Can be converted to a SwapTicket after oracle presence is checked
public struct RewardWithdrawTicket<phantom V, phantom T, phantom R> { reward: Balance<R> }

/// Wrapper for obligation ownership capability
public struct ObligationData has store {
    // bag.ObligationCapKey = lending_market::ObligationOwnerCap<L>
    obligation_cap: bag::Bag,
    obligation_id: ID,
}

// === Events ===

public struct VaultCreatedEvent has copy, drop {
    vault_id: object::ID,
    management_fee_bps: u64,
    performance_fee_bps: u64,
    deposit_fee_bps: u64,
    withdrawal_fee_bps: u64,
}

public struct VaultDepositEvent has copy, drop {
    vault_id: object::ID,
    user: address,
    deposit_amount: u64,
    shares_minted: u64,
    timestamp_ms: u64,
}

public struct VaultWithdrawEvent has copy, drop {
    vault_id: object::ID,
    user: address,
    amount: u64,
    shares_burned: u64,
    timestamp_ms: u64,
}

public struct ManagerAllocateEvent has copy, drop {
    vault_id: object::ID,
    lending_market_id: object::ID,
    reserve_index: u64,
    obligation_index: u64,
    user: address,
    deposit_amount: u64,
    timestamp_ms: u64,
}

public struct ManagerDivestEvent has copy, drop {
    vault_id: object::ID,
    lending_market_id: object::ID,
    reserve_index: u64,
    obligation_index: u64,
    user: address,
    amount: u64,
    timestamp_ms: u64,
}

public struct FeesAccruedEvent has copy, drop {
    vault_id: object::ID,
    fee_type: std::string::String,
    fee_shares: u64,
    timestamp_ms: u64,
}

public struct VaultStatsEvent has copy, drop {
    vault_id: object::ID,
    base_token_type: type_name::TypeName,
    nav_per_share_usd: u64,
    utilization_rate_bps: u64,
    aum_usd: u64,
    total_shares: u64,
    lending_market_allocations: vec_map::VecMap<TypeName, LendingMarketAllocation>,
}

public struct ObligationUnwindEvent has copy, drop {
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
    assert!(vault_share_currency.icon_url().is_empty(), EInvalidShareCurrency);
    assert!(vault_share_treasury_cap.total_supply() == 0, EInvalidShareCurrency);

    assert!(management_fee_bps <= MAX_MANAGEMENT_FEE_BPS, EFeeLimitExceeded);
    assert!(performance_fee_bps <= MAX_PERFORMANCE_FEE_BPS, EFeeLimitExceeded);
    assert!(deposit_fee_bps <= MAX_DEPOSIT_FEE_BPS, EFeeLimitExceeded);
    assert!(withdrawal_fee_bps <= MAX_WITHDRAWAL_FEE_BPS, EFeeLimitExceeded);

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
        accumulator_cap: option::some(accumulator::create_accumulator_cap()),
        redemption_ratio_high_water_mark: decimal::from(0), // Will be set on first crank that vault has value
        last_cranked_ms: current_time_ms,
    };

    let vault_manager_cap = VaultManagerCap {
        id: object::new(ctx),
        vault_id: object::id(&vault),
    };

    event::emit(VaultCreatedEvent {
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
public fun deploy_funds<V, T, L>(
    vault: &mut Vault<V, T>,
    _vault_manager_cap: &VaultManagerCap<V>,
    // LendingMarket to deploy funds to
    // Must contain reserve for T (deploy target + price source)
    lending_market: &mut LendingMarket<L>,
    obligation_index: u64,
    deploy_amount: u64,
    clock: &Clock,
    mut agg: VaultValueAggregate<V>,
    ctx: &mut TxContext,
): u64 {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.assert_vault_state_fresh<V, T>(clock);
    assert!(deploy_amount > 0, EInvalidDeposit);

    // Check if vault has sufficient liquid assets
    let available_amount = vault.deposit_asset.value();
    assert!(available_amount >= deploy_amount, EInsufficientLiquidity);

    // Split funds from vault's deposit asset
    let deploy_balance = vault.deposit_asset.split(deploy_amount);
    let deploy_coin = coin::from_balance(deploy_balance, ctx);

    // Get reserve index for the asset type T
    let reserve_array_index = extract_reserve_array_index<T, _>(lending_market);

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

    event::emit(ManagerAllocateEvent {
        vault_id: object::id(vault),
        lending_market_id: object::id(lending_market),
        reserve_index: reserve_array_index,
        obligation_index,
        user: ctx.sender(),
        deposit_amount: deploy_amount,
        timestamp_ms: clock.timestamp_ms(),
    });

    {
        agg.refresh_liquid_asset_value(&vault.deposit_asset, lending_market, clock);

        // Recalculate obligation allocations
        vault.refresh_aggregate_for_lending_market(&mut agg, lending_market);

        vault.emit_stats_event(&agg);
        absorb_vault_value_aggregate(agg, vault);
    };

    ctokens_amount
}

/// Withdraw funds from lending market obligation back to vault
public fun divest_funds<V, T, L>(
    vault: &mut Vault<V, T>,
    _vault_manager_cap: &VaultManagerCap<V>,
    // LendingMarket to withdraw funds from
    // Must contain reserve for T (withdraw target + price source)
    lending_market: &mut LendingMarket<L>,
    obligation_index: u64,
    // U64_MAX will divest all ctokens from this obligation
    ctoken_amount: u64,
    clock: &Clock,
    mut agg: VaultValueAggregate<V>,
    system_state: &mut SuiSystemState,
    ctx: &mut TxContext,
) {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.assert_vault_state_fresh<V, T>(clock);
    assert!(ctoken_amount > 0, EInsufficientShares);

    let lm_type = type_name::with_defining_ids<L>();
    let obligation_cap = vault.get_obligation_cap(&lm_type, obligation_index);

    // Get reserve index for the asset type T
    let reserve_array_index = extract_reserve_array_index<T, _>(lending_market);

    // Withdraw cTokens from obligation
    let withdrawn_coin = redeem_ctokens(
        lending_market,
        obligation_cap,
        ctoken_amount,
        clock,
        system_state,
        ctx,
    );

    let withdrawn_amount = withdrawn_coin.value();

    // Add withdrawn funds back to vault's deposit asset
    vault.deposit_asset.join(withdrawn_coin.into_balance());

    event::emit(ManagerDivestEvent {
        vault_id: object::id(vault),
        lending_market_id: object::id(lending_market),
        reserve_index: reserve_array_index,
        obligation_index,
        user: ctx.sender(),
        amount: withdrawn_amount,
        timestamp_ms: clock.timestamp_ms(),
    });

    {
        agg.refresh_liquid_asset_value(&vault.deposit_asset, lending_market, clock);

        // Recalculate obligation allocations
        vault.refresh_aggregate_for_lending_market(&mut agg, lending_market);

        vault.emit_stats_event(&agg);
        absorb_vault_value_aggregate(agg, vault);
    };
}

/// Claim accumulated manager fees
public fun claim_manager_fees<V, T>(
    vault: &mut Vault<V, T>,
    _vault_manager_cap: &VaultManagerCap<V>,
    amount: u64,
    ctx: &mut TxContext,
): Coin<V> {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);

    let fee_balance = if (amount == U64_MAX) {
        vault.manager_fees.withdraw_all()
    } else {
        vault.manager_fees.split(amount)
    };

    coin::from_balance(fee_balance, ctx)
}

/// Create a new obligation for the vault
public fun create_obligation<V, T, L>(
    vault: &mut Vault<V, T>,
    _vault_manager_cap: &VaultManagerCap<V>,
    // LendingMarket to create new obligation for
    lending_market: &mut LendingMarket<L>,
    ctx: &mut TxContext,
) {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);

    let obligation_cap = lending_market.create_obligation(ctx);
    let obligation_id = obligation_cap.obligation_id();
    let mut obl_bag = bag::new(ctx);
    obl_bag.add(ObligationCapKey {}, obligation_cap);
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

/// Set or update vault metadata field
public fun set_metadata<V, T>(
    vault: &mut Vault<V, T>,
    _vault_manager_cap: &VaultManagerCap<V>,
    key: std::string::String,
    value: std::string::String,
    _ctx: &mut TxContext,
) {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);

    if (vault.metadata.contains(&key)) {
        vault.metadata.remove(&key);
    };

    vault.metadata.insert(key, value);
}

/// Remove vault metadata field
public fun unset_metadata<V, T>(
    vault: &mut Vault<V, T>,
    _vault_manager_cap: &VaultManagerCap<V>,
    key: std::string::String,
    _ctx: &mut TxContext,
) {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);

    if (vault.metadata.contains(&key)) {
        vault.metadata.remove(&key);
    };
}

/// Move a specified lending market + associated obligations to the front of the VecMap
/// This lending market will be be prioritised for unwinds
public fun move_lending_market_to_front<V, T>(
    vault: &mut Vault<V, T>,
    _vault_manager_cap: &VaultManagerCap<V>,
    lending_market_type: TypeName,
) {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);

    move_pair_to_start(&mut vault.obligations, lending_market_type);
}

/// Move an obligation to the front within its lending market's obligations vector
/// This obligation will be be prioritised for unwinds
public fun move_obligation_to_front<V, T>(
    vault: &mut Vault<V, T>,
    _vault_manager_cap: &VaultManagerCap<V>,
    lending_market_type: TypeName,
    obligation_id: ID,
) {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);

    let obligations = vault.obligations.get_mut(&lending_market_type);

    let target_idx = obligations.find_index!(|obl| obl.obligation_id == obligation_id).extract();

    // Already at front, nothing to do
    if (target_idx == 0) {
        return
    };

    // Remove and insert at front
    let target = obligations.remove(target_idx);
    obligations.insert(target, 0);
}

// === User Functions ===

/// Deposit base token and receive vault shares
public fun deposit<V, T, L>(
    vault: &mut Vault<V, T>,
    deposit: Coin<T>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
    mut agg: VaultValueAggregate<V>,
    ctx: &mut TxContext,
): Coin<V> {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    vault.assert_vault_state_fresh<V, T>(clock);

    let deposit_amount = deposit.value();
    let current_time = clock.timestamp_ms();
    let user = ctx.sender();

    // Check minimum deposit in USD terms
    {
        let deposit_usd_value = token_amount_to_usd<_, T>(
            deposit_amount,
            lending_market,
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

        event::emit(FeesAccruedEvent {
            vault_id: object::id(vault),
            fee_type: b"deposit".to_string(),
            fee_shares,
            timestamp_ms: current_time,
        });
    };

    // Emit deposit event
    event::emit(VaultDepositEvent {
        vault_id: object::id(vault),
        user: user,
        deposit_amount: deposit_amount,
        shares_minted: total_shares,
        timestamp_ms: current_time,
    });

    {
        agg.refresh_liquid_asset_value(&vault.deposit_asset, lending_market, clock);

        vault.emit_stats_event(&agg);
        absorb_vault_value_aggregate(agg, vault);
    };

    user_shares
}

/// Burn shares and withdraw base token
public fun withdraw<V, T, L>(
    vault: &mut Vault<V, T>,
    shares: Coin<V>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
    agg: VaultValueAggregate<V>,
    ctx: &mut TxContext,
): Coin<T> {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);
    assert!(shares.value() > 0, EInsufficientShares);

    // Calculate withdrawal fee in shares
    let (net_shares, _) = split_amount(shares.value(), vault.withdrawal_fee_bps);

    // Calculate total USD value of net shares being redeemed
    let current_nav_per_share = vault.calculate_nav_per_share(&agg);
    let net_usd_value = shares_to_usd(decimal::from(net_shares), current_nav_per_share);

    // Convert net USD value to token amount
    let withdraw_amount = usd_to_token_amount<_, T>(
        net_usd_value,
        lending_market,
        clock,
    ).floor();

    // Check if vault has sufficient liquidity for withdrawal
    let available_amount = vault.deposit_asset.value();
    assert!(withdraw_amount <= available_amount, EInsufficientLiquidity);
    assert!(withdraw_amount > 0, EInsufficientShares);

    vault.process_withdrawal(
        shares.into_balance(),
        withdraw_amount,
        agg,
        lending_market,
        clock,
        ctx,
    )
}

/// For withdrawals requiring obligation unwinding:
///   1. Call create_unwind_accumulator() to create accumulator with target withdrawal amount
///   2. Call process_unwinds_for_lending_market() for each LM in configured order
///   3. Call withdraw_with_unwind() to complete withdrawal
///
/// User receives: min(base_token_value_of_shares, available_liquid_assets)
/// If unwinds don't fully cover the target, user receives what was recovered.
public fun withdraw_with_unwind<V, T, L>(
    vault: &mut Vault<V, T>,
    acc: VaultUnwindAccumulator<V>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<T> {
    vault.version.assert_version(CURRENT_VERSION);

    let (shares, base_token_value_of_shares, agg) = acc.finalize_unwind_accumulator(
        &vault.deposit_asset,
        lending_market,
        clock,
    );

    let withdraw_amount = base_token_value_of_shares.min(vault.deposit_asset.value());

    vault.process_withdrawal(
        shares,
        withdraw_amount,
        agg,
        lending_market,
        clock,
        ctx,
    )
}

// === Vault Rewards Functions ===

/// Compound rewards of same type as deposit asset
/// Permissionless
public fun compound_rewards<V, T, L>(
    vault: &mut Vault<V, T>,
    // LendingMarket to claim rewards from
    lending_market: &mut LendingMarket<L>,
    obligation_index: u64,
    reward_reserve_index: u64,
    reward_index: u64,
    is_deposit_reward: bool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    vault.version.assert_version(CURRENT_VERSION);
    assert!(vault.accumulator_cap.is_some(), EAccumulationInProgress);

    let lm_type = type_name::with_defining_ids<L>();
    let obligation_cap = vault.get_obligation_cap<_, _, L>(&lm_type, obligation_index);

    // Claim rewards and deposit them back into the obligation
    let rewards = lending_market.claim_rewards<L, T>(
        obligation_cap,
        clock,
        reward_reserve_index,
        reward_index,
        is_deposit_reward,
        ctx,
    );

    vault.deposit_asset.join(rewards.into_balance());
}

/// Withdraw a non-base token reward for swapping to base token and depositing to vault
/// Can be swapped permssionlessly if a reserve + oracle exists in MAIN_POOL for T + RewardType (swap_reward_for_base_token_w_oracle)
/// Or manager permissioned if no oracle exists (swap_reward_for_base_token_unchecked)
public fun withdraw_reward<V, T, L, RewardType>(
    vault: &Vault<V, T>,
    // LendingMarket to claim reward from
    lending_market: &mut LendingMarket<L>,
    obligation_index: u64,
    reward_reserve_index: u64,
    reward_index: u64,
    is_deposit_reward: bool,
    clock: &Clock,
    ctx: &mut TxContext,
): RewardWithdrawTicket<V, T, RewardType> {
    vault.version.assert_version(CURRENT_VERSION);

    // Ensure reward is not base token
    assert!(
        type_name::with_defining_ids<T>() != type_name::with_defining_ids<RewardType>(),
        EBaseTokenReward,
    );

    let lm_type = type_name::with_defining_ids<L>();
    let obligation_cap = vault.get_obligation_cap<_, _, L>(&lm_type, obligation_index);

    let reward_coin = lending_market.claim_rewards<L, RewardType>(
        obligation_cap,
        clock,
        reward_reserve_index,
        reward_index,
        is_deposit_reward,
        ctx,
    );

    RewardWithdrawTicket { reward: reward_coin.into_balance() }
}

/// Create swap ticket with oracle-based minimum output
public fun swap_reward_for_base_token_w_oracle<V, T, RewardType>(
    vault: &Vault<V, T>,
    ticket: RewardWithdrawTicket<V, T, RewardType>,
    main_lending_market: &LendingMarket<MAIN_POOL>, // Must contain reserves for RewardType + T (price sources)
    clock: &Clock,
    ctx: &mut TxContext,
): (SwapTicket<V, T>, coin::Coin<RewardType>) {
    vault.version.assert_version(CURRENT_VERSION);

    let RewardWithdrawTicket { reward } = ticket;

    let reward_reserve = main_lending_market.reserve<_, RewardType>();
    let deposit_reserve = main_lending_market.reserve<_, T>();

    deposit_reserve.assert_price_is_fresh(clock);
    reward_reserve.assert_price_is_fresh(clock);

    let reward_usd_value = reward_reserve.market_value(decimal::from(reward.value()));

    let expected_base_token_amount = deposit_reserve.usd_to_token_amount(
        reward_usd_value,
    );

    // Apply slippage: min_amount_out = expected_amount * (1 - slippage_bps / BASIS_POINTS)
    let min_amount_out = expected_base_token_amount
        .mul(decimal::from(BASIS_POINTS)
            .sub(
                decimal::from(SLIPPAGE_BPS),
            )
            .div(decimal::from(BASIS_POINTS)))
        .floor();

    assert!(min_amount_out > 0, EInsufficientRewardSwap);

    (
        SwapTicket<V, T> { min_amount_out: option::some(min_amount_out) },
        coin::from_balance(reward, ctx),
    )
}

/// Create swap ticket without oracle check (manager only)
public fun swap_reward_for_base_token_unchecked<V, T, RewardType>(
    _vault_manager_cap: &VaultManagerCap<V>,
    ticket: RewardWithdrawTicket<V, T, RewardType>,
    main_lending_market: &LendingMarket<MAIN_POOL>,
    ctx: &mut TxContext,
): (SwapTicket<V, T>, coin::Coin<RewardType>) {
    let RewardWithdrawTicket { reward } = ticket;

    // Ensure no main pool reserve/oracle exists for the reward token
    {
        let main_pool_reserve = get_reserve_array_index<RewardType, _>(main_lending_market);
        assert!(main_pool_reserve.is_none(), EReserveExists);
    };

    (SwapTicket<V, T> { min_amount_out: option::none() }, coin::from_balance(reward, ctx))
}

/// Deposit swapped rewards to vault
public fun deposit_swapped_rewards<V, T>(
    vault: &mut Vault<V, T>,
    swap_cap: SwapTicket<V, T>,
    deposit: coin::Coin<T>,
    _ctx: &mut TxContext,
) {
    vault.version.assert_version(CURRENT_VERSION);
    assert!(vault.accumulator_cap.is_some(), EAccumulationInProgress);

    let SwapTicket { mut min_amount_out } = swap_cap;

    if (min_amount_out.is_some()) {
        assert!(deposit.value() >= min_amount_out.extract(), EInsufficientRewardSwap);
    };

    vault.deposit_asset.join(deposit.into_balance());
}

// === Vault Accumulator Functions ===
// Required to accommodate conflicting LendingMarket type parameters
// Core functionality is in vaults::accumulator

/// Begin vault value accumulation
public fun create_vault_value_accumulator<V, T>(vault: &mut Vault<V, T>): VaultValueAccumulator<V> {
    assert!(vault.accumulator_cap.is_some(), EAccumulationInProgress);
    let cap = option::extract(&mut vault.accumulator_cap);

    let obligation_ids = vault.extract_obligation_ids();
    cap.create_vault_value_accumulator(obligation_ids)
}

public fun process_lending_market_for_value_accumulator<V, L>(
    acc: &mut VaultValueAccumulator<V>,
    lending_market: &LendingMarket<L>,
) {
    acc.process_lending_market_for_value_accumulator(lending_market)
}

public fun finalize_vault_value_accumulator<V, T, L>(
    vault: &Vault<V, T>,
    acc: VaultValueAccumulator<V>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
): VaultValueAggregate<V> {
    acc.finalize_vault_value_accumulator(&vault.deposit_asset, lending_market, clock)
}

/// Create a vault crank accumulator for processing all lending markets
/// Tracks all LMs and obligations that need to be processed by process_lending_market_for_crank()
public fun create_vault_crank_accumulator<V, T>(
    vault: &mut Vault<V, T>,
    clock: &Clock,
): VaultCrankAccumulator<V> {
    vault.version.assert_version_and_upgrade(CURRENT_VERSION);

    assert!(
        clock.timestamp_ms() >= (vault.last_cranked_ms + MIN_REWARDS_STALENESS_MS),
        ERecentCrank,
    );

    let obligation_ids = vault.extract_obligation_ids();

    assert!(vault.accumulator_cap.is_some(), EAccumulationInProgress);
    let cap = option::extract(&mut vault.accumulator_cap);

    cap.create_vault_crank_accumulator(obligation_ids)
}

/// Refresh all obligations attached to one LendingMarket
public fun refresh_obligations_for_crank<V, L>(
    crank: &mut VaultCrankAccumulator<V>,
    lending_market: &mut LendingMarket<L>,
    clock: &Clock,
) {
    crank.refresh_obligations_for_crank<_, L>(lending_market, clock);
}

/// Obligations must be refreshed beforehand with refresh_obligations_for_crank
public fun process_lending_market_for_crank<V, L>(
    crank: &mut VaultCrankAccumulator<V>,
    lending_market: &LendingMarket<L>,
    main_lending_market: &LendingMarket<MAIN_POOL>,
) {
    crank.process_lending_market_for_crank(lending_market, main_lending_market)
}

/// Ensures all LendingMarkets were processed, accrues fees, updates last_cranked_ms timestamp
public fun finalize_vault_crank<V, T, L>(
    vault: &mut Vault<V, T>,
    acc: VaultCrankAccumulator<V>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
) {
    vault.version.assert_version(CURRENT_VERSION);

    let agg = acc.finalize_crank_accumulator(&vault.deposit_asset, lending_market, clock);

    vault.accrue_all_fees(&agg, lending_market, clock);

    vault.emit_stats_event(&agg);

    absorb_vault_value_aggregate(agg, vault);

    vault.last_cranked_ms = clock.timestamp_ms();
}

/// Create an unwind accumulator for withdrawals that require unwinding obligations
/// Each LendingMarket must be processed by process_unwinds_for_lending_market() in configured order
/// Manager controls unwind priority via move_lending_market_to_front / move_obligation_to_front
/// A VaultValueAggregate must first be created
public fun create_unwind_accumulator<V, T, L>(
    vault: &Vault<V, T>,
    shares: Coin<V>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    agg: VaultValueAggregate<V>,
    clock: &Clock,
): VaultUnwindAccumulator<V> {
    vault.version.assert_version(CURRENT_VERSION);

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
    let withdraw_amount_base_token = usd_to_token_amount<_, T>(
        net_usd_value,
        lending_market,
        clock,
    ).floor();

    assert!(withdraw_amount_base_token > 0, EInsufficientShares);

    // Check if vault has sufficient liquidity for withdrawal
    let liquid_allocation = vault.deposit_asset.value();
    assert!(liquid_allocation < withdraw_amount_base_token, EUnwindNotNeeded);

    agg.create_unwind_accumulator(
        withdraw_amount_base_token,
        shares.into_balance(),
    )
}

/// Process unwinding for a specific lending market
/// Withdraws and redeems ctokens from obligations in configured order, adding funds to vault.deposit_asset
/// Early exits when sufficient funds have been recovered
/// Each LM must be processed exactly once in order; calling twice or out of order aborts
/// VaultUnwindAccumulator must be consumed in withdraw_with_unwind()
public fun process_unwinds_for_lending_market<V, T, L>(
    vault: &mut Vault<V, T>,
    acc: &mut VaultUnwindAccumulator<V>,
    lending_market: &mut LendingMarket<L>,
    clock: &Clock,
    system_state: &mut SuiSystemState,
    ctx: &mut TxContext,
) {
    vault.version.assert_version(CURRENT_VERSION);

    // Skip if enough liquidity exists
    if (vault.deposit_asset.value() >= acc.base_token_value_of_shares()) {
        return
    };

    // Get obligation IDs for this LM (aborts if already processed or out of order)
    let obligation_ids = acc.get_next_unwind_targets<_, L>();

    let reserve_index = extract_reserve_array_index<T, _>(lending_market);
    let lm_type = type_name::with_defining_ids<L>();

    // Process each obligation in configured order, redeeming only what's needed
    obligation_ids.length().do!(|obl_idx| {
        let current_liquid = vault.deposit_asset.value();
        let target = acc.base_token_value_of_shares();

        // Skip if enough liquidity exists
        if (current_liquid >= target) {
            return
        };

        // Calculate remaining shortfall and convert to ctokens
        let remaining_tokens_needed = target - current_liquid;
        let ctoken_amount_needed = convert_token_amount_to_ctoken<L, T>(
            remaining_tokens_needed,
            lending_market,
            clock,
        ).ceil();

        let obligation_cap = vault.get_obligation_cap(&lm_type, obl_idx);

        // Cap at obligation's available ctoken balance
        let obligation = lending_market.obligation(obligation_cap.obligation_id());
        let available_ctokens = obligation.deposited_ctoken_amount<L, T>();
        let ctoken_amount = ctoken_amount_needed.min(available_ctokens);

        // Skip if no ctokens available in this obligation
        if (ctoken_amount == 0) {
            return
        };

        let withdrawn_coin = redeem_ctokens(
            lending_market,
            obligation_cap,
            ctoken_amount,
            clock,
            system_state,
            ctx,
        );

        let withdrawn_amount = withdrawn_coin.value();

        // Add withdrawn funds directly to vault's deposit asset
        vault.deposit_asset.join(coin::into_balance(withdrawn_coin));

        // Emit unwind event
        event::emit(ObligationUnwindEvent {
            vault_id: object::id(vault),
            lending_market_id: object::id(lending_market),
            obligation_index: obl_idx,
            reserve_index,
            ctoken_amount,
            token_amount: withdrawn_amount,
            timestamp_ms: clock.timestamp_ms(),
        });
    });

    // Refresh obligation values for this lending market
    acc.refresh_unwind_aggregate_for_lending_market(obligation_ids, lending_market);
}

// === Public Helpers ===

/// Calculates the amount of shares that will be minted for deposit_amount of T
public fun calculate_shares_to_mint<V, T, L>(
    vault: &Vault<V, T>,
    deposit_amount: u64,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    agg: &VaultValueAggregate<V>,
    clock: &Clock,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(agg);
    let deposit_usd_value = token_amount_to_usd<_, T>(
        deposit_amount,
        lending_market,
        clock,
    );
    calculate_shares_from_usd_and_nav(deposit_usd_value, nav_per_share).floor()
}

/// Calculates the amount of shares that must be burned to redeem withdraw_amount of T
public fun calculate_shares_to_burn<V, T, L>(
    vault: &Vault<V, T>,
    withdraw_amount: u64,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    agg: &VaultValueAggregate<V>,
    clock: &Clock,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(agg);
    let withdraw_usd_value = token_amount_to_usd<_, T>(
        withdraw_amount,
        lending_market,
        clock,
    );
    calculate_shares_from_usd_and_nav(withdraw_usd_value, nav_per_share).floor()
}

/// Calculates the amount of T that can be redeemed for shares_amount
public fun calculate_withdraw_amount<V, T, L>(
    vault: &Vault<V, T>,
    shares_amount: u64,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    agg: &VaultValueAggregate<V>,
    clock: &Clock,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(agg);
    let withdraw_usd_value = shares_to_usd(decimal::from(shares_amount), nav_per_share);
    usd_to_token_amount<_, T>(withdraw_usd_value, lending_market, clock).floor()
}

/// Calculates the amount of T that shares_amount will cost
public fun calculate_deposit_amount<V, T, L>(
    vault: &Vault<V, T>,
    shares_amount: u64,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    agg: &VaultValueAggregate<V>,
    clock: &Clock,
): u64 {
    let nav_per_share = vault.calculate_nav_per_share(agg);
    let deposit_usd_value = shares_to_usd(decimal::from(shares_amount), nav_per_share);
    usd_to_token_amount<_, T>(deposit_usd_value, lending_market, clock).floor()
}

/// Calculate vault utilization rate in basis points
public fun calculate_utilization_rate<V>(agg: &VaultValueAggregate<V>): u64 {
    let total_vault_value = decimal::add(
        agg.liquid_asset_value_usd(),
        agg.total_obligation_value_usd(),
    );

    if (total_vault_value.eq(decimal::from(0))) {
        return 0
    };

    let utilization_decimal = decimal::div(
        decimal::mul(agg.total_obligation_value_usd(), decimal::from(BASIS_POINTS)),
        total_vault_value,
    );

    decimal::floor(utilization_decimal)
}

/// Calculate net asset value per share
public fun calculate_nav_per_share<V, T>(
    vault: &Vault<V, T>,
    agg: &VaultValueAggregate<V>,
): Decimal {
    let current_shares = vault.treasury_cap.total_supply();
    let vault_value = decimal::add(agg.total_obligation_value_usd(), agg.liquid_asset_value_usd());
    if (current_shares == 0 || decimal::eq(vault_value, decimal::from(0))) {
        decimal::from_u128(NAV_PRECISION) // 1.0 scaled
    } else {
        calculate_nav_from_shares_and_value(
            decimal::from(current_shares),
            vault_value,
        )
    }
}

// === Fee Management Functions ===

/// Calculate and mint performance and management fee shares
fun accrue_all_fees<V, T, L>(
    vault: &mut Vault<V, T>,
    agg: &VaultValueAggregate<V>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
) {
    let current_shares = vault.treasury_cap.total_supply();
    let total_value_usd = decimal::add(
        agg.total_obligation_value_usd(),
        agg.liquid_asset_value_usd(),
    );

    // Calculate management fee shares
    let management_fee_shares = calculate_management_fee_shares(vault, clock);

    // Calculate performance fee shares
    let performance_fee_shares = calculate_performance_fee_shares(
        vault,
        total_value_usd,
        current_shares,
        lending_market,
        clock,
    );

    // Calculate redemption ratio after fees
    let redemption_ratio_after_fees = calculate_redemption_ratio<L, T>(
        total_value_usd,
        current_shares + management_fee_shares + performance_fee_shares,
        lending_market,
        clock,
    );

    let current_time = clock.timestamp_ms();

    // Mint management fee shares if any
    if (management_fee_shares > 0) {
        let fee_balance = vault.treasury_cap.mint_balance(management_fee_shares);
        vault.manager_fees.join(fee_balance);

        event::emit(FeesAccruedEvent {
            vault_id: object::id(vault),
            fee_type: b"management".to_string(),
            fee_shares: management_fee_shares,
            timestamp_ms: current_time,
        });
    };

    // Mint performance fee shares if any
    if (performance_fee_shares > 0) {
        let fee_balance = vault.treasury_cap.mint_balance(performance_fee_shares);
        vault.manager_fees.join(fee_balance);

        event::emit(FeesAccruedEvent {
            vault_id: object::id(vault),
            fee_type: b"performance".to_string(),
            fee_shares: performance_fee_shares,
            timestamp_ms: current_time,
        });
    };

    // Update high water mark if exceeds previous and vault is non-empty
    if (
        current_shares > 0 && redemption_ratio_after_fees.gt(vault.redemption_ratio_high_water_mark)
    ) {
        vault.redemption_ratio_high_water_mark = redemption_ratio_after_fees;
    };
}

/// Calculate performance fee shares from redemption ratio growth
fun calculate_performance_fee_shares<V, T, L>(
    vault: &Vault<V, T>,
    total_value_usd: Decimal,
    current_shares: u64,
    lending_market: &LendingMarket<L>,
    clock: &Clock,
): u64 {
    if (vault.performance_fee_bps == 0 || current_shares == 0) {
        return 0
    };

    // Skip performance fees if HWM not yet established
    if (vault.redemption_ratio_high_water_mark.eq(decimal::from(0))) {
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

    // Calculate total gain: gain_ratio is per whole share, so divide by share_decimals_factor
    // to convert current_shares (in base units) to whole shares
    let total_gain_in_base_asset = gain_ratio
        .mul(decimal::from(current_shares))
        .div(share_decimals_factor_decimal());

    // Convert gain to USD for fee calculation
    let gain_usd = token_amount_to_usd<L, T>(
        total_gain_in_base_asset.floor(),
        lending_market,
        clock,
    );

    // Performance fee on the gain
    let perf_fee_value = gain_usd.mul(decimal::from_bps(vault.performance_fee_bps));

    let new_nav = calculate_nav_from_shares_and_value(
        decimal::from(current_shares),
        total_value_usd,
    );

    // Convert performance fee value to shares
    calculate_shares_from_usd_and_nav(
        perf_fee_value,
        new_nav,
    ).floor()
}

/// Calculate management fee shares based on time elapsed
fun calculate_management_fee_shares<V, T>(vault: &Vault<V, T>, clock: &Clock): u64 {
    let circulating_shares = vault.treasury_cap.total_supply();
    if (vault.management_fee_bps == 0 || circulating_shares == 0) {
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

    // Cap to 1 year max management fee, unlikely to occur
    let max_fee_factor = decimal::from_bps(MAX_MANAGEMENT_FEE_BPS);
    if (decimal::gt(fee_factor, max_fee_factor)) {
        fee_factor = max_fee_factor;
    };

    // Ensures fees represent exactly the correct percentage of total vault value
    let one_minus_fee = decimal::sub(decimal::from(1), fee_factor);
    let shares_to_mint = decimal::div(
        decimal::mul(decimal::from(circulating_shares), fee_factor),
        one_minus_fee,
    );

    decimal::floor(shares_to_mint)
}

// === Private Helpers ===

/// Returns the share decimals factor as a Decimal
fun share_decimals_factor_decimal(): Decimal {
    decimal::from(10u64.pow(VAULT_SHARE_DECIMALS))
}

/// Calculate redemption ratio: vault value in base asset terms per share
/// This is the key metric for performance fees
/// ratio = (total_vault_value_usd / base_asset_price) * share_decimals_factor / total_shares
fun calculate_redemption_ratio<L, T>(
    total_value_usd: Decimal,
    total_shares: u64,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
): Decimal {
    if (total_shares == 0 || total_value_usd.eq(decimal::from(0))) {
        decimal::from(0) // Initial ratio when vault is empty
    } else {
        let vault_value_in_base_asset = usd_to_token_amount<L, T>(
            total_value_usd,
            lending_market,
            clock,
        );

        // The share_decimals_factor scaling normalizes the ratio based on share decimals
        vault_value_in_base_asset
            .mul(share_decimals_factor_decimal())
            .div(decimal::from(total_shares))
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

/// Extract obligation IDs grouped by lending market
fun extract_obligation_ids<V, T>(vault: &Vault<V, T>): vec_map::VecMap<TypeName, vector<ID>> {
    // Get all lending market types and their obligation IDs
    let keys = vault.obligations.keys();
    let obligation_ids = keys.map_ref!(|k| {
        let obligations = vault.obligations.get(k);
        obligations.map_ref!(|obl_data| {
            obl_data.obligation_id
        })
    });

    vec_map::from_keys_values(keys, obligation_ids)
}

fun emit_stats_event<V, T>(vault: &Vault<V, T>, agg: &VaultValueAggregate<V>) {
    let nav_per_share_usd = vault.calculate_nav_per_share(agg).floor();
    let aum_usd = agg.total_obligation_value_usd().add(agg.liquid_asset_value_usd());
    let utilization_rate_bps = calculate_utilization_rate(agg);
    event::emit(VaultStatsEvent {
        vault_id: object::id(vault),
        base_token_type: type_name::with_defining_ids<T>(),
        nav_per_share_usd,
        utilization_rate_bps,
        aum_usd: aum_usd.floor(),
        total_shares: vault.treasury_cap.total_supply(),
        lending_market_allocations: agg.lending_market_allocations(),
    });
}

/// Calculate the ctoken amount needed to obtain a given token amount
fun convert_token_amount_to_ctoken<L, T>(
    token_amount: u64,
    lending_market: &LendingMarket<L>,
    clock: &Clock,
): Decimal {
    let reserve = lending_market.reserve<_, T>();
    reserve.assert_price_is_fresh(clock);

    let ctoken_ratio = reserve.ctoken_ratio();
    decimal::from(token_amount).div(ctoken_ratio)
}

/// Split amount into net and fee portions
fun split_amount(amount: u64, fee_bps: u64): (u64, u64) {
    let fee_amount = (amount * fee_bps) / BASIS_POINTS;
    (amount - fee_amount, fee_amount)
}

/// Recalculates aggregate values for a specific lending market
/// Updates both the lending market allocation and the total obligation value
fun refresh_aggregate_for_lending_market<V, T, L>(
    vault: &Vault<V, T>,
    agg: &mut VaultValueAggregate<V>,
    lending_market: &LendingMarket<L>,
) {
    let obligation_ids = vault.get_obligation_ids<_, _, L>();
    agg.refresh_aggregate_for_lending_market(obligation_ids, lending_market)
}

/// Get obligation IDs for specific lending market
fun get_obligation_ids<V, T, L>(vault: &Vault<V, T>): vector<ID> {
    let lending_market_type = type_name::with_defining_ids<L>();
    let obligations = vault.obligations.get(&lending_market_type);
    obligations.map_ref!(|obl| obl.obligation_id)
}

/// Return accumulator cap to vault
fun absorb_vault_value_aggregate<V, T>(agg: VaultValueAggregate<V>, vault: &mut Vault<V, T>) {
    let cap = agg.destroy_vault_value_aggregate();
    vault.accumulator_cap.fill(cap);
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
    obl.obligation_cap.borrow(ObligationCapKey {})
}

/// Check that vault was cranked within MAX_REWARDS_STALENESS_MS
fun assert_vault_state_fresh<V, T>(vault: &Vault<V, T>, clock: &Clock) {
    let current_time = clock.timestamp_ms();

    assert!(current_time - vault.last_cranked_ms <= MAX_REWARDS_STALENESS_MS, ERewardsStale);
}

/// Get reserve index if exists in lending market
fun get_reserve_array_index<T, L>(lending_market: &LendingMarket<L>): option::Option<u64> {
    let reserve_count = lending_market.reserves().length();
    let index = lending_market.reserve_array_index<_, T>();
    if (index < reserve_count) {
        option::some(index)
    } else {
        option::none()
    }
}

/// Get reserve index, abort if missing
fun extract_reserve_array_index<T, L>(lending_market: &LendingMarket<L>): u64 {
    let mut index = get_reserve_array_index<T, L>(lending_market);
    assert!(index.is_some(), EMissingReserve);
    index.extract()
}

fun redeem_ctokens<T, L>(
    lending_market: &mut LendingMarket<L>,
    obligation_cap: &ObligationOwnerCap<L>,
    // U64_MAX will redeem all ctokens
    ctoken_amount: u64,
    clock: &Clock,
    system_state: &mut SuiSystemState,
    ctx: &mut TxContext,
): Coin<T> {
    // Get reserve index for the asset type T
    let reserve_array_index = extract_reserve_array_index<T, _>(lending_market);

    // SUI may need to be unstaked before redemption
    if (type_name::with_defining_ids<T>() == type_name::with_defining_ids<SUI>()) {
        // Withdraw cTokens from obligation
        let ctokens = lending_market.withdraw_ctokens<L, SUI>(
            reserve_array_index,
            obligation_cap,
            clock,
            ctoken_amount,
            ctx,
        );

        let liquidity_request = lending_market.redeem_ctokens_and_withdraw_liquidity_request(
            reserve_array_index,
            clock,
            ctokens,
            option::none(), // No rate limiter exemption
            ctx,
        );

        // Will no-op if there is no staker,
        // or if there is sufficient SUI liquidity to fulfill the request
        lending_market.unstake_sui_from_staker(
            reserve_array_index,
            &liquidity_request,
            system_state,
            ctx,
        );

        let withdrawn_coin = lending_market.fulfill_liquidity_request(
            reserve_array_index,
            liquidity_request,
            ctx,
        );

        cast_as_type<_, Coin<T>>(withdrawn_coin, ctx)
    } else {
        let ctokens = lending_market.withdraw_ctokens<L, T>(
            reserve_array_index,
            obligation_cap,
            clock,
            ctoken_amount,
            ctx,
        );
        lending_market.redeem_ctokens_and_withdraw_liquidity(
            reserve_array_index,
            clock,
            ctokens,
            option::none(),
            ctx,
        )
    }
}

/// Identify generic input `t` as the `R` type.
fun cast_as_type<T: store, R: store>(t: T, ctx: &mut TxContext): R {
    let mut id = object::new(ctx);
    sui::dynamic_field::add(&mut id, true, t);
    let value: R = sui::dynamic_field::remove(&mut id, true);
    id.delete();
    value
}

fun move_pair_to_start<K: copy + drop, V>(map: &mut vec_map::VecMap<K, V>, key_to_shift: K) {
    // Remove the pair to move
    let (_k, value) = map.remove(&key_to_shift);

    // Extract all remaining entries
    let mut keys = vector::empty<K>();
    let mut values = vector::empty<V>();

    while (!map.is_empty()) {
        let (k, v) = map.remove_entry_by_idx(0);
        keys.push_back(k);
        values.push_back(v);
    };

    // Now map is empty
    // Insert the moved pair first
    map.insert(key_to_shift, value);

    // Insert all the other entries
    while (!keys.is_empty()) {
        map.insert(keys.remove(0), values.remove(0));
    };

    keys.destroy_empty();
    values.destroy_empty();
}

/// Common withdrawal logic: handle fees, burn shares, withdraw tokens, emit events
fun process_withdrawal<V, T, L>(
    vault: &mut Vault<V, T>,
    mut shares: Balance<V>,
    withdraw_amount: u64,
    mut agg: VaultValueAggregate<V>,
    lending_market: &LendingMarket<L>,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<T> {
    vault.assert_vault_state_fresh<V, T>(clock);

    let shares_amount = shares.value();
    let user = ctx.sender();
    let current_time = clock.timestamp_ms();

    // Calculate withdrawal fee in shares
    let (net_shares, withdrawal_fee_shares) = split_amount(shares_amount, vault.withdrawal_fee_bps);
    assert!(net_shares > 0, EInsufficientShares);

    // Accrue withdrawal fee to manager
    if (withdrawal_fee_shares > 0) {
        let fee_balance = shares.split(withdrawal_fee_shares);
        vault.manager_fees.join(fee_balance);
        event::emit(FeesAccruedEvent {
            vault_id: object::id(vault),
            fee_type: b"withdraw".to_string(),
            fee_shares: withdrawal_fee_shares,
            timestamp_ms: current_time,
        });
    };

    // Burn user's shares
    vault.treasury_cap.burn(coin::from_balance(shares, ctx));

    // Withdraw tokens
    let withdrawn_balance = vault.deposit_asset.split(withdraw_amount);
    let coins = coin::from_balance(withdrawn_balance, ctx);

    event::emit(VaultWithdrawEvent {
        vault_id: object::id(vault),
        user,
        amount: withdraw_amount,
        shares_burned: shares_amount,
        timestamp_ms: current_time,
    });

    // Update aggregate and emit stats
    agg.refresh_liquid_asset_value(&vault.deposit_asset, lending_market, clock);
    vault.emit_stats_event(&agg);
    absorb_vault_value_aggregate(agg, vault);

    coins
}

// === Test Functions ===

#[test_only]
public fun create_vault_value_aggregate_for_testing<V, T, L>(
    vault: &mut Vault<V, T>,
    lending_market: &LendingMarket<L>,
    clock: &Clock,
): VaultValueAggregate<V> {
    let mut acc = vault.create_vault_value_accumulator();
    if (!vault.obligations.is_empty()) {
        acc.process_lending_market_for_value_accumulator(lending_market);
    };
    let agg = acc.finalize_vault_value_accumulator(&vault.deposit_asset, lending_market, clock);
    agg
}

#[test_only]
public fun destroy_vault_value_aggregate_for_testing<V, T>(
    agg: VaultValueAggregate<V>,
    vault: &mut Vault<V, T>,
) {
    absorb_vault_value_aggregate(agg, vault);
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
public fun get_deposit_for_testing<V, T>(vault: &Vault<V, T>): u64 {
    vault.deposit_asset.value()
}

#[test_only]
public fun get_vault_share_supply_for_testing<V, T>(vault: &Vault<V, T>): u64 {
    vault.treasury_cap.total_supply()
}

#[test_only]
public fun get_hwm_for_testing<V, T>(vault: &Vault<V, T>): Decimal {
    vault.redemption_ratio_high_water_mark
}
