
<a name="suilend_reserve"></a>

# Module `suilend::reserve`

The reserve module holds the coins of a certain type for a given lending market.


-  [Struct `Reserve`](#suilend_reserve_Reserve)
-  [Struct `CToken`](#suilend_reserve_CToken)
-  [Struct `LiquidityRequest`](#suilend_reserve_LiquidityRequest)
-  [Struct `BalanceKey`](#suilend_reserve_BalanceKey)
-  [Struct `StakerKey`](#suilend_reserve_StakerKey)
-  [Struct `Balances`](#suilend_reserve_Balances)
-  [Struct `InterestUpdateEvent`](#suilend_reserve_InterestUpdateEvent)
-  [Struct `ReserveAssetDataEvent`](#suilend_reserve_ReserveAssetDataEvent)
-  [Struct `ClaimStakingRewardsEvent`](#suilend_reserve_ClaimStakingRewardsEvent)
-  [Constants](#@Constants_0)
-  [Function `create_reserve`](#suilend_reserve_create_reserve)
    -  [Arguments](#@Arguments_1)
    -  [Returns](#@Returns_2)
    -  [Panics](#@Panics_3)
-  [Function `price_identifier`](#suilend_reserve_price_identifier)
    -  [Arguments](#@Arguments_4)
    -  [Returns](#@Returns_5)
-  [Function `borrows_pool_reward_manager`](#suilend_reserve_borrows_pool_reward_manager)
    -  [Arguments](#@Arguments_6)
    -  [Returns](#@Returns_7)
-  [Function `deposits_pool_reward_manager`](#suilend_reserve_deposits_pool_reward_manager)
    -  [Arguments](#@Arguments_8)
    -  [Returns](#@Returns_9)
-  [Function `array_index`](#suilend_reserve_array_index)
    -  [Arguments](#@Arguments_10)
    -  [Returns](#@Returns_11)
-  [Function `available_amount`](#suilend_reserve_available_amount)
    -  [Arguments](#@Arguments_12)
    -  [Returns](#@Returns_13)
-  [Function `borrowed_amount`](#suilend_reserve_borrowed_amount)
    -  [Arguments](#@Arguments_14)
    -  [Returns](#@Returns_15)
-  [Function `coin_type`](#suilend_reserve_coin_type)
    -  [Arguments](#@Arguments_16)
    -  [Returns](#@Returns_17)
-  [Function `assert_price_is_fresh`](#suilend_reserve_assert_price_is_fresh)
    -  [Arguments](#@Arguments_18)
    -  [Panics](#@Panics_19)
-  [Function `is_price_fresh`](#suilend_reserve_is_price_fresh)
    -  [Arguments](#@Arguments_20)
    -  [Returns](#@Returns_21)
-  [Function `price`](#suilend_reserve_price)
    -  [Arguments](#@Arguments_22)
    -  [Returns](#@Returns_23)
-  [Function `price_lower_bound`](#suilend_reserve_price_lower_bound)
    -  [Arguments](#@Arguments_24)
    -  [Returns](#@Returns_25)
-  [Function `price_upper_bound`](#suilend_reserve_price_upper_bound)
    -  [Arguments](#@Arguments_26)
    -  [Returns](#@Returns_27)
-  [Function `market_value`](#suilend_reserve_market_value)
    -  [Arguments](#@Arguments_28)
    -  [Returns](#@Returns_29)
-  [Function `market_value_lower_bound`](#suilend_reserve_market_value_lower_bound)
    -  [Arguments](#@Arguments_30)
    -  [Returns](#@Returns_31)
-  [Function `market_value_upper_bound`](#suilend_reserve_market_value_upper_bound)
    -  [Arguments](#@Arguments_32)
    -  [Returns](#@Returns_33)
-  [Function `ctoken_market_value`](#suilend_reserve_ctoken_market_value)
    -  [Arguments](#@Arguments_34)
    -  [Returns](#@Returns_35)
-  [Function `ctoken_market_value_lower_bound`](#suilend_reserve_ctoken_market_value_lower_bound)
    -  [Arguments](#@Arguments_36)
    -  [Returns](#@Returns_37)
-  [Function `ctoken_market_value_upper_bound`](#suilend_reserve_ctoken_market_value_upper_bound)
    -  [Arguments](#@Arguments_38)
    -  [Returns](#@Returns_39)
-  [Function `usd_to_token_amount_lower_bound`](#suilend_reserve_usd_to_token_amount_lower_bound)
    -  [Arguments](#@Arguments_40)
    -  [Returns](#@Returns_41)
-  [Function `usd_to_token_amount_upper_bound`](#suilend_reserve_usd_to_token_amount_upper_bound)
    -  [Arguments](#@Arguments_42)
    -  [Returns](#@Returns_43)
-  [Function `cumulative_borrow_rate`](#suilend_reserve_cumulative_borrow_rate)
    -  [Arguments](#@Arguments_44)
    -  [Returns](#@Returns_45)
-  [Function `total_supply`](#suilend_reserve_total_supply)
    -  [Arguments](#@Arguments_46)
    -  [Returns](#@Returns_47)
-  [Function `simulated_total_supply`](#suilend_reserve_simulated_total_supply)
    -  [Arguments](#@Arguments_48)
    -  [Returns](#@Returns_49)
-  [Function `calculate_utilization_rate`](#suilend_reserve_calculate_utilization_rate)
    -  [Arguments](#@Arguments_50)
    -  [Returns](#@Returns_51)
-  [Function `ctoken_ratio`](#suilend_reserve_ctoken_ratio)
    -  [Arguments](#@Arguments_52)
    -  [Returns](#@Returns_53)
-  [Function `simulated_ctoken_ratio`](#suilend_reserve_simulated_ctoken_ratio)
    -  [Arguments](#@Arguments_54)
    -  [Returns](#@Returns_55)
-  [Function `config`](#suilend_reserve_config)
    -  [Arguments](#@Arguments_56)
    -  [Returns](#@Returns_57)
-  [Function `calculate_borrow_fee`](#suilend_reserve_calculate_borrow_fee)
    -  [Arguments](#@Arguments_58)
    -  [Returns](#@Returns_59)
-  [Function `max_borrow_amount`](#suilend_reserve_max_borrow_amount)
    -  [Arguments](#@Arguments_60)
    -  [Returns](#@Returns_61)
-  [Function `max_redeem_amount`](#suilend_reserve_max_redeem_amount)
    -  [Arguments](#@Arguments_62)
    -  [Returns](#@Returns_63)
-  [Function `ctoken_supply`](#suilend_reserve_ctoken_supply)
    -  [Arguments](#@Arguments_64)
    -  [Returns](#@Returns_65)
-  [Function `unclaimed_spread_fees`](#suilend_reserve_unclaimed_spread_fees)
    -  [Arguments](#@Arguments_66)
    -  [Returns](#@Returns_67)
-  [Function `balances`](#suilend_reserve_balances)
    -  [Arguments](#@Arguments_68)
    -  [Returns](#@Returns_69)
    -  [Panics](#@Panics_70)
-  [Function `balances_available_amount`](#suilend_reserve_balances_available_amount)
    -  [Arguments](#@Arguments_71)
    -  [Returns](#@Returns_72)
-  [Function `balances_ctoken_supply`](#suilend_reserve_balances_ctoken_supply)
    -  [Arguments](#@Arguments_73)
    -  [Returns](#@Returns_74)
-  [Function `balances_fees`](#suilend_reserve_balances_fees)
    -  [Arguments](#@Arguments_75)
    -  [Returns](#@Returns_76)
-  [Function `balances_ctoken_fees`](#suilend_reserve_balances_ctoken_fees)
    -  [Arguments](#@Arguments_77)
    -  [Returns](#@Returns_78)
-  [Function `liquidity_request_amount`](#suilend_reserve_liquidity_request_amount)
    -  [Arguments](#@Arguments_79)
    -  [Returns](#@Returns_80)
-  [Function `liquidity_request_fee`](#suilend_reserve_liquidity_request_fee)
    -  [Arguments](#@Arguments_81)
    -  [Returns](#@Returns_82)
-  [Function `staker`](#suilend_reserve_staker)
    -  [Arguments](#@Arguments_83)
    -  [Returns](#@Returns_84)
    -  [Panics](#@Panics_85)
-  [Function `deposits_pool_reward_manager_mut`](#suilend_reserve_deposits_pool_reward_manager_mut)
    -  [Arguments](#@Arguments_86)
    -  [Returns](#@Returns_87)
-  [Function `borrows_pool_reward_manager_mut`](#suilend_reserve_borrows_pool_reward_manager_mut)
    -  [Arguments](#@Arguments_88)
    -  [Returns](#@Returns_89)
-  [Function `deduct_liquidation_fee`](#suilend_reserve_deduct_liquidation_fee)
    -  [Arguments](#@Arguments_90)
    -  [Returns](#@Returns_91)
    -  [Panics](#@Panics_92)
-  [Function `join_fees`](#suilend_reserve_join_fees)
    -  [Arguments](#@Arguments_93)
    -  [Panics](#@Panics_94)
-  [Function `update_reserve_config`](#suilend_reserve_update_reserve_config)
    -  [Arguments](#@Arguments_95)
-  [Function `update_price`](#suilend_reserve_update_price)
    -  [Arguments](#@Arguments_96)
    -  [Panics](#@Panics_97)
-  [Function `compound_interest`](#suilend_reserve_compound_interest)
    -  [Arguments](#@Arguments_98)
-  [Function `simulated_compound_interest`](#suilend_reserve_simulated_compound_interest)
    -  [Arguments](#@Arguments_99)
    -  [Returns](#@Returns_100)
-  [Function `claim_fees`](#suilend_reserve_claim_fees)
    -  [Arguments](#@Arguments_101)
    -  [Returns](#@Returns_102)
    -  [Panics](#@Panics_103)
-  [Function `deposit_liquidity_and_mint_ctokens`](#suilend_reserve_deposit_liquidity_and_mint_ctokens)
    -  [Arguments](#@Arguments_104)
    -  [Returns](#@Returns_105)
    -  [Panics](#@Panics_106)
-  [Function `redeem_ctokens`](#suilend_reserve_redeem_ctokens)
    -  [Arguments](#@Arguments_107)
    -  [Returns](#@Returns_108)
    -  [Panics](#@Panics_109)
-  [Function `fulfill_liquidity_request`](#suilend_reserve_fulfill_liquidity_request)
    -  [Arguments](#@Arguments_110)
    -  [Returns](#@Returns_111)
    -  [Panics](#@Panics_112)
-  [Function `init_staker`](#suilend_reserve_init_staker)
    -  [Arguments](#@Arguments_113)
    -  [Panics](#@Panics_114)
-  [Function `rebalance_staker`](#suilend_reserve_rebalance_staker)
    -  [Arguments](#@Arguments_115)
    -  [Panics](#@Panics_116)
-  [Function `unstake_sui_from_staker`](#suilend_reserve_unstake_sui_from_staker)
    -  [Arguments](#@Arguments_117)
    -  [Panics](#@Panics_118)
-  [Function `borrow_liquidity`](#suilend_reserve_borrow_liquidity)
    -  [Arguments](#@Arguments_119)
    -  [Returns](#@Returns_120)
    -  [Panics](#@Panics_121)
-  [Function `repay_liquidity`](#suilend_reserve_repay_liquidity)
    -  [Arguments](#@Arguments_122)
    -  [Panics](#@Panics_123)
-  [Function `forgive_debt`](#suilend_reserve_forgive_debt)
    -  [Arguments](#@Arguments_124)
-  [Function `deposit_ctokens`](#suilend_reserve_deposit_ctokens)
    -  [Arguments](#@Arguments_125)
    -  [Panics](#@Panics_126)
-  [Function `withdraw_ctokens`](#suilend_reserve_withdraw_ctokens)
    -  [Arguments](#@Arguments_127)
    -  [Returns](#@Returns_128)
    -  [Panics](#@Panics_129)
-  [Function `change_price_feed`](#suilend_reserve_change_price_feed)
    -  [Arguments](#@Arguments_130)
-  [Function `interest_last_update_timestamp_s`](#suilend_reserve_interest_last_update_timestamp_s)
    -  [Arguments](#@Arguments_131)
    -  [Returns](#@Returns_132)
-  [Function `log_reserve_data`](#suilend_reserve_log_reserve_data)
    -  [Arguments](#@Arguments_133)


<pre><code><b>use</b> <a href="../dependencies/liquid_staking/cell.md#liquid_staking_cell">liquid_staking::cell</a>;
<b>use</b> <a href="../dependencies/liquid_staking/events.md#liquid_staking_events">liquid_staking::events</a>;
<b>use</b> <a href="../dependencies/liquid_staking/fees.md#liquid_staking_fees">liquid_staking::fees</a>;
<b>use</b> <a href="../dependencies/liquid_staking/liquid_staking.md#liquid_staking_liquid_staking">liquid_staking::liquid_staking</a>;
<b>use</b> <a href="../dependencies/liquid_staking/storage.md#liquid_staking_storage">liquid_staking::storage</a>;
<b>use</b> <a href="../dependencies/liquid_staking/version.md#liquid_staking_version">liquid_staking::version</a>;
<b>use</b> <a href="../dependencies/pyth/i64.md#pyth_i64">pyth::i64</a>;
<b>use</b> <a href="../dependencies/pyth/price.md#pyth_price">pyth::price</a>;
<b>use</b> <a href="../dependencies/pyth/price_feed.md#pyth_price_feed">pyth::price_feed</a>;
<b>use</b> <a href="../dependencies/pyth/price_identifier.md#pyth_price_identifier">pyth::price_identifier</a>;
<b>use</b> <a href="../dependencies/pyth/price_info.md#pyth_price_info">pyth::price_info</a>;
<b>use</b> <a href="../dependencies/sprungsui/sprungsui.md#sprungsui_sprungsui">sprungsui::sprungsui</a>;
<b>use</b> <a href="../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../dependencies/std/u64.md#std_u64">std::u64</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../dependencies/sui/bag.md#sui_bag">sui::bag</a>;
<b>use</b> <a href="../dependencies/sui/balance.md#sui_balance">sui::balance</a>;
<b>use</b> <a href="../dependencies/sui/clock.md#sui_clock">sui::clock</a>;
<b>use</b> <a href="../dependencies/sui/coin.md#sui_coin">sui::coin</a>;
<b>use</b> <a href="../dependencies/sui/config.md#sui_config">sui::config</a>;
<b>use</b> <a href="../dependencies/sui/deny_list.md#sui_deny_list">sui::deny_list</a>;
<b>use</b> <a href="../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../dependencies/sui/dynamic_object_field.md#sui_dynamic_object_field">sui::dynamic_object_field</a>;
<b>use</b> <a href="../dependencies/sui/event.md#sui_event">sui::event</a>;
<b>use</b> <a href="../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../dependencies/sui/package.md#sui_package">sui::package</a>;
<b>use</b> <a href="../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../dependencies/sui/priority_queue.md#sui_priority_queue">sui::priority_queue</a>;
<b>use</b> <a href="../dependencies/sui/sui.md#sui_sui">sui::sui</a>;
<b>use</b> <a href="../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../dependencies/sui/table_vec.md#sui_table_vec">sui::table_vec</a>;
<b>use</b> <a href="../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
<b>use</b> <a href="../dependencies/sui/versioned.md#sui_versioned">sui::versioned</a>;
<b>use</b> <a href="../dependencies/sui_system/stake_subsidy.md#sui_system_stake_subsidy">sui_system::stake_subsidy</a>;
<b>use</b> <a href="../dependencies/sui_system/staking_pool.md#sui_system_staking_pool">sui_system::staking_pool</a>;
<b>use</b> <a href="../dependencies/sui_system/storage_fund.md#sui_system_storage_fund">sui_system::storage_fund</a>;
<b>use</b> <a href="../dependencies/sui_system/sui_system.md#sui_system_sui_system">sui_system::sui_system</a>;
<b>use</b> <a href="../dependencies/sui_system/sui_system_state_inner.md#sui_system_sui_system_state_inner">sui_system::sui_system_state_inner</a>;
<b>use</b> <a href="../dependencies/sui_system/validator.md#sui_system_validator">sui_system::validator</a>;
<b>use</b> <a href="../dependencies/sui_system/validator_cap.md#sui_system_validator_cap">sui_system::validator_cap</a>;
<b>use</b> <a href="../dependencies/sui_system/validator_set.md#sui_system_validator_set">sui_system::validator_set</a>;
<b>use</b> <a href="../dependencies/sui_system/validator_wrapper.md#sui_system_validator_wrapper">sui_system::validator_wrapper</a>;
<b>use</b> <a href="../dependencies/sui_system/voting_power.md#sui_system_voting_power">sui_system::voting_power</a>;
<b>use</b> <a href="../suilend/cell.md#suilend_cell">suilend::cell</a>;
<b>use</b> <a href="../suilend/decimal.md#suilend_decimal">suilend::decimal</a>;
<b>use</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining">suilend::liquidity_mining</a>;
<b>use</b> <a href="../suilend/oracles.md#suilend_oracles">suilend::oracles</a>;
<b>use</b> <a href="../suilend/reserve_config.md#suilend_reserve_config">suilend::reserve_config</a>;
<b>use</b> <a href="../suilend/staker.md#suilend_staker">suilend::staker</a>;
</code></pre>



<a name="suilend_reserve_Reserve"></a>

## Struct `Reserve`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;<b>phantom</b> P&gt; <b>has</b> key, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>lending_market_id: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_array_index">array_index</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_config">config</a>: <a href="../suilend/cell.md#suilend_cell_Cell">suilend::cell::Cell</a>&lt;<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>mint_decimals: u8</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_price_identifier">price_identifier</a>: <a href="../dependencies/pyth/price_identifier.md#pyth_price_identifier_PriceIdentifier">pyth::price_identifier::PriceIdentifier</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_price">price</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>smoothed_price: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>price_last_update_timestamp_s: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">cumulative_borrow_rate</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_interest_last_update_timestamp_s">interest_last_update_timestamp_s</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>attributed_borrow_value: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 unused
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager">deposits_pool_reward_manager</a>: <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager">borrows_pool_reward_manager</a>: <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_reserve_CToken"></a>

## Struct `CToken`

Interest bearing token on the underlying Coin<T>. The ctoken can be redeemed for
the underlying token + any interest earned.


<pre><code><b>public</b> <b>struct</b> <a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;<b>phantom</b> P, <b>phantom</b> T&gt; <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="suilend_reserve_LiquidityRequest"></a>

## Struct `LiquidityRequest`

A request to withdraw liquidity from the reserve. This is a hot potato object.


<pre><code><b>public</b> <b>struct</b> <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a>&lt;<b>phantom</b> P, <b>phantom</b> T&gt;
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>amount: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>fee: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_reserve_BalanceKey"></a>

## Struct `BalanceKey`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="suilend_reserve_StakerKey"></a>

## Struct `StakerKey`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/reserve.md#suilend_reserve_StakerKey">StakerKey</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="suilend_reserve_Balances"></a>

## Struct `Balances`

Balances are stored in a dynamic field to avoid typing the Reserve with CoinType


<pre><code><b>public</b> <b>struct</b> <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;<b>phantom</b> P, <b>phantom</b> T&gt; <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>: <a href="../dependencies/sui/balance.md#sui_balance_Supply">sui::balance::Supply</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>fees: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>ctoken_fees: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>deposited_ctokens: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_reserve_InterestUpdateEvent"></a>

## Struct `InterestUpdateEvent`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/reserve.md#suilend_reserve_InterestUpdateEvent">InterestUpdateEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>lending_market_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">cumulative_borrow_rate</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>borrow_interest_paid: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>spread_fee: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>supply_interest_earned: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>borrow_interest_paid_usd_estimate: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>protocol_fee_usd_estimate: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>supply_interest_earned_usd_estimate: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_reserve_ReserveAssetDataEvent"></a>

## Struct `ReserveAssetDataEvent`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/reserve.md#suilend_reserve_ReserveAssetDataEvent">ReserveAssetDataEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>lending_market_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>supply_amount: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>available_amount_usd_estimate: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>supply_amount_usd_estimate: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>borrowed_amount_usd_estimate: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>borrow_apr: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>supply_apr: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">cumulative_borrow_rate</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_price">price</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>smoothed_price: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>price_last_update_timestamp_s: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_reserve_ClaimStakingRewardsEvent"></a>

## Struct `ClaimStakingRewardsEvent`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/reserve.md#suilend_reserve_ClaimStakingRewardsEvent">ClaimStakingRewardsEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>lending_market_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>amount: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="suilend_reserve_EPriceStale"></a>



<pre><code><b>const</b> <a href="../suilend/reserve.md#suilend_reserve_EPriceStale">EPriceStale</a>: u64 = 0;
</code></pre>



<a name="suilend_reserve_EPriceIdentifierMismatch"></a>



<pre><code><b>const</b> <a href="../suilend/reserve.md#suilend_reserve_EPriceIdentifierMismatch">EPriceIdentifierMismatch</a>: u64 = 1;
</code></pre>



<a name="suilend_reserve_EDepositLimitExceeded"></a>



<pre><code><b>const</b> <a href="../suilend/reserve.md#suilend_reserve_EDepositLimitExceeded">EDepositLimitExceeded</a>: u64 = 2;
</code></pre>



<a name="suilend_reserve_EBorrowLimitExceeded"></a>



<pre><code><b>const</b> <a href="../suilend/reserve.md#suilend_reserve_EBorrowLimitExceeded">EBorrowLimitExceeded</a>: u64 = 3;
</code></pre>



<a name="suilend_reserve_EInvalidPrice"></a>



<pre><code><b>const</b> <a href="../suilend/reserve.md#suilend_reserve_EInvalidPrice">EInvalidPrice</a>: u64 = 4;
</code></pre>



<a name="suilend_reserve_EMinAvailableAmountViolated"></a>



<pre><code><b>const</b> <a href="../suilend/reserve.md#suilend_reserve_EMinAvailableAmountViolated">EMinAvailableAmountViolated</a>: u64 = 5;
</code></pre>



<a name="suilend_reserve_EInvalidRepayBalance"></a>



<pre><code><b>const</b> <a href="../suilend/reserve.md#suilend_reserve_EInvalidRepayBalance">EInvalidRepayBalance</a>: u64 = 6;
</code></pre>



<a name="suilend_reserve_EWrongType"></a>



<pre><code><b>const</b> <a href="../suilend/reserve.md#suilend_reserve_EWrongType">EWrongType</a>: u64 = 7;
</code></pre>



<a name="suilend_reserve_EStakerAlreadyInitialized"></a>



<pre><code><b>const</b> <a href="../suilend/reserve.md#suilend_reserve_EStakerAlreadyInitialized">EStakerAlreadyInitialized</a>: u64 = 8;
</code></pre>



<a name="suilend_reserve_EStakerNotInitialized"></a>



<pre><code><b>const</b> <a href="../suilend/reserve.md#suilend_reserve_EStakerNotInitialized">EStakerNotInitialized</a>: u64 = 9;
</code></pre>



<a name="suilend_reserve_PRICE_STALENESS_THRESHOLD_S"></a>



<pre><code><b>const</b> <a href="../suilend/reserve.md#suilend_reserve_PRICE_STALENESS_THRESHOLD_S">PRICE_STALENESS_THRESHOLD_S</a>: u64 = 0;
</code></pre>



<a name="suilend_reserve_MIN_AVAILABLE_AMOUNT"></a>



<pre><code><b>const</b> <a href="../suilend/reserve.md#suilend_reserve_MIN_AVAILABLE_AMOUNT">MIN_AVAILABLE_AMOUNT</a>: u64 = 100;
</code></pre>



<a name="suilend_reserve_create_reserve"></a>

## Function `create_reserve`

Creates a new reserve for a lending market.

Initializes a reserve with the specified configuration, price information, and coin type.
Sets up initial balances and pool reward managers for deposits and borrows.


<a name="@Arguments_1"></a>

### Arguments


* <code>lending_market_id</code> - The ID of the lending market associated with the reserve.
* <code><a href="../suilend/reserve.md#suilend_reserve_config">config</a></code> - The <code>ReserveConfig</code> specifying the reserve's parameters.
* <code><a href="../suilend/reserve.md#suilend_reserve_array_index">array_index</a></code> - The index of the reserve in the lending market's reserve array.
* <code>mint_decimals</code> - The number of decimals for the coin type.
* <code>price_info_obj</code> - The price information object for the reserve's oracle.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based calculations.


<a name="@Returns_2"></a>

### Returns


* <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;</code> - A new reserve instance.


<a name="@Panics_3"></a>

### Panics


* If the price information is invalid or missing (<code><a href="../suilend/reserve.md#suilend_reserve_EInvalidPrice">EInvalidPrice</a></code>).


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_create_reserve">create_reserve</a>&lt;P, T&gt;(lending_market_id: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, <a href="../suilend/reserve.md#suilend_reserve_config">config</a>: <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>, <a href="../suilend/reserve.md#suilend_reserve_array_index">array_index</a>: u64, mint_decimals: u8, price_info_obj: &<a href="../dependencies/pyth/price_info.md#pyth_price_info_PriceInfoObject">pyth::price_info::PriceInfoObject</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_create_reserve">create_reserve</a>&lt;P, T&gt;(
    lending_market_id: ID,
    <a href="../suilend/reserve.md#suilend_reserve_config">config</a>: ReserveConfig,
    <a href="../suilend/reserve.md#suilend_reserve_array_index">array_index</a>: u64,
    mint_decimals: u8,
    price_info_obj: &PriceInfoObject,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext
): <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt; {
    <b>let</b> (<b>mut</b> price_decimal, smoothed_price_decimal, <a href="../suilend/reserve.md#suilend_reserve_price_identifier">price_identifier</a>) = <a href="../suilend/oracles.md#suilend_oracles_get_pyth_price_and_identifier">oracles::get_pyth_price_and_identifier</a>(price_info_obj, clock);
    <b>assert</b>!(option::is_some(&price_decimal), <a href="../suilend/reserve.md#suilend_reserve_EInvalidPrice">EInvalidPrice</a>);
    <b>let</b> <b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a> {
        id: object::new(ctx),
        lending_market_id,
        <a href="../suilend/reserve.md#suilend_reserve_array_index">array_index</a>,
        <a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>: type_name::get&lt;T&gt;(),
        <a href="../suilend/reserve.md#suilend_reserve_config">config</a>: <a href="../suilend/cell.md#suilend_cell_new">cell::new</a>(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>),
        mint_decimals,
        <a href="../suilend/reserve.md#suilend_reserve_price_identifier">price_identifier</a>,
        <a href="../suilend/reserve.md#suilend_reserve_price">price</a>: option::extract(&<b>mut</b> price_decimal),
        smoothed_price: smoothed_price_decimal,
        price_last_update_timestamp_s: clock::timestamp_ms(clock) / 1000,
        <a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>: 0,
        <a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>: 0,
        <a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        <a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">cumulative_borrow_rate</a>: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1),
        <a href="../suilend/reserve.md#suilend_reserve_interest_last_update_timestamp_s">interest_last_update_timestamp_s</a>: clock::timestamp_ms(clock) / 1000,
        <a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        attributed_borrow_value: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        <a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager">deposits_pool_reward_manager</a>: <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_new_pool_reward_manager">liquidity_mining::new_pool_reward_manager</a>(ctx),
        <a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager">borrows_pool_reward_manager</a>: <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_new_pool_reward_manager">liquidity_mining::new_pool_reward_manager</a>(ctx)
    };
    dynamic_field::add(
        &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id,
        <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {},
        <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt; {
            <a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>: balance::zero&lt;T&gt;(),
            <a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>: balance::create_supply(<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt; {}),
            fees: balance::zero&lt;T&gt;(),
            ctoken_fees: balance::zero&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt;(),
            deposited_ctokens: balance::zero&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt;()
        }
    );
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>
}
</code></pre>



</details>

<a name="suilend_reserve_price_identifier"></a>

## Function `price_identifier`

Gets the price identifier for the reserve's oracle.


<a name="@Arguments_4"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_5"></a>

### Returns


* <code>&PriceIdentifier</code> - A reference to the reserve's price identifier.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_price_identifier">price_identifier</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): &<a href="../dependencies/pyth/price_identifier.md#pyth_price_identifier_PriceIdentifier">pyth::price_identifier::PriceIdentifier</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_price_identifier">price_identifier</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): &PriceIdentifier {
    &<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_price_identifier">price_identifier</a>
}
</code></pre>



</details>

<a name="suilend_reserve_borrows_pool_reward_manager"></a>

## Function `borrows_pool_reward_manager`

Gets the pool reward manager for deposits.


<a name="@Arguments_6"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_7"></a>

### Returns


* <code>&PoolRewardManager</code> - A reference to the deposits pool reward manager.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager">borrows_pool_reward_manager</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager">borrows_pool_reward_manager</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): &PoolRewardManager {
    &<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager">borrows_pool_reward_manager</a>
}
</code></pre>



</details>

<a name="suilend_reserve_deposits_pool_reward_manager"></a>

## Function `deposits_pool_reward_manager`

Gets the pool reward manager for borrows.


<a name="@Arguments_8"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_9"></a>

### Returns


* <code>&PoolRewardManager</code> - A reference to the borrows pool reward manager.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager">deposits_pool_reward_manager</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager">deposits_pool_reward_manager</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): &PoolRewardManager {
    &<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager">deposits_pool_reward_manager</a>
}
</code></pre>



</details>

<a name="suilend_reserve_array_index"></a>

## Function `array_index`

Gets the array index of the reserve in the lending market's reserve array.


<a name="@Arguments_10"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_11"></a>

### Returns


* <code>u64</code> - The array index of the reserve.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_array_index">array_index</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_array_index">array_index</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): u64 {
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_array_index">array_index</a>
}
</code></pre>



</details>

<a name="suilend_reserve_available_amount"></a>

## Function `available_amount`

Gets the available amount of tokens in the reserve.


<a name="@Arguments_12"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_13"></a>

### Returns


* <code>u64</code> - The available amount of tokens.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): u64 {
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>
}
</code></pre>



</details>

<a name="suilend_reserve_borrowed_amount"></a>

## Function `borrowed_amount`

Gets the total borrowed amount in the reserve.


<a name="@Arguments_14"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_15"></a>

### Returns


* <code>Decimal</code> - The total borrowed amount as a decimal.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): Decimal {
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>
}
</code></pre>



</details>

<a name="suilend_reserve_coin_type"></a>

## Function `coin_type`

Gets the coin type of the reserve.


<a name="@Arguments_16"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_17"></a>

### Returns


* <code>TypeName</code> - The coin type of the reserve.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): TypeName {
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>
}
</code></pre>



</details>

<a name="suilend_reserve_assert_price_is_fresh"></a>

## Function `assert_price_is_fresh`

Asserts that the reserve's price is fresh based on the staleness threshold.


<a name="@Arguments_18"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to check.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based validation.


<a name="@Panics_19"></a>

### Panics


* If the price is stale based on the <code><a href="../suilend/reserve.md#suilend_reserve_PRICE_STALENESS_THRESHOLD_S">PRICE_STALENESS_THRESHOLD_S</a></code> (<code><a href="../suilend/reserve.md#suilend_reserve_EPriceStale">EPriceStale</a></code>).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_assert_price_is_fresh">assert_price_is_fresh</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_assert_price_is_fresh">assert_price_is_fresh</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;, clock: &Clock) {
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_is_price_fresh">is_price_fresh</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock), <a href="../suilend/reserve.md#suilend_reserve_EPriceStale">EPriceStale</a>);
}
</code></pre>



</details>

<a name="suilend_reserve_is_price_fresh"></a>

## Function `is_price_fresh`

Checks if the reserve's price is fresh based on the staleness threshold.


<a name="@Arguments_20"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to check.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based validation.


<a name="@Returns_21"></a>

### Returns


* <code>bool</code> - True if the price is fresh, false otherwise.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_is_price_fresh">is_price_fresh</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_is_price_fresh">is_price_fresh</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;, clock: &Clock): bool {
    <b>let</b> cur_time_s = clock::timestamp_ms(clock) / 1000;
    cur_time_s - <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.price_last_update_timestamp_s &lt;= <a href="../suilend/reserve.md#suilend_reserve_PRICE_STALENESS_THRESHOLD_S">PRICE_STALENESS_THRESHOLD_S</a>
}
</code></pre>



</details>

<a name="suilend_reserve_price"></a>

## Function `price`

Gets the current price of the reserve's underlying asset.


<a name="@Arguments_22"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_23"></a>

### Returns


* <code>Decimal</code> - The current price as a decimal.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_price">price</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_price">price</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): Decimal {
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_price">price</a>
}
</code></pre>



</details>

<a name="suilend_reserve_price_lower_bound"></a>

## Function `price_lower_bound`

Gets the lower bound of the reserve's price (minimum of price and smoothed price).


<a name="@Arguments_24"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_25"></a>

### Returns


* <code>Decimal</code> - The lower bound price as a decimal.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_price_lower_bound">price_lower_bound</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_price_lower_bound">price_lower_bound</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): Decimal {
    min(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_price">price</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.smoothed_price)
}
</code></pre>



</details>

<a name="suilend_reserve_price_upper_bound"></a>

## Function `price_upper_bound`

Gets the upper bound of the reserve's price (maximum of price and smoothed price).


<a name="@Arguments_26"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_27"></a>

### Returns


* <code>Decimal</code> - The upper bound price as a decimal.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_price_upper_bound">price_upper_bound</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_price_upper_bound">price_upper_bound</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): Decimal {
    max(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_price">price</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.smoothed_price)
}
</code></pre>



</details>

<a name="suilend_reserve_market_value"></a>

## Function `market_value`

Calculates the market value of a given liquidity amount in USD.


<a name="@Arguments_28"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.
* <code>liquidity_amount</code> - The amount of liquidity as a decimal.


<a name="@Returns_29"></a>

### Returns


* <code>Decimal</code> - The market value in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_market_value">market_value</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, liquidity_amount: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_market_value">market_value</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    liquidity_amount: Decimal
): Decimal {
    div(
        mul(
            <a href="../suilend/reserve.md#suilend_reserve_price">price</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
            liquidity_amount
        ),
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../dependencies/std/u64.md#std_u64_pow">std::u64::pow</a>(10, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.mint_decimals))
    )
}
</code></pre>



</details>

<a name="suilend_reserve_market_value_lower_bound"></a>

## Function `market_value_lower_bound`

Calculates the lower bound market value of a given liquidity amount in USD.


<a name="@Arguments_30"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.
* <code>liquidity_amount</code> - The amount of liquidity as a decimal.


<a name="@Returns_31"></a>

### Returns


* <code>Decimal</code> - The lower bound market value in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_market_value_lower_bound">market_value_lower_bound</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, liquidity_amount: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_market_value_lower_bound">market_value_lower_bound</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    liquidity_amount: Decimal
): Decimal {
    div(
        mul(
            <a href="../suilend/reserve.md#suilend_reserve_price_lower_bound">price_lower_bound</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
            liquidity_amount
        ),
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../dependencies/std/u64.md#std_u64_pow">std::u64::pow</a>(10, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.mint_decimals))
    )
}
</code></pre>



</details>

<a name="suilend_reserve_market_value_upper_bound"></a>

## Function `market_value_upper_bound`

Calculates the upper bound market value of a given liquidity amount in USD.


<a name="@Arguments_32"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.
* <code>liquidity_amount</code> - The amount of liquidity as a decimal.


<a name="@Returns_33"></a>

### Returns


* <code>Decimal</code> - The upper bound market value in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_market_value_upper_bound">market_value_upper_bound</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, liquidity_amount: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_market_value_upper_bound">market_value_upper_bound</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    liquidity_amount: Decimal
): Decimal {
    div(
        mul(
            <a href="../suilend/reserve.md#suilend_reserve_price_upper_bound">price_upper_bound</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
            liquidity_amount
        ),
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../dependencies/std/u64.md#std_u64_pow">std::u64::pow</a>(10, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.mint_decimals))
    )
}
</code></pre>



</details>

<a name="suilend_reserve_ctoken_market_value"></a>

## Function `ctoken_market_value`

Calculates the market value of a given ctoken amount in USD.


<a name="@Arguments_34"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.
* <code>ctoken_amount</code> - The amount of ctokens.


<a name="@Returns_35"></a>

### Returns


* <code>Decimal</code> - The market value in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_ctoken_market_value">ctoken_market_value</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, ctoken_amount: u64): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_ctoken_market_value">ctoken_market_value</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    ctoken_amount: u64
): Decimal {
    // TODO should i floor here?
    <b>let</b> liquidity_amount = mul(
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(ctoken_amount),
        <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">ctoken_ratio</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    );
    <a href="../suilend/reserve.md#suilend_reserve_market_value">market_value</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, liquidity_amount)
}
</code></pre>



</details>

<a name="suilend_reserve_ctoken_market_value_lower_bound"></a>

## Function `ctoken_market_value_lower_bound`

Calculates the lower bound market value of a given ctoken amount in USD.


<a name="@Arguments_36"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.
* <code>ctoken_amount</code> - The amount of ctokens.


<a name="@Returns_37"></a>

### Returns


* <code>Decimal</code> - The lower bound market value in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_ctoken_market_value_lower_bound">ctoken_market_value_lower_bound</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, ctoken_amount: u64): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_ctoken_market_value_lower_bound">ctoken_market_value_lower_bound</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    ctoken_amount: u64
): Decimal {
    // TODO should i floor here?
    <b>let</b> liquidity_amount = mul(
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(ctoken_amount),
        <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">ctoken_ratio</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    );
    <a href="../suilend/reserve.md#suilend_reserve_market_value_lower_bound">market_value_lower_bound</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, liquidity_amount)
}
</code></pre>



</details>

<a name="suilend_reserve_ctoken_market_value_upper_bound"></a>

## Function `ctoken_market_value_upper_bound`

Calculates the upper bound market value of a given ctoken amount in USD.


<a name="@Arguments_38"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.
* <code>ctoken_amount</code> - The amount of ctokens.


<a name="@Returns_39"></a>

### Returns


* <code>Decimal</code> - The upper bound market value in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_ctoken_market_value_upper_bound">ctoken_market_value_upper_bound</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, ctoken_amount: u64): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_ctoken_market_value_upper_bound">ctoken_market_value_upper_bound</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    ctoken_amount: u64
): Decimal {
    // TODO should i floor here?
    <b>let</b> liquidity_amount = mul(
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(ctoken_amount),
        <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">ctoken_ratio</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    );
    <a href="../suilend/reserve.md#suilend_reserve_market_value_upper_bound">market_value_upper_bound</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, liquidity_amount)
}
</code></pre>



</details>

<a name="suilend_reserve_usd_to_token_amount_lower_bound"></a>

## Function `usd_to_token_amount_lower_bound`

Converts a USD amount to the equivalent token amount using the lower bound price.
E.g. how much sui can i get for 1000 USDC


<a name="@Arguments_40"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.
* <code>usd_amount</code> - The USD amount to convert.


<a name="@Returns_41"></a>

### Returns


* <code>Decimal</code> - The equivalent token amount.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_usd_to_token_amount_lower_bound">usd_to_token_amount_lower_bound</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, usd_amount: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_usd_to_token_amount_lower_bound">usd_to_token_amount_lower_bound</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    usd_amount: Decimal
): Decimal {
    div(
        mul(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../dependencies/std/u64.md#std_u64_pow">std::u64::pow</a>(10, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.mint_decimals)),
            usd_amount
        ),
        <a href="../suilend/reserve.md#suilend_reserve_price_upper_bound">price_upper_bound</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    )
}
</code></pre>



</details>

<a name="suilend_reserve_usd_to_token_amount_upper_bound"></a>

## Function `usd_to_token_amount_upper_bound`

Converts a USD amount to the equivalent token amount using the upper bound price.


<a name="@Arguments_42"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.
* <code>usd_amount</code> - The USD amount to convert.


<a name="@Returns_43"></a>

### Returns


* <code>Decimal</code> - The equivalent token amount.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_usd_to_token_amount_upper_bound">usd_to_token_amount_upper_bound</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, usd_amount: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_usd_to_token_amount_upper_bound">usd_to_token_amount_upper_bound</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    usd_amount: Decimal
): Decimal {
    div(
        mul(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../dependencies/std/u64.md#std_u64_pow">std::u64::pow</a>(10, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.mint_decimals)),
            usd_amount
        ),
        <a href="../suilend/reserve.md#suilend_reserve_price_lower_bound">price_lower_bound</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    )
}
</code></pre>



</details>

<a name="suilend_reserve_cumulative_borrow_rate"></a>

## Function `cumulative_borrow_rate`

Gets the cumulative borrow rate of the reserve.


<a name="@Arguments_44"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_45"></a>

### Returns


* <code>Decimal</code> - The cumulative borrow rate as a decimal.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">cumulative_borrow_rate</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">cumulative_borrow_rate</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): Decimal {
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">cumulative_borrow_rate</a>
}
</code></pre>



</details>

<a name="suilend_reserve_total_supply"></a>

## Function `total_supply`

Calculates the total supply of the reserve, excluding unclaimed spread fees.


<a name="@Arguments_46"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_47"></a>

### Returns


* <code>Decimal</code> - The total supply as a decimal.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_total_supply">total_supply</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_total_supply">total_supply</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): Decimal {
    sub(
        add(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>),
            <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>
        ),
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>
    )
}
</code></pre>



</details>

<a name="suilend_reserve_simulated_total_supply"></a>

## Function `simulated_total_supply`

Simulates the total supply of the reserve with compounded interest.


<a name="@Arguments_48"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based calculations.


<a name="@Returns_49"></a>

### Returns


* <code>Decimal</code> - The simulated total supply as a decimal.


<pre><code><b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_simulated_total_supply">simulated_total_supply</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_simulated_total_supply">simulated_total_supply</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;, clock: &Clock): Decimal {
    <b>let</b> (
        <a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>,
        <a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>,
    ) = <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_simulated_compound_interest">simulated_compound_interest</a>(clock);
    sub(
        add(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>),
            <a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>
        ),
        <a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>
    )
}
</code></pre>



</details>

<a name="suilend_reserve_calculate_utilization_rate"></a>

## Function `calculate_utilization_rate`

Calculates the utilization rate of the reserve.


<a name="@Arguments_50"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_51"></a>

### Returns


* <code>Decimal</code> - The utilization rate as a decimal (0 to 1).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_calculate_utilization_rate">calculate_utilization_rate</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_calculate_utilization_rate">calculate_utilization_rate</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): Decimal {
    <b>let</b> total_supply_excluding_fees = add(
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>),
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>
    );
    <b>if</b> (eq(total_supply_excluding_fees, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0))) {
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0)
    }
    <b>else</b> {
        div(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>, total_supply_excluding_fees)
    }
}
</code></pre>



</details>

<a name="suilend_reserve_ctoken_ratio"></a>

## Function `ctoken_ratio`

Calculates the ctoken ratio (tokens per ctoken).
Always greater than or equal to one.


<a name="@Arguments_52"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_53"></a>

### Returns


* <code>Decimal</code> - The ctoken ratio as a decimal (at least 1).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">ctoken_ratio</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">ctoken_ratio</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): Decimal {
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_total_supply">total_supply</a> = <a href="../suilend/reserve.md#suilend_reserve_total_supply">total_supply</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    // this branch is only used once -- when the <a href="../suilend/reserve.md#suilend_reserve">reserve</a> is first initialized and <b>has</b>
    // zero deposits. after that, borrows and redemptions won't <b>let</b> the ctoken supply fall
    // below <a href="../suilend/reserve.md#suilend_reserve_MIN_AVAILABLE_AMOUNT">MIN_AVAILABLE_AMOUNT</a>
    <b>if</b> (<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a> == 0) {
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1)
    }
    <b>else</b> {
        div(
            <a href="../suilend/reserve.md#suilend_reserve_total_supply">total_supply</a>,
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>)
        )
    }
}
</code></pre>



</details>

<a name="suilend_reserve_simulated_ctoken_ratio"></a>

## Function `simulated_ctoken_ratio`

Simulates the ctoken ratio with compounded interest.


<a name="@Arguments_54"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based calculations.


<a name="@Returns_55"></a>

### Returns


* <code>Decimal</code> - The simulated ctoken ratio as a decimal (at least 1).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_simulated_ctoken_ratio">simulated_ctoken_ratio</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_simulated_ctoken_ratio">simulated_ctoken_ratio</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;, clock: &Clock): Decimal {
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_total_supply">total_supply</a> = <a href="../suilend/reserve.md#suilend_reserve_simulated_total_supply">simulated_total_supply</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock);
    // this branch is only used once -- when the <a href="../suilend/reserve.md#suilend_reserve">reserve</a> is first initialized and <b>has</b>
    // zero deposits. after that, borrows and redemptions won't <b>let</b> the ctoken supply fall
    // below <a href="../suilend/reserve.md#suilend_reserve_MIN_AVAILABLE_AMOUNT">MIN_AVAILABLE_AMOUNT</a>
    <b>if</b> (<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a> == 0) {
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1)
    }
    <b>else</b> {
        div(
            <a href="../suilend/reserve.md#suilend_reserve_total_supply">total_supply</a>,
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>)
        )
    }
}
</code></pre>



</details>

<a name="suilend_reserve_config"></a>

## Function `config`

Gets the reserve's configuration.


<a name="@Arguments_56"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_57"></a>

### Returns


* <code>&ReserveConfig</code> - A reference to the reserve's configuration.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_config">config</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_config">config</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): &ReserveConfig {
    <a href="../suilend/cell.md#suilend_cell_get">cell::get</a>(&<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_config">config</a>)
}
</code></pre>



</details>

<a name="suilend_reserve_calculate_borrow_fee"></a>

## Function `calculate_borrow_fee`

Calculates the borrow fee for a given amount.


<a name="@Arguments_58"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.
* <code>borrow_amount</code> - The amount to borrow.


<a name="@Returns_59"></a>

### Returns


* <code>u64</code> - The borrow fee in token units, ceilinged to the nearest integer.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_calculate_borrow_fee">calculate_borrow_fee</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, borrow_amount: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_calculate_borrow_fee">calculate_borrow_fee</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    borrow_amount: u64
): u64 {
    ceil(mul(<a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(borrow_amount), borrow_fee(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>))))
}
</code></pre>



</details>

<a name="suilend_reserve_max_borrow_amount"></a>

## Function `max_borrow_amount`

Calculates the maximum amount that can be borrowed from the reserve.
Aaximum amount that can be borrowed from the reserve. does not account for fees!

Accounts for available amount, borrow limit, and USD borrow limit, excluding fees.


<a name="@Arguments_60"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_61"></a>

### Returns


* <code>u64</code> - The maximum borrowable amount in token units.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_max_borrow_amount">max_borrow_amount</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_max_borrow_amount">max_borrow_amount</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): u64 {
    floor(min(
        saturating_sub(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>),
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/reserve.md#suilend_reserve_MIN_AVAILABLE_AMOUNT">MIN_AVAILABLE_AMOUNT</a>)
        ),
        min(
            // borrow limit
            saturating_sub(
                <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(borrow_limit(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>))),
                <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>
            ),
            // usd borrow limit
            <a href="../suilend/reserve.md#suilend_reserve_usd_to_token_amount_lower_bound">usd_to_token_amount_lower_bound</a>(
                <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
                saturating_sub(
                    <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(borrow_limit_usd(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>))),
                    <a href="../suilend/reserve.md#suilend_reserve_market_value_upper_bound">market_value_upper_bound</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>)
                )
            )
        )
    ))
}
</code></pre>



</details>

<a name="suilend_reserve_max_redeem_amount"></a>

## Function `max_redeem_amount`

Calculates the maximum amount of ctokens that can be redeemed.


<a name="@Arguments_62"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_63"></a>

### Returns


* <code>u64</code> - The maximum redeemable ctoken amount.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_max_redeem_amount">max_redeem_amount</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_max_redeem_amount">max_redeem_amount</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): u64 {
    floor(div(
        sub(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>),
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/reserve.md#suilend_reserve_MIN_AVAILABLE_AMOUNT">MIN_AVAILABLE_AMOUNT</a>)
        ),
        <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">ctoken_ratio</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    ))
}
</code></pre>



</details>

<a name="suilend_reserve_ctoken_supply"></a>

## Function `ctoken_supply`

Gets the total ctoken supply of the reserve.


<a name="@Arguments_64"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_65"></a>

### Returns


* <code>u64</code> - The total ctoken supply.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): u64 {
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>
}
</code></pre>



</details>

<a name="suilend_reserve_unclaimed_spread_fees"></a>

## Function `unclaimed_spread_fees`

Gets the unclaimed spread fees of the reserve.


<a name="@Arguments_66"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_67"></a>

### Returns


* <code>Decimal</code> - The unclaimed spread fees as a decimal.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): Decimal {
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>
}
</code></pre>



</details>

<a name="suilend_reserve_balances"></a>

## Function `balances`

Gets the balances of the reserve.


<a name="@Arguments_68"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_69"></a>

### Returns


* <code>&<a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt;</code> - A reference to the reserve's balances.


<a name="@Panics_70"></a>

### Panics


* If the <code><a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a></code> dynamic field is not found.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): &<a href="../suilend/reserve.md#suilend_reserve_Balances">suilend::reserve::Balances</a>&lt;P, T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): &<a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt; {
    dynamic_field::borrow(&<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {})
}
</code></pre>



</details>

<a name="suilend_reserve_balances_available_amount"></a>

## Function `balances_available_amount`

Gets the available amount balance from the reserve's balances.


<a name="@Arguments_71"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve_balances">balances</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a></code> struct.


<a name="@Returns_72"></a>

### Returns


* <code>&Balance&lt;T&gt;</code> - A reference to the available amount balance.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_balances_available_amount">balances_available_amount</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<a href="../suilend/reserve.md#suilend_reserve_Balances">suilend::reserve::Balances</a>&lt;P, T&gt;): &<a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_balances_available_amount">balances_available_amount</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt;): &Balance&lt;T&gt; {
    &<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>
}
</code></pre>



</details>

<a name="suilend_reserve_balances_ctoken_supply"></a>

## Function `balances_ctoken_supply`

Gets the ctoken supply from the reserve's balances.


<a name="@Arguments_73"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve_balances">balances</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a></code> struct.


<a name="@Returns_74"></a>

### Returns


* <code>&Supply&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt;</code> - A reference to the ctoken supply.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_balances_ctoken_supply">balances_ctoken_supply</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<a href="../suilend/reserve.md#suilend_reserve_Balances">suilend::reserve::Balances</a>&lt;P, T&gt;): &<a href="../dependencies/sui/balance.md#sui_balance_Supply">sui::balance::Supply</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_balances_ctoken_supply">balances_ctoken_supply</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt;): &Supply&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt; {
    &<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>
}
</code></pre>



</details>

<a name="suilend_reserve_balances_fees"></a>

## Function `balances_fees`

Gets the fees balance from the reserve's balances.


<a name="@Arguments_75"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve_balances">balances</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a></code> struct.


<a name="@Returns_76"></a>

### Returns


* <code>&Balance&lt;T&gt;</code> - A reference to the fees balance.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_balances_fees">balances_fees</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<a href="../suilend/reserve.md#suilend_reserve_Balances">suilend::reserve::Balances</a>&lt;P, T&gt;): &<a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_balances_fees">balances_fees</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt;): &Balance&lt;T&gt; {
    &<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.fees
}
</code></pre>



</details>

<a name="suilend_reserve_balances_ctoken_fees"></a>

## Function `balances_ctoken_fees`

Gets the ctoken fees balance from the reserve's balances.


<a name="@Arguments_77"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve_balances">balances</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a></code> struct.


<a name="@Returns_78"></a>

### Returns


* <code>&Balance&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt;</code> - A reference to the ctoken fees balance.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_balances_ctoken_fees">balances_ctoken_fees</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<a href="../suilend/reserve.md#suilend_reserve_Balances">suilend::reserve::Balances</a>&lt;P, T&gt;): &<a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_balances_ctoken_fees">balances_ctoken_fees</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt;): &Balance&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt; {
    &<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.ctoken_fees
}
</code></pre>



</details>

<a name="suilend_reserve_liquidity_request_amount"></a>

## Function `liquidity_request_amount`

Gets the amount from a liquidity request.


<a name="@Arguments_79"></a>

### Arguments


* <code>request</code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a></code> to query.


<a name="@Returns_80"></a>

### Returns


* <code>u64</code> - The amount in the liquidity request (includes fee).


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_liquidity_request_amount">liquidity_request_amount</a>&lt;P, T&gt;(request: &<a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">suilend::reserve::LiquidityRequest</a>&lt;P, T&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_liquidity_request_amount">liquidity_request_amount</a>&lt;P, T&gt;(request: &<a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a>&lt;P, T&gt;): u64 {
    request.amount
}
</code></pre>



</details>

<a name="suilend_reserve_liquidity_request_fee"></a>

## Function `liquidity_request_fee`

Gets the fee from a liquidity request.


<a name="@Arguments_81"></a>

### Arguments


* <code>request</code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a></code> to query.


<a name="@Returns_82"></a>

### Returns


* <code>u64</code> - The fee in the liquidity request.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_liquidity_request_fee">liquidity_request_fee</a>&lt;P, T&gt;(request: &<a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">suilend::reserve::LiquidityRequest</a>&lt;P, T&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_liquidity_request_fee">liquidity_request_fee</a>&lt;P, T&gt;(request: &<a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a>&lt;P, T&gt;): u64 {
    request.fee
}
</code></pre>



</details>

<a name="suilend_reserve_staker"></a>

## Function `staker`

Gets the staker associated with the reserve.


<a name="@Arguments_83"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_84"></a>

### Returns


* <code>&Staker&lt;S&gt;</code> - A reference to the staker.


<a name="@Panics_85"></a>

### Panics


* If the <code><a href="../suilend/reserve.md#suilend_reserve_StakerKey">StakerKey</a></code> dynamic field is not found.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/staker.md#suilend_staker">staker</a>&lt;P, S&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): &<a href="../suilend/staker.md#suilend_staker_Staker">suilend::staker::Staker</a>&lt;S&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/staker.md#suilend_staker">staker</a>&lt;P, S&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): &Staker&lt;S&gt; {
    dynamic_field::borrow(&<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_StakerKey">StakerKey</a> {})
}
</code></pre>



</details>

<a name="suilend_reserve_deposits_pool_reward_manager_mut"></a>

## Function `deposits_pool_reward_manager_mut`

Gets a mutable reference to the deposits pool reward manager.


<a name="@Arguments_86"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.


<a name="@Returns_87"></a>

### Returns


* <code>&<b>mut</b> PoolRewardManager</code> - A mutable reference to the deposits pool reward manager.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager_mut">deposits_pool_reward_manager_mut</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager_mut">deposits_pool_reward_manager_mut</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): &<b>mut</b> PoolRewardManager {
    &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager">deposits_pool_reward_manager</a>
}
</code></pre>



</details>

<a name="suilend_reserve_borrows_pool_reward_manager_mut"></a>

## Function `borrows_pool_reward_manager_mut`

Gets a mutable reference to the borrows pool reward manager.


<a name="@Arguments_88"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.


<a name="@Returns_89"></a>

### Returns


* <code>&<b>mut</b> PoolRewardManager</code> - A mutable reference to the borrows pool reward manager.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager_mut">borrows_pool_reward_manager_mut</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager_mut">borrows_pool_reward_manager_mut</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): &<b>mut</b> PoolRewardManager {
    &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager">borrows_pool_reward_manager</a>
}
</code></pre>



</details>

<a name="suilend_reserve_deduct_liquidation_fee"></a>

## Function `deduct_liquidation_fee`

Deducts liquidation fees from ctokens during liquidation.

Splits the ctoken amount into protocol fees and liquidator bonus based on configuration.


<a name="@Arguments_90"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>ctokens</code> - A mutable reference to the ctoken balance to deduct from.


<a name="@Returns_91"></a>

### Returns


* <code>(u64, u64)</code> - A tuple containing the protocol fee amount and liquidator bonus amount.


<a name="@Panics_92"></a>

### Panics


* If the <code><a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a></code> dynamic field is not found.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_deduct_liquidation_fee">deduct_liquidation_fee</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, ctokens: &<b>mut</b> <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_deduct_liquidation_fee">deduct_liquidation_fee</a>&lt;P, T&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    ctokens: &<b>mut</b> Balance&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt;,
): (u64, u64) {
    <b>let</b> bonus = liquidation_bonus(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>));
    <b>let</b> protocol_liquidation_fee = protocol_liquidation_fee(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>));
    <b>let</b> take_rate = div(
        protocol_liquidation_fee,
        add(add(<a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1), bonus), protocol_liquidation_fee)
    );
    <b>let</b> protocol_fee_amount = ceil(mul(take_rate, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(balance::value(ctokens))));
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt; = dynamic_field::borrow_mut(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {});
    balance::join(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.ctoken_fees, balance::split(ctokens, protocol_fee_amount));
    <b>let</b> bonus_rate = div(
        bonus,
        add(add(<a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1), bonus), protocol_liquidation_fee)
    );
    <b>let</b> liquidator_bonus_amount = ceil(mul(bonus_rate, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(balance::value(ctokens))));
    (protocol_fee_amount, liquidator_bonus_amount)
}
</code></pre>



</details>

<a name="suilend_reserve_join_fees"></a>

## Function `join_fees`

Joins fees to the reserve's fee balance.


<a name="@Arguments_93"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>fees</code> - The balance of fees to join.


<a name="@Panics_94"></a>

### Panics


* If the <code><a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a></code> dynamic field is not found.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_join_fees">join_fees</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, fees: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_join_fees">join_fees</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;, fees: Balance&lt;T&gt;) {
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt; = dynamic_field::borrow_mut(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {});
    balance::join(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.fees, fees);
}
</code></pre>



</details>

<a name="suilend_reserve_update_reserve_config"></a>

## Function `update_reserve_config`

Updates the reserve's configuration.

Replaces the current configuration with a new one and destroys the old configuration.


<a name="@Arguments_95"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code><a href="../suilend/reserve.md#suilend_reserve_config">config</a></code> - The new <code>ReserveConfig</code> to set.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_update_reserve_config">update_reserve_config</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve_config">config</a>: <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_update_reserve_config">update_reserve_config</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve_config">config</a>: ReserveConfig,
) {
    <b>let</b> old = <a href="../suilend/cell.md#suilend_cell_set">cell::set</a>(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_config">config</a>, <a href="../suilend/reserve.md#suilend_reserve_config">config</a>);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_destroy">reserve_config::destroy</a>(old);
}
</code></pre>



</details>

<a name="suilend_reserve_update_price"></a>

## Function `update_price`

Updates the reserve's price using the provided price information.


<a name="@Arguments_96"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based calculations.
* <code>price_info_obj</code> - The price information object to update from.


<a name="@Panics_97"></a>

### Panics


* If the price identifier does not match the reserve's (<code><a href="../suilend/reserve.md#suilend_reserve_EPriceIdentifierMismatch">EPriceIdentifierMismatch</a></code>).
* If the price information is invalid or missing (<code><a href="../suilend/reserve.md#suilend_reserve_EInvalidPrice">EInvalidPrice</a></code>).


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_update_price">update_price</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, price_info_obj: &<a href="../dependencies/pyth/price_info.md#pyth_price_info_PriceInfoObject">pyth::price_info::PriceInfoObject</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_update_price">update_price</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    clock: &Clock,
    price_info_obj: &PriceInfoObject
) {
    <b>let</b> (<b>mut</b> price_decimal, ema_price_decimal, <a href="../suilend/reserve.md#suilend_reserve_price_identifier">price_identifier</a>) = <a href="../suilend/oracles.md#suilend_oracles_get_pyth_price_and_identifier">oracles::get_pyth_price_and_identifier</a>(price_info_obj, clock);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_price_identifier">price_identifier</a> == <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_price_identifier">price_identifier</a>, <a href="../suilend/reserve.md#suilend_reserve_EPriceIdentifierMismatch">EPriceIdentifierMismatch</a>);
    <b>assert</b>!(option::is_some(&price_decimal), <a href="../suilend/reserve.md#suilend_reserve_EInvalidPrice">EInvalidPrice</a>);
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_price">price</a> = option::extract(&<b>mut</b> price_decimal);
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.smoothed_price = ema_price_decimal;
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.price_last_update_timestamp_s = clock::timestamp_ms(clock) / 1000;
}
</code></pre>



</details>

<a name="suilend_reserve_compound_interest"></a>

## Function `compound_interest`

Compounds interest and debt for the reserve.

Updates the cumulative borrow rate, borrowed amount, and unclaimed spread fees based
on the elapsed time and APR.


<a name="@Arguments_98"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based calculations.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_compound_interest">compound_interest</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_compound_interest">compound_interest</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;, clock: &Clock) {
    <b>let</b> cur_time_s = clock::timestamp_ms(clock) / 1000;
    <b>let</b> time_elapsed_s = cur_time_s - <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_interest_last_update_timestamp_s">interest_last_update_timestamp_s</a>;
    <b>if</b> (time_elapsed_s == 0) {
        <b>return</b>
    };
    // I(t + n) = I(t) * (1 + apr()/SECONDS_IN_YEAR) ^ n
    <b>let</b> utilization_rate = <a href="../suilend/reserve.md#suilend_reserve_calculate_utilization_rate">calculate_utilization_rate</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>let</b> compounded_borrow_rate = pow(
        add(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1),
            div(
                calculate_apr(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>), utilization_rate),
                <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(365 * 24 * 60 * 60)
            )
        ),
        time_elapsed_s
    );
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">cumulative_borrow_rate</a> = mul(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">cumulative_borrow_rate</a>,
        compounded_borrow_rate
    );
    <b>let</b> net_new_debt = mul(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>,
        sub(compounded_borrow_rate, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1))
    );
    <b>let</b> spread_fee = mul(net_new_debt, spread_fee(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)));
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a> = add(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>,
        spread_fee
    );
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a> = add(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>,
        net_new_debt
    );
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_interest_last_update_timestamp_s">interest_last_update_timestamp_s</a> = cur_time_s;
    event::emit(<a href="../suilend/reserve.md#suilend_reserve_InterestUpdateEvent">InterestUpdateEvent</a> {
        lending_market_id: object::id_to_address(&<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.lending_market_id),
        <a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>,
        reserve_id: object::uid_to_address(&<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id),
        <a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">cumulative_borrow_rate</a>: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">cumulative_borrow_rate</a>,
        <a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>,
        <a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>,
        <a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>,
        <a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>,
        borrow_interest_paid: net_new_debt,
        spread_fee: spread_fee,
        supply_interest_earned: sub(net_new_debt, spread_fee),
        borrow_interest_paid_usd_estimate: <a href="../suilend/reserve.md#suilend_reserve_market_value">market_value</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, net_new_debt),
        protocol_fee_usd_estimate: <a href="../suilend/reserve.md#suilend_reserve_market_value">market_value</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, spread_fee),
        supply_interest_earned_usd_estimate: <a href="../suilend/reserve.md#suilend_reserve_market_value">market_value</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, sub(net_new_debt, spread_fee)),
    });
}
</code></pre>



</details>

<a name="suilend_reserve_simulated_compound_interest"></a>

## Function `simulated_compound_interest`

Simulates compounding interest and debt for the reserve.

Calculates the updated borrowed amount and unclaimed spread fees without modifying the reserve.


<a name="@Arguments_99"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based calculations.


<a name="@Returns_100"></a>

### Returns


* <code>(Decimal, Decimal)</code> - A tuple containing the simulated borrowed amount and unclaimed spread fees.


<pre><code><b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_simulated_compound_interest">simulated_compound_interest</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (<a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_simulated_compound_interest">simulated_compound_interest</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;, clock: &Clock): (Decimal, Decimal) {
    <b>let</b> cur_time_s = clock::timestamp_ms(clock) / 1000;
    <b>let</b> time_elapsed_s = cur_time_s - <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_interest_last_update_timestamp_s">interest_last_update_timestamp_s</a>;
    <b>if</b> (time_elapsed_s == 0) {
        <b>return</b> (
            <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>,
            <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>
        )
    };
    // I(t + n) = I(t) * (1 + apr()/SECONDS_IN_YEAR) ^ n
    <b>let</b> utilization_rate = <a href="../suilend/reserve.md#suilend_reserve_calculate_utilization_rate">calculate_utilization_rate</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>let</b> compounded_borrow_rate = pow(
        add(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1),
            div(
                calculate_apr(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>), utilization_rate),
                <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(365 * 24 * 60 * 60)
            )
        ),
        time_elapsed_s
    );
    <b>let</b> net_new_debt = mul(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>,
        sub(compounded_borrow_rate, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1))
    );
    <b>let</b> spread_fee = mul(net_new_debt, spread_fee(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)));
    <b>return</b> (
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>.add(net_new_debt),
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>.add(spread_fee)
    )
}
</code></pre>



</details>

<a name="suilend_reserve_claim_fees"></a>

## Function `claim_fees`

Claims accumulated fees from the reserve.

Withdraws all fees and ctoken fees, and claims unclaimed spread fees if sufficient liquidity is available.


<a name="@Arguments_101"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>system_state</code> - A mutable reference to the <code>SuiSystemState</code> for staking operations.


<a name="@Returns_102"></a>

### Returns


* <code>(Balance&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt;, Balance&lt;T&gt;)</code> - A tuple containing the ctoken fees and token fees.


<a name="@Panics_103"></a>

### Panics


* If the <code><a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a></code> dynamic field is not found.
* If the reserve's coin type is SUI and a staker is initialized but the staker type is incorrect (<code><a href="../suilend/reserve.md#suilend_reserve_EWrongType">EWrongType</a></code>).


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_claim_fees">claim_fees</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, system_state: &<b>mut</b> <a href="../dependencies/sui_system/sui_system.md#sui_system_sui_system_SuiSystemState">sui_system::sui_system::SuiSystemState</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;, <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_claim_fees">claim_fees</a>&lt;P, T&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    system_state: &<b>mut</b> SuiSystemState,
    ctx: &<b>mut</b> TxContext
): (Balance&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt;, Balance&lt;T&gt;) {
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt; = dynamic_field::borrow_mut(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {});
    <b>let</b> <b>mut</b> fees = balance::withdraw_all(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.fees);
    <b>let</b> ctoken_fees = balance::withdraw_all(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.ctoken_fees);
    // spread fees
    <b>if</b> (<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> &gt;= <a href="../suilend/reserve.md#suilend_reserve_MIN_AVAILABLE_AMOUNT">MIN_AVAILABLE_AMOUNT</a>) {
        <b>let</b> claimable_spread_fees = floor(min(
            <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>,
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> - <a href="../suilend/reserve.md#suilend_reserve_MIN_AVAILABLE_AMOUNT">MIN_AVAILABLE_AMOUNT</a>)
        ));
        <b>let</b> spread_fees = {
            <b>let</b> liquidity_request = <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a>&lt;P, T&gt; { amount: claimable_spread_fees, fee: 0 };
            <b>if</b> (type_name::get&lt;T&gt;() == type_name::get&lt;SUI&gt;()) {
                <a href="../suilend/reserve.md#suilend_reserve_unstake_sui_from_staker">unstake_sui_from_staker</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, &liquidity_request, system_state, ctx);
            };
            <a href="../suilend/reserve.md#suilend_reserve_fulfill_liquidity_request">fulfill_liquidity_request</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, liquidity_request)
        };
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a> = sub(
            <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_unclaimed_spread_fees">unclaimed_spread_fees</a>,
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(balance::value(&spread_fees))
        );
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> = <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> - balance::value(&spread_fees);
        balance::join(&<b>mut</b> fees, spread_fees);
    };
    (ctoken_fees, fees)
}
</code></pre>



</details>

<a name="suilend_reserve_deposit_liquidity_and_mint_ctokens"></a>

## Function `deposit_liquidity_and_mint_ctokens`

Deposits liquidity into the reserve and mints corresponding ctokens.


<a name="@Arguments_104"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>liquidity</code> - The balance of tokens to deposit.


<a name="@Returns_105"></a>

### Returns


* <code>Balance&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt;</code> - The minted ctoken balance.


<a name="@Panics_106"></a>

### Panics


* If the total supply exceeds the deposit limit (<code><a href="../suilend/reserve.md#suilend_reserve_EDepositLimitExceeded">EDepositLimitExceeded</a></code>).
* If the total supply in USD exceeds the USD deposit limit (<code><a href="../suilend/reserve.md#suilend_reserve_EDepositLimitExceeded">EDepositLimitExceeded</a></code>).
* If the <code><a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a></code> dynamic field is not found.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_deposit_liquidity_and_mint_ctokens">deposit_liquidity_and_mint_ctokens</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, liquidity: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_deposit_liquidity_and_mint_ctokens">deposit_liquidity_and_mint_ctokens</a>&lt;P, T&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    liquidity: Balance&lt;T&gt;,
): Balance&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt; {
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">ctoken_ratio</a> = <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">ctoken_ratio</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>let</b> new_ctokens = floor(div(
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(balance::value(&liquidity)),
        <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">ctoken_ratio</a>
    ));
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> = <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> + balance::value(&liquidity);
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a> = <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a> + new_ctokens;
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_total_supply">total_supply</a> = <a href="../suilend/reserve.md#suilend_reserve_total_supply">total_supply</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>assert</b>!(
        le(<a href="../suilend/reserve.md#suilend_reserve_total_supply">total_supply</a>, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(deposit_limit(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)))),
        <a href="../suilend/reserve.md#suilend_reserve_EDepositLimitExceeded">EDepositLimitExceeded</a>
    );
    <b>let</b> total_supply_usd = <a href="../suilend/reserve.md#suilend_reserve_market_value_upper_bound">market_value_upper_bound</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, <a href="../suilend/reserve.md#suilend_reserve_total_supply">total_supply</a>);
    <b>assert</b>!(
        le(total_supply_usd, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(deposit_limit_usd(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)))),
        <a href="../suilend/reserve.md#suilend_reserve_EDepositLimitExceeded">EDepositLimitExceeded</a>
    );
    <a href="../suilend/reserve.md#suilend_reserve_log_reserve_data">log_reserve_data</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt; = dynamic_field::borrow_mut(
        &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id,
        <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {}
    );
    balance::join(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>, liquidity);
    balance::increase_supply(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>, new_ctokens)
}
</code></pre>



</details>

<a name="suilend_reserve_redeem_ctokens"></a>

## Function `redeem_ctokens`

Redeems ctokens for liquidity from the reserve.


<a name="@Arguments_107"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>ctokens</code> - The ctoken balance to redeem.


<a name="@Returns_108"></a>

### Returns


* <code><a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a>&lt;P, T&gt;</code> - A liquidity request for the redeemed amount.


<a name="@Panics_109"></a>

### Panics


* If the available amount or ctoken supply falls below <code><a href="../suilend/reserve.md#suilend_reserve_MIN_AVAILABLE_AMOUNT">MIN_AVAILABLE_AMOUNT</a></code> after redemption (<code><a href="../suilend/reserve.md#suilend_reserve_EMinAvailableAmountViolated">EMinAvailableAmountViolated</a></code>).
* If the <code><a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a></code> dynamic field is not found.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_redeem_ctokens">redeem_ctokens</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, ctokens: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;): <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">suilend::reserve::LiquidityRequest</a>&lt;P, T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_redeem_ctokens">redeem_ctokens</a>&lt;P, T&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    ctokens: Balance&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt;
): <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a>&lt;P, T&gt; {
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">ctoken_ratio</a> = <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">ctoken_ratio</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>let</b> liquidity_amount = floor(mul(
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(balance::value(&ctokens)),
        <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">ctoken_ratio</a>
    ));
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> = <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> - liquidity_amount;
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a> = <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a> - balance::value(&ctokens);
    <b>assert</b>!(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> &gt;= <a href="../suilend/reserve.md#suilend_reserve_MIN_AVAILABLE_AMOUNT">MIN_AVAILABLE_AMOUNT</a> && <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a> &gt;= <a href="../suilend/reserve.md#suilend_reserve_MIN_AVAILABLE_AMOUNT">MIN_AVAILABLE_AMOUNT</a>,
        <a href="../suilend/reserve.md#suilend_reserve_EMinAvailableAmountViolated">EMinAvailableAmountViolated</a>
    );
    <a href="../suilend/reserve.md#suilend_reserve_log_reserve_data">log_reserve_data</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt; = dynamic_field::borrow_mut(
        &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id,
        <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {}
    );
    balance::decrease_supply(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>, ctokens);
    <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a>&lt;P, T&gt; {
        amount: liquidity_amount,
        fee: 0
    }
}
</code></pre>



</details>

<a name="suilend_reserve_fulfill_liquidity_request"></a>

## Function `fulfill_liquidity_request`

Fulfills a liquidity request by splitting the requested amount from the reserve's balance.


<a name="@Arguments_110"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>request</code> - The <code><a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a></code> to fulfill.


<a name="@Returns_111"></a>

### Returns


* <code>Balance&lt;T&gt;</code> - The fulfilled liquidity amount.


<a name="@Panics_112"></a>

### Panics


* If the <code><a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a></code> dynamic field is not found.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_fulfill_liquidity_request">fulfill_liquidity_request</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, request: <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">suilend::reserve::LiquidityRequest</a>&lt;P, T&gt;): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_fulfill_liquidity_request">fulfill_liquidity_request</a>&lt;P, T&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    request: <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a>&lt;P, T&gt;,
): Balance&lt;T&gt; {
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a> { amount, fee } = request;
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt; = dynamic_field::borrow_mut(
        &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id,
        <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {}
    );
    <b>let</b> <b>mut</b> liquidity = balance::split(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>, amount);
    balance::join(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.fees, balance::split(&<b>mut</b> liquidity, fee));
    liquidity
}
</code></pre>



</details>

<a name="suilend_reserve_init_staker"></a>

## Function `init_staker`

Initializes a staker for the reserve.


<a name="@Arguments_113"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>treasury_cap</code> - The treasury cap for the staker's coin type.


<a name="@Panics_114"></a>

### Panics


* If a staker is already initialized (<code><a href="../suilend/reserve.md#suilend_reserve_EStakerAlreadyInitialized">EStakerAlreadyInitialized</a></code>).
* If the staker's coin type is not SPRUNGSUI (<code><a href="../suilend/reserve.md#suilend_reserve_EWrongType">EWrongType</a></code>).


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_init_staker">init_staker</a>&lt;P, S: drop&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, treasury_cap: <a href="../dependencies/sui/coin.md#sui_coin_TreasuryCap">sui::coin::TreasuryCap</a>&lt;S&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_init_staker">init_staker</a>&lt;P, S: drop&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    treasury_cap: TreasuryCap&lt;S&gt;,
    ctx: &<b>mut</b> TxContext
) {
    <b>assert</b>!(!dynamic_field::exists_(&<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_StakerKey">StakerKey</a> {}), <a href="../suilend/reserve.md#suilend_reserve_EStakerAlreadyInitialized">EStakerAlreadyInitialized</a>);
    <b>assert</b>!(type_name::get&lt;S&gt;() == type_name::get&lt;SPRUNGSUI&gt;(), <a href="../suilend/reserve.md#suilend_reserve_EWrongType">EWrongType</a>);
    <b>let</b> <a href="../suilend/staker.md#suilend_staker">staker</a> = <a href="../suilend/staker.md#suilend_staker_create_staker">staker::create_staker</a>(treasury_cap, ctx);
    dynamic_field::add(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_StakerKey">StakerKey</a> {}, <a href="../suilend/staker.md#suilend_staker">staker</a>);
}
</code></pre>



</details>

<a name="suilend_reserve_rebalance_staker"></a>

## Function `rebalance_staker`

Rebalances the staker and claims staking fees.


<a name="@Arguments_115"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>system_state</code> - A mutable reference to the <code>SuiSystemState</code> for staking operations.


<a name="@Panics_116"></a>

### Panics


* If a staker is not initialized (<code><a href="../suilend/reserve.md#suilend_reserve_EStakerNotInitialized">EStakerNotInitialized</a></code>).
* If the <code><a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a></code> dynamic field is not found.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_rebalance_staker">rebalance_staker</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, system_state: &<b>mut</b> <a href="../dependencies/sui_system/sui_system.md#sui_system_sui_system_SuiSystemState">sui_system::sui_system::SuiSystemState</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_rebalance_staker">rebalance_staker</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    system_state: &<b>mut</b> SuiSystemState,
    ctx: &<b>mut</b> TxContext
) {
    <b>assert</b>!(dynamic_field::exists_(&<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_StakerKey">StakerKey</a> {}), <a href="../suilend/reserve.md#suilend_reserve_EStakerNotInitialized">EStakerNotInitialized</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, SUI&gt; = dynamic_field::borrow_mut(
        &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id,
        <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {}
    );
    <b>let</b> sui = balance::withdraw_all(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>);
    <b>let</b> <a href="../suilend/staker.md#suilend_staker">staker</a>: &<b>mut</b> Staker&lt;SPRUNGSUI&gt; = dynamic_field::borrow_mut(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_StakerKey">StakerKey</a> {});
    <a href="../suilend/staker.md#suilend_staker_deposit">staker::deposit</a>(<a href="../suilend/staker.md#suilend_staker">staker</a>, sui);
    <a href="../suilend/staker.md#suilend_staker_rebalance">staker::rebalance</a>(<a href="../suilend/staker.md#suilend_staker">staker</a>, system_state, ctx);
    <b>let</b> fees = <a href="../suilend/staker.md#suilend_staker_claim_fees">staker::claim_fees</a>(<a href="../suilend/staker.md#suilend_staker">staker</a>, system_state, ctx);
    <b>if</b> (balance::value(&fees) &gt; 0) {
        event::emit(<a href="../suilend/reserve.md#suilend_reserve_ClaimStakingRewardsEvent">ClaimStakingRewardsEvent</a> {
            lending_market_id: object::id_to_address(&<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.lending_market_id),
            <a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>,
            reserve_id: object::uid_to_address(&<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id),
            amount: balance::value(&fees),
        });
        <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, SUI&gt; = dynamic_field::borrow_mut(
            &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id,
            <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {}
        );
        balance::join(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.fees, fees);
    }
    <b>else</b> {
        balance::destroy_zero(fees);
    };
}
</code></pre>



</details>

<a name="suilend_reserve_unstake_sui_from_staker"></a>

## Function `unstake_sui_from_staker`

Unstakes SUI from the staker to fulfill a liquidity request if necessary.


<a name="@Arguments_117"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>liquidity_request</code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a></code> to fulfill.
* <code>system_state</code> - A mutable reference to the <code>SuiSystemState</code> for staking operations.


<a name="@Panics_118"></a>

### Panics


* If the reserve's coin type or liquidity request type is not SUI (<code><a href="../suilend/reserve.md#suilend_reserve_EWrongType">EWrongType</a></code>).
* If the <code><a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a></code> dynamic field is not found.
* If the <code><a href="../suilend/reserve.md#suilend_reserve_StakerKey">StakerKey</a></code> dynamic field is found but the staker type is incorrect.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_unstake_sui_from_staker">unstake_sui_from_staker</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, liquidity_request: &<a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">suilend::reserve::LiquidityRequest</a>&lt;P, T&gt;, system_state: &<b>mut</b> <a href="../dependencies/sui_system/sui_system.md#sui_system_sui_system_SuiSystemState">sui_system::sui_system::SuiSystemState</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_unstake_sui_from_staker">unstake_sui_from_staker</a>&lt;P, T&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    liquidity_request: &<a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a>&lt;P, T&gt;,
    system_state: &<b>mut</b> SuiSystemState,
    ctx: &<b>mut</b> TxContext
) {
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a> == type_name::get&lt;SUI&gt;() && type_name::get&lt;T&gt;() == type_name::get&lt;SUI&gt;(), <a href="../suilend/reserve.md#suilend_reserve_EWrongType">EWrongType</a>);
    <b>if</b> (!dynamic_field::exists_(&<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_StakerKey">StakerKey</a> {})) {
        <b>return</b>
    };
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, SUI&gt; = dynamic_field::borrow(&<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {});
    <b>if</b> (liquidity_request.amount &lt;= balance::value(&<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>)) {
        <b>return</b>
    };
    <b>let</b> withdraw_amount = liquidity_request.amount - balance::value(&<a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>);
    <b>let</b> <a href="../suilend/staker.md#suilend_staker">staker</a>: &<b>mut</b> Staker&lt;SPRUNGSUI&gt; = dynamic_field::borrow_mut(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_StakerKey">StakerKey</a> {});
    <b>let</b> sui = <a href="../suilend/staker.md#suilend_staker_withdraw">staker::withdraw</a>(
        <a href="../suilend/staker.md#suilend_staker">staker</a>,
        withdraw_amount,
        system_state,
        ctx
    );
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, SUI&gt; = dynamic_field::borrow_mut(
        &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id,
        <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {}
    );
    balance::join(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>, sui);
}
</code></pre>



</details>

<a name="suilend_reserve_borrow_liquidity"></a>

## Function `borrow_liquidity`

Borrows liquidity from the reserve with a fee.


<a name="@Arguments_119"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>amount</code> - The amount to borrow.


<a name="@Returns_120"></a>

### Returns


* <code><a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a>&lt;P, T&gt;</code> - A liquidity request for the borrowed amount including fees.


<a name="@Panics_121"></a>

### Panics


* If the borrowed amount exceeds the borrow limit (<code><a href="../suilend/reserve.md#suilend_reserve_EBorrowLimitExceeded">EBorrowLimitExceeded</a></code>).
* If the borrowed amount in USD exceeds the USD borrow limit (<code><a href="../suilend/reserve.md#suilend_reserve_EBorrowLimitExceeded">EBorrowLimitExceeded</a></code>).
* If the available amount or ctoken supply falls below <code><a href="../suilend/reserve.md#suilend_reserve_MIN_AVAILABLE_AMOUNT">MIN_AVAILABLE_AMOUNT</a></code> after borrowing (<code><a href="../suilend/reserve.md#suilend_reserve_EMinAvailableAmountViolated">EMinAvailableAmountViolated</a></code>).


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_borrow_liquidity">borrow_liquidity</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, amount: u64): <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">suilend::reserve::LiquidityRequest</a>&lt;P, T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_borrow_liquidity">borrow_liquidity</a>&lt;P, T&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    amount: u64
): <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a>&lt;P, T&gt; {
    <b>let</b> borrow_fee = <a href="../suilend/reserve.md#suilend_reserve_calculate_borrow_fee">calculate_borrow_fee</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, amount);
    <b>let</b> borrow_amount_with_fees = amount + borrow_fee;
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> = <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> - borrow_amount_with_fees;
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a> = add(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(borrow_amount_with_fees));
    <b>assert</b>!(
        le(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(borrow_limit(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)))),
        <a href="../suilend/reserve.md#suilend_reserve_EBorrowLimitExceeded">EBorrowLimitExceeded</a>
    );
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a> = <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>;
    <b>assert</b>!(
        le(
            <a href="../suilend/reserve.md#suilend_reserve_market_value_upper_bound">market_value_upper_bound</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, <a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>),
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(borrow_limit_usd(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)))
        ),
        <a href="../suilend/reserve.md#suilend_reserve_EBorrowLimitExceeded">EBorrowLimitExceeded</a>
    );
    <b>assert</b>!(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> &gt;= <a href="../suilend/reserve.md#suilend_reserve_MIN_AVAILABLE_AMOUNT">MIN_AVAILABLE_AMOUNT</a> && <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a> &gt;= <a href="../suilend/reserve.md#suilend_reserve_MIN_AVAILABLE_AMOUNT">MIN_AVAILABLE_AMOUNT</a>,
        <a href="../suilend/reserve.md#suilend_reserve_EMinAvailableAmountViolated">EMinAvailableAmountViolated</a>
    );
    <a href="../suilend/reserve.md#suilend_reserve_log_reserve_data">log_reserve_data</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">LiquidityRequest</a>&lt;P, T&gt; {
        amount: borrow_amount_with_fees,
        fee: borrow_fee
    }
}
</code></pre>



</details>

<a name="suilend_reserve_repay_liquidity"></a>

## Function `repay_liquidity`

Repays liquidity to the reserve.


<a name="@Arguments_122"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>liquidity</code> - The balance of tokens to repay.
* <code>settle_amount</code> - The amount to settle as a decimal.


<a name="@Panics_123"></a>

### Panics


* If the liquidity amount does not match the ceiling of the settle amount (<code><a href="../suilend/reserve.md#suilend_reserve_EInvalidRepayBalance">EInvalidRepayBalance</a></code>).
* If the <code><a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a></code> dynamic field is not found.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_repay_liquidity">repay_liquidity</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, liquidity: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;, settle_amount: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_repay_liquidity">repay_liquidity</a>&lt;P, T&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    liquidity: Balance&lt;T&gt;,
    settle_amount: Decimal
) {
    <b>assert</b>!(balance::value(&liquidity) == ceil(settle_amount), <a href="../suilend/reserve.md#suilend_reserve_EInvalidRepayBalance">EInvalidRepayBalance</a>);
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> = <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a> + balance::value(&liquidity);
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a> = saturating_sub(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>,
        settle_amount
    );
    <a href="../suilend/reserve.md#suilend_reserve_log_reserve_data">log_reserve_data</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt; = dynamic_field::borrow_mut(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {});
    balance::join(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>, liquidity);
}
</code></pre>



</details>

<a name="suilend_reserve_forgive_debt"></a>

## Function `forgive_debt`

Forgives a portion of the reserve's debt.


<a name="@Arguments_124"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>forgive_amount</code> - The amount of debt to forgive as a decimal.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_forgive_debt">forgive_debt</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, forgive_amount: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_forgive_debt">forgive_debt</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    forgive_amount: Decimal
) {
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a> = saturating_sub(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>,
        forgive_amount
    );
    <a href="../suilend/reserve.md#suilend_reserve_log_reserve_data">log_reserve_data</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
}
</code></pre>



</details>

<a name="suilend_reserve_deposit_ctokens"></a>

## Function `deposit_ctokens`

Deposits ctokens into the reserve's deposited ctokens balance.


<a name="@Arguments_125"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>ctokens</code> - The ctoken balance to deposit.


<a name="@Panics_126"></a>

### Panics


* If the <code><a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a></code> dynamic field is not found.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_deposit_ctokens">deposit_ctokens</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, ctokens: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_deposit_ctokens">deposit_ctokens</a>&lt;P, T&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    ctokens: Balance&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt;
) {
    <a href="../suilend/reserve.md#suilend_reserve_log_reserve_data">log_reserve_data</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt; = dynamic_field::borrow_mut(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {});
    balance::join(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.deposited_ctokens, ctokens);
}
</code></pre>



</details>

<a name="suilend_reserve_withdraw_ctokens"></a>

## Function `withdraw_ctokens`

Withdraws ctokens from the reserve's deposited ctokens balance.


<a name="@Arguments_127"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>amount</code> - The amount of ctokens to withdraw.


<a name="@Returns_128"></a>

### Returns


* <code>Balance&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt;</code> - The withdrawn ctoken balance.


<a name="@Panics_129"></a>

### Panics


* If the <code><a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a></code> dynamic field is not found.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_withdraw_ctokens">withdraw_ctokens</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, amount: u64): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_withdraw_ctokens">withdraw_ctokens</a>&lt;P, T&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    amount: u64
): Balance&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">CToken</a>&lt;P, T&gt;&gt; {
    <a href="../suilend/reserve.md#suilend_reserve_log_reserve_data">log_reserve_data</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Balances">Balances</a>&lt;P, T&gt; = dynamic_field::borrow_mut(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id, <a href="../suilend/reserve.md#suilend_reserve_BalanceKey">BalanceKey</a> {});
    balance::split(&<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_balances">balances</a>.deposited_ctokens, amount)
}
</code></pre>



</details>

<a name="suilend_reserve_change_price_feed"></a>

## Function `change_price_feed`

Changes the price feed for the reserve.


<a name="@Arguments_130"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A mutable reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to modify.
* <code>price_info_obj</code> - The new price information object.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based calculations.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_change_price_feed">change_price_feed</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, price_info_obj: &<a href="../dependencies/pyth/price_info.md#pyth_price_info_PriceInfoObject">pyth::price_info::PriceInfoObject</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_change_price_feed">change_price_feed</a>&lt;P&gt;(
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;,
    price_info_obj: &PriceInfoObject,
    clock: &Clock,
){
    <b>let</b> (_, _, <a href="../suilend/reserve.md#suilend_reserve_price_identifier">price_identifier</a>) = <a href="../suilend/oracles.md#suilend_oracles_get_pyth_price_and_identifier">oracles::get_pyth_price_and_identifier</a>(price_info_obj, clock);
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_price_identifier">price_identifier</a> = <a href="../suilend/reserve.md#suilend_reserve_price_identifier">price_identifier</a>;
}
</code></pre>



</details>

<a name="suilend_reserve_interest_last_update_timestamp_s"></a>

## Function `interest_last_update_timestamp_s`

Gets the timestamp of the last interest update in seconds.


<a name="@Arguments_131"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> to query.


<a name="@Returns_132"></a>

### Returns


* <code>u64</code> - The timestamp of the last interest update in seconds.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_interest_last_update_timestamp_s">interest_last_update_timestamp_s</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_interest_last_update_timestamp_s">interest_last_update_timestamp_s</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;): u64 {
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_interest_last_update_timestamp_s">interest_last_update_timestamp_s</a>
}
</code></pre>



</details>

<a name="suilend_reserve_log_reserve_data"></a>

## Function `log_reserve_data`

Logs the reserve's data as an event.

Emits a <code><a href="../suilend/reserve.md#suilend_reserve_ReserveAssetDataEvent">ReserveAssetDataEvent</a></code> with the current state of the reserve, including amounts, prices, and APRs.


<a name="@Arguments_133"></a>

### Arguments


* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> - A reference to the <code><a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a></code> whose data is to be logged.


<pre><code><b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_log_reserve_data">log_reserve_data</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/reserve.md#suilend_reserve_log_reserve_data">log_reserve_data</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">Reserve</a>&lt;P&gt;) {
    <b>let</b> available_amount_decimal = <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>);
    <b>let</b> supply_amount = <a href="../suilend/reserve.md#suilend_reserve_total_supply">total_supply</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>let</b> cur_util = <a href="../suilend/reserve.md#suilend_reserve_calculate_utilization_rate">calculate_utilization_rate</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>let</b> borrow_apr = calculate_apr(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>), cur_util);
    <b>let</b> supply_apr = calculate_supply_apr(<a href="../suilend/reserve.md#suilend_reserve_config">config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>), cur_util, borrow_apr);
    event::emit(<a href="../suilend/reserve.md#suilend_reserve_ReserveAssetDataEvent">ReserveAssetDataEvent</a> {
        lending_market_id: object::id_to_address(&<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.lending_market_id),
        <a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_coin_type">coin_type</a>,
        reserve_id: object::uid_to_address(&<a href="../suilend/reserve.md#suilend_reserve">reserve</a>.id),
        <a href="../suilend/reserve.md#suilend_reserve_available_amount">available_amount</a>: available_amount_decimal,
        supply_amount: supply_amount,
        <a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>,
        available_amount_usd_estimate: <a href="../suilend/reserve.md#suilend_reserve_market_value">market_value</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, available_amount_decimal),
        supply_amount_usd_estimate: <a href="../suilend/reserve.md#suilend_reserve_market_value">market_value</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, supply_amount),
        borrowed_amount_usd_estimate: <a href="../suilend/reserve.md#suilend_reserve_market_value">market_value</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_borrowed_amount">borrowed_amount</a>),
        borrow_apr: borrow_apr,
        supply_apr: supply_apr,
        <a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_ctoken_supply">ctoken_supply</a>,
        <a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">cumulative_borrow_rate</a>: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">cumulative_borrow_rate</a>,
        <a href="../suilend/reserve.md#suilend_reserve_price">price</a>: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/reserve.md#suilend_reserve_price">price</a>,
        smoothed_price: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.smoothed_price,
        price_last_update_timestamp_s: <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.price_last_update_timestamp_s,
    });
}
</code></pre>



</details>
