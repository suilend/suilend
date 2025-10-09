/**************************************************************
 * THIS FILE IS GENERATED AND SHOULD NOT BE MANUALLY MODIFIED *
 **************************************************************/
import { MoveStruct, MoveEnum, normalizeMoveArguments, type RawTransactionArgument } from '../utils/index.js';
import { bcs } from '@mysten/sui/bcs';
import { type Transaction } from '@mysten/sui/transactions';
import * as bag from './deps/sui/bag.js';
import * as object from './deps/sui/object.js';
import * as vec_map from './deps/sui/vec_map.js';
import * as type_name from './deps/std/type_name.js';
import * as coin from './deps/sui/coin.js';
import * as balance from './deps/sui/balance.js';
const $moduleName = '@local-pkg/vault::vault';
export const ObligationData = new MoveStruct({ name: `${$moduleName}::ObligationData`, fields: {
        obligation_cap: bag.Bag,
        obligation_id: bcs.Address
    } });
export const Vault = new MoveStruct({ name: `${$moduleName}::Vault`, fields: {
        id: object.UID,
        version: bcs.u64(),
        obligations: vec_map.VecMap(type_name.TypeName, bcs.vector(ObligationData)),
        treasury_cap: coin.TreasuryCap,
        deposit_asset: balance.Balance,
        manager_fees: balance.Balance,
        management_fee_bps: bcs.u64(),
        performance_fee_bps: bcs.u64(),
        deposit_fee_bps: bcs.u64(),
        withdrawal_fee_bps: bcs.u64(),
        nav_high_water_mark: bcs.u64(),
        fee_last_update_timestamp_s: bcs.u64()
    } });
export const VaultManagerCap = new MoveStruct({ name: `${$moduleName}::VaultManagerCap`, fields: {
        id: object.UID,
        vault_id: bcs.Address
    } });
export const VaultValueAccumulator = new MoveStruct({ name: `${$moduleName}::VaultValueAccumulator`, fields: {
        obligation_ids: vec_map.VecMap(type_name.TypeName, bcs.vector(bcs.Address)),
        lending_market_values: vec_map.VecMap(type_name.TypeName, bcs.u64())
    } });
export const VaultValueAggregate = new MoveStruct({ name: `${$moduleName}::VaultValueAggregate`, fields: {
        liquid_asset_value_usd: bcs.u64(),
        total_obligation_value_usd: bcs.u64(),
        lending_market_values: vec_map.VecMap(type_name.TypeName, bcs.u64())
    } });
export const FeeAccrual = new MoveStruct({ name: `${$moduleName}::FeeAccrual`, fields: {
        management_fee_shares: bcs.u64(),
        performance_fee_shares: bcs.u64(),
        total_fee_shares: bcs.u64(),
        new_nav_per_share: bcs.u64()
    } });
export const VaultCreated = new MoveStruct({ name: `${$moduleName}::VaultCreated`, fields: {
        vault_id: bcs.Address,
        management_fee_bps: bcs.u64(),
        performance_fee_bps: bcs.u64(),
        deposit_fee_bps: bcs.u64(),
        withdrawal_fee_bps: bcs.u64()
    } });
export const VaultDeposit = new MoveStruct({ name: `${$moduleName}::VaultDeposit`, fields: {
        vault_id: bcs.Address,
        user: bcs.Address,
        deposit_amount: bcs.u64(),
        shares_minted: bcs.u64(),
        timestamp_ms: bcs.u64()
    } });
export const VaultWithdraw = new MoveStruct({ name: `${$moduleName}::VaultWithdraw`, fields: {
        vault_id: bcs.Address,
        user: bcs.Address,
        amount: bcs.u64(),
        shares_burned: bcs.u64(),
        timestamp_ms: bcs.u64()
    } });
export const ManagerAllocate = new MoveStruct({ name: `${$moduleName}::ManagerAllocate`, fields: {
        vault_id: bcs.Address,
        user: bcs.Address,
        deposit_amount: bcs.u64(),
        timestamp_ms: bcs.u64()
    } });
export const ManagerDivest = new MoveStruct({ name: `${$moduleName}::ManagerDivest`, fields: {
        vault_id: bcs.Address,
        user: bcs.Address,
        amount: bcs.u64(),
        timestamp_ms: bcs.u64()
    } });
export const FeeType = new MoveEnum({ name: `${$moduleName}::FeeType`, fields: {
        DepositFee: null,
        WithdrawalFee: null,
        PerformanceFee: null,
        ManagementFee: null
    } });
export const FeesAccrued = new MoveStruct({ name: `${$moduleName}::FeesAccrued`, fields: {
        vault_id: bcs.Address,
        fee_type: FeeType,
        fee_shares: bcs.u64(),
        timestamp_ms: bcs.u64()
    } });
export interface CreateVaultArguments {
    treasuryCap: RawTransactionArgument<string>;
    currency: RawTransactionArgument<string>;
    managementFeeBps: RawTransactionArgument<number | bigint>;
    performanceFeeBps: RawTransactionArgument<number | bigint>;
    depositFeeBps: RawTransactionArgument<number | bigint>;
    withdrawalFeeBps: RawTransactionArgument<number | bigint>;
}
export interface CreateVaultOptions {
    package?: string;
    arguments: CreateVaultArguments | [
        treasuryCap: RawTransactionArgument<string>,
        currency: RawTransactionArgument<string>,
        managementFeeBps: RawTransactionArgument<number | bigint>,
        performanceFeeBps: RawTransactionArgument<number | bigint>,
        depositFeeBps: RawTransactionArgument<number | bigint>,
        withdrawalFeeBps: RawTransactionArgument<number | bigint>
    ];
    typeArguments: [
        string,
        string
    ];
}
export function createVault(options: CreateVaultOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `0x0000000000000000000000000000000000000000000000000000000000000002::coin::TreasuryCap<${options.typeArguments[0]}>`,
        `0x0000000000000000000000000000000000000000000000000000000000000002::coin_registry::Currency<${options.typeArguments[0]}>`,
        'u64',
        'u64',
        'u64',
        'u64',
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
    ] satisfies string[];
    const parameterNames = ["treasuryCap", "currency", "managementFeeBps", "performanceFeeBps", "depositFeeBps", "withdrawalFeeBps"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'create_vault',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface DepositArguments {
    vault: RawTransactionArgument<string>;
    deposit: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
    agg: RawTransactionArgument<string>;
}
export interface DepositOptions {
    package?: string;
    arguments: DepositArguments | [
        vault: RawTransactionArgument<string>,
        deposit: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>,
        agg: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
export function deposit(options: DepositOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[2]}>`,
        `0x0000000000000000000000000000000000000000000000000000000000000002::coin::Coin<${options.typeArguments[2]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[1]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock',
        `${packageAddress}::vault::VaultValueAggregate`
    ] satisfies string[];
    const parameterNames = ["vault", "deposit", "lendingMarket", "agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'deposit',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface WithdrawArguments {
    vault: RawTransactionArgument<string>;
    shares: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
    agg: RawTransactionArgument<string>;
}
export interface WithdrawOptions {
    package?: string;
    arguments: WithdrawArguments | [
        vault: RawTransactionArgument<string>,
        shares: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>,
        agg: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/**
 * User burns shares and withdraws proportional assets with performance fees on
 * realized gains
 */
export function withdraw(options: WithdrawOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[2]}>`,
        `0x0000000000000000000000000000000000000000000000000000000000000002::coin::Coin<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[1]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock',
        `${packageAddress}::vault::VaultValueAggregate`
    ] satisfies string[];
    const parameterNames = ["vault", "shares", "lendingMarket", "agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'withdraw',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface CalculateSharesToMintArguments {
    vault: RawTransactionArgument<string>;
    depositAmount: RawTransactionArgument<number | bigint>;
    lendingMarket: RawTransactionArgument<string>;
    agg: RawTransactionArgument<string>;
}
export interface CalculateSharesToMintOptions {
    package?: string;
    arguments: CalculateSharesToMintArguments | [
        vault: RawTransactionArgument<string>,
        depositAmount: RawTransactionArgument<number | bigint>,
        lendingMarket: RawTransactionArgument<string>,
        agg: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/** Calculates the amount of shares that will be minted for deposit_amount of T */
export function calculateSharesToMint(options: CalculateSharesToMintOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[2]}>`,
        'u64',
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultValueAggregate`
    ] satisfies string[];
    const parameterNames = ["vault", "depositAmount", "lendingMarket", "agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'calculate_shares_to_mint',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface CalculateSharesToBurnArguments {
    vault: RawTransactionArgument<string>;
    withdrawAmount: RawTransactionArgument<number | bigint>;
    lendingMarket: RawTransactionArgument<string>;
    agg: RawTransactionArgument<string>;
}
export interface CalculateSharesToBurnOptions {
    package?: string;
    arguments: CalculateSharesToBurnArguments | [
        vault: RawTransactionArgument<string>,
        withdrawAmount: RawTransactionArgument<number | bigint>,
        lendingMarket: RawTransactionArgument<string>,
        agg: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/**
 * Calculates the amount of shares that must be burned to redeem withdraw_amount of
 * T
 */
export function calculateSharesToBurn(options: CalculateSharesToBurnOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[2]}>`,
        'u64',
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultValueAggregate`
    ] satisfies string[];
    const parameterNames = ["vault", "withdrawAmount", "lendingMarket", "agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'calculate_shares_to_burn',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface CalculateWithdrawAmountArguments {
    vault: RawTransactionArgument<string>;
    sharesAmount: RawTransactionArgument<number | bigint>;
    lendingMarket: RawTransactionArgument<string>;
    agg: RawTransactionArgument<string>;
}
export interface CalculateWithdrawAmountOptions {
    package?: string;
    arguments: CalculateWithdrawAmountArguments | [
        vault: RawTransactionArgument<string>,
        sharesAmount: RawTransactionArgument<number | bigint>,
        lendingMarket: RawTransactionArgument<string>,
        agg: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/** Calculates the amount of T that can be redeemed for shares_amount */
export function calculateWithdrawAmount(options: CalculateWithdrawAmountOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[2]}>`,
        'u64',
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultValueAggregate`
    ] satisfies string[];
    const parameterNames = ["vault", "sharesAmount", "lendingMarket", "agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'calculate_withdraw_amount',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface CalculateDepositAmountArguments {
    vault: RawTransactionArgument<string>;
    sharesAmount: RawTransactionArgument<number | bigint>;
    lendingMarket: RawTransactionArgument<string>;
    agg: RawTransactionArgument<string>;
}
export interface CalculateDepositAmountOptions {
    package?: string;
    arguments: CalculateDepositAmountArguments | [
        vault: RawTransactionArgument<string>,
        sharesAmount: RawTransactionArgument<number | bigint>,
        lendingMarket: RawTransactionArgument<string>,
        agg: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/** Calculates the amount of T that shares_amount will cost */
export function calculateDepositAmount(options: CalculateDepositAmountOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[2]}>`,
        'u64',
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultValueAggregate`
    ] satisfies string[];
    const parameterNames = ["vault", "sharesAmount", "lendingMarket", "agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'calculate_deposit_amount',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface CanDeployFundsArguments {
    agg: RawTransactionArgument<string>;
    usdAmount: RawTransactionArgument<string>;
}
export interface CanDeployFundsOptions {
    package?: string;
    arguments: CanDeployFundsArguments | [
        agg: RawTransactionArgument<string>,
        usdAmount: RawTransactionArgument<string>
    ];
}
/**
 * Check if vault can deploy a USD amount of liquid assets (and vault remains under
 * MAX_UTILIZATION_RATE_BPS)
 */
export function canDeployFunds(options: CanDeployFundsOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::VaultValueAggregate`,
        '0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::decimal::Decimal'
    ] satisfies string[];
    const parameterNames = ["agg", "usdAmount"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'can_deploy_funds',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
    });
}
export interface TotalSupplyArguments {
    vault: RawTransactionArgument<string>;
}
export interface TotalSupplyOptions {
    package?: string;
    arguments: TotalSupplyArguments | [
        vault: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string
    ];
}
/** Total supply of shares */
export function totalSupply(options: TotalSupplyOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`
    ] satisfies string[];
    const parameterNames = ["vault"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'total_supply',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface CalculateObligationValuesUsdArguments {
    obligationIds: RawTransactionArgument<string[]>;
    lendingMarket: RawTransactionArgument<string>;
}
export interface CalculateObligationValuesUsdOptions {
    package?: string;
    arguments: CalculateObligationValuesUsdArguments | [
        obligationIds: RawTransactionArgument<string[]>,
        lendingMarket: RawTransactionArgument<string>
    ];
    typeArguments: [
        string
    ];
}
/** Calculate total obligation value within one Lending Market in USD */
export function calculateObligationValuesUsd(options: CalculateObligationValuesUsdOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        'vector<0x0000000000000000000000000000000000000000000000000000000000000002::object::ID>',
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[0]}>`
    ] satisfies string[];
    const parameterNames = ["obligationIds", "lendingMarket"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'calculate_obligation_values_usd',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface ValidateManagerCapArguments {
    vault: RawTransactionArgument<string>;
    managerCap: RawTransactionArgument<string>;
}
export interface ValidateManagerCapOptions {
    package?: string;
    arguments: ValidateManagerCapArguments | [
        vault: RawTransactionArgument<string>,
        managerCap: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string
    ];
}
/** Validate that a manager cap belongs to a specific vault */
export function validateManagerCap(options: ValidateManagerCapOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`
    ] satisfies string[];
    const parameterNames = ["vault", "managerCap"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'validate_manager_cap',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface ClaimManagerFeesArguments {
    vault: RawTransactionArgument<string>;
    vaultManagerCap: RawTransactionArgument<string>;
    amount: RawTransactionArgument<number | bigint>;
}
export interface ClaimManagerFeesOptions {
    package?: string;
    arguments: ClaimManagerFeesArguments | [
        vault: RawTransactionArgument<string>,
        vaultManagerCap: RawTransactionArgument<string>,
        amount: RawTransactionArgument<number | bigint>
    ];
    typeArguments: [
        string,
        string
    ];
}
/** Claim accumulated manager fees */
export function claimManagerFees(options: ClaimManagerFeesOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        'u64'
    ] satisfies string[];
    const parameterNames = ["vault", "vaultManagerCap", "amount"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'claim_manager_fees',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface CreateObligationArguments {
    vault: RawTransactionArgument<string>;
    vaultManagerCap: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
}
export interface CreateObligationOptions {
    package?: string;
    arguments: CreateObligationArguments | [
        vault: RawTransactionArgument<string>,
        vaultManagerCap: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/** Create a new obligation for the vault */
export function createObligation(options: CreateObligationOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[2]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[1]}>`
    ] satisfies string[];
    const parameterNames = ["vault", "vaultManagerCap", "lendingMarket"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'create_obligation',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface GetObligationCapArguments {
    vault: RawTransactionArgument<string>;
    lendingMarketType: RawTransactionArgument<string>;
    index: RawTransactionArgument<number | bigint>;
}
export interface GetObligationCapOptions {
    package?: string;
    arguments: GetObligationCapArguments | [
        vault: RawTransactionArgument<string>,
        lendingMarketType: RawTransactionArgument<string>,
        index: RawTransactionArgument<number | bigint>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/** Get obligation cap at lending_market_type + index (read-only) */
export function getObligationCap(options: GetObligationCapOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[2]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000001::type_name::TypeName',
        'u64'
    ] satisfies string[];
    const parameterNames = ["vault", "lendingMarketType", "index"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'get_obligation_cap',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface GetObligationCapMutArguments {
    vaultManagerCap: RawTransactionArgument<string>;
    vault: RawTransactionArgument<string>;
    lendingMarketType: RawTransactionArgument<string>;
    index: RawTransactionArgument<number | bigint>;
}
export interface GetObligationCapMutOptions {
    package?: string;
    arguments: GetObligationCapMutArguments | [
        vaultManagerCap: RawTransactionArgument<string>,
        vault: RawTransactionArgument<string>,
        lendingMarketType: RawTransactionArgument<string>,
        index: RawTransactionArgument<number | bigint>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/** Get mutable obligation cap at lending_market_type + index (manager only) */
export function getObligationCapMut(options: GetObligationCapMutOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[2]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000001::type_name::TypeName',
        'u64'
    ] satisfies string[];
    const parameterNames = ["vaultManagerCap", "vault", "lendingMarketType", "index"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'get_obligation_cap_mut',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface ObligationCountArguments {
    vault: RawTransactionArgument<string>;
}
export interface ObligationCountOptions {
    package?: string;
    arguments: ObligationCountArguments | [
        vault: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string
    ];
}
/** Get number of obligations in vault */
export function obligationCount(options: ObligationCountOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`
    ] satisfies string[];
    const parameterNames = ["vault"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'obligation_count',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface DeployFundsArguments {
    vault: RawTransactionArgument<string>;
    vaultManagerCap: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
    obligationIndex: RawTransactionArgument<number | bigint>;
    amount: RawTransactionArgument<number | bigint>;
    agg: RawTransactionArgument<string>;
}
export interface DeployFundsOptions {
    package?: string;
    arguments: DeployFundsArguments | [
        vault: RawTransactionArgument<string>,
        vaultManagerCap: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>,
        obligationIndex: RawTransactionArgument<number | bigint>,
        amount: RawTransactionArgument<number | bigint>,
        agg: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/** Deploy funds from vault to lending market obligation */
export function deployFunds(options: DeployFundsOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[2]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[1]}>`,
        'u64',
        'u64',
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock',
        `${packageAddress}::vault::VaultValueAggregate`
    ] satisfies string[];
    const parameterNames = ["vault", "vaultManagerCap", "lendingMarket", "obligationIndex", "amount", "agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'deploy_funds',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface WithdrawDeployedFundsArguments {
    vault: RawTransactionArgument<string>;
    vaultManagerCap: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
    obligationIndex: RawTransactionArgument<number | bigint>;
    ctokenAmount: RawTransactionArgument<number | bigint>;
    agg: RawTransactionArgument<string>;
}
export interface WithdrawDeployedFundsOptions {
    package?: string;
    arguments: WithdrawDeployedFundsArguments | [
        vault: RawTransactionArgument<string>,
        vaultManagerCap: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>,
        obligationIndex: RawTransactionArgument<number | bigint>,
        ctokenAmount: RawTransactionArgument<number | bigint>,
        agg: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/** Withdraw funds from lending market obligation back to vault */
export function withdrawDeployedFunds(options: WithdrawDeployedFundsOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[2]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[1]}>`,
        'u64',
        'u64',
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock',
        `${packageAddress}::vault::VaultValueAggregate`
    ] satisfies string[];
    const parameterNames = ["vault", "vaultManagerCap", "lendingMarket", "obligationIndex", "ctokenAmount", "agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'withdraw_deployed_funds',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface CreateVaultValueAccumulatorArguments {
    vault: RawTransactionArgument<string>;
}
export interface CreateVaultValueAccumulatorOptions {
    package?: string;
    arguments: CreateVaultValueAccumulatorArguments | [
        vault: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string
    ];
}
export function createVaultValueAccumulator(options: CreateVaultValueAccumulatorOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`
    ] satisfies string[];
    const parameterNames = ["vault"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'create_vault_value_accumulator',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface ProcessLendingMarketArguments {
    acc: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
}
export interface ProcessLendingMarketOptions {
    package?: string;
    arguments: ProcessLendingMarketArguments | [
        acc: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>
    ];
    typeArguments: [
        string
    ];
}
export function processLendingMarket(options: ProcessLendingMarketOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::VaultValueAccumulator`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[0]}>`
    ] satisfies string[];
    const parameterNames = ["acc", "lendingMarket"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'process_lending_market',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface CreateVaultValueAggregateArguments {
    acc: RawTransactionArgument<string>;
    vault: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
}
export interface CreateVaultValueAggregateOptions {
    package?: string;
    arguments: CreateVaultValueAggregateArguments | [
        acc: RawTransactionArgument<string>,
        vault: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
export function createVaultValueAggregate(options: CreateVaultValueAggregateOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::VaultValueAccumulator`,
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[2]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[1]}>`
    ] satisfies string[];
    const parameterNames = ["acc", "vault", "lendingMarket"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'create_vault_value_aggregate',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}