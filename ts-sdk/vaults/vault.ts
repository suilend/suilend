/**************************************************************
 * THIS FILE IS GENERATED AND SHOULD NOT BE MANUALLY MODIFIED *
 **************************************************************/
import { MoveStruct, MoveEnum, normalizeMoveArguments, type RawTransactionArgument } from '../utils/index.js';
import { bcs } from '@mysten/sui/bcs';
import { type Transaction } from '@mysten/sui/transactions';
import * as bag from './deps/sui/bag.js';
import * as object from './deps/sui/object.js';
import * as version from './version.js';
import * as vec_map from './deps/sui/vec_map.js';
import * as type_name from './deps/std/type_name.js';
import * as coin from './deps/sui/coin.js';
import * as balance from './deps/sui/balance.js';
import * as decimal from './deps/suilend/decimal.js';
const $moduleName = '@local-pkg/vault::vault';
export const ObligationData = new MoveStruct({ name: `${$moduleName}::ObligationData`, fields: {
        obligation_cap: bag.Bag,
        obligation_id: bcs.Address
    } });
export const Vault = new MoveStruct({ name: `${$moduleName}::Vault`, fields: {
        id: object.UID,
        version: version.Version,
        metadata: vec_map.VecMap(bcs.string(), bcs.string()),
        obligations: vec_map.VecMap(type_name.TypeName, bcs.vector(ObligationData)),
        treasury_cap: coin.TreasuryCap,
        deposit_asset: balance.Balance,
        manager_fees: balance.Balance,
        management_fee_bps: bcs.u64(),
        performance_fee_bps: bcs.u64(),
        deposit_fee_bps: bcs.u64(),
        withdrawal_fee_bps: bcs.u64(),
        slippage_bps: bcs.u64(),
        redemption_ratio_high_water_mark: decimal.Decimal,
        last_cranked_ms: bcs.u64()
    } });
export const VaultManagerCap = new MoveStruct({ name: `${$moduleName}::VaultManagerCap`, fields: {
        id: object.UID,
        vault_id: bcs.Address
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
        vault_id: bcs.Address,
        obligation_ids: vec_map.VecMap(type_name.TypeName, bcs.vector(bcs.Address)),
        lending_market_allocations: vec_map.VecMap(type_name.TypeName, LendingMarketAllocation)
    } });
export const VaultValueAggregate = new MoveStruct({ name: `${$moduleName}::VaultValueAggregate`, fields: {
        vault_id: bcs.Address,
        liquid_asset_value_usd: decimal.Decimal,
        total_obligation_value_usd: decimal.Decimal,
        lending_market_allocations: vec_map.VecMap(type_name.TypeName, LendingMarketAllocation)
    } });
export const VaultCrankAccumulator = new MoveStruct({ name: `${$moduleName}::VaultCrankAccumulator`, fields: {
        vault_id: bcs.Address,
        pending_lending_markets: vec_map.VecMap(type_name.TypeName, bcs.vector(bcs.Address)),
        lending_market_allocations: vec_map.VecMap(type_name.TypeName, LendingMarketAllocation)
    } });
export const UnwindTarget = new MoveStruct({ name: `${$moduleName}::UnwindTarget`, fields: {
        obligation_index: bcs.u64(),
        usd_to_recover: decimal.Decimal
    } });
export const VaultUnwindAccumulator = new MoveStruct({ name: `${$moduleName}::VaultUnwindAccumulator`, fields: {
        vault_id: bcs.Address,
        target_withdraw_amount: bcs.u64(),
        shares: balance.Balance,
        pending_unwinds: vec_map.VecMap(type_name.TypeName, bcs.vector(UnwindTarget)),
        agg: VaultValueAggregate
    } });
export const VaultCreated = new MoveStruct({ name: `${$moduleName}::VaultCreated`, fields: {
        vault_id: bcs.Address,
        management_fee_bps: bcs.u64(),
        performance_fee_bps: bcs.u64(),
        deposit_fee_bps: bcs.u64(),
        withdrawal_fee_bps: bcs.u64(),
        slippage_bps: bcs.u64()
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
        lending_market_id: bcs.Address,
        reserve_index: bcs.u64(),
        obligation_index: bcs.u64(),
        user: bcs.Address,
        deposit_amount: bcs.u64(),
        timestamp_ms: bcs.u64()
    } });
export const ManagerDivest = new MoveStruct({ name: `${$moduleName}::ManagerDivest`, fields: {
        vault_id: bcs.Address,
        lending_market_id: bcs.Address,
        reserve_index: bcs.u64(),
        obligation_index: bcs.u64(),
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
export const VaultStats = new MoveStruct({ name: `${$moduleName}::VaultStats`, fields: {
        vault_id: bcs.Address,
        base_token_type: type_name.TypeName,
        nav_per_share_usd: bcs.u64(),
        utilization_rate_bps: bcs.u64(),
        aum_usd: bcs.u64(),
        total_shares: bcs.u64(),
        lending_market_allocations: vec_map.VecMap(type_name.TypeName, LendingMarketAllocation)
    } });
export const ObligationUnwind = new MoveStruct({ name: `${$moduleName}::ObligationUnwind`, fields: {
        vault_id: bcs.Address,
        lending_market_id: bcs.Address,
        obligation_index: bcs.u64(),
        reserve_index: bcs.u64(),
        ctoken_amount: bcs.u64(),
        token_amount: bcs.u64(),
        timestamp_ms: bcs.u64()
    } });
export interface CreateVaultArguments {
    vaultShareTreasuryCap: RawTransactionArgument<string>;
    vaultShareCurrency: RawTransactionArgument<string>;
    managementFeeBps: RawTransactionArgument<number | bigint>;
    performanceFeeBps: RawTransactionArgument<number | bigint>;
    depositFeeBps: RawTransactionArgument<number | bigint>;
    withdrawalFeeBps: RawTransactionArgument<number | bigint>;
    slippageBps: RawTransactionArgument<number | bigint>;
}
export interface CreateVaultOptions {
    package?: string;
    arguments: CreateVaultArguments | [
        vaultShareTreasuryCap: RawTransactionArgument<string>,
        vaultShareCurrency: RawTransactionArgument<string>,
        managementFeeBps: RawTransactionArgument<number | bigint>,
        performanceFeeBps: RawTransactionArgument<number | bigint>,
        depositFeeBps: RawTransactionArgument<number | bigint>,
        withdrawalFeeBps: RawTransactionArgument<number | bigint>,
        slippageBps: RawTransactionArgument<number | bigint>
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
        'u64',
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
    ] satisfies string[];
    const parameterNames = ["vaultShareTreasuryCap", "vaultShareCurrency", "managementFeeBps", "performanceFeeBps", "depositFeeBps", "withdrawalFeeBps", "slippageBps"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'create_vault',
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
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
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
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
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
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`
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
export interface SetMetadataArguments {
    vault: RawTransactionArgument<string>;
    vaultManagerCap: RawTransactionArgument<string>;
    key: RawTransactionArgument<string>;
    value: RawTransactionArgument<string>;
}
export interface SetMetadataOptions {
    package?: string;
    arguments: SetMetadataArguments | [
        vault: RawTransactionArgument<string>,
        vaultManagerCap: RawTransactionArgument<string>,
        key: RawTransactionArgument<string>,
        value: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string
    ];
}
export function setMetadata(options: SetMetadataOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000001::string::String',
        '0x0000000000000000000000000000000000000000000000000000000000000001::string::String'
    ] satisfies string[];
    const parameterNames = ["vault", "vaultManagerCap", "key", "value"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'set_metadata',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface UnsetMetadataArguments {
    vault: RawTransactionArgument<string>;
    vaultManagerCap: RawTransactionArgument<string>;
    key: RawTransactionArgument<string>;
}
export interface UnsetMetadataOptions {
    package?: string;
    arguments: UnsetMetadataArguments | [
        vault: RawTransactionArgument<string>,
        vaultManagerCap: RawTransactionArgument<string>,
        key: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string
    ];
}
export function unsetMetadata(options: UnsetMetadataOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000001::string::String'
    ] satisfies string[];
    const parameterNames = ["vault", "vaultManagerCap", "key"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'unset_metadata',
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
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `0x0000000000000000000000000000000000000000000000000000000000000002::coin::Coin<${options.typeArguments[1]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
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
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `0x0000000000000000000000000000000000000000000000000000000000000002::coin::Coin<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
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
export interface WithdrawWithUnwindArguments {
    vault: RawTransactionArgument<string>;
    acc: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
}
export interface WithdrawWithUnwindOptions {
    package?: string;
    arguments: WithdrawWithUnwindArguments | [
        vault: RawTransactionArgument<string>,
        acc: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/**
 * For withdrawals requiring obligation unwinding:
 *
 * 1.  Call create_unwind_accumulator() to calculate unwind plan
 * 2.  Call process_unwinds_for_lending_market() for each LM
 * 3.  Call withdraw_with_unwind() All pending unwinds must be processed before
 *     calling
 */
export function withdrawWithUnwind(options: WithdrawWithUnwindOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultUnwindAccumulator<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
    ] satisfies string[];
    const parameterNames = ["vault", "acc", "lendingMarket"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'withdraw_with_unwind',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface CreateUnwindAccumulatorArguments {
    vault: RawTransactionArgument<string>;
    shares: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
    agg: RawTransactionArgument<string>;
}
export interface CreateUnwindAccumulatorOptions {
    package?: string;
    arguments: CreateUnwindAccumulatorArguments | [
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
 * Create an unwind accumulator for withdrawals that require unwinding obligations
 * Calculate which obligations need to be unwound to satisfy withdrawal liquidity
 * needs Each LendingMarket must be processed by
 * process_unwinds_for_lending_market() A VaultValueAggregate must first be created
 */
export function createUnwindAccumulator(options: CreateUnwindAccumulatorOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `0x0000000000000000000000000000000000000000000000000000000000000002::coin::Coin<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        `${packageAddress}::vault::VaultValueAggregate`,
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
    ] satisfies string[];
    const parameterNames = ["vault", "shares", "lendingMarket", "agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'create_unwind_accumulator',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface ProcessUnwindsForLendingMarketArguments {
    vault: RawTransactionArgument<string>;
    acc: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
}
export interface ProcessUnwindsForLendingMarketOptions {
    package?: string;
    arguments: ProcessUnwindsForLendingMarketArguments | [
        vault: RawTransactionArgument<string>,
        acc: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/**
 * Process unwinding for a specific lending market Withdraws and redeems ctokens
 * from obligations, adding funds to vault.deposit_asset Removes the lending market
 * from pending_unwinds
 */
export function processUnwindsForLendingMarket(options: ProcessUnwindsForLendingMarketOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultUnwindAccumulator<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
    ] satisfies string[];
    const parameterNames = ["vault", "acc", "lendingMarket"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'process_unwinds_for_lending_market',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface CompoundRewardsArguments {
    vault: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
    obligationIndex: RawTransactionArgument<number | bigint>;
    rewardReserveIndex: RawTransactionArgument<number | bigint>;
    rewardIndex: RawTransactionArgument<number | bigint>;
    isDepositReward: RawTransactionArgument<boolean>;
    depositReserveIndex: RawTransactionArgument<number | bigint>;
}
export interface CompoundRewardsOptions {
    package?: string;
    arguments: CompoundRewardsArguments | [
        vault: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>,
        obligationIndex: RawTransactionArgument<number | bigint>,
        rewardReserveIndex: RawTransactionArgument<number | bigint>,
        rewardIndex: RawTransactionArgument<number | bigint>,
        isDepositReward: RawTransactionArgument<boolean>,
        depositReserveIndex: RawTransactionArgument<number | bigint>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/** Compound rewards of same type as deposit asset Permissionless */
export function compoundRewards(options: CompoundRewardsOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        'u64',
        'u64',
        'u64',
        'bool',
        'u64',
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
    ] satisfies string[];
    const parameterNames = ["vault", "lendingMarket", "obligationIndex", "rewardReserveIndex", "rewardIndex", "isDepositReward", "depositReserveIndex"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'compound_rewards',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface CompoundRewardsWithSwapArguments {
    vault: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
    swapPool: RawTransactionArgument<string>;
    obligationIndex: RawTransactionArgument<number | bigint>;
    rewardReserveIndex: RawTransactionArgument<number | bigint>;
    rewardIndex: RawTransactionArgument<number | bigint>;
    isDepositReward: RawTransactionArgument<boolean>;
}
export interface CompoundRewardsWithSwapOptions {
    package?: string;
    arguments: CompoundRewardsWithSwapArguments | [
        vault: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>,
        swapPool: RawTransactionArgument<string>,
        obligationIndex: RawTransactionArgument<number | bigint>,
        rewardReserveIndex: RawTransactionArgument<number | bigint>,
        rewardIndex: RawTransactionArgument<number | bigint>,
        isDepositReward: RawTransactionArgument<boolean>
    ];
    typeArguments: [
        string,
        string,
        string,
        string,
        string
    ];
}
/**
 * Compound rewards of a different token type by swapping through a Steamm pool
 * This allows compounding rewards that don't match the vault's base asset type
 * min_amount_out is determined by vault.slippage_bps Permissionless
 */
export function compoundRewardsWithSwap(options: CompoundRewardsWithSwapOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        `0x4fb1cf45dffd6230305f1d269dd1816678cc8e3ba0b747a813a556921219f261::pool::Pool<${options.typeArguments[3]}, ${options.typeArguments[1]}, 0x4fb1cf45dffd6230305f1d269dd1816678cc8e3ba0b747a813a556921219f261::cpmm::CpQuoter, ${options.typeArguments[4]}>`,
        'u64',
        'u64',
        'u64',
        'bool',
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
    ] satisfies string[];
    const parameterNames = ["vault", "lendingMarket", "swapPool", "obligationIndex", "rewardReserveIndex", "rewardIndex", "isDepositReward"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'compound_rewards_with_swap',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface CreateVaultCrankAccumulatorArguments {
    vault: RawTransactionArgument<string>;
}
export interface CreateVaultCrankAccumulatorOptions {
    package?: string;
    arguments: CreateVaultCrankAccumulatorArguments | [
        vault: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string
    ];
}
/**
 * Create a vault crank accumulator for processing all lending markets Tracks all
 * LMs and obligations that need to be processed by
 * process_lending_market_for_crank()
 */
export function createVaultCrankAccumulator(options: CreateVaultCrankAccumulatorOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`
    ] satisfies string[];
    const parameterNames = ["vault"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'create_vault_crank_accumulator',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface ProcessLendingMarketForCrankArguments {
    acc: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
}
export interface ProcessLendingMarketForCrankOptions {
    package?: string;
    arguments: ProcessLendingMarketForCrankArguments | [
        acc: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>
    ];
    typeArguments: [
        string
    ];
}
/**
 * This verifies none of the obligations for this LendingMarket have outstanding
 * rewards to be compounded It also calculates the overall value of the positions
 * to be used to calculate manager fees in finalize_vault_crank() Removes the
 * LendingMarket from acc.pending_lending_markets
 */
export function processLendingMarketForCrank(options: ProcessLendingMarketForCrankOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::VaultCrankAccumulator`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[0]}>`
    ] satisfies string[];
    const parameterNames = ["acc", "lendingMarket"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'process_lending_market_for_crank',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface FinalizeVaultCrankArguments {
    vault: RawTransactionArgument<string>;
    acc: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
}
export interface FinalizeVaultCrankOptions {
    package?: string;
    arguments: FinalizeVaultCrankArguments | [
        vault: RawTransactionArgument<string>,
        acc: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/**
 * Ensures all LendingMarkets were processed, accrues fees, updates last_cranked_ms
 * timestamp
 */
export function finalizeVaultCrank(options: FinalizeVaultCrankOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultCrankAccumulator`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
    ] satisfies string[];
    const parameterNames = ["vault", "acc", "lendingMarket"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'finalize_vault_crank',
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
export interface ProcessLendingMarketForValueAccumulatorArguments {
    acc: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
}
export interface ProcessLendingMarketForValueAccumulatorOptions {
    package?: string;
    arguments: ProcessLendingMarketForValueAccumulatorArguments | [
        acc: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>
    ];
    typeArguments: [
        string
    ];
}
export function processLendingMarketForValueAccumulator(options: ProcessLendingMarketForValueAccumulatorOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::VaultValueAccumulator`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[0]}>`
    ] satisfies string[];
    const parameterNames = ["acc", "lendingMarket"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'process_lending_market_for_value_accumulator',
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
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
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
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        'u64',
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        `${packageAddress}::vault::VaultValueAggregate`,
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
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
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        'u64',
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        `${packageAddress}::vault::VaultValueAggregate`,
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
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
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        'u64',
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        `${packageAddress}::vault::VaultValueAggregate`,
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
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
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        'u64',
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        `${packageAddress}::vault::VaultValueAggregate`,
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
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
export interface CalculateUtilizationRateArguments {
    agg: RawTransactionArgument<string>;
}
export interface CalculateUtilizationRateOptions {
    package?: string;
    arguments: CalculateUtilizationRateArguments | [
        agg: RawTransactionArgument<string>
    ];
}
export function calculateUtilizationRate(options: CalculateUtilizationRateOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::VaultValueAggregate`
    ] satisfies string[];
    const parameterNames = ["agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'calculate_utilization_rate',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
    });
}
export interface CalculateNavPerShareArguments {
    vault: RawTransactionArgument<string>;
    agg: RawTransactionArgument<string>;
}
export interface CalculateNavPerShareOptions {
    package?: string;
    arguments: CalculateNavPerShareArguments | [
        vault: RawTransactionArgument<string>,
        agg: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string
    ];
}
export function calculateNavPerShare(options: CalculateNavPerShareOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultValueAggregate`
    ] satisfies string[];
    const parameterNames = ["vault", "agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'calculate_nav_per_share',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
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