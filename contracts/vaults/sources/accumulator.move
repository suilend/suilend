module vaults::accumulator;

use std::type_name::{Self, TypeName};
use sui::{balance::Balance, clock::Clock, vec_map};
use suilend::{
    decimal::{Self, Decimal},
    lending_market::LendingMarket,
    liquidity_mining,
    suilend::MAIN_POOL
};
use vaults::utils::token_amount_to_usd;

// === Constants ===

const MIN_REWARD_USD_SCALED: u256 = 1_000_000_000_000_000_000; // Minimum reward value where compounding is enforced: 1 USD (1 * 1e18)

// === Errors ===

#[error]
const EIncorrectOrder: vector<u8> = b"LendingMarket processed out of order";
#[error]
const EIncompleteAccumulation: vector<u8> = b"VaultValueAccumulator processing incomplete";
#[error]
const EUnclaimedRewards: vector<u8> = b"All rewards must be claimed before cranking";
#[error]
const EObligationsNotRefreshed: vector<u8> = b"Obligations must be refreshed before proceeding";

// === Structs ===

/// The capability to build and use an accumulator
public struct AccumulatorCap<phantom V> has store {}

/// Used to aggregate the obligation values from all LendingMarkets utilised by the vault
/// Must be consumed in PTB
public struct VaultValueAccumulator<phantom V> {
    ticket: AccumulatorCap<V>,
    // Keyed by 'L' from LendingMarket<L> -> obligation IDs (removed as each LM is scanned for outstanding rewards)
    pending_lending_markets: vec_map::VecMap<TypeName, vector<ID>>,
    // Keyed by LM TypeName -> allocation data (added as each LM is processed)
    lending_market_allocations: vec_map::VecMap<TypeName, LendingMarketAllocation>,
}

/// Created from a VaultValueAccumulator once it has been fully processed
public struct VaultValueAggregate<phantom V> {
    ticket: AccumulatorCap<V>,
    liquid_asset_value_usd: Decimal,
    total_obligation_value_usd: Decimal,
    lending_market_allocations: vec_map::VecMap<TypeName, LendingMarketAllocation>,
}

/// Accumulator for vault crank operations (refreshing obligations, validating rewards status then accumulating fees)
/// Processes all lending markets in the vault
/// Must be consumed in PTB
public struct VaultCrankAccumulator<phantom V> {
    acc: VaultValueAccumulator<V>,
    // NOTE: refreshing must be separate from the reward crank processing as the
    // reward checking requires 2 LendingMarket parameters (MAIN_POOL + other), which can be the same
    // therefore it is not possible for one of them to be a mutable reference
    pending_obligations_for_refresh: vec_map::VecMap<TypeName, vector<ID>>,
}

/// For tracking obligation unwinds needed to satisfy a withdrawal
/// Must be consumed in PTB
public struct VaultUnwindAccumulator<phantom V> {
    // vault shares to redeem
    shares: Balance<V>,
    // base token value that shares entitle user to (net of withdrawal fee)
    base_token_value_of_shares: u64,
    // Keyed by lending market type -> obligation IDs (removed as each LM is processed)
    pending_unwinds: vec_map::VecMap<TypeName, vector<ID>>,
    agg: VaultValueAggregate<V>,
}

/// Aggregated value data for all obligations in a lending market
public struct LendingMarketAllocation has copy, drop {
    deposited_value_usd: Decimal,
    borrowed_value_usd: Decimal,
    net_value_usd: Decimal,
    obligations: vector<ObligationAllocation>,
}

/// Value data for a single obligation
public struct ObligationAllocation has copy, drop, store {
    obligation_id: ID,
    deposited_value_usd: Decimal,
    borrowed_value_usd: Decimal,
    net_value_usd: Decimal,
}

// === Public functions ===

/// Total USD value of all obligations across all lending markets
public fun total_obligation_value_usd<V>(self: &VaultValueAggregate<V>): Decimal {
    self.total_obligation_value_usd
}

/// USD value of vault's liquid assets
public fun liquid_asset_value_usd<V>(self: &VaultValueAggregate<V>): Decimal {
    self.liquid_asset_value_usd
}

/// Allocation data for each lending market
public fun lending_market_allocations<V>(
    self: &VaultValueAggregate<V>,
): vec_map::VecMap<TypeName, LendingMarketAllocation> {
    self.lending_market_allocations
}

public fun base_token_value_of_shares<V>(self: &VaultUnwindAccumulator<V>): u64 {
    self.base_token_value_of_shares
}

// === Package functions ===

/// Create accumulator capability. Use once per vault. V = vault share type
public(package) fun create_accumulator_cap<V>(): AccumulatorCap<V> {
    AccumulatorCap {}
}

/// Create accumulator to aggregate obligation values
public(package) fun create_vault_value_accumulator<V>(
    cap: AccumulatorCap<V>,
    lm_obligations_map: vec_map::VecMap<TypeName, vector<ID>>,
): VaultValueAccumulator<V> {
    VaultValueAccumulator {
        ticket: cap,
        pending_lending_markets: lm_obligations_map,
        lending_market_allocations: vec_map::empty(),
    }
}

/// Process lending market and calculate obligation values
public(package) fun process_lending_market_for_value_accumulator<V, L>(
    acc: &mut VaultValueAccumulator<V>,
    lending_market: &LendingMarket<L>,
) {
    let lending_market_type = type_name::with_defining_ids<L>();

    let obligation_ids = {
        // Ensure order is maintained
        let (lm_type, obligation_ids) = acc.pending_lending_markets.remove_entry_by_idx(0);
        assert!(lm_type == lending_market_type, EIncorrectOrder);
        obligation_ids
    };

    let obligation_allocations = calculate_obligation_values(obligation_ids, lending_market);

    let lending_market_allocation = aggregate_allocation_data(
        obligation_allocations,
    );

    acc.lending_market_allocations.insert(lending_market_type, lending_market_allocation);
}

/// Complete accumulation and return aggregate with total vault value
public(package) fun finalize_vault_value_accumulator<V, T, L>(
    acc: VaultValueAccumulator<V>,
    deposit_asset: &Balance<T>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
): VaultValueAggregate<V> {
    assert!(acc.pending_lending_markets.is_empty(), EIncompleteAccumulation);

    let liquid_asset_value_usd = {
        let liquid_asset_value = deposit_asset.value();
        token_amount_to_usd<L, T>(liquid_asset_value, lending_market, clock)
    };

    let VaultValueAccumulator {
        ticket,
        pending_lending_markets: _,
        lending_market_allocations,
    } = acc;

    // Calculate total obligation value from all lending markets
    let total_obligation_value_usd = aggregate_lending_market_obligations(
        lending_market_allocations,
    );

    VaultValueAggregate {
        ticket,
        liquid_asset_value_usd,
        total_obligation_value_usd,
        lending_market_allocations,
    }
}

/// Consume aggregate and return accumulator capability
public(package) fun destroy_vault_value_aggregate<V>(
    agg: VaultValueAggregate<V>,
): AccumulatorCap<V> {
    let VaultValueAggregate {
        ticket,
        liquid_asset_value_usd: _,
        total_obligation_value_usd: _,
        lending_market_allocations: _,
    } = agg;
    ticket
}

/// Create a vault crank accumulator for processing all lending markets
/// Tracks all LMs and obligations that need to be processed by process_lending_market_for_crank()
public(package) fun create_vault_crank_accumulator<V>(
    cap: AccumulatorCap<V>,
    lm_obligations_map: vec_map::VecMap<TypeName, vector<ID>>,
): VaultCrankAccumulator<V> {
    VaultCrankAccumulator {
        acc: create_vault_value_accumulator(cap, lm_obligations_map),
        pending_obligations_for_refresh: lm_obligations_map,
    }
}

public(package) fun refresh_obligations_for_crank<V, L>(
    crank: &mut VaultCrankAccumulator<V>,
    lending_market: &mut LendingMarket<L>,
    clock: &Clock,
) {
    let lending_market_type = type_name::with_defining_ids<L>();
    let (_, obligation_ids) = crank.pending_obligations_for_refresh.remove(&lending_market_type);
    obligation_ids.do_ref!(|obligation_id| {
        let obligation = lending_market.obligation(*obligation_id);
        // Only refresh if there are deposits
        if (!obligation.deposits().is_empty()) {
            lending_market.refresh_obligation(*obligation_id, clock);
        };
    });
}

/// This verifies none of the obligations for this LendingMarket have outstanding rewards to be compounded
/// It also calculates the current obligation net values
/// Removes the LendingMarket from acc.pending_lending_markets
/// Obligations must be refreshed beforehand with refresh_obligations_for_crank
public(package) fun process_lending_market_for_crank<V, L>(
    crank: &mut VaultCrankAccumulator<V>,
    lending_market: &LendingMarket<L>,
    main_lending_market: &LendingMarket<MAIN_POOL>,
) {
    let lending_market_type = type_name::with_defining_ids<L>();

    // Ensure obligations have been refreshed
    assert!(crank.pending_obligations_for_refresh.is_empty(), EObligationsNotRefreshed);

    // Enforce that this lending market is in the pending list and remove it
    let (_, obligation_ids) = crank.acc.pending_lending_markets.remove(&lending_market_type);

    obligation_ids.do!(|obligation_id| {
        assert_no_claimable_rewards(
            lending_market,
            main_lending_market,
            obligation_id,
        );
    });

    let obligation_allocations = calculate_obligation_values(obligation_ids, lending_market);

    let lending_market_allocation = aggregate_allocation_data(
        obligation_allocations,
    );

    crank.acc.lending_market_allocations.insert(lending_market_type, lending_market_allocation);
}

/// Complete crank accumulation and return aggregate
public(package) fun finalize_crank_accumulator<V, T, L>(
    crank: VaultCrankAccumulator<V>,
    deposit_asset: &Balance<T>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
): VaultValueAggregate<V> {
    let VaultCrankAccumulator {
        acc,
        pending_obligations_for_refresh: _,
    } = crank;

    let agg = acc.finalize_vault_value_accumulator(deposit_asset, lending_market, clock);

    agg
}

/// Create accumulator for unwind withdrawal
/// Client controls unwind order by calling process_unwinds_for_lending_market in desired sequence
public(package) fun create_unwind_accumulator<V>(
    agg: VaultValueAggregate<V>,
    base_token_value_of_shares: u64,
    shares: Balance<V>,
): VaultUnwindAccumulator<V> {
    let (lm_keys, lm_vals) = agg.lending_market_allocations.into_keys_values();

    let ids = lm_vals.map!(|allocation| {
        let obligation_ids = allocation.obligations.map_ref!(|obl| obl.obligation_id);
        obligation_ids
    });

    let pending_unwinds = vec_map::from_keys_values(lm_keys, ids);

    VaultUnwindAccumulator {
        base_token_value_of_shares,
        pending_unwinds,
        shares,
        agg,
    }
}

/// Complete unwind accumulation and return shares, base_token_value_of_shares, and updated aggregate
public(package) fun finalize_unwind_accumulator<V, T, L>(
    acc: VaultUnwindAccumulator<V>,
    deposit_asset: &Balance<T>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
): (Balance<V>, u64, VaultValueAggregate<V>) {
    let VaultUnwindAccumulator {
        base_token_value_of_shares,
        pending_unwinds: _,
        shares,
        mut agg,
    } = acc;

    // Update liquid value as unwinds will have increased it
    agg.refresh_liquid_asset_value(deposit_asset, lending_market, clock);

    (shares, base_token_value_of_shares, agg)
}

/// Recalculates aggregate values for a specific lending market
/// Updates both the lending market allocation and the total obligation value
public(package) fun refresh_aggregate_for_lending_market<V, L>(
    agg: &mut VaultValueAggregate<V>,
    obligation_ids: vector<ID>,
    lending_market: &LendingMarket<L>,
) {
    let lending_market_type = type_name::with_defining_ids<L>();
    let obligation_allocations = calculate_obligation_values(obligation_ids, lending_market);

    let updated_lm_allocation = aggregate_allocation_data(obligation_allocations);

    let alloc = agg.lending_market_allocations.get_mut(&lending_market_type);
    *alloc = updated_lm_allocation;

    // Recalculate total obligation value from all lending markets
    let total_obligation_value_usd = aggregate_lending_market_obligations(agg.lending_market_allocations);

    agg.total_obligation_value_usd = total_obligation_value_usd;
}

/// Update aggregate for lending market within unwind accumulator
public(package) fun refresh_unwind_aggregate_for_lending_market<V, L>(
    acc: &mut VaultUnwindAccumulator<V>,
    obligation_ids: vector<ID>,
    lending_market: &LendingMarket<L>,
) {
    acc.agg.refresh_aggregate_for_lending_market(obligation_ids, lending_market)
}

/// Recalculate liquid asset value in USD
public(package) fun refresh_liquid_asset_value<V, T, L>(
    agg: &mut VaultValueAggregate<V>,
    deposit_asset: &Balance<T>,
    lending_market: &LendingMarket<L>,
    clock: &Clock,
) {
    let updated_liquid_asset_value_usd = {
        let liquid_asset_value = deposit_asset.value();
        token_amount_to_usd<_, T>(liquid_asset_value, lending_market, clock)
    };
    agg.liquid_asset_value_usd = updated_liquid_asset_value_usd;
}

/// Get and remove obligation IDs for next lending market in configured order
/// Aborts if LM was already processed or is out of order
public(package) fun get_next_unwind_targets<V, L>(acc: &mut VaultUnwindAccumulator<V>): vector<ID> {
    let (lm_type, obligation_ids) = acc.pending_unwinds.remove_entry_by_idx(0);
    assert!(lm_type == type_name::with_defining_ids<L>(), EIncorrectOrder);
    obligation_ids
}

// === Private functions ===

/// Verify obligation has no unclaimed main pool rewards
fun assert_no_claimable_rewards<V>(
    lending_market: &LendingMarket<V>,
    main_lending_market: &LendingMarket<MAIN_POOL>,
    obligation_id: ID,
) {
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

        let unclaimed_rewards = get_unclaimed_reward_indexes(
            main_lending_market,
            user_reward_manager,
            pool_reward_manager,
        );

        assert!(unclaimed_rewards.is_empty(), EUnclaimedRewards);
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

        let unclaimed_rewards = get_unclaimed_reward_indexes(
            main_lending_market,
            user_reward_manager,
            pool_reward_manager,
        );

        assert!(unclaimed_rewards.is_empty(), EUnclaimedRewards);
    });
}

/// Get indexes of rewards that are in MAIN_POOL and have a value > 1 USD
fun get_unclaimed_reward_indexes(
    main_lending_market: &LendingMarket<MAIN_POOL>,
    user_reward_manager: &liquidity_mining::UserRewardManager,
    pool_reward_manager: &liquidity_mining::PoolRewardManager,
): vector<u64> {
    let user_rewards = user_reward_manager.rewards();
    let pool_rewards = pool_reward_manager.pool_rewards();
    let reserves = main_lending_market.reserves();

    let mut result = vector::empty();
    user_rewards.length().do!(|reward_index| {
        let optional_user_reward = user_rewards.borrow(reward_index);

        if (optional_user_reward.is_some()) {
            let user_reward = optional_user_reward.borrow();

            // Only include rewards with non-zero earnings
            if (user_reward.earned_rewards().gt(decimal::from(0))) {
                let optional_pool_reward = pool_rewards.borrow(reward_index);
                if (optional_pool_reward.is_some()) {
                    let pool_reward = optional_pool_reward.borrow();
                    let main_pool_reserve_index = reserves.find_index!(|r| {
                        r.coin_type() == pool_reward.coin_type()
                    });
                    // Ignore rewards that aren't in MAIN_POOL
                    if (main_pool_reserve_index.is_some()) {
                        let reward_reserve = reserves.borrow(*main_pool_reserve_index.borrow());
                        let reward_usd_value = reward_reserve.market_value(user_reward.earned_rewards());
                        // Ignore rewards that are less than 1 USD
                        if (reward_usd_value.ge(decimal::from_scaled_val(MIN_REWARD_USD_SCALED))) {
                            result.push_back(reward_index);
                        };
                    }
                };
            };
        };
    });

    result
}

/// Aggregate obligation allocations into lending market totals
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

/// Sum net value across all lending markets
fun aggregate_lending_market_obligations(
    allocations: vec_map::VecMap<TypeName, LendingMarketAllocation>,
): Decimal {
    let ks = allocations.keys();
    let total_obligation_value_usd = ks.fold!(decimal::from(0), |acc, k| {
        let allocation = allocations.get(&k);
        acc.add(allocation.net_value_usd)
    });
    total_obligation_value_usd
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

        // TODO: handle negative balances if borrowing is enabled
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
