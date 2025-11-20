/**************************************************************
 * THIS FILE IS GENERATED AND SHOULD NOT BE MANUALLY MODIFIED *
 **************************************************************/
import { MoveStruct, normalizeMoveArguments, type RawTransactionArgument } from '../utils/index.js';
import { bcs } from '@mysten/sui/bcs';
import { type Transaction } from '@mysten/sui/transactions';
import * as bag from './deps/sui/bag.js';
import * as object from './deps/sui/object.js';
import * as version from './version.js';
import * as vec_map from './deps/sui/vec_map.js';
import * as type_name from './deps/std/type_name.js';
import * as coin from './deps/sui/coin.js';
import * as balance from './deps/sui/balance.js';
import * as accumulator from './accumulator.js';
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
        accumulator_cap: bcs.option(accumulator.AccumulatorCap),
        redemption_ratio_high_water_mark: decimal.Decimal,
        last_cranked_ms: bcs.u64()
    } });
export const VaultManagerCap = new MoveStruct({ name: `${$moduleName}::VaultManagerCap`, fields: {
        id: object.UID,
        vault_id: bcs.Address
    } });
export const ObligationCapKey = new MoveStruct({ name: `${$moduleName}::ObligationCapKey`, fields: {
        dummy_field: bcs.bool()
    } });
export const SwapTicket = new MoveStruct({ name: `${$moduleName}::SwapTicket`, fields: {
        min_amount_out: bcs.option(bcs.u64())
    } });
export const RewardWithdrawTicket = new MoveStruct({ name: `${$moduleName}::RewardWithdrawTicket`, fields: {
        reward: balance.Balance
    } });
export const VaultCreatedEvent = new MoveStruct({ name: `${$moduleName}::VaultCreatedEvent`, fields: {
        vault_id: bcs.Address,
        management_fee_bps: bcs.u64(),
        performance_fee_bps: bcs.u64(),
        deposit_fee_bps: bcs.u64(),
        withdrawal_fee_bps: bcs.u64()
    } });
export const VaultDepositEvent = new MoveStruct({ name: `${$moduleName}::VaultDepositEvent`, fields: {
        vault_id: bcs.Address,
        user: bcs.Address,
        deposit_amount: bcs.u64(),
        shares_minted: bcs.u64(),
        timestamp_ms: bcs.u64()
    } });
export const VaultWithdrawEvent = new MoveStruct({ name: `${$moduleName}::VaultWithdrawEvent`, fields: {
        vault_id: bcs.Address,
        user: bcs.Address,
        amount: bcs.u64(),
        shares_burned: bcs.u64(),
        timestamp_ms: bcs.u64()
    } });
export const ManagerAllocateEvent = new MoveStruct({ name: `${$moduleName}::ManagerAllocateEvent`, fields: {
        vault_id: bcs.Address,
        lending_market_id: bcs.Address,
        reserve_index: bcs.u64(),
        obligation_index: bcs.u64(),
        user: bcs.Address,
        deposit_amount: bcs.u64(),
        timestamp_ms: bcs.u64()
    } });
export const ManagerDivestEvent = new MoveStruct({ name: `${$moduleName}::ManagerDivestEvent`, fields: {
        vault_id: bcs.Address,
        lending_market_id: bcs.Address,
        reserve_index: bcs.u64(),
        obligation_index: bcs.u64(),
        user: bcs.Address,
        amount: bcs.u64(),
        timestamp_ms: bcs.u64()
    } });
export const FeesAccruedEvent = new MoveStruct({ name: `${$moduleName}::FeesAccruedEvent`, fields: {
        vault_id: bcs.Address,
        fee_type: bcs.string(),
        fee_shares: bcs.u64(),
        timestamp_ms: bcs.u64()
    } });
export const VaultStatsEvent = new MoveStruct({ name: `${$moduleName}::VaultStatsEvent`, fields: {
        vault_id: bcs.Address,
        base_token_type: type_name.TypeName,
        nav_per_share_usd: bcs.u64(),
        utilization_rate_bps: bcs.u64(),
        aum_usd: bcs.u64(),
        total_shares: bcs.u64(),
        lending_market_allocations: vec_map.VecMap(type_name.TypeName, accumulator.LendingMarketAllocation)
    } });
export const ObligationUnwindEvent = new MoveStruct({ name: `${$moduleName}::ObligationUnwindEvent`, fields: {
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
}
export interface CreateVaultOptions {
    package?: string;
    arguments: CreateVaultArguments | [
        vaultShareTreasuryCap: RawTransactionArgument<string>,
        vaultShareCurrency: RawTransactionArgument<string>,
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
/** Create new vault with specified fee structure */
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
    const parameterNames = ["vaultShareTreasuryCap", "vaultShareCurrency", "managementFeeBps", "performanceFeeBps", "depositFeeBps", "withdrawalFeeBps"];
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
    _: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
    obligationIndex: RawTransactionArgument<number | bigint>;
    deployAmount: RawTransactionArgument<number | bigint>;
    agg: RawTransactionArgument<string>;
}
export interface DeployFundsOptions {
    package?: string;
    arguments: DeployFundsArguments | [
        vault: RawTransactionArgument<string>,
        _: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>,
        obligationIndex: RawTransactionArgument<number | bigint>,
        deployAmount: RawTransactionArgument<number | bigint>,
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
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`
    ] satisfies string[];
    const parameterNames = ["vault", "_", "lendingMarket", "obligationIndex", "deployAmount", "agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'deploy_funds',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface DivestFundsArguments {
    vault: RawTransactionArgument<string>;
    _: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
    obligationIndex: RawTransactionArgument<number | bigint>;
    ctokenAmount: RawTransactionArgument<number | bigint>;
    agg: RawTransactionArgument<string>;
}
export interface DivestFundsOptions {
    package?: string;
    arguments: DivestFundsArguments | [
        vault: RawTransactionArgument<string>,
        _: RawTransactionArgument<string>,
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
export function divestFunds(options: DivestFundsOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        'u64',
        'u64',
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock',
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`
    ] satisfies string[];
    const parameterNames = ["vault", "_", "lendingMarket", "obligationIndex", "ctokenAmount", "agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'divest_funds',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface ClaimManagerFeesArguments {
    vault: RawTransactionArgument<string>;
    _: RawTransactionArgument<string>;
    amount: RawTransactionArgument<number | bigint>;
}
export interface ClaimManagerFeesOptions {
    package?: string;
    arguments: ClaimManagerFeesArguments | [
        vault: RawTransactionArgument<string>,
        _: RawTransactionArgument<string>,
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
    const parameterNames = ["vault", "_", "amount"];
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
    _: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
}
export interface CreateObligationOptions {
    package?: string;
    arguments: CreateObligationArguments | [
        vault: RawTransactionArgument<string>,
        _: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/**
 * Create a new obligation for the vault Create new obligation for vault in lending
 * market
 */
export function createObligation(options: CreateObligationOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`
    ] satisfies string[];
    const parameterNames = ["vault", "_", "lendingMarket"];
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
    _: RawTransactionArgument<string>;
    key: RawTransactionArgument<string>;
    value: RawTransactionArgument<string>;
}
export interface SetMetadataOptions {
    package?: string;
    arguments: SetMetadataArguments | [
        vault: RawTransactionArgument<string>,
        _: RawTransactionArgument<string>,
        key: RawTransactionArgument<string>,
        value: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string
    ];
}
/** Set or update vault metadata field */
export function setMetadata(options: SetMetadataOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000001::string::String',
        '0x0000000000000000000000000000000000000000000000000000000000000001::string::String'
    ] satisfies string[];
    const parameterNames = ["vault", "_", "key", "value"];
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
    _: RawTransactionArgument<string>;
    key: RawTransactionArgument<string>;
}
export interface UnsetMetadataOptions {
    package?: string;
    arguments: UnsetMetadataArguments | [
        vault: RawTransactionArgument<string>,
        _: RawTransactionArgument<string>,
        key: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string
    ];
}
/** Remove vault metadata field */
export function unsetMetadata(options: UnsetMetadataOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000001::string::String'
    ] satisfies string[];
    const parameterNames = ["vault", "_", "key"];
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
/** Deposit base token and receive vault shares */
export function deposit(options: DepositOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `0x0000000000000000000000000000000000000000000000000000000000000002::coin::Coin<${options.typeArguments[1]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock',
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`
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
/** Burn shares and withdraw base token */
export function withdraw(options: WithdrawOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `0x0000000000000000000000000000000000000000000000000000000000000002::coin::Coin<${options.typeArguments[0]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock',
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`
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
        `${packageAddress}::accumulator::VaultUnwindAccumulator<${options.typeArguments[0]}>`,
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
export interface WithdrawRewardArguments {
    vault: RawTransactionArgument<string>;
    lendingMarket: RawTransactionArgument<string>;
    obligationIndex: RawTransactionArgument<number | bigint>;
    rewardReserveIndex: RawTransactionArgument<number | bigint>;
    rewardIndex: RawTransactionArgument<number | bigint>;
    isDepositReward: RawTransactionArgument<boolean>;
}
export interface WithdrawRewardOptions {
    package?: string;
    arguments: WithdrawRewardArguments | [
        vault: RawTransactionArgument<string>,
        lendingMarket: RawTransactionArgument<string>,
        obligationIndex: RawTransactionArgument<number | bigint>,
        rewardReserveIndex: RawTransactionArgument<number | bigint>,
        rewardIndex: RawTransactionArgument<number | bigint>,
        isDepositReward: RawTransactionArgument<boolean>
    ];
    typeArguments: [
        string,
        string,
        string,
        string
    ];
}
/**
 * Withdraw a non-base token reward for swapping to base token and depositing to
 * vault Can be swapped permssionlessly if a reserve + oracle exists in MAIN_POOL
 * for T + RewardType (swap_reward_for_base_token_w_oracle) Or manager permissioned
 * if no oracle exists (swap_reward_for_base_token_unchecked)
 */
export function withdrawReward(options: WithdrawRewardOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<${options.typeArguments[2]}>`,
        'u64',
        'u64',
        'u64',
        'bool',
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
    ] satisfies string[];
    const parameterNames = ["vault", "lendingMarket", "obligationIndex", "rewardReserveIndex", "rewardIndex", "isDepositReward"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'withdraw_reward',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface SwapRewardForBaseTokenWOracleArguments {
    vault: RawTransactionArgument<string>;
    ticket: RawTransactionArgument<string>;
    mainLendingMarket: RawTransactionArgument<string>;
}
export interface SwapRewardForBaseTokenWOracleOptions {
    package?: string;
    arguments: SwapRewardForBaseTokenWOracleArguments | [
        vault: RawTransactionArgument<string>,
        ticket: RawTransactionArgument<string>,
        mainLendingMarket: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/** Create swap ticket with oracle-based minimum output */
export function swapRewardForBaseTokenWOracle(options: SwapRewardForBaseTokenWOracleOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::RewardWithdrawTicket<${options.typeArguments[0]}, ${options.typeArguments[1]}, ${options.typeArguments[2]}>`,
        '0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::suilend::MAIN_POOL>',
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
    ] satisfies string[];
    const parameterNames = ["vault", "ticket", "mainLendingMarket"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'swap_reward_for_base_token_w_oracle',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface SwapRewardForBaseTokenUncheckedArguments {
    _: RawTransactionArgument<string>;
    ticket: RawTransactionArgument<string>;
    mainLendingMarket: RawTransactionArgument<string>;
}
export interface SwapRewardForBaseTokenUncheckedOptions {
    package?: string;
    arguments: SwapRewardForBaseTokenUncheckedArguments | [
        _: RawTransactionArgument<string>,
        ticket: RawTransactionArgument<string>,
        mainLendingMarket: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string,
        string
    ];
}
/** Create swap ticket without oracle check (manager only) */
export function swapRewardForBaseTokenUnchecked(options: SwapRewardForBaseTokenUncheckedOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::VaultManagerCap<${options.typeArguments[0]}>`,
        `${packageAddress}::vault::RewardWithdrawTicket<${options.typeArguments[0]}, ${options.typeArguments[1]}, ${options.typeArguments[2]}>`,
        '0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::suilend::MAIN_POOL>'
    ] satisfies string[];
    const parameterNames = ["_", "ticket", "mainLendingMarket"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'swap_reward_for_base_token_unchecked',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
    });
}
export interface DepositSwappedRewardsArguments {
    vault: RawTransactionArgument<string>;
    swapCap: RawTransactionArgument<string>;
    deposit: RawTransactionArgument<string>;
}
export interface DepositSwappedRewardsOptions {
    package?: string;
    arguments: DepositSwappedRewardsArguments | [
        vault: RawTransactionArgument<string>,
        swapCap: RawTransactionArgument<string>,
        deposit: RawTransactionArgument<string>
    ];
    typeArguments: [
        string,
        string
    ];
}
/** Deposit swapped rewards to vault */
export function depositSwappedRewards(options: DepositSwappedRewardsOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::vault::SwapTicket<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `0x0000000000000000000000000000000000000000000000000000000000000002::coin::Coin<${options.typeArguments[1]}>`
    ] satisfies string[];
    const parameterNames = ["vault", "swapCap", "deposit"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'deposit_swapped_rewards',
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
/** Begin vault value accumulation */
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
export interface CreateVaultCrankAccumulatorArguments {
    vault: RawTransactionArgument<string>;
    mainLendingMarket: RawTransactionArgument<string>;
}
export interface CreateVaultCrankAccumulatorOptions {
    package?: string;
    arguments: CreateVaultCrankAccumulatorArguments | [
        vault: RawTransactionArgument<string>,
        mainLendingMarket: RawTransactionArgument<string>
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
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        '0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::lending_market::LendingMarket<0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::suilend::MAIN_POOL>',
        '0x0000000000000000000000000000000000000000000000000000000000000002::clock::Clock'
    ] satisfies string[];
    const parameterNames = ["vault", "mainLendingMarket"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'create_vault_crank_accumulator',
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
        `${packageAddress}::accumulator::VaultCrankAccumulator<${options.typeArguments[0]}>`,
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
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`,
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
        `${packageAddress}::accumulator::VaultUnwindAccumulator<${options.typeArguments[0]}>`,
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
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`,
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
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`,
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
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`,
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
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`,
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
    typeArguments: [
        string
    ];
}
/** Calculate vault utilization rate in basis points */
export function calculateUtilizationRate(options: CalculateUtilizationRateOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`
    ] satisfies string[];
    const parameterNames = ["agg"];
    return (tx: Transaction) => tx.moveCall({
        package: packageAddress,
        module: 'vault',
        function: 'calculate_utilization_rate',
        arguments: normalizeMoveArguments(options.arguments, argumentsTypes, parameterNames),
        typeArguments: options.typeArguments
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
/** Calculate net asset value per share */
export function calculateNavPerShare(options: CalculateNavPerShareOptions) {
    const packageAddress = options.package ?? '@local-pkg/vault';
    const argumentsTypes = [
        `${packageAddress}::vault::Vault<${options.typeArguments[0]}, ${options.typeArguments[1]}>`,
        `${packageAddress}::accumulator::VaultValueAggregate<${options.typeArguments[0]}>`
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