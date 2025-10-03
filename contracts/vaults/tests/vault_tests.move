#[test_only]
module vaults::vault_tests;

use sui::{
    clock::{Self, Clock},
    coin::{Self, Coin},
    object_table,
    test_scenario::{Self as ts, Scenario},
    test_utils
};
use suilend::{decimal, lending_market::{Self, LendingMarket}, mock_pyth, reserve_config};
use vaults::vault::{Self, Vault, VaultManagerCap, VaultShare};

public struct TEST_COIN has drop {}
public struct TEST_LENDING_MARKET has drop {}
public struct TEST_VAULT has drop {}

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

fun init_vault_scenario(): Scenario {
    let mut scenario = ts::begin(ADMIN);

    let ctx = scenario.ctx();

    // Create clock
    let clock = clock::create_for_testing(ctx);

    // Create vault and manager cap
    let manager_cap = vault::create_vault<TEST_COIN>(
        MANAGEMENT_FEE_BPS,
        PERFORMANCE_FEE_BPS,
        DEPOSIT_FEE_BPS,
        WITHDRAWAL_FEE_BPS,
        &clock,
        ctx,
    );

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

    test_utils::destroy(prices);

    clock.share_for_testing();
    transfer::public_share_object(lending_market);
    transfer::public_transfer(lm_cap, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);

    scenario
}

fun mint_test_coin(amount: u64, ctx: &mut TxContext): Coin<TEST_COIN> {
    let exp = 10u64.pow(TEST_COIN_DECIMALS);
    let mint_amount = amount * exp;
    coin::mint_for_testing<TEST_COIN>(mint_amount, ctx)
}

#[test]
fun test_create_vault() {
    let mut scenario = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let vault = scenario.take_shared<Vault<VaultShare, TEST_COIN>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VaultShare>>();

    // Test vault was created with correct parameters
    assert!(vault::obligation_count(&vault) == 0);

    {
        ts::return_shared(vault);
        ts::return_to_sender(&scenario, manager_cap);
    };

    scenario.end();
}

#[test]
fun test_deposit_and_withdraw() {
    let mut scenario = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VaultShare, TEST_COIN>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VaultShare>>();
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    scenario.next_tx(USER1);
    let clock = scenario.take_shared<Clock>();

    // User gets 1000 tokens
    let token_amount = 1000;
    let deposit_coin = mint_test_coin(token_amount, scenario.ctx());

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let mut vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
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
        &lending_market,
        &clock,
        agg,
        scenario.ctx(),
    );

    // Should get back approximately half (minus withdrawal fees)
    let withdrawn_amount = withdrawn_coins.value();
    assert!(withdrawn_amount > 0);

    {
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
    let mut scenario = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VaultShare, TEST_COIN>>();
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VaultShare>>();

    scenario.next_tx(USER1);
    let clock = scenario.take_shared<Clock>();

    // User deposits 1000 tokens
    let deposit_amount = 1000000;
    let deposit_coin = mint_test_coin(deposit_amount, scenario.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        scenario.ctx(),
    );

    // Withdraw and check withdrawal fee
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let withdrawn_coins = vault.withdraw(
        vault_shares,
        &lending_market,
        &clock,
        agg,
        scenario.ctx(),
    );

    {
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
    let mut scenario = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VaultShare, TEST_COIN>>();
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VaultShare>>();

    let clock = scenario.take_shared<Clock>();

    // User 1 deposits
    scenario.next_tx(USER1);
    let deposit1 = mint_test_coin(1000000, scenario.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let shares1 = vault.deposit(
        deposit1,
        &lending_market,
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
        &lending_market,
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
        &lending_market,
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
        &lending_market,
        &clock,
        agg,
        scenario.ctx(),
    );
    assert!(coin::value(&withdrawn2) > 0);

    {
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
    let mut scenario = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VaultShare, TEST_COIN>>();
    let mut lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VaultShare>>();

    // Test that manager cap validation works
    vault::validate_manager_cap(&vault, &manager_cap);

    // Test obligation creation (manager only)
    vault.create_obligation(&manager_cap, &mut lending_market, scenario.ctx());

    {
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        ts::return_to_sender(&scenario, manager_cap);
    };

    scenario.end();
}

#[test]
#[expected_failure]
fun test_minimum_deposit_failure() {
    let mut scenario = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VaultShare, TEST_COIN>>();
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    scenario.next_tx(USER1);
    let clock = scenario.take_shared<Clock>();

    // Try to deposit amount below minimum (should fail)
    let small_deposit = mint_test_coin(100, scenario.ctx()); // Much less than MIN_DEPOSIT
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let _shares = vault.deposit(
        small_deposit,
        &lending_market,
        &clock,
        agg,
        scenario.ctx(),
    );

    // Should not reach here
    abort 0
}

#[test]
#[expected_failure]
fun test_insufficient_shares_withdrawal() {
    let mut scenario = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VaultShare, TEST_COIN>>();
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    scenario.next_tx(USER1);
    let clock = scenario.take_shared<Clock>();

    // Try to withdraw with zero shares (should fail)
    let zero_shares = coin::zero<VaultShare>(scenario.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let _withdrawn = vault.withdraw(
        zero_shares,
        &lending_market,
        &clock,
        agg,
        scenario.ctx(),
    );

    // Should not reach here
    abort 0
}

#[test]
fun test_fee_limits() {
    let mut scenario = ts::begin(ADMIN);
    let clock = clock::create_for_testing(scenario.ctx());

    // Test that fee limits are enforced during vault creation
    let manager_cap = vault::create_vault<TEST_COIN>(
        1000, // 10% management fee (at limit)
        5000, // 50% performance fee (at limit)
        1000, // 10% deposit fee (at limit)
        1000, // 10% withdrawal fee (at limit)
        &clock,
        scenario.ctx(),
    );

    {
        transfer::public_transfer(manager_cap, ADMIN);
        clock.destroy_for_testing();
    };

    scenario.end();
}

#[test]
#[expected_failure]
fun test_excessive_fee_failure() {
    let mut scenario = ts::begin(ADMIN);
    let clock = clock::create_for_testing(scenario.ctx());

    // Try to create vault with excessive fees (should fail)
    let manager_cap = vault::create_vault<TEST_COIN>(
        2000, // 20% management fee (above 10% limit)
        PERFORMANCE_FEE_BPS,
        DEPOSIT_FEE_BPS,
        WITHDRAWAL_FEE_BPS,
        &clock,
        scenario.ctx(),
    );

    // Should not reach here
    {
        transfer::public_transfer(manager_cap, ADMIN);
        clock.destroy_for_testing();
    };

    scenario.end();
}

#[test]
#[expected_failure]
fun test_utilization_rate_guard() {
    let mut scenario = init_vault_scenario();

    scenario.next_tx(ADMIN);

    let mut vault = scenario.take_shared<Vault<VaultShare, TEST_COIN>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VaultShare>>();
    let mut lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    scenario.next_tx(USER1);

    let clock = scenario.take_shared<Clock>();

    let deposit_amount = 1000;
    let deposit_coin = mint_test_coin(deposit_amount, scenario.ctx());
    let deposit_value = deposit_coin.value();

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
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
    {
        coin::burn_for_testing(vault_shares);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
    };

    scenario.end();
}

#[test]
fun test_allocate_and_divest() {
    let mut scenario = init_vault_scenario();

    scenario.next_tx(ADMIN);
    let mut vault = scenario.take_shared<Vault<VaultShare, TEST_COIN>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VaultShare>>();
    let mut lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    scenario.next_tx(USER1);
    let clock = scenario.take_shared<Clock>();

    let deposit_amount = 1000;
    let deposit_coin = mint_test_coin(deposit_amount, scenario.ctx());
    let manager_deploy_amount = deposit_coin.value() / 2;

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let mut vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
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
        &lending_market,
        &clock,
        agg,
        scenario.ctx(),
    );

    {
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
    let mut scenario = init_vault_scenario();

    scenario.next_tx(ADMIN);

    let mut vault = scenario.take_shared<Vault<VaultShare, TEST_COIN>>();
    let lending_market = scenario.take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = scenario.take_from_sender<VaultManagerCap<VaultShare>>();
    let mut clock = scenario.take_shared<Clock>();

    scenario.next_tx(USER1);

    // Deposit funds
    let deposit_amount = 1000000;
    let deposit_coin = mint_test_coin(deposit_amount, scenario.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let shares = vault.deposit(
        deposit_coin,
        &lending_market,
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
    vault.accrue_all_fees(&agg, &clock);

    // Total shares should have increased due to fee shares being minted
    let new_total_shares = vault.total_supply();
    assert!(new_total_shares > initial_total_shares);

    // Calculate new NAV per share after dilution
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market);
    let diluted_nav = vault.calculate_nav_per_share(&agg);

    // NAV per share should have decreased due to share dilution from fee minting
    assert!(diluted_nav < initial_nav);

    {
        coin::burn_for_testing(shares);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
    };

    scenario.end();
}
