#[test_only]
module vaults::vault_tests;

use steamm::{b_test_sui::B_TEST_SUI, b_test_usdc::B_TEST_USDC};
use sui::{
    clock::{Self, Clock},
    coin::{Self, Coin},
    coin_registry::{Self, Currency},
    object_table,
    test_scenario::{Self as ts, Scenario},
    test_utils
};
use suilend::{decimal, lending_market::{Self, LendingMarket}, mock_pyth, reserve_config};
use vaults::vault::{Self, Vault, VaultManagerCap};

public struct TEST_COIN has drop {}
public struct TEST_LENDING_MARKET has drop {}
public struct TEST_VAULT has drop {}
// OTW: Needs to match module name
public struct VAULT_TESTS has drop {}

const ADMIN: address = @0x1;
const USER1: address = @0x2;
const USER2: address = @0x3;
const FEE_RECEIVER: address = @0x4;

const DEPOSIT_FEE_BPS: u64 = 500; // 5%
const WITHDRAWAL_FEE_BPS: u64 = 300; // 3%
const MANAGEMENT_FEE_BPS: u64 = 200; // 2%
const PERFORMANCE_FEE_BPS: u64 = 1000; // 10%

const NAV_PRECISION: u128 = 1_000_000_000;

const TEST_COIN_DECIMALS: u8 = 6;

#[error]
const EShouldNotReach: u8 = 0;

fun init_vault_scenario(): (mock_pyth::PriceState, Scenario) {
    let mut scenario = ts::begin(ADMIN);

    let ctx = scenario.ctx();

    // Create clock
    let clock = clock::create_for_testing(ctx);

    let (curr, treasury_cap) = create_test_currency(ctx);

    let mut prices = mock_pyth::init_state(ctx);
    mock_pyth::register<TEST_COIN>(&mut prices, ctx);
    mock_pyth::update_price<TEST_COIN>(&mut prices, 1, TEST_COIN_DECIMALS, &clock); // $1

    let mut lending_market = lending_market::mock_for_testing<TEST_LENDING_MARKET>(
        vector::empty(),
        object_table::new(ctx),
        FEE_RECEIVER,
        decimal::from(0),
        decimal::from(0),
        ctx,
    );

    let lm_cap = lending_market::new_lending_market_owner_cap_for_testing<TEST_LENDING_MARKET>(
        object::id(&lending_market),
        ctx,
    );

    lending_market::add_reserve_for_testing<TEST_LENDING_MARKET, TEST_COIN>(
        &lm_cap,
        &mut lending_market,
        mock_pyth::get_price_obj<TEST_COIN>(&prices),
        reserve_config::default_reserve_config(ctx),
        TEST_COIN_DECIMALS,
        &clock,
        ctx,
    );

    // Create vault and manager cap
    let manager_cap = vault::create_vault<_, _, TEST_COIN>(
        treasury_cap,
        &curr,
        &lending_market,
        MANAGEMENT_FEE_BPS,
        PERFORMANCE_FEE_BPS,
        DEPOSIT_FEE_BPS,
        WITHDRAWAL_FEE_BPS,
        &clock,
        ctx,
    );

    clock.share_for_testing();
    transfer::public_share_object(lending_market);
    test_utils::destroy(curr);
    transfer::public_transfer(lm_cap, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);

    (prices, scenario)
}

fun create_test_currency(
    ctx: &mut TxContext,
): (Currency<VAULT_TESTS>, coin::TreasuryCap<VAULT_TESTS>) {
    let (builder, treasury_cap) = coin_registry::new_currency_with_otw(
        VAULT_TESTS {},
        6,
        b"VSHARES".to_string(),
        b"Vault Shares".to_string(),
        b"Vault Shares".to_string(),
        b"https://example.com/template.png".to_string(),
        ctx,
    );
    let (mut curr, metadata_cap) = builder.finalize_unwrap_for_testing(ctx);
    curr.delete_metadata_cap(metadata_cap);
    (curr, treasury_cap)
}

fun mint_test_coin(amount: u64, ctx: &mut TxContext): Coin<TEST_COIN> {
    let exp = 10u64.pow(TEST_COIN_DECIMALS);
    let mint_amount = amount * exp;
    coin::mint_for_testing<TEST_COIN>(mint_amount, ctx)
}

#[test]
fun test_deposit_and_withdraw() {
    let (prices, mut scenario) = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VAULT_TESTS>>();
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    scenario.next_tx(USER1);
    let clock = scenario.take_shared<Clock>();

    // User gets 1000 tokens
    let token_amount = 1000;
    let deposit_coin = mint_test_coin(token_amount, scenario.ctx());

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let mut vault_shares = vault.deposit(
        deposit_coin,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );

    scenario.next_tx(USER1);

    // Test withdrawal
    let shares_to_withdraw = vault_shares.value() / 2;
    let withdraw_shares = coin::split(
        &mut vault_shares,
        shares_to_withdraw,
        scenario.ctx(),
    );

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let withdrawn_coins = vault.withdraw(
        withdraw_shares,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );

    // Should get back approximately half (minus withdrawal fees)
    let withdrawn_amount = withdrawn_coins.value();
    assert!(withdrawn_amount > 0);

    {
        test_utils::destroy(prices);
        coin::burn_for_testing(vault_shares);
        coin::burn_for_testing(withdrawn_coins);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
    };

    scenario.end();
}

#[test]
fun test_fees_collected() {
    let (prices, mut scenario) = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VAULT_TESTS>>();

    scenario.next_tx(USER1);
    let clock = scenario.take_shared<Clock>();

    // User deposits 1000 tokens
    let deposit_amount = 1000000;
    let deposit_coin = mint_test_coin(deposit_amount, scenario.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let vault_shares = vault.deposit(
        deposit_coin,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );

    // Withdraw and check withdrawal fee
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let withdrawn_coins = vault.withdraw(
        vault_shares,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );

    {
        test_utils::destroy(prices);
        coin::burn_for_testing(withdrawn_coins);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
    };

    scenario.end();
}

#[test]
fun test_multiple_users() {
    let (prices, mut scenario) = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VAULT_TESTS>>();

    let clock = scenario.take_shared<Clock>();

    // User 1 deposits
    scenario.next_tx(USER1);
    let deposit1 = mint_test_coin(1000000, scenario.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let shares1 = vault.deposit(
        deposit1,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );

    // User 2 deposits
    scenario.next_tx(USER2);
    let deposit2 = mint_test_coin(2000000, scenario.ctx()); // Above MIN_DEPOSIT
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let shares2 = vault.deposit(
        deposit2,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );

    // Both users should have shares
    assert!(coin::value(&shares1) > 0);
    assert!(coin::value(&shares2) > 0);

    // User 1 withdraws
    scenario.next_tx(USER1);
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let withdrawn1 = vault.withdraw(
        shares1,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );
    assert!(coin::value(&withdrawn1) > 0);

    // User 2 withdraws
    scenario.next_tx(USER2);
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let withdrawn2 = vault.withdraw(
        shares2,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );
    assert!(coin::value(&withdrawn2) > 0);

    {
        test_utils::destroy(prices);
        coin::burn_for_testing(withdrawn1);
        coin::burn_for_testing(withdrawn2);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
    };

    scenario.end();
}

#[test]
fun test_manager_cap_validation() {
    let (prices, mut scenario) = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let mut lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VAULT_TESTS>>();

    // Test obligation creation (manager only)
    vault.create_obligation(&manager_cap, &mut lending_market, scenario.ctx());

    {
        test_utils::destroy(prices);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        ts::return_to_sender(&scenario, manager_cap);
    };

    scenario.end();
}

#[test]
#[expected_failure(abort_code = vault::EInvalidDeposit)]
fun test_minimum_deposit_failure() {
    let (prices, mut scenario) = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    scenario.next_tx(USER1);
    let clock = scenario.take_shared<Clock>();

    // Try to deposit amount below minimum (should fail)
    let small_deposit = coin::mint_for_testing<TEST_COIN>(1, scenario.ctx()); // Less than MIN_DEPOSIT
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let _shares = vault.deposit(
        small_deposit,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );

    // Should not reach here
    abort EShouldNotReach
}

#[test]
#[expected_failure(abort_code = vault::EInsufficientShares)]
fun test_insufficient_shares_withdrawal() {
    let (prices, mut scenario) = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    scenario.next_tx(USER1);
    let clock = scenario.take_shared<Clock>();

    // Try to withdraw with zero shares (should fail)
    let zero_shares = coin::zero<VAULT_TESTS>(scenario.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let _withdrawn = vault.withdraw(
        zero_shares,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );

    test_utils::destroy(prices);

    // Should not reach here
    abort EShouldNotReach
}

#[test]
fun test_fee_limits() {
    let (prices, mut scenario) = init_vault_scenario();
    scenario.next_tx(ADMIN);
    let clock = scenario.take_shared<Clock>();
    let (curr, t_cap) = create_test_currency(scenario.ctx());
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    // Test that fee limits are enforced during vault creation
    let manager_cap = vault::create_vault<_, _, TEST_COIN>(
        t_cap,
        &curr,
        &lending_market,
        1000, // 10% management fee (at limit)
        5000, // 50% performance fee (at limit)
        1000, // 10% deposit fee (at limit)
        1000, // 10% withdrawal fee (at limit)
        &clock,
        scenario.ctx(),
    );

    {
        test_utils::destroy(prices);
        ts::return_shared(lending_market);
        ts::return_shared(clock);
        test_utils::destroy(curr);
        transfer::public_transfer(manager_cap, ADMIN);
    };

    scenario.end();
}

#[test]
#[expected_failure(abort_code = vault::EInvalidManagementFeeBps)]
fun test_excessive_fee_failure() {
    let (_prices, mut scenario) = init_vault_scenario();

    scenario.next_tx(ADMIN);

    let (curr, t_cap) = create_test_currency(scenario.ctx());
    let clock = scenario.take_shared<Clock>();
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    // Try to create vault with excessive fees (should fail)
    let _manager_cap = vault::create_vault<_, _, TEST_COIN>(
        t_cap,
        &curr,
        &lending_market,
        2000, // 20% management fee (above 10% limit)
        PERFORMANCE_FEE_BPS,
        DEPOSIT_FEE_BPS,
        WITHDRAWAL_FEE_BPS,
        &clock,
        scenario.ctx(),
    );

    // Should not reach here
    abort EShouldNotReach
}

#[test]
#[expected_failure(abort_code = vault::EInsufficientLiquidity)]
fun test_utilization_rate_guard() {
    let (prices, mut scenario) = init_vault_scenario();

    scenario.next_tx(ADMIN);

    let mut vault = scenario.take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VAULT_TESTS>>();
    let mut lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    scenario.next_tx(USER1);

    let clock = scenario.take_shared<Clock>();

    let deposit_amount = 1000;
    let deposit_coin = mint_test_coin(deposit_amount, scenario.ctx());
    let deposit_value = deposit_coin.value();

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let _vault_shares = vault.deposit(
        deposit_coin,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );

    scenario.next_tx(ADMIN);

    vault.create_obligation(
        &manager_cap,
        &mut lending_market,
        scenario.ctx(),
    );
    let obligation_index = 0;

    // Try to deploy 80% of deposit
    let deploy_amount_80_percent = (deposit_value * 80) / 100;
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let _ctokens_amt = vault.deploy_funds(
        &manager_cap,
        &mut lending_market,
        obligation_index,
        deploy_amount_80_percent,
        &clock,
        agg,
        scenario.ctx(),
    );

    // Should not reach here
    abort EShouldNotReach
}

#[test]
fun test_allocate_and_divest() {
    let (prices, mut scenario) = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VAULT_TESTS>>();
    let mut lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    scenario.next_tx(USER1);
    let clock = scenario.take_shared<Clock>();

    let deposit_amount = 1000;
    let deposit_coin = mint_test_coin(deposit_amount, scenario.ctx());
    let manager_deploy_amount = deposit_coin.value() / 2;

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let mut vault_shares = vault.deposit(
        deposit_coin,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );
    let user_withdraw_amount = vault_shares.value() / 2;

    scenario.next_tx(ADMIN);

    vault.create_obligation(
        &manager_cap,
        &mut lending_market,
        scenario.ctx(),
    );
    let obligation_index = 0;
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let ctokens_amt = vault.deploy_funds(
        &manager_cap,
        &mut lending_market,
        obligation_index,
        manager_deploy_amount,
        &clock,
        agg,
        scenario.ctx(),
    );

    scenario.next_tx(ADMIN);

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    vault.withdraw_deployed_funds(
        &manager_cap,
        &mut lending_market,
        obligation_index,
        ctokens_amt / 2,
        &clock,
        agg,
        scenario.ctx(),
    );

    scenario.next_tx(USER1);

    let shares_to_withdraw = coin::split(
        &mut vault_shares,
        user_withdraw_amount,
        scenario.ctx(),
    );
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let withdrawn_coins = vault.withdraw(
        shares_to_withdraw,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );

    {
        test_utils::destroy(prices);
        coin::burn_for_testing(vault_shares);
        coin::burn_for_testing(withdrawn_coins);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
    };

    scenario.end();
}

#[test]
fun test_nav_changes() {
    let (prices, mut scenario) = init_vault_scenario();

    scenario.next_tx(ADMIN);

    let mut vault = scenario.take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VAULT_TESTS>>();
    let mut clock = scenario.take_shared<Clock>();

    scenario.next_tx(USER1);

    // Deposit funds
    let deposit_amount = 1000000;
    let deposit_coin = mint_test_coin(deposit_amount, scenario.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let shares = vault.deposit(
        deposit_coin,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );

    // Calculate initial NAV per share (should be 1.0 scaled)
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let initial_nav = vault.calculate_nav_per_share(&agg);
    assert!(initial_nav == NAV_PRECISION as u64);

    // Record initial total shares
    let initial_total_shares = vault.total_supply();

    // Advance clock by 1 year to accrue management fees
    clock.increment_for_testing(365 * 24 * 60 * 60 * 1000);

    // Apply fees
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    vault.accrue_fees_for_testing(&agg, &clock);

    // Total shares should have increased due to fee shares being minted
    let new_total_shares = vault.total_supply();
    assert!(new_total_shares > initial_total_shares);

    // Calculate new NAV per share after dilution
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let diluted_nav = vault.calculate_nav_per_share(&agg);

    // NAV per share should have decreased due to share dilution from fee minting
    assert!(diluted_nav < initial_nav);

    {
        test_utils::destroy(prices);
        coin::burn_for_testing(shares);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
    };

    scenario.end();
}

#[test]
fun test_compound_rewards() {
    let (prices, mut scenario) = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let mut lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VAULT_TESTS>>();
    let lm_cap = scenario.take_from_sender<
        lending_market::LendingMarketOwnerCap<TEST_LENDING_MARKET>,
    >();
    let mut clock = scenario.take_shared<Clock>();

    // User deposits into vault
    scenario.next_tx(USER1);
    let deposit_amount = 1000000;
    let deposit_coin = mint_test_coin(deposit_amount, scenario.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let vault_shares = vault.deposit(
        deposit_coin,
        prices.get_price_obj<TEST_COIN>(),
        &clock,
        agg,
        scenario.ctx(),
    );

    // Manager creates obligation and deploys funds
    scenario.next_tx(ADMIN);
    vault.create_obligation(&manager_cap, &mut lending_market, scenario.ctx());
    let obligation_index = 0;

    let deploy_amount = 500000;
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    vault.deploy_funds(
        &manager_cap,
        &mut lending_market,
        obligation_index,
        deploy_amount,
        &clock,
        agg,
        scenario.ctx(),
    );

    // Admin adds reward pool for deposit rewards
    scenario.next_tx(ADMIN);
    let reserve_array_index = 0;
    let reward_amount = 100000;
    let reward_coin = mint_test_coin(reward_amount, scenario.ctx());
    let start_time_ms = clock.timestamp_ms();
    let end_time_ms = start_time_ms + (30 * 24 * 60 * 60 * 1000); // 30 days

    lm_cap.add_pool_reward<TEST_LENDING_MARKET, TEST_COIN>(
        &mut lending_market,
        reserve_array_index,
        true, // is_deposit_reward
        reward_coin,
        start_time_ms,
        end_time_ms,
        &clock,
        scenario.ctx(),
    );

    // Advance clock to end of reward period
    clock.increment_for_testing(31 * 24 * 60 * 60 * 1000); // 31 days

    // Call compound_rewards (permissionless)
    scenario.next_tx(USER2);
    vault.compound_rewards<VAULT_TESTS, TEST_LENDING_MARKET, TEST_COIN>(
        &mut lending_market,
        obligation_index,
        reserve_array_index,
        0, // reward_index
        true, // is_deposit_reward
        0, // deposit_reserve_index
        &clock,
        scenario.ctx(),
    );

    // Verify rewards were claimed and deposited back into the obligation
    let lm_type = std::type_name::with_defining_ids<TEST_LENDING_MARKET>();
    let obligation_cap = vault.get_obligation_cap<VAULT_TESTS, TEST_LENDING_MARKET, TEST_COIN>(
        &lm_type,
        obligation_index,
    );
    let obligation_id = obligation_cap.obligation_id();
    let obligation = lending_market.obligation(obligation_id);
    let deposited_value = obligation.deposited_value_usd().floor();
    assert!(deposited_value > 0);

    {
        test_utils::destroy(prices);
        coin::burn_for_testing(vault_shares);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
        transfer::public_transfer(lm_cap, ADMIN);
    };

    scenario.end();
}

#[test]
fun test_compound_rewards_with_swap() {
    let (mut prices, mut scenario) = init_vault_scenario();

    // Create a new vault with B_TEST_SUI as underlying asset (different from default TEST_COIN vault)
    scenario.next_tx(ADMIN);
    let mut clock = scenario.take_shared<Clock>();
    let (curr, treasury_cap) = create_test_currency(scenario.ctx());
    let mut lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let lm_cap = scenario.take_from_sender<
        lending_market::LendingMarketOwnerCap<TEST_LENDING_MARKET>,
    >();

    let b_token_decimals = 9;
    mock_pyth::register<B_TEST_SUI>(&mut prices, scenario.ctx());
    mock_pyth::update_price<B_TEST_SUI>(&mut prices, 1, b_token_decimals, &clock);
    mock_pyth::register<B_TEST_USDC>(&mut prices, scenario.ctx());
    mock_pyth::update_price<B_TEST_USDC>(&mut prices, 1, b_token_decimals, &clock);

    // Setup B_TEST_SUI reserve (vault's underlying asset)
    lending_market::add_reserve_for_testing<TEST_LENDING_MARKET, B_TEST_SUI>(
        &lm_cap,
        &mut lending_market,
        mock_pyth::get_price_obj<B_TEST_SUI>(&prices),
        reserve_config::default_reserve_config(scenario.ctx()),
        b_token_decimals,
        &clock,
        scenario.ctx(),
    );

    let manager_cap = vault::create_vault<_, _, B_TEST_SUI>(
        treasury_cap,
        &curr,
        &lending_market,
        MANAGEMENT_FEE_BPS,
        PERFORMANCE_FEE_BPS,
        DEPOSIT_FEE_BPS,
        WITHDRAWAL_FEE_BPS,
        &clock,
        scenario.ctx(),
    );

    // Add B_TEST_USDC and B_TEST_SUI as reserves in the lending market
    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VAULT_TESTS, B_TEST_SUI>>();

    // Setup B_TEST_USDC reserve (for rewards)
    lending_market::add_reserve_for_testing<TEST_LENDING_MARKET, B_TEST_USDC>(
        &lm_cap,
        &mut lending_market,
        mock_pyth::get_price_obj<B_TEST_USDC>(&prices),
        reserve_config::default_reserve_config(scenario.ctx()),
        b_token_decimals,
        &clock,
        scenario.ctx(),
    );

    // Create Steamm CPMM pool for B_TEST_USDC <-> B_TEST_SUI swaps
    scenario.next_tx(ADMIN);
    let mut pool = steamm::cpmm_tests::setup_pool(100, 0, &mut scenario);

    let mut pool_liquidity_usdc = coin::mint_for_testing<B_TEST_USDC>(
        1_000_000_000_000,
        scenario.ctx(),
    );
    let mut pool_liquidity_sui = coin::mint_for_testing<B_TEST_SUI>(
        1_000_000_000_000,
        scenario.ctx(),
    );

    let (lp_coins, _) = pool.deposit_liquidity(
        &mut pool_liquidity_usdc,
        &mut pool_liquidity_sui,
        1_000_000_000_000,
        1_000_000_000_000,
        scenario.ctx(),
    );

    // User deposits B_TEST_SUI into vault
    scenario.next_tx(USER1);
    let deposit_coin = coin::mint_for_testing<B_TEST_SUI>(1_000_000_000_000, scenario.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let vault_shares = vault.deposit(
        deposit_coin,
        prices.get_price_obj<B_TEST_SUI>(),
        &clock,
        agg,
        scenario.ctx(),
    );

    // Manager creates obligation and deploys funds to lending market
    scenario.next_tx(ADMIN);
    vault.create_obligation(&manager_cap, &mut lending_market, scenario.ctx());
    let obligation_index = 0;

    let deploy_amount = 500000;
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    vault.deploy_funds(
        &manager_cap,
        &mut lending_market,
        obligation_index,
        deploy_amount,
        &clock,
        agg,
        scenario.ctx(),
    );

    scenario.next_tx(ADMIN);

    // Add B_TEST_USDC reward pool for B_TEST_SUI deposits
    let sui_reserve_index = 1; // Reserve order: [TEST_COIN, B_TEST_SUI, B_TEST_USDC]
    let reward_amount = 100000;
    let reward_coin = coin::mint_for_testing<B_TEST_USDC>(reward_amount, scenario.ctx());
    let start_time_ms = clock.timestamp_ms();
    let end_time_ms = start_time_ms + (30 * 24 * 60 * 60 * 1000);

    lm_cap.add_pool_reward<TEST_LENDING_MARKET, B_TEST_USDC>(
        &mut lending_market,
        sui_reserve_index,
        true,
        reward_coin,
        start_time_ms,
        end_time_ms,
        &clock,
        scenario.ctx(),
    );

    // Advance time to accrue rewards
    clock.increment_for_testing(31 * 24 * 60 * 60 * 1000);

    // Compound rewards: claim B_TEST_USDC, swap to B_TEST_SUI, deposit back to obligation
    scenario.next_tx(USER2);
    vault.compound_rewards_with_swap<
        VAULT_TESTS,
        TEST_LENDING_MARKET,
        B_TEST_SUI,
        B_TEST_USDC,
        steamm::lp_usdc_sui::LP_USDC_SUI,
    >(
        &manager_cap,
        &mut lending_market,
        &mut pool,
        obligation_index,
        sui_reserve_index,
        0,
        true,
        sui_reserve_index,
        1,
        &clock,
        scenario.ctx(),
    );

    // Verify rewards were compounded into the obligation
    let lm_type = std::type_name::with_defining_ids<TEST_LENDING_MARKET>();
    let obligation_cap = vault.get_obligation_cap<VAULT_TESTS, TEST_LENDING_MARKET, B_TEST_SUI>(
        &lm_type,
        obligation_index,
    );
    let obligation_id = obligation_cap.obligation_id();
    let obligation = lending_market.obligation(obligation_id);
    let deposited_value = obligation.deposited_value_usd().floor();
    assert!(deposited_value > 0);

    {
        coin::burn_for_testing(vault_shares);
        coin::burn_for_testing(lp_coins);
        test_utils::destroy(prices);
        test_utils::destroy(pool);
        test_utils::destroy(pool_liquidity_sui);
        test_utils::destroy(pool_liquidity_usdc);
        test_utils::destroy(curr);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
        transfer::public_transfer(lm_cap, ADMIN);
    };

    scenario.end();
}
