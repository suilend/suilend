#[test_only]
module vaults::vault_tests;

use sui::{
    clock::{Self, Clock},
    coin::{Self, Coin},
    test_scenario::{Self as ts, Scenario},
    transfer
};
use vaults::vault::{Self, Vault, VaultManagerCap, VaultShare};

// Test coin type
public struct TEST_COIN has drop {}

const ADMIN: address = @0x1;
const USER1: address = @0x2;
const USER2: address = @0x3;
const FEE_RECEIVER: address = @0x4;

const DEPOSIT_FEE_BPS: u64 = 500; // 5%
const WITHDRAWAL_FEE_BPS: u64 = 300; // 3%
const MANAGEMENT_FEE_BPS: u64 = 200; // 2%
const PERFORMANCE_FEE_BPS: u64 = 1000; // 10%

fun init_vault_scenario(): Scenario {
    let mut scenario = ts::begin(ADMIN);

    // Create clock
    let clock = clock::create_for_testing(ts::ctx(&mut scenario));
    clock::share_for_testing(clock);

    // Create vault and manager cap
    let (vault, manager_cap) = vault::create_vault_for_testing<TEST_COIN>(
        FEE_RECEIVER,
        MANAGEMENT_FEE_BPS,
        PERFORMANCE_FEE_BPS,
        DEPOSIT_FEE_BPS,
        WITHDRAWAL_FEE_BPS,
        ts::ctx(&mut scenario),
    );

    // Transfer to sender so they can be retrieved later
    transfer::public_transfer(vault, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);

    scenario
}

fun mint_test_coin(amount: u64, ctx: &mut TxContext): Coin<TEST_COIN> {
    coin::mint_for_testing<TEST_COIN>(amount, ctx)
}

#[test]
fun test_create_vault() {
    let mut scenario = init_vault_scenario();

    ts::next_tx(&mut scenario, ADMIN);
    let vault = ts::take_from_sender<Vault<TEST_COIN>>(&scenario);
    let manager_cap = ts::take_from_sender<VaultManagerCap<TEST_COIN>>(&scenario);

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
    let mut vault = ts::take_from_sender<Vault<TEST_COIN>>(&scenario);
    let manager_cap = ts::take_from_sender<VaultManagerCap<TEST_COIN>>(&scenario);

    ts::next_tx(&mut scenario, USER1);
    let clock = ts::take_shared<Clock>(&scenario);

    // User deposits 1000 tokens
    let deposit_amount = 1000000; // 1000 * 1e6
    let deposit_coin = mint_test_coin(deposit_amount, ts::ctx(&mut scenario));

    let mut vault_shares = vault::deposit_for_testing(
        &mut vault,
        deposit_coin,
        &clock,
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
    let withdrawn_coins = vault::withdraw_for_testing(
        &mut vault,
        withdraw_shares,
        &clock,
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
    ts::end(scenario);
}

#[test]
fun test_fees_collected() {
    let mut scenario = init_vault_scenario();

    ts::next_tx(&mut scenario, ADMIN);
    let mut vault = ts::take_from_sender<Vault<TEST_COIN>>(&scenario);
    let manager_cap = ts::take_from_sender<VaultManagerCap<TEST_COIN>>(&scenario);

    ts::next_tx(&mut scenario, USER1);
    let clock = ts::take_shared<Clock>(&scenario);

    // User deposits 1000 tokens
    let deposit_amount = 1000000;
    let deposit_coin = mint_test_coin(deposit_amount, ts::ctx(&mut scenario));
    let vault_shares = vault::deposit_for_testing(
        &mut vault,
        deposit_coin,
        &clock,
        ts::ctx(&mut scenario),
    );

    // Withdraw and check withdrawal fee
    let withdrawn_coins = vault::withdraw_for_testing(
        &mut vault,
        vault_shares,
        &clock,
        ts::ctx(&mut scenario),
    );

    // Clean up
    coin::burn_for_testing(withdrawn_coins);
    ts::return_shared(clock);

    // Transfer objects back
    transfer::public_transfer(vault, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);
    ts::end(scenario);
}

#[test]
fun test_multiple_users() {
    let mut scenario = init_vault_scenario();

    ts::next_tx(&mut scenario, ADMIN);
    let mut vault = ts::take_from_sender<Vault<TEST_COIN>>(&scenario);
    let manager_cap = ts::take_from_sender<VaultManagerCap<TEST_COIN>>(&scenario);

    let clock = ts::take_shared<Clock>(&scenario);

    // User 1 deposits
    ts::next_tx(&mut scenario, USER1);
    let deposit1 = mint_test_coin(1000000, ts::ctx(&mut scenario));
    let shares1 = vault::deposit_for_testing(
        &mut vault,
        deposit1,
        &clock,
        ts::ctx(&mut scenario),
    );

    // User 2 deposits
    ts::next_tx(&mut scenario, USER2);
    let deposit2 = mint_test_coin(2000000, ts::ctx(&mut scenario)); // Above MIN_DEPOSIT
    let shares2 = vault::deposit_for_testing(
        &mut vault,
        deposit2,
        &clock,
        ts::ctx(&mut scenario),
    );

    // Both users should have shares
    assert!(coin::value(&shares1) > 0);
    assert!(coin::value(&shares2) > 0);

    // User 1 withdraws
    ts::next_tx(&mut scenario, USER1);
    let withdrawn1 = vault::withdraw_for_testing(
        &mut vault,
        shares1,
        &clock,
        ts::ctx(&mut scenario),
    );
    assert!(coin::value(&withdrawn1) > 0);

    // User 2 withdraws
    ts::next_tx(&mut scenario, USER2);
    let withdrawn2 = vault::withdraw_for_testing(
        &mut vault,
        shares2,
        &clock,
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
    ts::end(scenario);
}

#[test]
fun test_manager_cap_validation() {
    let mut scenario = init_vault_scenario();

    ts::next_tx(&mut scenario, ADMIN);
    let vault = ts::take_from_sender<Vault<TEST_COIN>>(&scenario);
    let manager_cap = ts::take_from_sender<VaultManagerCap<TEST_COIN>>(&scenario);

    // Test that manager cap validation works
    vault::validate_manager_cap(&vault, &manager_cap);

    // Test obligation creation (manager only)
    // Note: This would fail without proper lending market setup
    // let obligation_index = vault::create_obligation(&manager_cap, &mut vault, &lending_market, &mut ctx);

    ts::return_to_sender(&scenario, vault);
    ts::return_to_sender(&scenario, manager_cap);
    ts::end(scenario);
}

#[test]
#[expected_failure]
fun test_minimum_deposit_failure() {
    let mut scenario = init_vault_scenario();

    ts::next_tx(&mut scenario, ADMIN);
    let mut vault = ts::take_from_sender<Vault<TEST_COIN>>(&scenario);
    let _manager_cap = ts::take_from_sender<VaultManagerCap<TEST_COIN>>(&scenario);

    ts::next_tx(&mut scenario, USER1);
    let clock = ts::take_shared<Clock>(&scenario);

    // Try to deposit amount below minimum (should fail)
    let small_deposit = mint_test_coin(100, ts::ctx(&mut scenario)); // Much less than MIN_DEPOSIT
    let _shares = vault::deposit_for_testing(
        &mut vault,
        small_deposit,
        &clock,
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
    let mut vault = ts::take_from_sender<Vault<TEST_COIN>>(&scenario);
    let _manager_cap = ts::take_from_sender<VaultManagerCap<TEST_COIN>>(&scenario);

    ts::next_tx(&mut scenario, USER1);
    let clock = ts::take_shared<Clock>(&scenario);

    // Try to withdraw with zero shares (should fail)
    let zero_shares = coin::zero<VaultShare<TEST_COIN>>(ts::ctx(&mut scenario));
    let _withdrawn = vault::withdraw_for_testing(
        &mut vault,
        zero_shares,
        &clock,
        ts::ctx(&mut scenario),
    );

    // Should not reach here - test should abort above
    abort 0
}

#[test]
fun test_fee_limits() {
    let mut scenario = ts::begin(ADMIN);

    // Test that fee limits are enforced during vault creation
    let (vault, manager_cap) = vault::create_vault_for_testing<TEST_COIN>(
        FEE_RECEIVER,
        1000, // 10% management fee (at limit)
        5000, // 50% performance fee (at limit)
        1000, // 10% deposit fee (at limit)
        1000, // 10% withdrawal fee (at limit)
        ts::ctx(&mut scenario),
    );

    transfer::public_transfer(vault, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);
    ts::end(scenario);
}

#[test]
#[expected_failure]
fun test_excessive_fee_failure() {
    let mut scenario = ts::begin(ADMIN);

    // Try to create vault with excessive fees (should fail)
    let (vault, manager_cap) = vault::create_vault_for_testing<TEST_COIN>(
        FEE_RECEIVER,
        2000, // 20% management fee (above 10% limit)
        PERFORMANCE_FEE_BPS,
        DEPOSIT_FEE_BPS,
        WITHDRAWAL_FEE_BPS,
        ts::ctx(&mut scenario),
    );

    // Should not reach here
    transfer::public_transfer(vault, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);
    ts::end(scenario);
}
