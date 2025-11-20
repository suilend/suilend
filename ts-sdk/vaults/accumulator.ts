/**************************************************************
 * THIS FILE IS GENERATED AND SHOULD NOT BE MANUALLY MODIFIED *
 **************************************************************/
import { MoveStruct, normalizeMoveArguments, type RawTransactionArgument } from '../utils/index.js';
import { bcs } from '@mysten/sui/bcs';
import { type Transaction } from '@mysten/sui/transactions';
import * as decimal from './deps/suilend/decimal.js';
import * as vec_map from './deps/sui/vec_map.js';
import * as type_name from './deps/std/type_name.js';
import * as balance from './deps/sui/balance.js';
const $moduleName = '@local-pkg/vault::accumulator';
export const AccumulatorCap = new MoveStruct({ name: `${$moduleName}::AccumulatorCap`, fields: {
        dummy_field: bcs.bool()
    } });
export const ObligationAllocation = new MoveStruct({ name: `${$moduleName}::ObligationAllocation`, fields: {
        obligation_id: bcs.Address,
        deposited_value_usd: decimal.Decimal,
        borrowed_value_usd: decimal.Decimal,
        net_value_usd: decimal.Decimal
    } });
export const LendingMarketAllocation = new MoveStruct({ name: `${$moduleName}::LendingMarketAllocation`, fields: {
        deposited_value_usd: decimal.Decimal,
        borrowed_value_usd: decimal.Decimal,
        net_value_usd: decimal.Decimal,
        obligations: bcs.vector(ObligationAllocation)
    } });
export const VaultValueAccumulator = new MoveStruct({ name: `${$moduleName}::VaultValueAccumulator`, fields: {
        ticket: AccumulatorCap,
        pending_lending_markets: vec_map.VecMap(type_name.TypeName, bcs.vector(bcs.Address)),
        lending_market_allocations: vec_map.VecMap(type_name.TypeName, LendingMarketAllocation)
    } });
export const VaultValueAggregate = new MoveStruct({ name: `${$moduleName}::VaultValueAggregate`, fields: {
        ticket: AccumulatorCap,
        liquid_asset_value_usd: decimal.Decimal,
        total_obligation_value_usd: decimal.Decimal,
        lending_market_allocations: vec_map.VecMap(type_name.TypeName, LendingMarketAllocation)
    } });
export const VaultCrankAccumulator = new MoveStruct({ name: `${$moduleName}::VaultCrankAccumulator`, fields: {
        acc: VaultValueAccumulator,
        main_pool_reserves: bcs.vector(type_name.TypeName)
    } });
export const UnwindTarget = new MoveStruct({ name: `${$moduleName}::UnwindTarget`, fields: {
        obligation_index: bcs.u64(),
        usd_to_recover: decimal.Decimal
    } });
export const VaultUnwindAccumulator = new MoveStruct({ name: `${$moduleName}::VaultUnwindAccumulator`, fields: {
        shares: balance.Balance,
        pending_unwinds: vec_map.VecMap(type_name.TypeName, bcs.vector(UnwindTarget)),
        agg: VaultValueAggregate
    } });
export interface TotalObligationValueUsdArguments {
    self: RawTransactionArgument<string>;
}
export interface TotalObligationValueUsdOptions {
    package?: string;
    arguments: TotalObligationValueUsdArguments | [
        self: RawTransactionArgument<string>
    ];
    typeArguments: [
        string
    ];
}
/** Total USD value of all obligations across all lending markets */
export function totalObligationValueUsd(options: TotalObligationValueUsdOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`
    ] satisfies string[];
    const parameterNames = ["self"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'accumulator',
        function: 'total_obligation_value_usd',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface LiquidAssetValueUsdArguments {
    self: RawTransactionArgument<string>;
}
export interface LiquidAssetValueUsdOptions {
    package?: string;
    arguments: LiquidAssetValueUsdArguments | [
        self: RawTransactionArgument<string>
    ];
    typeArguments: [
        string
    ];
}
/** USD value of vault's liquid assets */
export function liquidAssetValueUsd(options: LiquidAssetValueUsdOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`
    ] satisfies string[];
    const parameterNames = ["self"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'accumulator',
        function: 'liquid_asset_value_usd',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface ObligationIndexArguments {
    self: RawTransactionArgument<string>;
}
export interface ObligationIndexOptions {
    package?: string;
    arguments: ObligationIndexArguments | [
        self: RawTransactionArgument<string>
    ];
}
/** Obligation index for this unwind target */
export function obligationIndex(options: ObligationIndexOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::accumulator::UnwindTarget`
    ] satisfies string[];
    const parameterNames = ["self"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'accumulator',
        function: 'obligation_index',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
    });
}
export interface UsdToRecoverArguments {
    self: RawTransactionArgument<string>;
}
export interface UsdToRecoverOptions {
    package?: string;
    arguments: UsdToRecoverArguments | [
        self: RawTransactionArgument<string>
    ];
}
/** USD amount to recover from this unwind */
export function usdToRecover(options: UsdToRecoverOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::accumulator::UnwindTarget`
    ] satisfies string[];
    const parameterNames = ["self"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'accumulator',
        function: 'usd_to_recover',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
    });
}
export interface LendingMarketAllocationsArguments {
    self: RawTransactionArgument<string>;
}
export interface LendingMarketAllocationsOptions {
    package?: string;
    arguments: LendingMarketAllocationsArguments | [
        self: RawTransactionArgument<string>
    ];
    typeArguments: [
        string
    ];
}
/** Allocation data for each lending market */
export function lendingMarketAllocations(options: LendingMarketAllocationsOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`
    ] satisfies string[];
    const parameterNames = ["self"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'accumulator',
        function: 'lending_market_allocations',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}