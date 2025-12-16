#[test_only]
module vaults::vault_tests;

use steamm::{b_test_sui::B_TEST_SUI, b_test_usdc::B_TEST_USDC};
use sui::{
    clock::Clock,
    coin::{Self, Coin},
    coin_registry::{Self, Currency},
    object_table,
    test_scenario::{Self as ts, Scenario}
};
use sui_system::test_runner::{Self, TestRunner};
use suilend::{
    decimal,
    lending_market::{Self, LendingMarket},
    lending_market_tests::LENDING_MARKET as TEST_LENDING_MARKET,
    mock_pyth,
    reserve_config,
    suilend::MAIN_POOL,
    test_sui::TEST_SUI as TEST_COIN
};
use vaults::{utils, vault::{Self, Vault, VaultManagerCap}};

// OTW: Needs to match module name
public struct VAULT_TESTS has drop {}

const ADMIN: address = @0x1;
const USER1: address = @0x2;
const USER2: address = @0x3;

const BASIS_POINTS: u64 = 10_000; // 100%
const U64_MAX: u64 = 18_446_744_073_709_551_615;

const DEPOSIT_FEE_BPS: u64 = 500; // 5%
const WITHDRAWAL_FEE_BPS: u64 = 300; // 3%
const MANAGEMENT_FEE_BPS: u64 = 200; // 2%
const PERFORMANCE_FEE_BPS: u64 = 1000; // 10%

const NAV_PRECISION: u128 = 1_000_000_000;

const TEST_COIN_DECIMALS: u8 = 9;
const VAULT_SHARE_DECIMALS: u8 = 6;

// lending_market_tests::LENDING_MARKET layout: [TEST_USDC, TEST_SUI, SUI]
const TEST_SUI_RESERVE_INDEX: u64 = 1;

const TEST_COIN_MAIN_POOL_RESERVE_INDEX: u64 = 0;

#[error]
const EShouldNotReach: u8 = 0;

fun init_vault_scenario(): (mock_pyth::PriceState, TestRunner) {
    let mut runner = test_runner::build(test_runner::new());

    let (vault_share_currency, treasury_cap) = create_vault_shares(runner.ctx());

    let (clock, lm_cap, mut lending_market, mut prices, bag) = suilend::lending_market_tests::setup(
        sui::bag::new(runner.ctx()),
        runner.ctx(),
    ).destruct_state();

    prices.update_price<TEST_COIN>(1, 0, &clock); // $1
    lending_market.refresh_reserve_price(
        TEST_SUI_RESERVE_INDEX,
        &clock,
        prices.get_price_obj<TEST_COIN>(),
    );

    // Setup suilend::MAIN_POOL LendingMarket
    setup_main_pool(&clock, &prices, runner.scenario_mut());

    // Create vault and manager cap
    let manager_cap = vault::create_vault<_, TEST_COIN>(
        treasury_cap,
        &vault_share_currency,
        MANAGEMENT_FEE_BPS,
        PERFORMANCE_FEE_BPS,
        DEPOSIT_FEE_BPS,
        WITHDRAWAL_FEE_BPS,
        &clock,
        runner.ctx(),
    );

    // Create Steamm CPMM pool for B_TEST_USDC <-> B_TEST_SUI swaps
    let mut pool = steamm::cpmm_tests::setup_pool(100, 0, runner.scenario_mut());

    let mut pool_liquidity_usdc = coin::mint_for_testing<B_TEST_USDC>(
        1_000_000_000_000,
        runner.ctx(),
    );
    let mut pool_liquidity_sui = coin::mint_for_testing<B_TEST_SUI>(
        1_000_000_000_000,
        runner.ctx(),
    );

    let (lp_coins, _) = pool.deposit_liquidity(
        &mut pool_liquidity_usdc,
        &mut pool_liquidity_sui,
        1_000_000_000_000,
        1_000_000_000_000,
        runner.ctx(),
    );

    coin::burn_for_testing(lp_coins);
    test_runner::destroy(pool_liquidity_sui);
    test_runner::destroy(pool_liquidity_usdc);
    clock.share_for_testing();
    transfer::public_share_object(pool);
    transfer::public_share_object(lending_market);
    test_runner::destroy(vault_share_currency);
    test_runner::destroy(bag);
    transfer::public_transfer(lm_cap, ADMIN);
    transfer::public_transfer(manager_cap, ADMIN);

    (prices, runner)
}

fun setup_main_pool(clock: &Clock, prices: &mock_pyth::PriceState, scenario: &mut Scenario) {
    let mut lending_market = lending_market::mock_for_testing<suilend::suilend::MAIN_POOL>(
        vector::empty(),
        object_table::new(scenario.ctx()),
        ADMIN, // fee receiver
        decimal::from(0),
        decimal::from(0),
        scenario.ctx(),
    );

    let lm_cap = lending_market::new_lending_market_owner_cap_for_testing<
        suilend::suilend::MAIN_POOL,
    >(
        object::id(&lending_market),
        scenario.ctx(),
    );

    lending_market::add_reserve_for_testing<suilend::suilend::MAIN_POOL, TEST_COIN>(
        &lm_cap,
        &mut lending_market,
        prices.get_price_obj<TEST_COIN>(),
        reserve_config::default_reserve_config(scenario.ctx()),
        TEST_COIN_DECIMALS,
        clock,
        scenario.ctx(),
    );

    transfer::public_share_object(lending_market);
    transfer::public_transfer(lm_cap, ADMIN);
}

fun create_vault_shares(
    ctx: &mut TxContext,
): (Currency<VAULT_TESTS>, coin::TreasuryCap<VAULT_TESTS>) {
    let (builder, treasury_cap) = coin_registry::new_currency_with_otw(
        VAULT_TESTS {},
        VAULT_SHARE_DECIMALS,
        b"vSHARES".to_string(),
        b"Suilend Vault Shares".to_string(),
        b"Suilend Vault Shares".to_string(),
        b"".to_string(),
        ctx,
    );
    let (mut curr, metadata_cap) = builder.finalize_unwrap_for_testing(ctx);
    curr.delete_metadata_cap(metadata_cap);
    (curr, treasury_cap)
}

fun steamm_swap_usdc_to_sui(
    mut input_coin: Coin<B_TEST_USDC>,
    scenario: &mut Scenario,
): Coin<B_TEST_SUI> {
    let mut pool = scenario.take_shared<
        steamm::pool::Pool<
            B_TEST_USDC,
            B_TEST_SUI,
            steamm::cpmm::CpQuoter,
            steamm::lp_usdc_sui::LP_USDC_SUI,
        >,
    >();
    let mut output_coin = coin::zero<_>(scenario.ctx());
    let input_amount = input_coin.value();

    let _swap_result = steamm::cpmm::swap(
        &mut pool,
        &mut input_coin,
        &mut output_coin,
        true, // USDC -> SUI direction
        input_amount,
        0, // min_amount_out
        scenario.ctx(),
    );
    coin::destroy_zero(input_coin);
    ts::return_shared(pool);
    output_coin
}

fun mint_test_coin(amount: u64, ctx: &mut TxContext): Coin<TEST_COIN> {
    let exp = 10u64.pow(TEST_COIN_DECIMALS);
    let mint_amount = amount * exp;
    coin::mint_for_testing<TEST_COIN>(mint_amount, ctx)
}

#[test]
fun test_deposit_and_withdraw() {
    let (prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let lending_market = runner.scenario_mut().take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    runner.set_sender(USER1);
    let clock = runner.scenario_mut().take_shared<Clock>();

    // User gets 1000 tokens
    let token_amount = 1000;
    let deposit_coin = mint_test_coin(token_amount, runner.ctx());

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let mut vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    runner.set_sender(USER1);

    // Test withdrawal
    let shares_to_withdraw = vault_shares.value() / 2;
    let withdraw_shares = coin::split(
        &mut vault_shares,
        shares_to_withdraw,
        runner.ctx(),
    );

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let withdrawn_coins = vault.withdraw(
        withdraw_shares,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    // Should get back approximately half (minus withdrawal fees)
    let withdrawn_amount = withdrawn_coins.value();
    assert!(withdrawn_amount > 0);

    {
        test_runner::destroy(prices);
        coin::burn_for_testing(vault_shares);
        coin::burn_for_testing(withdrawn_coins);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
    };

    runner.finish();
}

/// Tests fee mechanisms: deposit fees, management fees, and performance fees
///
/// Test scenarios:
/// 1. Deposit fee: User deposits and X% goes to manager fees
/// 2. Management fee (stage 1): After 1 year, X% annual management fee is charged
/// 3. Management fee (stage 2): After base token price increases, only management fee charged (no performance fee)
/// 4. Performance fee: After generating alpha through rewards, both management and performance fees are charged
#[test]
fun test_fees_collected() {
    let (mut prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let mut lending_market = runner.scenario_mut().take_shared<LendingMarket<MAIN_POOL>>();
    let mut clock = runner.scenario_mut().take_shared<Clock>();

    // User deposits 1,000,000 tokens
    runner.set_sender(USER1);
    let deposit_amount = 1_000_000;
    let deposit_coin = mint_test_coin(deposit_amount, runner.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    let share_exp = 10u64.pow(VAULT_SHARE_DECIMALS);
    let initial_user_shares = vault_shares.value();
    let initial_total_supply = vault.get_vault_share_supply_for_testing();
    let initial_manager_fees = vault.get_manager_fees_for_testing();

    // Exact deposit fee calculation: 5% of deposit goes to fees
    // Total minted = deposit_amount * share_exp (after decimals)
    // Fee shares = 5% of total = deposit_amount * share_exp * 500 / BASIS_POINTS
    let expected_deposit_fee_shares = deposit_amount * share_exp * DEPOSIT_FEE_BPS / BASIS_POINTS;
    assert!(initial_manager_fees == expected_deposit_fee_shares);

    // User should get 95% of shares (after 5% deposit fee)
    let expected_user_shares =
        deposit_amount * share_exp * (BASIS_POINTS - DEPOSIT_FEE_BPS) / BASIS_POINTS;
    assert!(initial_user_shares == expected_user_shares);

    // Total supply = user shares + fee shares
    assert!(initial_total_supply == deposit_amount * share_exp);

    // Manager creates obligation and deploys funds
    runner.set_sender(ADMIN);
    runner.owned_tx!<VaultManagerCap<VAULT_TESTS>>(|manager_cap| {
        vault.create_obligation(&manager_cap, &mut lending_market, runner.ctx());
        runner.keep(manager_cap);
    });
    let obligation_index = 0;

    let deploy_amount = 500_000 * 10u64.pow(TEST_COIN_DECIMALS);
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    runner.owned_tx!<VaultManagerCap<VAULT_TESTS>>(|manager_cap| {
        vault.deploy_funds(
            &manager_cap,
            &mut lending_market,
            obligation_index,
            deploy_amount,
            &clock,
            agg,
            runner.ctx(),
        );
        runner.keep(manager_cap);
    });

    // === TEST 1: Management fees after 1 year ===

    // Advance time by exactly 1 year
    clock.increment_for_testing(365 * 24 * 60 * 60 * 1000);

    // Must refresh price after clock increment to avoid staleness
    prices.update_price<TEST_COIN>(1, 0, &clock);
    lending_market.refresh_reserve_price(
        TEST_COIN_MAIN_POOL_RESERVE_INDEX,
        &clock,
        prices.get_price_obj<TEST_COIN>(),
    );

    let total_supply_before_crank = vault.get_vault_share_supply_for_testing();

    // Crank to apply management fees (no performance fee yet since ratio hasn't increased)
    runner.set_sender(ADMIN);
    let mut crank_acc = vault.create_vault_crank_accumulator(&clock);
    crank_acc.process_lending_market_for_crank(&lending_market, &lending_market);
    vault.finalize_vault_crank(crank_acc, &lending_market, &clock);

    let total_supply_after_mgmt = vault.get_vault_share_supply_for_testing();
    let manager_fees_after_mgmt = vault.get_manager_fees_for_testing();

    let mgmt_fee_shares_round1 = total_supply_after_mgmt - total_supply_before_crank;

    // Verify management fees are non-zero
    assert!(mgmt_fee_shares_round1 > 0);

    // Verify total supply increased by exactly the management fee amount
    assert!(total_supply_after_mgmt == total_supply_before_crank + mgmt_fee_shares_round1);

    // Manager fees should equal: initial deposit fees + round 1 management fees
    assert!(manager_fees_after_mgmt == expected_deposit_fee_shares + mgmt_fee_shares_round1);

    // === TEST 2: Price doubles but vault holds same amount (NO performance fee) ===
    runner.set_sender(ADMIN);

    // Advance time by another year
    clock.increment_for_testing(365 * 24 * 60 * 60 * 1000);

    // Refresh price at $2 (doubled from $1)
    prices.update_price<TEST_COIN>(2, 0, &clock);
    lending_market.refresh_reserve_price(
        TEST_COIN_MAIN_POOL_RESERVE_INDEX,
        &clock,
        prices.get_price_obj<TEST_COIN>(),
    );

    let supply_before_price_double_crank = vault.get_vault_share_supply_for_testing();
    let manager_fees_before_round2 = vault.get_manager_fees_for_testing();

    // Crank again - should only get management fees, NOT performance fees
    let mut crank_acc = vault.create_vault_crank_accumulator(&clock);
    crank_acc.process_lending_market_for_crank(&lending_market, &lending_market);
    vault.finalize_vault_crank(crank_acc, &lending_market, &clock);

    let supply_after_price_double_crank = vault.get_vault_share_supply_for_testing();
    let manager_fees_after_round2 = vault.get_manager_fees_for_testing();
    let mgmt_fee_shares_round2 = supply_after_price_double_crank - supply_before_price_double_crank;

    // Verify management fees are non-zero after another year
    assert!(mgmt_fee_shares_round2 > 0);

    // Calculate expected fee rate as percentage of supply
    let fee_rate_bps = (mgmt_fee_shares_round2 * BASIS_POINTS) / supply_before_price_double_crank;

    // Fee rate should be approximately 2% (200 bps) for 1 year
    assert!(fee_rate_bps == 204);

    // Verify total supply increased correctly
    assert!(
        supply_after_price_double_crank == supply_before_price_double_crank + mgmt_fee_shares_round2,
    );

    // Manager fees delta should equal the management fee minted
    let manager_fees_delta_round2 = manager_fees_after_round2 - manager_fees_before_round2;
    assert!(manager_fees_delta_round2 == mgmt_fee_shares_round2);

    // === TEST 3: Manager generates actual alpha through reward compounding ===
    runner.set_sender(ADMIN);

    // Set up rewards pool to simulate real yield generation
    let reward_amount = 150_000; // 150k tokens in rewards
    let reward_coin = mint_test_coin(reward_amount, runner.ctx());
    let start_time_ms = clock.timestamp_ms();
    let end_time_ms = start_time_ms + (30 * 24 * 60 * 60 * 1000); // 30 days

    let lm_cap = runner
        .scenario_mut()
        .take_from_sender<lending_market::LendingMarketOwnerCap<MAIN_POOL>>();

    lm_cap.add_pool_reward<MAIN_POOL, TEST_COIN>(
        &mut lending_market,
        TEST_COIN_MAIN_POOL_RESERVE_INDEX,
        true, // is_deposit_reward
        reward_coin,
        start_time_ms,
        end_time_ms,
        &clock,
        runner.ctx(),
    );

    // Get vault value before rewards
    let agg_before_rewards = vault.create_vault_value_aggregate_for_testing(
        &lending_market,
        &clock,
    );
    let liquid_before = agg_before_rewards.liquid_asset_value_usd();
    let obligation_before = agg_before_rewards.total_obligation_value_usd();
    let total_value_before_rewards = liquid_before.add(obligation_before);
    vault::destroy_vault_value_aggregate_for_testing(agg_before_rewards, &mut vault);

    // Advance time to accrue rewards
    clock.increment_for_testing(31 * 24 * 60 * 60 * 1000); // 31 days

    // Refresh prices after time advancement
    prices.update_price<TEST_COIN>(2, 0, &clock);
    lending_market.refresh_reserve_price(
        TEST_COIN_MAIN_POOL_RESERVE_INDEX,
        &clock,
        prices.get_price_obj<TEST_COIN>(),
    );

    // Compound the rewards
    runner.set_sender(USER2);
    vault.compound_rewards<VAULT_TESTS, TEST_COIN, MAIN_POOL>(
        &mut lending_market,
        obligation_index,
        TEST_COIN_MAIN_POOL_RESERVE_INDEX,
        0, // reward_index
        true, // is_deposit_reward
        &clock,
        runner.ctx(),
    );

    // Get vault value after rewards to verify alpha was generated
    let agg_after_rewards = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let liquid_after = agg_after_rewards.liquid_asset_value_usd();
    let obligation_after = agg_after_rewards.total_obligation_value_usd();
    let total_value_after_rewards = liquid_after.add(obligation_after);
    vault::destroy_vault_value_aggregate_for_testing(agg_after_rewards, &mut vault);

    // Vault value should have increased by rewards amount (in USD at $2 per token)
    // 150k tokens * $2 = $300k increase
    let expected_value_increase = decimal::from(reward_amount * 2); // $2 per token
    let actual_value_increase = total_value_after_rewards.sub(total_value_before_rewards);

    assert!(actual_value_increase.eq(expected_value_increase.mul(decimal::from_bps(BASIS_POINTS))));

    // Advance another year for management + performance fees
    clock.increment_for_testing(365 * 24 * 60 * 60 * 1000);

    // Refresh price after clock increment (keep at $2)
    prices.update_price<TEST_COIN>(2, 0, &clock);
    lending_market.refresh_reserve_price(
        TEST_COIN_MAIN_POOL_RESERVE_INDEX,
        &clock,
        prices.get_price_obj<TEST_COIN>(),
    );

    let supply_before_perf_fee = vault.get_vault_share_supply_for_testing();
    let manager_fees_before_perf = vault.get_manager_fees_for_testing();

    // Crank - now should get BOTH management and performance fees
    runner.set_sender(ADMIN);
    let mut crank_acc = vault.create_vault_crank_accumulator(&clock);
    crank_acc.process_lending_market_for_crank(&lending_market, &lending_market);
    vault.finalize_vault_crank(crank_acc, &lending_market, &clock);

    let supply_after_perf_fee = vault.get_vault_share_supply_for_testing();
    let manager_fees_after_perf = vault.get_manager_fees_for_testing();

    let total_fee_shares_round3 = supply_after_perf_fee - supply_before_perf_fee;

    // Verify total fees are non-zero
    assert!(total_fee_shares_round3 > 0);

    // Calculate baseline management fee (no alpha generation)
    let baseline_mgmt_fee_round3 =
        supply_before_perf_fee * MANAGEMENT_FEE_BPS / (BASIS_POINTS - MANAGEMENT_FEE_BPS);

    // Total fees should include BOTH management and performance fees
    // Since the vault generated alpha through rewards, total should exceed baseline management fee
    assert!(total_fee_shares_round3 > baseline_mgmt_fee_round3);

    // Calculate performance fee component (excess over baseline management)
    let perf_fee_shares = total_fee_shares_round3 - baseline_mgmt_fee_round3;

    // Performance fee should be positive (alpha generated through rewards)
    assert!(perf_fee_shares > 0);

    // Calculate performance fee as percentage of baseline management fee
    let perf_fee_ratio_pct = (perf_fee_shares * 100) / baseline_mgmt_fee_round3;

    assert!(perf_fee_ratio_pct == 8);

    // Verify total supply increased correctly
    assert!(supply_after_perf_fee == supply_before_perf_fee + total_fee_shares_round3);

    // Manager fees should have increased by the sum of management + performance fees
    let manager_fees_delta_round3 = manager_fees_after_perf - manager_fees_before_perf;
    assert!(manager_fees_delta_round3 == total_fee_shares_round3);

    {
        test_runner::destroy(prices);
        coin::burn_for_testing(vault_shares);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(lm_cap, ADMIN);
    };

    runner.finish();
}

#[test]
fun test_multiple_users() {
    let (prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let lending_market = runner.scenario_mut().take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    let clock = runner.scenario_mut().take_shared<Clock>();

    // User 1 deposits
    runner.set_sender(USER1);
    let deposit1 = mint_test_coin(1000000, runner.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let shares1 = vault.deposit(
        deposit1,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    // User 2 deposits
    runner.set_sender(USER2);
    let deposit2 = mint_test_coin(2000000, runner.ctx()); // Above MIN_DEPOSIT
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let shares2 = vault.deposit(
        deposit2,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    // Both users should have shares
    assert!(coin::value(&shares1) > 0);
    assert!(coin::value(&shares2) > 0);

    // User 1 withdraws
    runner.set_sender(USER1);
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let withdrawn1 = vault.withdraw(
        shares1,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );
    assert!(coin::value(&withdrawn1) > 0);

    // User 2 withdraws
    runner.set_sender(USER2);
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let withdrawn2 = vault.withdraw(
        shares2,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );
    assert!(coin::value(&withdrawn2) > 0);

    {
        test_runner::destroy(prices);
        coin::burn_for_testing(withdrawn1);
        coin::burn_for_testing(withdrawn2);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
    };

    runner.finish();
}

#[test]
fun test_manager_cap_validation() {
    let (prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let mut lending_market = runner
        .scenario_mut()
        .take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = runner.scenario_mut().take_from_sender<VaultManagerCap<VAULT_TESTS>>();

    // Test obligation creation (manager only)
    vault.create_obligation(&manager_cap, &mut lending_market, runner.ctx());

    {
        test_runner::destroy(prices);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        test_runner::destroy(manager_cap);
    };

    runner.finish();
}

#[test]
#[expected_failure(abort_code = vault::EInvalidDeposit)]
fun test_minimum_deposit_failure() {
    let (_prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let lending_market = runner.scenario_mut().take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    runner.set_sender(USER1);
    let clock = runner.scenario_mut().take_shared<Clock>();

    // Try to deposit amount below minimum (should fail)
    let small_deposit = coin::mint_for_testing<TEST_COIN>(1, runner.ctx()); // Less than MIN_DEPOSIT
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let _shares = vault.deposit(
        small_deposit,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    abort EShouldNotReach
}

#[test]
#[expected_failure(abort_code = vault::EInsufficientShares)]
fun test_insufficient_shares_withdrawal() {
    let (_prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let lending_market = runner.scenario_mut().take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    runner.set_sender(USER1);
    let clock = runner.scenario_mut().take_shared<Clock>();

    // Try to withdraw with zero shares (should fail)
    let zero_shares = coin::zero<VAULT_TESTS>(runner.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let _withdrawn = vault.withdraw(
        zero_shares,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    abort EShouldNotReach
}

#[test]
fun test_fee_limits() {
    let (prices, mut runner) = init_vault_scenario();
    runner.set_sender(ADMIN);
    let clock = runner.scenario_mut().take_shared<Clock>();
    let (curr, t_cap) = create_vault_shares(runner.ctx());

    // Test that fee limits are enforced during vault creation
    let manager_cap = vault::create_vault<_, TEST_COIN>(
        t_cap,
        &curr,
        500, // 5% management fee (at limit)
        5000, // 50% performance fee (at limit)
        500, // 5% deposit fee (at limit)
        500, // 5% withdrawal fee (at limit)
        &clock,
        runner.ctx(),
    );

    {
        test_runner::destroy(prices);
        ts::return_shared(clock);
        test_runner::destroy(curr);
        transfer::public_transfer(manager_cap, ADMIN);
    };

    runner.finish();
}

#[test]
#[expected_failure(abort_code = vault::EFeeLimitExceeded)]
fun test_excessive_fee_failure() {
    let (_prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);

    let (curr, t_cap) = create_vault_shares(runner.ctx());
    let clock = runner.scenario_mut().take_shared<Clock>();

    // Try to create vault with excessive fees (should fail)
    let _manager_cap = vault::create_vault<_, TEST_COIN>(
        t_cap,
        &curr,
        2000, // 20% management fee (above 10% limit)
        PERFORMANCE_FEE_BPS,
        DEPOSIT_FEE_BPS,
        WITHDRAWAL_FEE_BPS,
        &clock,
        runner.ctx(),
    );

    abort EShouldNotReach
}

#[test]
fun test_allocate_and_divest() {
    let (prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let manager_cap = runner.scenario_mut().take_from_sender<VaultManagerCap<VAULT_TESTS>>();
    let mut lending_market = runner
        .scenario_mut()
        .take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    runner.set_sender(USER1);
    let clock = runner.scenario_mut().take_shared<Clock>();

    let deposit_amount = 1000;
    let deposit_coin = mint_test_coin(deposit_amount, runner.ctx());
    let manager_deploy_amount = deposit_coin.value() / 2;

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let mut vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );
    let user_withdraw_amount = vault_shares.value() / 2;

    runner.set_sender(ADMIN);

    vault.create_obligation(
        &manager_cap,
        &mut lending_market,
        runner.ctx(),
    );
    let obligation_index = 0;
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let _ctokens_amt = vault.deploy_funds(
        &manager_cap,
        &mut lending_market,
        obligation_index,
        manager_deploy_amount,
        &clock,
        agg,
        runner.ctx(),
    );

    runner.set_sender(ADMIN);

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    runner.system_tx!(|state, ctx| {
        vault.divest_funds(
            &manager_cap,
            &mut lending_market,
            obligation_index,
            U64_MAX, // withdraw all
            &clock,
            agg,
            state,
            ctx,
        );
    });

    runner.set_sender(USER1);

    let shares_to_withdraw = coin::split(
        &mut vault_shares,
        user_withdraw_amount,
        runner.ctx(),
    );
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let withdrawn_coins = vault.withdraw(
        shares_to_withdraw,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    {
        test_runner::destroy(prices);
        coin::burn_for_testing(vault_shares);
        coin::burn_for_testing(withdrawn_coins);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
    };

    runner.finish();
}

#[test]
fun test_nav_changes() {
    let (mut prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);

    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let main_pool_lm = runner.scenario_mut().take_shared<LendingMarket<MAIN_POOL>>();
    let mut lending_market = runner
        .scenario_mut()
        .take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let mut clock = runner.scenario_mut().take_shared<Clock>();

    runner.set_sender(USER1);

    // Deposit funds
    let deposit_amount = 1000000;
    let deposit_coin = mint_test_coin(deposit_amount, runner.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    // Calculate initial NAV per share (should be 1.0 scaled)
    let initial_agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let initial_nav = vault.calculate_nav_per_share(&initial_agg).floor();
    assert!(initial_nav == NAV_PRECISION as u64);
    vault::destroy_vault_value_aggregate_for_testing(initial_agg, &mut vault);

    // Record initial total shares
    let initial_total_shares = vault.get_vault_share_supply_for_testing();

    // Advance clock by 1 year to accrue management fees
    clock.increment_for_testing(365 * 24 * 60 * 60 * 1000);

    // Refresh price
    prices.update_price<TEST_COIN>(1, 0, &clock);
    lending_market.refresh_reserve_price(
        TEST_SUI_RESERVE_INDEX, // reserve_array_index
        &clock,
        prices.get_price_obj<TEST_COIN>(),
    );

    // Crank to apply fees
    {
        let crank_acc = vault.create_vault_crank_accumulator(&clock);
        vault.finalize_vault_crank(
            crank_acc,
            &lending_market,
            &clock,
        );
    };

    // Total shares should have increased due to fee shares being minted
    let new_total_shares = vault.get_vault_share_supply_for_testing();
    assert!(new_total_shares > initial_total_shares);

    // Calculate new NAV per share after dilution
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let diluted_nav = vault.calculate_nav_per_share(&agg).floor();

    // NAV per share should have decreased due to share dilution from fee minting
    assert!(diluted_nav < initial_nav);

    {
        test_runner::destroy(prices);
        test_runner::destroy(agg);
        coin::burn_for_testing(shares);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        ts::return_shared(main_pool_lm);
    };

    runner.finish();
}

#[test]
fun test_compound_rewards() {
    let (prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let mut lending_market = runner
        .scenario_mut()
        .take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let manager_cap = runner.scenario_mut().take_from_sender<VaultManagerCap<VAULT_TESTS>>();
    let lm_cap = runner
        .scenario_mut()
        .take_from_sender<lending_market::LendingMarketOwnerCap<TEST_LENDING_MARKET>>();
    let mut clock = runner.scenario_mut().take_shared<Clock>();

    // User deposits into vault
    runner.set_sender(USER1);
    let deposit_amount = 1000000;
    let deposit_coin = mint_test_coin(deposit_amount, runner.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    // Manager creates obligation and deploys funds
    runner.set_sender(ADMIN);
    vault.create_obligation(&manager_cap, &mut lending_market, runner.ctx());
    let obligation_index = 0;

    let deploy_amount = 500000;
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    vault.deploy_funds(
        &manager_cap,
        &mut lending_market,
        obligation_index,
        deploy_amount,
        &clock,
        agg,
        runner.ctx(),
    );

    // Admin adds reward pool for deposit rewards
    runner.set_sender(ADMIN);
    let reward_amount = 100000;
    let reward_coin = mint_test_coin(reward_amount, runner.ctx());
    let start_time_ms = clock.timestamp_ms();
    let end_time_ms = start_time_ms + (30 * 24 * 60 * 60 * 1000); // 30 days

    lm_cap.add_pool_reward<TEST_LENDING_MARKET, TEST_COIN>(
        &mut lending_market,
        TEST_SUI_RESERVE_INDEX,
        true, // is_deposit_reward
        reward_coin,
        start_time_ms,
        end_time_ms,
        &clock,
        runner.ctx(),
    );

    // Advance clock to end of reward period
    clock.increment_for_testing(31 * 24 * 60 * 60 * 1000); // 31 days

    let deposit_amount = vault.get_deposit_for_testing();

    // Call compound_rewards (permissionless)
    runner.set_sender(USER2);
    vault.compound_rewards<VAULT_TESTS, TEST_COIN, TEST_LENDING_MARKET>(
        &mut lending_market,
        obligation_index,
        TEST_SUI_RESERVE_INDEX,
        0, // reward_index
        true, // is_deposit_reward
        &clock,
        runner.ctx(),
    );

    // Verify rewards were claimed and deposited back into the vault
    assert!(vault.get_deposit_for_testing() > deposit_amount);

    {
        test_runner::destroy(prices);
        coin::burn_for_testing(vault_shares);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
        transfer::public_transfer(lm_cap, ADMIN);
    };

    runner.finish();
}

#[test]
fun test_compound_rewards_with_swap() {
    let (mut prices, mut runner) = init_vault_scenario();

    // Create a new vault with B_TEST_SUI as underlying asset (different from default TEST_COIN vault)
    runner.set_sender(ADMIN);
    let mut clock = runner.scenario_mut().take_shared<Clock>();
    let (curr, treasury_cap) = create_vault_shares(runner.ctx());
    let mut lending_market = runner.scenario_mut().take_shared<LendingMarket<MAIN_POOL>>();
    let lm_cap = runner
        .scenario_mut()
        .take_from_sender<lending_market::LendingMarketOwnerCap<MAIN_POOL>>();

    let b_token_decimals = 9;
    mock_pyth::register<B_TEST_SUI>(&mut prices, runner.ctx());
    mock_pyth::update_price<B_TEST_SUI>(&mut prices, 4, 0, &clock); // $4
    mock_pyth::register<B_TEST_USDC>(&mut prices, runner.ctx());
    mock_pyth::update_price<B_TEST_USDC>(&mut prices, 1, 0, &clock); // $1

    // Setup B_TEST_SUI reserve (vault's underlying asset)
    lending_market::add_reserve_for_testing<MAIN_POOL, B_TEST_SUI>(
        &lm_cap,
        &mut lending_market,
        mock_pyth::get_price_obj<B_TEST_SUI>(&prices),
        reserve_config::default_reserve_config(runner.ctx()),
        b_token_decimals,
        &clock,
        runner.ctx(),
    );

    let manager_cap = vault::create_vault<_, B_TEST_SUI>(
        treasury_cap,
        &curr,
        MANAGEMENT_FEE_BPS,
        PERFORMANCE_FEE_BPS,
        DEPOSIT_FEE_BPS,
        WITHDRAWAL_FEE_BPS,
        &clock,
        runner.ctx(),
    );

    // Add B_TEST_USDC and B_TEST_SUI as reserves in the lending market
    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, B_TEST_SUI>>();

    // Setup B_TEST_USDC reserve (for rewards)
    lending_market::add_reserve_for_testing<MAIN_POOL, B_TEST_USDC>(
        &lm_cap,
        &mut lending_market,
        mock_pyth::get_price_obj<B_TEST_USDC>(&prices),
        reserve_config::default_reserve_config(runner.ctx()),
        b_token_decimals,
        &clock,
        runner.ctx(),
    );

    runner.set_sender(ADMIN);

    // User deposits B_TEST_SUI into vault
    runner.set_sender(USER1);
    let deposit_coin = coin::mint_for_testing<B_TEST_SUI>(1_000_000_000_000, runner.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    // Manager creates obligation and deploys funds to lending market
    runner.set_sender(ADMIN);
    vault.create_obligation(&manager_cap, &mut lending_market, runner.ctx());
    let obligation_index = 0;

    let deploy_amount = 500_000_000_000; // 500 SUI (with 9 decimals)
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    vault.deploy_funds(
        &manager_cap,
        &mut lending_market,
        obligation_index,
        deploy_amount,
        &clock,
        agg,
        runner.ctx(),
    );

    runner.set_sender(ADMIN);

    // Add B_TEST_USDC reward pool for B_TEST_SUI deposits
    let sui_reserve_index = 1; // Reserve order: [TEST_COIN, B_TEST_SUI, B_TEST_USDC]
    let usdc_reserve_index = 2;
    let reward_amount = 100_000_000_000; // 100 USDC (with 9 decimals)
    let reward_coin = coin::mint_for_testing<B_TEST_USDC>(reward_amount, runner.ctx());
    let start_time_ms = clock.timestamp_ms();
    let end_time_ms = start_time_ms + (30 * 24 * 60 * 60 * 1000);

    lm_cap.add_pool_reward<MAIN_POOL, B_TEST_USDC>(
        &mut lending_market,
        sui_reserve_index,
        true,
        reward_coin,
        start_time_ms,
        end_time_ms,
        &clock,
        runner.ctx(),
    );

    // Advance time to accrue rewards
    clock.increment_for_testing(31 * 24 * 60 * 60 * 1000);

    // Refresh prices
    {
        prices.update_price<B_TEST_SUI>(4, 0, &clock);
        lending_market.refresh_reserve_price(
            sui_reserve_index, // reserve_array_index
            &clock,
            prices.get_price_obj<B_TEST_SUI>(),
        );

        prices.update_price<B_TEST_USDC>(1, 0, &clock);
        lending_market.refresh_reserve_price(
            usdc_reserve_index, // reserve_array_index
            &clock,
            prices.get_price_obj<B_TEST_USDC>(),
        );
    };

    // Compound rewards: claim B_TEST_USDC, swap to B_TEST_SUI, deposit in vault
    runner.set_sender(USER2);
    let ticket = vault.withdraw_reward<VAULT_TESTS, B_TEST_SUI, MAIN_POOL, B_TEST_USDC>(
        &mut lending_market,
        obligation_index,
        sui_reserve_index, // reward_reserve_index
        0, // reward_index
        true, // is_deposit_reward
        &clock,
        runner.ctx(),
    );

    let (swap_ticket, reward) = vault.swap_reward_for_base_token_w_oracle(
        ticket,
        &lending_market,
        &clock,
        runner.ctx(),
    );

    let output_coin = steamm_swap_usdc_to_sui(reward, runner.scenario_mut());

    vault.deposit_swapped_rewards(swap_ticket, output_coin, runner.ctx());

    // Verify rewards were compounded into the obligation
    let lm_type = std::type_name::with_defining_ids<MAIN_POOL>();
    let obligation_cap = vault.get_obligation_cap_for_testing<VAULT_TESTS, B_TEST_SUI, MAIN_POOL>(
        &lm_type,
        obligation_index,
    );
    let obligation_id = obligation_cap.obligation_id();
    let obligation = lending_market.obligation(obligation_id);
    let deposited_value = obligation.deposited_value_usd().floor();
    assert!(deposited_value > 0);

    {
        coin::burn_for_testing(vault_shares);
        test_runner::destroy(prices);
        test_runner::destroy(curr);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
        transfer::public_transfer(lm_cap, ADMIN);
    };

    runner.finish();
}

#[test]
fun test_share_precision() {
    let (prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let lending_market = runner.scenario_mut().take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    runner.set_sender(USER1);
    let clock = runner.scenario_mut().take_shared<Clock>();

    let vault_share_exp = 10u64.pow(VAULT_SHARE_DECIMALS);
    let test_coin_exp = 10u64.pow(TEST_COIN_DECIMALS);

    // === First deposit (1000 tokens) ===
    let small_coin = mint_test_coin(1000, runner.ctx());

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let initial_nav = vault.calculate_nav_per_share(&agg).floor();

    // Initial NAV should be exactly 1.0 (NAV_PRECISION)
    assert!(initial_nav == NAV_PRECISION as u64);

    let mut small_shares = vault.deposit(
        small_coin,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    let small_shares_amount = small_shares.value();
    let total_supply_after_first = vault.get_vault_share_supply_for_testing();

    // After 5% fee: net deposit = 950 tokens (worth $950), fee = 50 tokens
    // At NAV = 1.0, get 950 shares for user, 50 shares for fees (in base units with 6 decimals)
    assert!(small_shares_amount == 950 * vault_share_exp);
    assert!(total_supply_after_first == 1000 * vault_share_exp); // user + fee shares

    // Check NAV remains stable after first deposit
    let agg_after_first = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let nav_after_first = vault.calculate_nav_per_share(&agg_after_first).floor();
    assert!(nav_after_first == NAV_PRECISION as u64);
    vault::destroy_vault_value_aggregate_for_testing(agg_after_first, &mut vault);

    // === Second deposit (95.5 tokens) ===
    runner.set_sender(USER2);
    let large_deposit = (955 * test_coin_exp) / 10; // 95.5 tokens = 95,500,000 base units
    let large_coin = coin::mint_for_testing<TEST_COIN>(large_deposit, runner.ctx());

    let agg2 = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let nav_before_second = vault.calculate_nav_per_share(&agg2).floor();
    let supply_before_second = vault.get_vault_share_supply_for_testing();

    // NAV should still be 1.0 before second deposit
    assert!(nav_before_second == NAV_PRECISION as u64);
    assert!(supply_before_second == 1000 * vault_share_exp);

    let large_shares = vault.deposit(
        large_coin,
        &lending_market,
        &clock,
        agg2,
        runner.ctx(),
    );

    let large_shares_amount = large_shares.value();

    // After 5% fee: net deposit = 90.725 tokens (worth $90.725)
    // At NAV = 1.0, should get 90.725 shares in base units = 90,725,000 base units
    assert!(large_shares_amount == 90_725_000);

    // === Verify proportional share distribution ===
    // Small net deposit: 950 tokens → 950,000,000 share base units
    // Large net deposit: 90.725 tokens → 90,725,000 share base units
    // Ratio: 90.725 / 950 ≈ 0.0955

    let actual_ratio = (large_shares_amount * 1000) / small_shares_amount;
    assert!(actual_ratio == 95); // 95.5 rounded down

    let agg_final = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let nav_final = vault.calculate_nav_per_share(&agg_final).floor();
    vault::destroy_vault_value_aggregate_for_testing(agg_final, &mut vault);

    // NAV should remain at 1.0
    assert!(nav_final == NAV_PRECISION as u64);

    // === Verify total supply is correct ===
    // Total = first_user_shares + first_fee_shares + second_user_shares + second_fee_shares
    // Total = 950,000,000 + 50,000,000 + 90,725,000 + 4,775,000 = 1,095,500,000
    let final_total_supply = vault.get_vault_share_supply_for_testing();
    assert!(final_total_supply == 1_095_500_000);

    // === Test small withdrawal to verify reverse calculation ===
    runner.set_sender(USER1);
    let withdraw_shares = coin::split(&mut small_shares, 100 * vault_share_exp, runner.ctx());
    let agg3 = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let withdrawn = vault.withdraw(
        withdraw_shares,
        &lending_market,
        &clock,
        agg3,
        runner.ctx(),
    );

    // Withdrawing 100 shares (100 * 1e6 base units) at NAV = 1.0 means $100 worth
    // After 3% withdrawal fee: get 97 tokens = 97,000,000 base units
    let withdrawn_amount = withdrawn.value();
    assert!(withdrawn_amount == 97 * test_coin_exp);

    {
        test_runner::destroy(prices);
        coin::burn_for_testing(small_shares);
        coin::burn_for_testing(large_shares);
        coin::burn_for_testing(withdrawn);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
    };

    runner.finish();
}

#[test]
fun test_small_deposit() {
    let (prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let lending_market = runner.scenario_mut().take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    runner.set_sender(USER1);
    let clock = runner.scenario_mut().take_shared<Clock>();

    let small_deposit = (27 * 10u64.pow(TEST_COIN_DECIMALS)) / 100; // $0.27
    let small_coin = coin::mint_for_testing<TEST_COIN>(small_deposit, runner.ctx());

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);

    let small_shares = vault.deposit(
        small_coin,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    {
        test_runner::destroy(prices);
        coin::burn_for_testing(small_shares);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
    };

    runner.finish();
}

#[test]
fun test_vault_crank_with_multiple_obligations_and_rewards() {
    let (mut prices, mut runner) = init_vault_scenario();

    // Setup vault with B_TEST_SUI as underlying asset
    runner.set_sender(ADMIN);
    let mut clock = runner.scenario_mut().take_shared<Clock>();
    let (curr, treasury_cap) = create_vault_shares(runner.ctx());
    let mut lending_market = runner.scenario_mut().take_shared<LendingMarket<MAIN_POOL>>();
    let lm_cap = runner
        .scenario_mut()
        .take_from_sender<lending_market::LendingMarketOwnerCap<MAIN_POOL>>();

    let b_token_decimals = 9;
    mock_pyth::register<B_TEST_SUI>(&mut prices, runner.ctx());
    mock_pyth::update_price<B_TEST_SUI>(&mut prices, 4, 0, &clock);
    mock_pyth::register<B_TEST_USDC>(&mut prices, runner.ctx());
    mock_pyth::update_price<B_TEST_USDC>(&mut prices, 1, 0, &clock);

    // Add B_TEST_SUI reserve (vault's base asset)
    lending_market::add_reserve_for_testing<MAIN_POOL, B_TEST_SUI>(
        &lm_cap,
        &mut lending_market,
        mock_pyth::get_price_obj<B_TEST_SUI>(&prices),
        reserve_config::default_reserve_config(runner.ctx()),
        b_token_decimals,
        &clock,
        runner.ctx(),
    );

    let manager_cap = vault::create_vault<_, B_TEST_SUI>(
        treasury_cap,
        &curr,
        MANAGEMENT_FEE_BPS,
        PERFORMANCE_FEE_BPS,
        DEPOSIT_FEE_BPS,
        WITHDRAWAL_FEE_BPS,
        &clock,
        runner.ctx(),
    );

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, B_TEST_SUI>>();

    // Add B_TEST_USDC reserve (for non-base rewards)
    lending_market::add_reserve_for_testing<MAIN_POOL, B_TEST_USDC>(
        &lm_cap,
        &mut lending_market,
        mock_pyth::get_price_obj<B_TEST_USDC>(&prices),
        reserve_config::default_reserve_config(runner.ctx()),
        b_token_decimals,
        &clock,
        runner.ctx(),
    );

    runner.set_sender(ADMIN);

    // User deposits into vault
    runner.set_sender(USER1);
    let deposit_coin = coin::mint_for_testing<B_TEST_SUI>(2_000_000_000_000, runner.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    // Create two obligations
    runner.set_sender(ADMIN);
    let obligation_0 = 0;
    let obligation_1 = 1;
    vault.create_obligation(&manager_cap, &mut lending_market, runner.ctx());
    vault.create_obligation(&manager_cap, &mut lending_market, runner.ctx());

    // Deploy funds to both obligations
    let deploy_amount = 500_000_000_000;
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    vault.deploy_funds(
        &manager_cap,
        &mut lending_market,
        obligation_0,
        deploy_amount,
        &clock,
        agg,
        runner.ctx(),
    );

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    vault.deploy_funds(
        &manager_cap,
        &mut lending_market,
        obligation_1,
        deploy_amount,
        &clock,
        agg,
        runner.ctx(),
    );

    runner.set_sender(ADMIN);

    // Reserve indices: [TEST_COIN, B_TEST_SUI, B_TEST_USDC]
    let sui_reserve_index = 1;
    let usdc_reserve_index = 2;
    let sui_reward_index = 0;
    let usdc_reward_index = 1;
    let is_deposit_reward = true;

    let start_time_ms = clock.timestamp_ms();
    let end_time_ms = start_time_ms + (30 * 24 * 60 * 60 * 1000);

    // Add B_TEST_SUI reward pool (base token - direct compound)
    let sui_reward_amount = 50_000_000_000;
    let sui_reward_coin = coin::mint_for_testing<B_TEST_SUI>(sui_reward_amount, runner.ctx());
    lm_cap.add_pool_reward<MAIN_POOL, B_TEST_SUI>(
        &mut lending_market,
        sui_reserve_index,
        is_deposit_reward,
        sui_reward_coin,
        start_time_ms,
        end_time_ms,
        &clock,
        runner.ctx(),
    );

    // Add B_TEST_USDC reward pool (non-base token - requires swap)
    let usdc_reward_amount = 100_000_000_000;
    let usdc_reward_coin = coin::mint_for_testing<B_TEST_USDC>(usdc_reward_amount, runner.ctx());
    lm_cap.add_pool_reward<MAIN_POOL, B_TEST_USDC>(
        &mut lending_market,
        sui_reserve_index,
        is_deposit_reward,
        usdc_reward_coin,
        start_time_ms,
        end_time_ms,
        &clock,
        runner.ctx(),
    );

    // Advance clock past reward period and staleness limit
    clock.increment_for_testing(31 * 24 * 60 * 60 * 1000); // 31 days - past rewards
    clock.increment_for_testing(3_700_000); // Just over 1 hour staleness

    // Refresh prices
    {
        prices.update_price<B_TEST_SUI>(4, 0, &clock);
        lending_market.refresh_reserve_price(
            sui_reserve_index, // reserve_array_index
            &clock,
            prices.get_price_obj<B_TEST_SUI>(),
        );

        prices.update_price<B_TEST_USDC>(1, 0, &clock);
        lending_market.refresh_reserve_price(
            usdc_reserve_index, // reserve_array_index
            &clock,
            prices.get_price_obj<B_TEST_USDC>(),
        );
    };

    runner.set_sender(USER2);

    let lm_type = std::type_name::with_defining_ids<MAIN_POOL>();

    // Compound all rewards from both obligations (4 total)
    {
        // Obligation 0: SUI rewards
        vault.compound_rewards<VAULT_TESTS, B_TEST_SUI, MAIN_POOL>(
            &mut lending_market,
            obligation_0,
            sui_reserve_index,
            sui_reward_index,
            is_deposit_reward,
            &clock,
            runner.ctx(),
        );

        // Obligation 0: USDC rewards
        {
            let ticket = vault.withdraw_reward<VAULT_TESTS, B_TEST_SUI, MAIN_POOL, B_TEST_USDC>(
                &mut lending_market,
                obligation_0,
                sui_reserve_index, // reward_reserve_index
                usdc_reward_index, // reward_index
                is_deposit_reward,
                &clock,
                runner.ctx(),
            );

            let (swap_ticket, reward) = vault.swap_reward_for_base_token_w_oracle(
                ticket,
                &lending_market,
                &clock,
                runner.ctx(),
            );

            let output_coin = steamm_swap_usdc_to_sui(reward, runner.scenario_mut());

            vault.deposit_swapped_rewards(swap_ticket, output_coin, runner.ctx());
        };

        runner.set_sender(USER2);

        // Obligation 1: SUI rewards
        vault.compound_rewards<VAULT_TESTS, B_TEST_SUI, MAIN_POOL>(
            &mut lending_market,
            obligation_1,
            sui_reserve_index,
            sui_reward_index,
            is_deposit_reward,
            &clock,
            runner.ctx(),
        );

        // Obligation 1: USDC rewards
        {
            let ticket = vault.withdraw_reward<VAULT_TESTS, B_TEST_SUI, MAIN_POOL, B_TEST_USDC>(
                &mut lending_market,
                obligation_1,
                sui_reserve_index, // reward_reserve_index
                usdc_reward_index, // reward_index
                is_deposit_reward,
                &clock,
                runner.ctx(),
            );

            let (swap_ticket, reward) = vault.swap_reward_for_base_token_w_oracle(
                ticket,
                &lending_market,
                &clock,
                runner.ctx(),
            );

            let output_coin = steamm_swap_usdc_to_sui(reward, runner.scenario_mut());

            vault.deposit_swapped_rewards(swap_ticket, output_coin, runner.ctx());
        };
    };

    let mut crank_acc = vault.create_vault_crank_accumulator(&clock);

    crank_acc.process_lending_market_for_crank(&lending_market, &lending_market);

    vault.finalize_vault_crank(
        crank_acc,
        &lending_market,
        &clock,
    );

    // Verify rewards were compounded into both obligations
    let obligation_cap_0 = vault.get_obligation_cap_for_testing<VAULT_TESTS, B_TEST_SUI, MAIN_POOL>(
        &lm_type,
        obligation_0,
    );
    let obligation = lending_market.obligation(obligation_cap_0.obligation_id());
    assert!(obligation.deposited_value_usd().floor() > 0);

    let obligation_cap_1 = vault.get_obligation_cap_for_testing<VAULT_TESTS, B_TEST_SUI, MAIN_POOL>(
        &lm_type,
        obligation_1,
    );
    let obligation = lending_market.obligation(obligation_cap_1.obligation_id());
    assert!(obligation.deposited_value_usd().floor() > 0);

    // Now user operations should work again (state is fresh)
    runner.set_sender(USER1);
    let test_deposit = coin::mint_for_testing<B_TEST_SUI>(1_000_000_000, runner.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let new_shares = vault.deposit(
        test_deposit,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    {
        coin::burn_for_testing(vault_shares);
        coin::burn_for_testing(new_shares);
        test_runner::destroy(prices);
        test_runner::destroy(curr);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
        transfer::public_transfer(lm_cap, ADMIN);
    };

    runner.finish();
}

#[test]
#[expected_failure(abort_code = vault::EInsufficientLiquidity)]
fun test_withdraw_insufficient_liquidity_failure() {
    let (_prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let manager_cap = runner.scenario_mut().take_from_sender<VaultManagerCap<VAULT_TESTS>>();
    let mut lending_market = runner
        .scenario_mut()
        .take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    runner.set_sender(USER1);
    let clock = runner.scenario_mut().take_shared<Clock>();

    // User deposits 1000 tokens
    let deposit_amount = 1000;
    let deposit_coin = mint_test_coin(deposit_amount, runner.ctx());
    let net_deposit_amount = (
        deposit_amount as u64 * (BASIS_POINTS - DEPOSIT_FEE_BPS) / BASIS_POINTS,
    );
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let mut vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    // Manager deploys most of the funds, leaving insufficient liquid assets
    runner.set_sender(ADMIN);
    vault.create_obligation(&manager_cap, &mut lending_market, runner.ctx());
    let obligation_index = 0;
    let exp = 10u64.pow(TEST_COIN_DECIMALS);
    let liquid_assets_left = 100 * exp;
    let deploy_amount = net_deposit_amount * exp - liquid_assets_left;
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    vault.deploy_funds(
        &manager_cap,
        &mut lending_market,
        obligation_index,
        deploy_amount,
        &clock,
        agg,
        runner.ctx(),
    );

    // User tries to withdraw more than is liquid
    runner.set_sender(USER1);
    let shares_to_withdraw = vault_shares.value() / 2;
    let withdraw_shares = coin::split(&mut vault_shares, shares_to_withdraw, runner.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let _withdrawn_coins = vault.withdraw(
        withdraw_shares,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    abort EShouldNotReach
}

#[test]
fun test_unwind_withdrawal_success() {
    let (prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let manager_cap = runner.scenario_mut().take_from_sender<VaultManagerCap<VAULT_TESTS>>();
    let mut lending_market = runner
        .scenario_mut()
        .take_shared<LendingMarket<TEST_LENDING_MARKET>>();

    runner.set_sender(USER1);
    let clock = runner.scenario_mut().take_shared<Clock>();

    // User deposits 1000 tokens
    let deposit_amount = 1000;
    let deposit_coin = mint_test_coin(deposit_amount, runner.ctx());
    let net_deposit_amount = (
        deposit_amount as u64 * (BASIS_POINTS - DEPOSIT_FEE_BPS) / BASIS_POINTS,
    );
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let mut vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    // Manager deploys most of the funds, leaving insufficient liquid assets
    runner.set_sender(ADMIN);
    vault.create_obligation(&manager_cap, &mut lending_market, runner.ctx());
    let obligation_index = 0;
    let exp = 10u64.pow(TEST_COIN_DECIMALS);
    let liquid_assets_left = 100 * exp;
    let deploy_amount = net_deposit_amount * exp - liquid_assets_left;
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    vault.deploy_funds(
        &manager_cap,
        &mut lending_market,
        obligation_index,
        deploy_amount,
        &clock,
        agg,
        runner.ctx(),
    );

    // User tries to withdraw more than is liquid, using the unwind flow
    runner.set_sender(USER1);
    let shares_to_withdraw_val = vault_shares.value() / 2;
    let withdraw_shares = coin::split(&mut vault_shares, shares_to_withdraw_val, runner.ctx());

    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let mut unwind_acc = vault.create_unwind_accumulator(
        withdraw_shares,
        &lending_market,
        agg,
        &clock,
    );

    runner.system_tx!(|state, ctx| {
        vault.process_unwinds_for_lending_market(
            &mut unwind_acc,
            &mut lending_market,
            &clock,
            state,
            ctx,
        );
    });

    let withdrawn_coins = vault.withdraw_with_unwind(
        unwind_acc,
        &lending_market,
        &clock,
        runner.ctx(),
    );

    assert!(withdrawn_coins.value() > 0);

    {
        test_runner::destroy(prices);
        coin::burn_for_testing(vault_shares);
        coin::burn_for_testing(withdrawn_coins);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(manager_cap, ADMIN);
    };

    runner.finish();
}

#[test]
fun test_token_usd_conversion_roundtrip() {
    let (mut prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let lending_market = runner.scenario_mut().take_shared<LendingMarket<TEST_LENDING_MARKET>>();
    let clock = runner.scenario_mut().take_shared<Clock>();
    prices.update_decimal_price<TEST_COIN>(457823, 6, true, &clock);

    let exp = 10u64.pow(TEST_COIN_DECIMALS);

    // Test various token amounts with exact round-trip conversion
    let test_amounts = vector[
        exp, // 1 token = $1
        100 * exp, // 100 tokens = $100
        1_000 * exp, // 1,000 tokens = $1,000
        50_000 * exp, // 50,000 tokens = $50,000
        123_456 * exp, // 123,456 tokens = $123,456
    ];

    test_amounts.do!(|token_amount| {
        // Convert token -> USD
        let usd_value = utils::token_amount_to_usd<TEST_LENDING_MARKET, TEST_COIN>(
            token_amount,
            &lending_market,
            &clock,
        );

        // Convert USD -> token
        let recovered_token_amount = utils::usd_to_token_amount<TEST_LENDING_MARKET, TEST_COIN>(
            usd_value,
            &lending_market,
            &clock,
        );

        assert!(decimal::from(token_amount).eq(recovered_token_amount));

        let expected_usd = decimal::from(token_amount / exp);
        assert!(usd_value.eq(expected_usd));
    });

    // Test with fractional amounts
    let fractional_amounts = vector[
        exp / 2, // 0.5 tokens = $0.5
        exp / 4, // 0.25 tokens = $0.25
        exp / 10, // 0.1 tokens = $0.1
        exp / 100, // 0.01 tokens = $0.01
    ];

    fractional_amounts.do!(|token_amount| {
        let usd_value = utils::token_amount_to_usd<TEST_LENDING_MARKET, TEST_COIN>(
            token_amount,
            &lending_market,
            &clock,
        );

        let recovered_token_amount_decimal = utils::usd_to_token_amount<
            TEST_LENDING_MARKET,
            TEST_COIN,
        >(usd_value, &lending_market, &clock);

        let original_as_decimal = decimal::from(token_amount);
        assert!(recovered_token_amount_decimal.eq(original_as_decimal));
    });

    {
        let zero_usd = utils::token_amount_to_usd<TEST_LENDING_MARKET, TEST_COIN>(
            0,
            &lending_market,
            &clock,
        );
        assert!(zero_usd.eq(decimal::from(0)));

        let zero_tokens = utils::usd_to_token_amount<TEST_LENDING_MARKET, TEST_COIN>(
            decimal::from(0),
            &lending_market,
            &clock,
        );
        assert!(zero_tokens.eq(decimal::from(0)));
    };

    {
        test_runner::destroy(prices);
        ts::return_shared(clock);
        ts::return_shared(lending_market);
    };

    runner.finish();
}

/// Ensures that cranking an empty vault followed by deposits
/// does not incorrectly charge performance fees.
///
/// 1. Initialize HWM to 0
/// 2. Skip performance fee calculation when HWM == 0
/// 3. Only update HWM when current_shares > 0
#[test]
fun test_perf_fees_in_new_vault() {
    let (mut prices, mut runner) = init_vault_scenario();

    runner.set_sender(ADMIN);
    let mut vault = runner.scenario_mut().take_shared<Vault<VAULT_TESTS, TEST_COIN>>();
    let mut lending_market = runner.scenario_mut().take_shared<LendingMarket<MAIN_POOL>>();
    let mut clock = runner.scenario_mut().take_shared<Clock>();

    // === Step 1: Crank while vault is empty ===
    // Advance time past MIN_REWARDS_STALENESS_MS (1 min)
    clock.increment_for_testing(61_000);

    // Refresh price after clock increment
    prices.update_price<TEST_COIN>(1, 0, &clock);
    lending_market.refresh_reserve_price(
        TEST_COIN_MAIN_POOL_RESERVE_INDEX,
        &clock,
        prices.get_price_obj<TEST_COIN>(),
    );

    // Crank empty vault
    let crank_acc = vault.create_vault_crank_accumulator(&clock);
    vault.finalize_vault_crank(crank_acc, &lending_market, &clock);

    // Verify no shares exist and no fees were charged
    let shares_after_empty_crank = vault.get_vault_share_supply_for_testing();
    let fees_after_empty_crank = vault.get_manager_fees_for_testing();
    assert!(shares_after_empty_crank == 0);
    assert!(fees_after_empty_crank == 0);
    assert!(vault.get_hwm_for_testing().eq(decimal::from(0)));

    // === Step 2: User deposits ===
    runner.set_sender(USER1);
    let deposit_amount = 1_000_000;
    let deposit_coin = mint_test_coin(deposit_amount, runner.ctx());
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    let vault_shares = vault.deposit(
        deposit_coin,
        &lending_market,
        &clock,
        agg,
        runner.ctx(),
    );

    let share_exp = 10u64.pow(VAULT_SHARE_DECIMALS);
    let total_supply_after_deposit = vault.get_vault_share_supply_for_testing();
    let deposit_fees = vault.get_manager_fees_for_testing();

    // Verify deposit worked correctly with 5% deposit fee
    let expected_deposit_fee_shares = deposit_amount * share_exp * DEPOSIT_FEE_BPS / BASIS_POINTS;
    assert!(deposit_fees == expected_deposit_fee_shares);
    assert!(total_supply_after_deposit == deposit_amount * share_exp);

    // === Step 3: Crank after deposit - should only charge management fees, not performance fees ===
    runner.set_sender(ADMIN);

    // Advance time by 1 year for management fees
    clock.increment_for_testing(365 * 24 * 60 * 60 * 1000);

    // Refresh price (keep at $1)
    prices.update_price<TEST_COIN>(1, 0, &clock);
    lending_market.refresh_reserve_price(
        TEST_COIN_MAIN_POOL_RESERVE_INDEX,
        &clock,
        prices.get_price_obj<TEST_COIN>(),
    );

    let supply_before_second_crank = vault.get_vault_share_supply_for_testing();
    let fees_before_second_crank = vault.get_manager_fees_for_testing();

    // Crank: should not charge performance fees
    let crank_acc = vault.create_vault_crank_accumulator(&clock);
    vault.finalize_vault_crank(crank_acc, &lending_market, &clock);

    let supply_after_second_crank = vault.get_vault_share_supply_for_testing();
    let fees_after_second_crank = vault.get_manager_fees_for_testing();

    let new_fee_shares = supply_after_second_crank - supply_before_second_crank;
    let fee_delta = fees_after_second_crank - fees_before_second_crank;

    // Verify fees were minted
    assert!(fee_delta == new_fee_shares);

    // Calculate fee rate in bps: (fee_shares * BASIS_POINTS) / supply_before
    // For 1 year at 2% (200 bps), the rate is 204 bps due to the formula:
    // shares_to_mint = supply * fee_factor / (1 - fee_factor)
    let fee_rate_bps = (new_fee_shares * BASIS_POINTS) / supply_before_second_crank;

    // Fee rate should be exactly 204 bps for 1 year at 2% management fee
    assert!(fee_rate_bps == 204);

    // === Step 4: Verify subsequent cranks work correctly (HWM now established) ===
    // Advance another year
    clock.increment_for_testing(365 * 24 * 60 * 60 * 1000);

    prices.update_price<TEST_COIN>(1, 0, &clock);
    lending_market.refresh_reserve_price(
        TEST_COIN_MAIN_POOL_RESERVE_INDEX,
        &clock,
        prices.get_price_obj<TEST_COIN>(),
    );

    let supply_before_third_crank = vault.get_vault_share_supply_for_testing();

    let crank_acc = vault.create_vault_crank_accumulator(&clock);
    vault.finalize_vault_crank(crank_acc, &lending_market, &clock);

    let supply_after_third_crank = vault.get_vault_share_supply_for_testing();
    let third_crank_fees = supply_after_third_crank - supply_before_third_crank;

    // Third crank should also only have management fees (no alpha generated)
    let third_fee_rate_bps = (third_crank_fees * BASIS_POINTS) / supply_before_third_crank;
    assert!(third_fee_rate_bps == 204);

    // === Step 5: Generate alpha through rewards and verify performance fees are collected ===
    runner.set_sender(ADMIN);

    // Create obligation and deploy funds
    runner.owned_tx!<VaultManagerCap<VAULT_TESTS>>(|manager_cap| {
        vault.create_obligation(&manager_cap, &mut lending_market, runner.ctx());
        runner.keep(manager_cap);
    });
    let obligation_index = 0;

    let deploy_amount = 500_000 * 10u64.pow(TEST_COIN_DECIMALS);
    let agg = vault.create_vault_value_aggregate_for_testing(&lending_market, &clock);
    runner.owned_tx!<VaultManagerCap<VAULT_TESTS>>(|manager_cap| {
        vault.deploy_funds(
            &manager_cap,
            &mut lending_market,
            obligation_index,
            deploy_amount,
            &clock,
            agg,
            runner.ctx(),
        );
        runner.keep(manager_cap);
    });

    // Set up rewards pool
    let reward_amount = 150_000;
    let reward_coin = mint_test_coin(reward_amount, runner.ctx());
    let start_time_ms = clock.timestamp_ms();
    let end_time_ms = start_time_ms + (30 * 24 * 60 * 60 * 1000); // 30 days

    let lm_cap = runner
        .scenario_mut()
        .take_from_sender<lending_market::LendingMarketOwnerCap<MAIN_POOL>>();

    lm_cap.add_pool_reward<MAIN_POOL, TEST_COIN>(
        &mut lending_market,
        TEST_COIN_MAIN_POOL_RESERVE_INDEX,
        true, // is_deposit_reward
        reward_coin,
        start_time_ms,
        end_time_ms,
        &clock,
        runner.ctx(),
    );

    // Advance time to accrue rewards
    clock.increment_for_testing(31 * 24 * 60 * 60 * 1000); // 31 days

    // Refresh price
    prices.update_price<TEST_COIN>(1, 0, &clock);
    lending_market.refresh_reserve_price(
        TEST_COIN_MAIN_POOL_RESERVE_INDEX,
        &clock,
        prices.get_price_obj<TEST_COIN>(),
    );

    // Compound rewards
    runner.set_sender(USER2);
    vault.compound_rewards<VAULT_TESTS, TEST_COIN, MAIN_POOL>(
        &mut lending_market,
        obligation_index,
        TEST_COIN_MAIN_POOL_RESERVE_INDEX,
        0, // reward_index
        true, // is_deposit_reward
        &clock,
        runner.ctx(),
    );

    // Advance 1 year for fees
    clock.increment_for_testing(365 * 24 * 60 * 60 * 1000);

    prices.update_price<TEST_COIN>(1, 0, &clock);
    lending_market.refresh_reserve_price(
        TEST_COIN_MAIN_POOL_RESERVE_INDEX,
        &clock,
        prices.get_price_obj<TEST_COIN>(),
    );

    let supply_before_perf_fee = vault.get_vault_share_supply_for_testing();

    // Crank - should get both management and performance fees
    runner.set_sender(ADMIN);
    let mut crank_acc = vault.create_vault_crank_accumulator(&clock);
    crank_acc.process_lending_market_for_crank(&lending_market, &lending_market);
    vault.finalize_vault_crank(crank_acc, &lending_market, &clock);

    let supply_after_perf_fee = vault.get_vault_share_supply_for_testing();
    let total_fee_shares = supply_after_perf_fee - supply_before_perf_fee;

    // Calculate baseline management fee
    let baseline_mgmt_fee =
        supply_before_perf_fee * MANAGEMENT_FEE_BPS / (BASIS_POINTS - MANAGEMENT_FEE_BPS);

    // Total fees should exceed baseline (includes performance fee from alpha)
    assert!(total_fee_shares > baseline_mgmt_fee);

    // Performance fee component
    let perf_fee_shares = total_fee_shares - baseline_mgmt_fee;
    assert!(perf_fee_shares > 0);

    // Performance fee as percentage of baseline management fee
    // Higher than test_fees_collected (8%) because no price increase inflated HWM before rewards
    let perf_fee_ratio_pct = (perf_fee_shares * 100) / baseline_mgmt_fee;
    assert!(perf_fee_ratio_pct == 63);

    {
        test_runner::destroy(prices);
        coin::burn_for_testing(vault_shares);
        ts::return_shared(clock);
        ts::return_shared(vault);
        ts::return_shared(lending_market);
        transfer::public_transfer(lm_cap, ADMIN);
    };

    runner.finish();
}
