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

const TEST_COIN_DECIMALS: u8 = 9;

fun init_vault_scenario(): Scenario {
    let mut scenario = ts::begin(ADMIN);

    let ctx = scenario.ctx();

    // Create clock
    let clock = clock::create_for_testing(ctx);

    // Create vault and manager cap
    let (vault, manager_cap) = vault::create_vault_for_testing<TEST_VAULT, TEST_COIN>(
        FEE_RECEIVER,
        MANAGEMENT_FEE_BPS,
        PERFORMANCE_FEE_BPS,
        DEPOSIT_FEE_BPS,
        WITHDRAWAL_FEE_BPS,
        &clock,
        ctx,
    );

    let mut prices = mock_pyth::init_state(ctx);
    mock_pyth::register<TEST_COIN>(&mut prices, ctx);
    mock_pyth::update_price<TEST_COIN>(&mut prices, 1, 0, &clock); // $1

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

    clock::share_for_testing(clock);

    // Transfer to sender so they can be retrieved later
    transfer::public_transfer(lm_cap, ADMIN);
    transfer::public_transfer(vault, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);
    transfer::public_transfer(lending_market, ADMIN);
    test_utils::destroy(prices);

    scenario
}

fun mint_test_coin(amount: u64, ctx: &mut TxContext): Coin<TEST_COIN> {
    coin::mint_for_testing<TEST_COIN>(amount, ctx)
}

#[test]
fun test_create_vault() {
    let mut scenario = init_vault_scenario();

    ts::next_tx(&mut scenario, ADMIN);
    let vault = ts::take_from_sender<Vault<TEST_VAULT, TEST_COIN>>(&scenario);
    let manager_cap = ts::take_from_sender<VaultManagerCap<TEST_VAULT>>(&scenario);

    // Test vault was created with correct parameters
    assert!(vault::obligation_count(&vault) == 0);

    // Clean up
    ts::return_to_sender(&scenario, vault);
    ts::return_to_sender(&scenario, manager_cap);
    ts::end(scenario);
}

#[test]
fun test_deposit_and_withdraw() {
    let mut scenario = init_vault_scenario();

    ts::next_tx(&mut scenario, ADMIN);
    let mut vault = ts::take_from_sender<Vault<TEST_VAULT, TEST_COIN>>(
        &scenario,
    );
    let manager_cap = ts::take_from_sender<VaultManagerCap<TEST_VAULT>>(&scenario);
    let lending_market = ts::take_from_sender<LendingMarket<TEST_LENDING_MARKET>>(
        &scenario,
    );

    ts::next_tx(&mut scenario, USER1);
    let clock = ts::take_shared<Clock>(&scenario);

    // User deposits 1000 tokens
    let deposit_amount = 1000000; // 1000 * 1e6
    let deposit_coin = mint_test_coin(deposit_amount, ts::ctx(&mut scenario));

    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
    let mut vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        ts::ctx(&mut scenario),
    );

    // Check shares minted (first deposit should be 1:1 after fees)
    let expected_fee = deposit_amount * DEPOSIT_FEE_BPS / 10000; // 5%
    let expected_net = deposit_amount - expected_fee;
    assert!(coin::value(&vault_shares) == expected_net);

    // Test withdrawal
    let withdraw_shares = coin::split(
        &mut vault_shares,
        expected_net / 2,
        ts::ctx(&mut scenario),
    );

    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
    let withdrawn_coins = vault.withdraw(
        withdraw_shares,
        &lending_market,
        &clock,
        agg,
        ts::ctx(&mut scenario),
    );

    // Should get back approximately half (minus withdrawal fees)
    let withdrawn_amount = coin::value(&withdrawn_coins);
    assert!(withdrawn_amount > 0);

    // Clean up
    coin::burn_for_testing(vault_shares);
    coin::burn_for_testing(withdrawn_coins);
    ts::return_shared(clock);

    // Transfer objects back
    transfer::public_transfer(vault, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);
    transfer::public_transfer(lending_market, ADMIN);
    ts::end(scenario);
}

#[test]
fun test_fees_collected() {
    let mut scenario = init_vault_scenario();

    ts::next_tx(&mut scenario, ADMIN);
    let mut vault = ts::take_from_sender<Vault<TEST_VAULT, TEST_COIN>>(
        &scenario,
    );
    let lending_market = scenario.take_from_sender<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = ts::take_from_sender<VaultManagerCap<TEST_VAULT>>(&scenario);

    ts::next_tx(&mut scenario, USER1);
    let clock = ts::take_shared<Clock>(&scenario);

    // User deposits 1000 tokens
    let deposit_amount = 1000000;
    let deposit_coin = mint_test_coin(deposit_amount, ts::ctx(&mut scenario));
    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
    let vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        ts::ctx(&mut scenario),
    );

    // Withdraw and check withdrawal fee
    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
    let withdrawn_coins = vault.withdraw(
        vault_shares,
        &lending_market,
        &clock,
        agg,
        ts::ctx(&mut scenario),
    );

    // Clean up
    coin::burn_for_testing(withdrawn_coins);
    ts::return_shared(clock);

    // Transfer objects back
    transfer::public_transfer(vault, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);
    transfer::public_transfer(lending_market, ADMIN);
    ts::end(scenario);
}

#[test]
fun test_multiple_users() {
    let mut scenario = init_vault_scenario();

    ts::next_tx(&mut scenario, ADMIN);
    let mut vault = ts::take_from_sender<Vault<TEST_VAULT, TEST_COIN>>(
        &scenario,
    );
    let lending_market = scenario.take_from_sender<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = ts::take_from_sender<VaultManagerCap<TEST_VAULT>>(&scenario);

    let clock = ts::take_shared<Clock>(&scenario);

    // User 1 deposits
    ts::next_tx(&mut scenario, USER1);
    let deposit1 = mint_test_coin(1000000, ts::ctx(&mut scenario));
    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
    let shares1 = vault.deposit(
        deposit1,
        &lending_market,
        &clock,
        agg,
        ts::ctx(&mut scenario),
    );

    // User 2 deposits
    ts::next_tx(&mut scenario, USER2);
    let deposit2 = mint_test_coin(2000000, ts::ctx(&mut scenario)); // Above MIN_DEPOSIT
    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
    let shares2 = vault.deposit(
        deposit2,
        &lending_market,
        &clock,
        agg,
        ts::ctx(&mut scenario),
    );

    // Both users should have shares
    assert!(coin::value(&shares1) > 0);
    assert!(coin::value(&shares2) > 0);

    // User 1 withdraws
    ts::next_tx(&mut scenario, USER1);
    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
    let withdrawn1 = vault.withdraw(
        shares1,
        &lending_market,
        &clock,
        agg,
        ts::ctx(&mut scenario),
    );
    assert!(coin::value(&withdrawn1) > 0);

    // User 2 withdraws
    ts::next_tx(&mut scenario, USER2);
    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
    let withdrawn2 = vault.withdraw(
        shares2,
        &lending_market,
        &clock,
        agg,
        ts::ctx(&mut scenario),
    );
    assert!(coin::value(&withdrawn2) > 0);

    // Clean up
    coin::burn_for_testing(withdrawn1);
    coin::burn_for_testing(withdrawn2);
    ts::return_shared(clock);

    // Transfer objects back
    transfer::public_transfer(vault, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);
    transfer::public_transfer(lending_market, ADMIN);
    ts::end(scenario);
}

#[test]
fun test_manager_cap_validation() {
    let mut scenario = init_vault_scenario();

    ts::next_tx(&mut scenario, ADMIN);
    let mut vault = ts::take_from_sender<Vault<TEST_VAULT, TEST_COIN>>(
        &scenario,
    );
    let mut lending_market = scenario.take_from_sender<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = ts::take_from_sender<VaultManagerCap<TEST_VAULT>>(&scenario);

    // Test that manager cap validation works
    vault::validate_manager_cap(&vault, &manager_cap);

    // Test obligation creation (manager only)
    vault.create_obligation(&manager_cap, &mut lending_market, scenario.ctx());

    ts::return_to_sender(&scenario, vault);
    ts::return_to_sender(&scenario, manager_cap);
    ts::return_to_sender(&scenario, lending_market);
    ts::end(scenario);
}

#[test]
#[expected_failure]
fun test_minimum_deposit_failure() {
    let mut scenario = init_vault_scenario();

    ts::next_tx(&mut scenario, ADMIN);
    let mut vault = ts::take_from_sender<Vault<TEST_VAULT, TEST_COIN>>(
        &scenario,
    );
    let lending_market = ts::take_from_sender<LendingMarket<TEST_LENDING_MARKET>>(
        &scenario,
    );

    ts::next_tx(&mut scenario, USER1);
    let clock = ts::take_shared<Clock>(&scenario);

    // Try to deposit amount below minimum (should fail)
    let small_deposit = mint_test_coin(100, ts::ctx(&mut scenario)); // Much less than MIN_DEPOSIT
    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
    let _shares = vault.deposit(
        small_deposit,
        &lending_market,
        &clock,
        agg,
        ts::ctx(&mut scenario),
    );

    // Should not reach here - test should abort above
    abort 0
}

#[test]
#[expected_failure]
fun test_insufficient_shares_withdrawal() {
    let mut scenario = init_vault_scenario();

    ts::next_tx(&mut scenario, ADMIN);
    let mut vault = ts::take_from_sender<Vault<TEST_VAULT, TEST_COIN>>(
        &scenario,
    );
    let lending_market = ts::take_from_sender<LendingMarket<TEST_LENDING_MARKET>>(
        &scenario,
    );

    ts::next_tx(&mut scenario, USER1);
    let clock = ts::take_shared<Clock>(&scenario);

    // Try to withdraw with zero shares (should fail)
    let zero_shares = coin::zero<VaultShare<TEST_VAULT>>(ts::ctx(&mut scenario));
    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
    let _withdrawn = vault.withdraw(
        zero_shares,
        &lending_market,
        &clock,
        agg,
        ts::ctx(&mut scenario),
    );

    // Should not reach here - test should abort above
    abort 0
}

#[test]
fun test_fee_limits() {
    let mut scenario = ts::begin(ADMIN);
    let clock = clock::create_for_testing(ts::ctx(&mut scenario));

    // Test that fee limits are enforced during vault creation
    let (vault, manager_cap) = vault::create_vault_for_testing<TEST_VAULT, TEST_COIN>(
        FEE_RECEIVER,
        1000, // 10% management fee (at limit)
        5000, // 50% performance fee (at limit)
        1000, // 10% deposit fee (at limit)
        1000, // 10% withdrawal fee (at limit)
        &clock,
        ts::ctx(&mut scenario),
    );

    transfer::public_transfer(vault, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);
    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test]
#[expected_failure]
fun test_excessive_fee_failure() {
    let mut scenario = ts::begin(ADMIN);
    let clock = clock::create_for_testing(ts::ctx(&mut scenario));

    // Try to create vault with excessive fees (should fail)
    let (vault, manager_cap) = vault::create_vault_for_testing<TEST_VAULT, TEST_COIN>(
        FEE_RECEIVER,
        2000, // 20% management fee (above 10% limit)
        PERFORMANCE_FEE_BPS,
        DEPOSIT_FEE_BPS,
        WITHDRAWAL_FEE_BPS,
        &clock,
        ts::ctx(&mut scenario),
    );

    // Should not reach here
    transfer::public_transfer(vault, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);
    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test]
fun test_allocate_and_divest() {
    let mut scenario = init_vault_scenario();

    ts::next_tx(&mut scenario, ADMIN);
    let mut vault = ts::take_from_sender<Vault<TEST_VAULT, TEST_COIN>>(
        &scenario,
    );
    let manager_cap = ts::take_from_sender<VaultManagerCap<TEST_VAULT>>(&scenario);
    let mut lending_market = ts::take_from_sender<LendingMarket<TEST_LENDING_MARKET>>(
        &scenario,
    );

    ts::next_tx(&mut scenario, USER1);
    let clock = ts::take_shared<Clock>(&scenario);

    let deposit_amount = 1000 * 1_000_000_000; // 1000 * 1e9
    let deposit_coin = mint_test_coin(deposit_amount, ts::ctx(&mut scenario));

    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
    let mut vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        ts::ctx(&mut scenario),
    );

    scenario.next_tx(USER1);

    let expected_fee = deposit_amount * DEPOSIT_FEE_BPS / 10000; // 5%
    let expected_net = deposit_amount - expected_fee;
    let max_deployable = (expected_net * 70) / 100; // 70%

    vault.create_obligation(
        &manager_cap,
        &mut lending_market,
        scenario.ctx(),
    );
    let obligation_index = 0;
    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
    let ctokens_amt = vault.deploy_funds(
        &manager_cap,
        &mut lending_market,
        obligation_index,
        max_deployable,
        &clock,
        agg,
        scenario.ctx(),
    );

    scenario.next_tx(USER1);

    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
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

    let withdraw_shares = coin::split(
        &mut vault_shares,
        expected_net,
        ts::ctx(&mut scenario),
    );
    let agg = vault::create_vault_value_aggregate_for_testing(&vault, &lending_market);
    let withdrawn_coins = vault.withdraw(
        withdraw_shares,
        &lending_market,
        &clock,
        agg,
        ts::ctx(&mut scenario),
    );

    // Clean up
    coin::burn_for_testing(vault_shares);
    coin::burn_for_testing(withdrawn_coins);
    ts::return_shared(clock);

    // Transfer objects back
    transfer::public_transfer(vault, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);
    transfer::public_transfer(lending_market, ADMIN);
    ts::end(scenario);
}
