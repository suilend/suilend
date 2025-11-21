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

// === Errors ===

#[error]
const EIncorrectOrder: vector<u8> = b"LendingMarket processed out of order";
#[error]
const EIncompleteAccumulation: vector<u8> = b"VaultValueAccumulator processing incomplete";
#[error]
const EUnclaimedRewards: vector<u8> = b"All rewards must be claimed before cranking";
#[error]
const EInsufficientLiquidityForUnwind: vector<u8> =
    b"Enough liquidity to redeem shares was not found";

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

/// Accumulator for vault crank operations (validating rewards status then accumulating fees)
/// Processes all lending markets in the vault
/// Must be consumed in PTB
public struct VaultCrankAccumulator<phantom V> {
    acc: VaultValueAccumulator<V>,
    main_pool_reserves: vector<TypeName>,
}

/// For tracking obligation unwinds needed to satisfy a withdrawal
/// Must be consumed in PTB
public struct VaultUnwindAccumulator<phantom V> {
    // vault shares to redeem
    shares: Balance<V>,
    // Keyed by lending market type -> vector of unwind targets in FIFO order
    pending_unwinds: vec_map::VecMap<TypeName, vector<UnwindTarget>>,
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

/// Specifies an obligation position planned for unwind
public struct UnwindTarget has drop {
    obligation_index: u64,
    usd_to_recover: Decimal,
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

/// Obligation index for this unwind target
public fun obligation_index(self: &UnwindTarget): u64 {
    self.obligation_index
}

/// USD amount to recover from this unwind
public fun usd_to_recover(self: &UnwindTarget): Decimal {
    self.usd_to_recover
}

/// Allocation data for each lending market
public fun lending_market_allocations<V>(
    self: &VaultValueAggregate<V>,
): vec_map::VecMap<TypeName, LendingMarketAllocation> {
    self.lending_market_allocations
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
    main_lending_market: &LendingMarket<MAIN_POOL>,
): VaultCrankAccumulator<V> {
    let main_pool_reserves = main_lending_market.reserves().map_ref!(|r| {
        r.coin_type()
    });
    VaultCrankAccumulator {
        acc: create_vault_value_accumulator(cap, lm_obligations_map),
        main_pool_reserves,
    }
}

/// This verifies none of the obligations for this LendingMarket have outstanding rewards to be compounded
/// It also calculates the current obligation net values
/// Removes the LendingMarket from acc.pending_lending_markets
public(package) fun process_lending_market_for_crank<V, L>(
    crank: &mut VaultCrankAccumulator<V>,
    lending_market: &LendingMarket<L>,
) {
    let lending_market_type = type_name::with_defining_ids<L>();

    // Enforce that this lending market is in the pending list and remove it
    let (_, obligation_ids) = crank.acc.pending_lending_markets.remove(&lending_market_type);

    obligation_ids.do!(|obligation_id| {
        assert_no_claimable_rewards(lending_market, &crank.main_pool_reserves, obligation_id);
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
        main_pool_reserves: _,
    } = crank;

    let agg = acc.finalize_vault_value_accumulator(deposit_asset, lending_market, clock);

    agg
}

/// Create accumulator with unwind plan to cover withdrawal shortfall
public(package) fun create_unwind_accumulator<V>(
    agg: VaultValueAggregate<V>,
    shortfall_usd: Decimal,
    shares: Balance<V>,
): VaultUnwindAccumulator<V> {
    let pending_unwinds = agg.calculate_unwind_plan(shortfall_usd);

    VaultUnwindAccumulator {
        pending_unwinds,
        shares,
        agg,
    }
}

/// Complete unwind accumulation and return shares and updated aggregate
public(package) fun finalize_unwind_accumulator<V, T, L>(
    acc: VaultUnwindAccumulator<V>,
    deposit_asset: &Balance<T>,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
): (Balance<V>, VaultValueAggregate<V>) {
    assert!(acc.pending_unwinds.is_empty(), EIncompleteAccumulation);

    let VaultUnwindAccumulator {
        pending_unwinds: _,
        shares,
        mut agg,
    } = acc;

    // Update liquid value as unwinds will have increased it
    agg.refresh_liquid_asset_value(deposit_asset, lending_market, clock);

    (shares, agg)
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

/// Get next unwind targets for lending market
public(package) fun get_next_unwind_targets<V, L>(
    acc: &mut VaultUnwindAccumulator<V>,
): option::Option<vector<UnwindTarget>> {
    let lending_market_type = type_name::with_defining_ids<L>();

    if (!acc.pending_unwinds.contains(&lending_market_type)) {
        return option::none()
    };

    let unwind_targets = {
        // Ensure order is maintained
        let (lm_type, unwind_targets) = acc.pending_unwinds.remove_entry_by_idx(0);
        assert!(lm_type == lending_market_type, EIncorrectOrder);
        unwind_targets
    };

    if (unwind_targets.is_empty()) {
        return option::none()
    };

    option::some(unwind_targets)
}

// === Private functions ===

/// Verify obligation has no unclaimed main pool rewards
fun assert_no_claimable_rewards<V>(
    lending_market: &LendingMarket<V>,
    main_pool_reserves: &vector<TypeName>,
    obligation_id: ID,
) {
    let reserves = lending_market.reserves();
    let obligation = lending_market.obligation(obligation_id);

    // Process deposit rewards
    obligation.deposits().do_ref!(|deposit| {
        let reserve_index = deposit.reserve_array_index();
        let reserve = reserves.borrow(reserve_index);
        if (main_pool_reserves.contains(&reserve.coin_type())) {
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
        }
    });

    // Process borrow rewards
    obligation.borrows().do_ref!(|borrow| {
        let reserve_index = borrow.reserve_array_index();
        let reserve = reserves.borrow(reserve_index);
        if (main_pool_reserves.contains(&reserve.coin_type())) {
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
        }
    });
}

/// Get indexes of rewards with non-zero claimable amounts
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

/// Calculate which obligations need to be unwound to cover a shortfall
/// Uses FIFO strategy: processes obligations in order of creation (by LM type, then index)
/// Returns a map of lending market type -> vector of UnwindTargets
fun calculate_unwind_plan<V>(
    agg: &VaultValueAggregate<V>,
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

        // TODO: handle negative balances if lending is enabled
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
