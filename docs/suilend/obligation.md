
<a name="suilend_obligation"></a>

# Module `suilend::obligation`



-  [Struct `Obligation`](#suilend_obligation_Obligation)
-  [Struct `Deposit`](#suilend_obligation_Deposit)
-  [Struct `Borrow`](#suilend_obligation_Borrow)
-  [Struct `ExistStaleOracles`](#suilend_obligation_ExistStaleOracles)
-  [Struct `ObligationDataEvent`](#suilend_obligation_ObligationDataEvent)
-  [Struct `DepositRecord`](#suilend_obligation_DepositRecord)
-  [Struct `BorrowRecord`](#suilend_obligation_BorrowRecord)
-  [Constants](#@Constants_0)
-  [Function `create_obligation`](#suilend_obligation_create_obligation)
    -  [Arguments](#@Arguments_1)
    -  [Returns](#@Returns_2)
-  [Function `refresh`](#suilend_obligation_refresh)
    -  [Arguments](#@Arguments_3)
    -  [Returns](#@Returns_4)
    -  [Panics](#@Panics_5)
-  [Function `deposit`](#suilend_obligation_deposit)
    -  [Arguments](#@Arguments_6)
    -  [Panics](#@Panics_7)
-  [Function `borrow`](#suilend_obligation_borrow)
    -  [Arguments](#@Arguments_8)
    -  [Panics](#@Panics_9)
-  [Function `repay`](#suilend_obligation_repay)
    -  [Arguments](#@Arguments_10)
    -  [Returns](#@Returns_11)
    -  [Panics](#@Panics_12)
-  [Function `withdraw`](#suilend_obligation_withdraw)
    -  [Arguments](#@Arguments_13)
    -  [Panics](#@Panics_14)
-  [Function `liquidate`](#suilend_obligation_liquidate)
    -  [Arguments](#@Arguments_15)
    -  [Returns](#@Returns_16)
    -  [Panics](#@Panics_17)
-  [Function `forgive`](#suilend_obligation_forgive)
    -  [Arguments](#@Arguments_18)
    -  [Returns](#@Returns_19)
    -  [Panics](#@Panics_20)
-  [Function `claim_rewards`](#suilend_obligation_claim_rewards)
    -  [Arguments](#@Arguments_21)
    -  [Returns](#@Returns_22)
    -  [Panics](#@Panics_23)
-  [Function `deposits`](#suilend_obligation_deposits)
-  [Function `borrows`](#suilend_obligation_borrows)
-  [Function `deposited_value_usd`](#suilend_obligation_deposited_value_usd)
-  [Function `allowed_borrow_value_usd`](#suilend_obligation_allowed_borrow_value_usd)
-  [Function `unhealthy_borrow_value_usd`](#suilend_obligation_unhealthy_borrow_value_usd)
-  [Function `unweighted_borrowed_value_usd`](#suilend_obligation_unweighted_borrowed_value_usd)
-  [Function `weighted_borrowed_value_usd`](#suilend_obligation_weighted_borrowed_value_usd)
-  [Function `weighted_borrowed_value_upper_bound_usd`](#suilend_obligation_weighted_borrowed_value_upper_bound_usd)
-  [Function `borrowing_isolated_asset`](#suilend_obligation_borrowing_isolated_asset)
-  [Function `user_reward_managers`](#suilend_obligation_user_reward_managers)
-  [Function `deposit_coin_type`](#suilend_obligation_deposit_coin_type)
-  [Function `deposit_reserve_array_index`](#suilend_obligation_deposit_reserve_array_index)
-  [Function `deposit_deposited_ctoken_amount`](#suilend_obligation_deposit_deposited_ctoken_amount)
-  [Function `deposit_market_value`](#suilend_obligation_deposit_market_value)
-  [Function `deposit_user_reward_manager_index`](#suilend_obligation_deposit_user_reward_manager_index)
-  [Function `borrow_coin_type`](#suilend_obligation_borrow_coin_type)
-  [Function `borrow_reserve_array_index`](#suilend_obligation_borrow_reserve_array_index)
-  [Function `borrow_borrowed_amount`](#suilend_obligation_borrow_borrowed_amount)
-  [Function `borrow_cumulative_borrow_rate`](#suilend_obligation_borrow_cumulative_borrow_rate)
-  [Function `borrow_market_value`](#suilend_obligation_borrow_market_value)
-  [Function `borrow_user_reward_manager_index`](#suilend_obligation_borrow_user_reward_manager_index)
-  [Function `deposited_ctoken_amount`](#suilend_obligation_deposited_ctoken_amount)
-  [Function `borrowed_amount`](#suilend_obligation_borrowed_amount)
-  [Function `is_healthy`](#suilend_obligation_is_healthy)
-  [Function `is_liquidatable`](#suilend_obligation_is_liquidatable)
-  [Function `is_forgivable`](#suilend_obligation_is_forgivable)
-  [Function `max_borrow_amount`](#suilend_obligation_max_borrow_amount)
    -  [Arguments](#@Arguments_24)
    -  [Returns](#@Returns_25)
    -  [Panics](#@Panics_26)
-  [Function `max_withdraw_amount`](#suilend_obligation_max_withdraw_amount)
    -  [Arguments](#@Arguments_27)
    -  [Returns](#@Returns_28)
    -  [Panics](#@Panics_29)
-  [Function `assert_no_stale_oracles`](#suilend_obligation_assert_no_stale_oracles)
    -  [Arguments](#@Arguments_30)
    -  [Panics](#@Panics_31)
-  [Function `zero_out_rewards_if_looped`](#suilend_obligation_zero_out_rewards_if_looped)
    -  [Arguments](#@Arguments_32)
    -  [Panics](#@Panics_33)
-  [Function `is_looped`](#suilend_obligation_is_looped)
    -  [Panics](#@Panics_34)
-  [Function `zero_out_rewards`](#suilend_obligation_zero_out_rewards)
-  [Function `log_obligation_data`](#suilend_obligation_log_obligation_data)
-  [Function `liability_shares`](#suilend_obligation_liability_shares)
-  [Function `withdraw_unchecked`](#suilend_obligation_withdraw_unchecked)
-  [Function `compound_debt`](#suilend_obligation_compound_debt)
-  [Function `find_deposit_index`](#suilend_obligation_find_deposit_index)
-  [Function `find_deposit_index_by_reserve_array_index`](#suilend_obligation_find_deposit_index_by_reserve_array_index)
-  [Function `find_borrow_index`](#suilend_obligation_find_borrow_index)
-  [Function `find_borrow`](#suilend_obligation_find_borrow)
-  [Function `find_deposit`](#suilend_obligation_find_deposit)
-  [Function `find_or_add_borrow`](#suilend_obligation_find_or_add_borrow)
-  [Function `find_or_add_deposit`](#suilend_obligation_find_or_add_deposit)
-  [Function `find_user_reward_manager_index`](#suilend_obligation_find_user_reward_manager_index)
-  [Function `find_or_add_user_reward_manager`](#suilend_obligation_find_or_add_user_reward_manager)


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
<b>use</b> <a href="../suilend/reserve.md#suilend_reserve">suilend::reserve</a>;
<b>use</b> <a href="../suilend/reserve_config.md#suilend_reserve_config">suilend::reserve_config</a>;
<b>use</b> <a href="../suilend/staker.md#suilend_staker">suilend::staker</a>;
</code></pre>



<a name="suilend_obligation_Obligation"></a>

## Struct `Obligation`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;<b>phantom</b> P&gt; <b>has</b> key, store
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
<code><a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>: vector&lt;<a href="../suilend/obligation.md#suilend_obligation_Deposit">suilend::obligation::Deposit</a>&gt;</code>
</dt>
<dd>
 all deposits in the obligation. there is at most one deposit per coin type
 There should never be a deposit object with a zeroed amount
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>: vector&lt;<a href="../suilend/obligation.md#suilend_obligation_Borrow">suilend::obligation::Borrow</a>&gt;</code>
</dt>
<dd>
 all borrows in the obligation. there is at most one deposit per coin type
 There should never be a borrow object with a zeroed amount
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 value of all deposits in USD
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 sum(deposit value * open ltv) for all deposits.
 if weighted_borrowed_value_usd > allowed_borrow_value_usd,
 the obligation is not healthy
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 sum(deposit value * close ltv) for all deposits
 if weighted_borrowed_value_usd > unhealthy_borrow_value_usd,
 the obligation is unhealthy and can be liquidated
</dd>
<dt>
<code>super_unhealthy_borrow_value_usd: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 value of all borrows in USD
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 weighted value of all borrows in USD. used when checking if an obligation is liquidatable
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 weighted value of all borrows in USD, but using the upper bound of the market value
 used to limit borrows and withdraws
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_borrowing_isolated_asset">borrowing_isolated_asset</a>: bool</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>: vector&lt;<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">suilend::liquidity_mining::UserRewardManager</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>bad_debt_usd: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 unused
</dd>
<dt>
<code>closable: bool</code>
</dt>
<dd>
 unused
</dd>
</dl>


</details>

<a name="suilend_obligation_Deposit"></a>

## Struct `Deposit`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/obligation.md#suilend_obligation_Deposit">Deposit</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_array_index: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>market_value: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>user_reward_manager_index: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>attributed_borrow_value: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 unused
</dd>
</dl>


</details>

<a name="suilend_obligation_Borrow"></a>

## Struct `Borrow`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/obligation.md#suilend_obligation_Borrow">Borrow</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_array_index: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>cumulative_borrow_rate: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>market_value: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>user_reward_manager_index: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_obligation_ExistStaleOracles"></a>

## Struct `ExistStaleOracles`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">ExistStaleOracles</a>
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="suilend_obligation_ObligationDataEvent"></a>

## Struct `ObligationDataEvent`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/obligation.md#suilend_obligation_ObligationDataEvent">ObligationDataEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>obligation_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>: vector&lt;<a href="../suilend/obligation.md#suilend_obligation_DepositRecord">suilend::obligation::DepositRecord</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>: vector&lt;<a href="../suilend/obligation.md#suilend_obligation_BorrowRecord">suilend::obligation::BorrowRecord</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>super_unhealthy_borrow_value_usd: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_borrowing_isolated_asset">borrowing_isolated_asset</a>: bool</code>
</dt>
<dd>
</dd>
<dt>
<code>bad_debt_usd: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>closable: bool</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_obligation_DepositRecord"></a>

## Struct `DepositRecord`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/obligation.md#suilend_obligation_DepositRecord">DepositRecord</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_array_index: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>market_value: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>user_reward_manager_index: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>attributed_borrow_value: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 unused
</dd>
</dl>


</details>

<a name="suilend_obligation_BorrowRecord"></a>

## Struct `BorrowRecord`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/obligation.md#suilend_obligation_BorrowRecord">BorrowRecord</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_array_index: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>cumulative_borrow_rate: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>market_value: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>user_reward_manager_index: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="suilend_obligation_EObligationIsNotLiquidatable"></a>



<pre><code><b>const</b> <a href="../suilend/obligation.md#suilend_obligation_EObligationIsNotLiquidatable">EObligationIsNotLiquidatable</a>: u64 = 0;
</code></pre>



<a name="suilend_obligation_EObligationIsNotHealthy"></a>



<pre><code><b>const</b> <a href="../suilend/obligation.md#suilend_obligation_EObligationIsNotHealthy">EObligationIsNotHealthy</a>: u64 = 1;
</code></pre>



<a name="suilend_obligation_EBorrowNotFound"></a>



<pre><code><b>const</b> <a href="../suilend/obligation.md#suilend_obligation_EBorrowNotFound">EBorrowNotFound</a>: u64 = 2;
</code></pre>



<a name="suilend_obligation_EDepositNotFound"></a>



<pre><code><b>const</b> <a href="../suilend/obligation.md#suilend_obligation_EDepositNotFound">EDepositNotFound</a>: u64 = 3;
</code></pre>



<a name="suilend_obligation_EIsolatedAssetViolation"></a>



<pre><code><b>const</b> <a href="../suilend/obligation.md#suilend_obligation_EIsolatedAssetViolation">EIsolatedAssetViolation</a>: u64 = 4;
</code></pre>



<a name="suilend_obligation_ETooManyDeposits"></a>



<pre><code><b>const</b> <a href="../suilend/obligation.md#suilend_obligation_ETooManyDeposits">ETooManyDeposits</a>: u64 = 5;
</code></pre>



<a name="suilend_obligation_ETooManyBorrows"></a>



<pre><code><b>const</b> <a href="../suilend/obligation.md#suilend_obligation_ETooManyBorrows">ETooManyBorrows</a>: u64 = 6;
</code></pre>



<a name="suilend_obligation_EObligationIsNotForgivable"></a>



<pre><code><b>const</b> <a href="../suilend/obligation.md#suilend_obligation_EObligationIsNotForgivable">EObligationIsNotForgivable</a>: u64 = 7;
</code></pre>



<a name="suilend_obligation_ECannotDepositAndBorrowSameAsset"></a>



<pre><code><b>const</b> <a href="../suilend/obligation.md#suilend_obligation_ECannotDepositAndBorrowSameAsset">ECannotDepositAndBorrowSameAsset</a>: u64 = 8;
</code></pre>



<a name="suilend_obligation_EOraclesAreStale"></a>



<pre><code><b>const</b> <a href="../suilend/obligation.md#suilend_obligation_EOraclesAreStale">EOraclesAreStale</a>: u64 = 9;
</code></pre>



<a name="suilend_obligation_CLOSE_FACTOR_PCT"></a>



<pre><code><b>const</b> <a href="../suilend/obligation.md#suilend_obligation_CLOSE_FACTOR_PCT">CLOSE_FACTOR_PCT</a>: u8 = 20;
</code></pre>



<a name="suilend_obligation_MAX_DEPOSITS"></a>



<pre><code><b>const</b> <a href="../suilend/obligation.md#suilend_obligation_MAX_DEPOSITS">MAX_DEPOSITS</a>: u64 = 5;
</code></pre>



<a name="suilend_obligation_MAX_BORROWS"></a>



<pre><code><b>const</b> <a href="../suilend/obligation.md#suilend_obligation_MAX_BORROWS">MAX_BORROWS</a>: u64 = 5;
</code></pre>



<a name="suilend_obligation_create_obligation"></a>

## Function `create_obligation`

Creates a new obligation for a lending market.

Initializes an <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a></code> with empty deposits and borrows, zeroed financial metrics,
and associates it with the specified lending market.


<a name="@Arguments_1"></a>

### Arguments


* <code>lending_market_id</code> - The ID of the lending market to associate with the obligation.


<a name="@Returns_2"></a>

### Returns


* <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;</code> - A new <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a></code> instance.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_create_obligation">create_obligation</a>&lt;P&gt;(lending_market_id: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_create_obligation">create_obligation</a>&lt;P&gt;(
    lending_market_id: ID,
    ctx: &<b>mut</b> TxContext,
): <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt; {
    <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt; {
        id: object::new(ctx),
        lending_market_id,
        <a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>: vector::empty(),
        <a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>: vector::empty(),
        <a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        <a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        <a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        <a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a>: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        super_unhealthy_borrow_value_usd: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        <a href="../suilend/obligation.md#suilend_obligation_borrowing_isolated_asset">borrowing_isolated_asset</a>: <b>false</b>,
        <a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>: vector::empty(),
        bad_debt_usd: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        closable: <b>false</b>,
    }
}
</code></pre>



</details>

<a name="suilend_obligation_refresh"></a>

## Function `refresh`

Refreshes the obligation's health status by updating deposit and borrow values.

This function is called by the lending market before any borrow, withdraw, or liquidate
operation to ensure the obligation's state is up-to-date. It iterates through
all deposits and borrows, compounding interest, updating market values based on the
latest oracle prices, and recalculating various health metrics like
<code><a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a></code>, <code><a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a></code>, and <code><a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a></code>.


<a name="@Arguments_3"></a>

### Arguments


* <code><a href="../suilend/obligation.md#suilend_obligation">obligation</a></code>: A mutable reference to the <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a></code> to be refreshed.
* <code>reserves</code>: A mutable reference to the <code>vector&lt;Reserve&lt;P&gt;&gt;</code> from the lending market.
* <code>clock</code>: A reference to the <code>Clock</code> for timestamp-based calculations.


<a name="@Returns_4"></a>

### Returns


* <code>Option&lt;<a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">ExistStaleOracles</a>&gt;</code>: Returns <code>Some(<a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">ExistStaleOracles</a>)</code> if any of the oracle
prices for the involved reserves are stale, indicating that the calculated values
may not be reliable. Otherwise, it returns <code>None</code>.


<a name="@Panics_5"></a>

### Panics


* If any <code>reserve_array_index</code> in the obligation's deposits or borrows is out
of bounds for the <code>reserves</code> vector.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_refresh">refresh</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, reserves: &<b>mut</b> vector&lt;<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">suilend::obligation::ExistStaleOracles</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_refresh">refresh</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    reserves: &<b>mut</b> vector&lt;Reserve&lt;P&gt;&gt;,
    clock: &Clock,
): Option&lt;<a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">ExistStaleOracles</a>&gt; {
    <b>let</b> <b>mut</b> exist_stale_oracles = <b>false</b>;
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> <b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a> = <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0);
    <b>let</b> <b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a> = <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0);
    <b>let</b> <b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a> = <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0);
    <b>while</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>)) {
        <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>, i);
        <b>let</b> deposit_reserve = vector::borrow_mut(reserves, <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.reserve_array_index);
        <a href="../suilend/reserve.md#suilend_reserve_compound_interest">reserve::compound_interest</a>(deposit_reserve, clock);
        <b>if</b> (!<a href="../suilend/reserve.md#suilend_reserve_is_price_fresh">reserve::is_price_fresh</a>(deposit_reserve, clock)) {
            exist_stale_oracles = <b>true</b>;
        };
        <b>let</b> market_value = <a href="../suilend/reserve.md#suilend_reserve_ctoken_market_value">reserve::ctoken_market_value</a>(
            deposit_reserve,
            <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>,
        );
        <b>let</b> market_value_lower_bound = <a href="../suilend/reserve.md#suilend_reserve_ctoken_market_value_lower_bound">reserve::ctoken_market_value_lower_bound</a>(
            deposit_reserve,
            <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>,
        );
        <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.market_value = market_value;
        <a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a> = add(<a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a>, market_value);
        <a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a> =
            add(
                <a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>,
                mul(
                    market_value_lower_bound,
                    open_ltv(config(deposit_reserve)),
                ),
            );
        <a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a> =
            add(
                <a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a>,
                mul(
                    market_value,
                    close_ltv(config(deposit_reserve)),
                ),
            );
        i = i + 1;
    };
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a> = <a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a>;
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a> = <a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>;
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a> = <a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a>;
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> <b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a> = <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0);
    <b>let</b> <b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a> = <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0);
    <b>let</b> <b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a> = <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0);
    <b>let</b> <b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_borrowing_isolated_asset">borrowing_isolated_asset</a> = <b>false</b>;
    <b>while</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>)) {
        <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>, i);
        <b>let</b> borrow_reserve = vector::borrow_mut(reserves, <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.reserve_array_index);
        <a href="../suilend/reserve.md#suilend_reserve_compound_interest">reserve::compound_interest</a>(borrow_reserve, clock);
        <b>if</b> (!<a href="../suilend/reserve.md#suilend_reserve_is_price_fresh">reserve::is_price_fresh</a>(borrow_reserve, clock)) {
            exist_stale_oracles = <b>true</b>;
        };
        <a href="../suilend/obligation.md#suilend_obligation_compound_debt">compound_debt</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>, borrow_reserve);
        <b>let</b> market_value = <a href="../suilend/reserve.md#suilend_reserve_market_value">reserve::market_value</a>(borrow_reserve, <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>);
        <b>let</b> market_value_upper_bound = <a href="../suilend/reserve.md#suilend_reserve_market_value_upper_bound">reserve::market_value_upper_bound</a>(
            borrow_reserve,
            <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>,
        );
        <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.market_value = market_value;
        <a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a> = add(<a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a>, market_value);
        <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a> =
            add(
                <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>,
                mul(
                    market_value,
                    borrow_weight(config(borrow_reserve)),
                ),
            );
        <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a> =
            add(
                <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>,
                mul(
                    market_value_upper_bound,
                    borrow_weight(config(borrow_reserve)),
                ),
            );
        <b>if</b> (isolated(config(borrow_reserve))) {
            <a href="../suilend/obligation.md#suilend_obligation_borrowing_isolated_asset">borrowing_isolated_asset</a> = <b>true</b>;
        };
        i = i + 1;
    };
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a> = <a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a>;
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a> = <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>;
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a> =
        <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>;
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowing_isolated_asset">borrowing_isolated_asset</a> = <a href="../suilend/obligation.md#suilend_obligation_borrowing_isolated_asset">borrowing_isolated_asset</a>;
    <b>if</b> (exist_stale_oracles) {
        <b>return</b> option::some(<a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">ExistStaleOracles</a> {})
    };
    option::none()
}
</code></pre>



</details>

<a name="suilend_obligation_deposit"></a>

## Function `deposit`

Processes a deposit into the obligation.

This function handles the logic for depositing a specified amount of ctokens into a
reserve. It finds or creates a deposit entry for the given reserve, updates the

(<code><a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a></code>, <code><a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a></code>, <code><a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a></code>).
It also updates the user's reward manager to reflect the new deposit amount for
liquidity mining purposes.

Note: This function does not enforce price freshness for oracle prices. It is expected
that any operation requiring up-to-date prices (e.g., withdraw, borrow, liquidate)
will call <code><a href="../suilend/obligation.md#suilend_obligation_refresh">refresh</a></code> beforehand.


<a name="@Arguments_6"></a>

### Arguments


* <code><a href="../suilend/obligation.md#suilend_obligation">obligation</a></code>: A mutable reference to the <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a></code> being deposited into.
* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code>: A mutable reference to the <code>Reserve</code> corresponding to the deposit asset.
* <code>clock</code>: A reference to the <code>Clock</code> for timestamp-based calculations.
* <code>ctoken_amount</code>: The amount of ctokens to be deposited.


<a name="@Panics_7"></a>

### Panics


* If the number of deposits exceeds <code><a href="../suilend/obligation.md#suilend_obligation_MAX_DEPOSITS">MAX_DEPOSITS</a></code>.
* If the obligation already has a borrow for the same asset as the deposit (<code><a href="../suilend/obligation.md#suilend_obligation_ECannotDepositAndBorrowSameAsset">ECannotDepositAndBorrowSameAsset</a></code>).
* If the <code>reserve_array_index</code> of the deposit is invalid or out of bounds for the <code>reserves</code> vector.
* If the <code>user_reward_manager_index</code> is invalid or out of bounds for the <code><a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a></code> vector.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctoken_amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> Reserve&lt;P&gt;,
    clock: &Clock,
    ctoken_amount: u64,
) {
    <b>let</b> deposit_index = <a href="../suilend/obligation.md#suilend_obligation_find_or_add_deposit">find_or_add_deposit</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock);
    <b>assert</b>!(vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>) &lt;= <a href="../suilend/obligation.md#suilend_obligation_MAX_DEPOSITS">MAX_DEPOSITS</a>, <a href="../suilend/obligation.md#suilend_obligation_ETooManyDeposits">ETooManyDeposits</a>);
    <b>let</b> borrow_index = <a href="../suilend/obligation.md#suilend_obligation_find_borrow_index">find_borrow_index</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>assert</b>!(
        borrow_index == vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>),
        <a href="../suilend/obligation.md#suilend_obligation_ECannotDepositAndBorrowSameAsset">ECannotDepositAndBorrowSameAsset</a>,
    );
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>, deposit_index);
    <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a> = <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a> + ctoken_amount;
    <b>let</b> deposit_value = <a href="../suilend/reserve.md#suilend_reserve_ctoken_market_value">reserve::ctoken_market_value</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, ctoken_amount);
    // update other health values. note that we don't enforce price freshness here. this is purely
    // to make offchain accounting easier. any operation that requires price
    // freshness (<a href="../suilend/obligation.md#suilend_obligation_withdraw">withdraw</a>, <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>, <a href="../suilend/obligation.md#suilend_obligation_liquidate">liquidate</a>) will <a href="../suilend/obligation.md#suilend_obligation_refresh">refresh</a> the <a href="../suilend/obligation.md#suilend_obligation">obligation</a> right before.
    <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.market_value = add(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.market_value, deposit_value);
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a> = add(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a>, deposit_value);
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a> =
        add(
            <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>,
            mul(
                <a href="../suilend/reserve.md#suilend_reserve_ctoken_market_value_lower_bound">reserve::ctoken_market_value_lower_bound</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, ctoken_amount),
                open_ltv(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)),
            ),
        );
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a> =
        add(
            <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a>,
            mul(
                deposit_value,
                close_ltv(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)),
            ),
        );
    <b>let</b> user_reward_manager = vector::borrow_mut(
        &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>,
        <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.user_reward_manager_index,
    );
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_change_user_reward_manager_share">liquidity_mining::change_user_reward_manager_share</a>(
        <a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager_mut">reserve::deposits_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        user_reward_manager,
        <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>,
        clock,
    );
    <a href="../suilend/obligation.md#suilend_obligation_log_obligation_data">log_obligation_data</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>);
}
</code></pre>



</details>

<a name="suilend_obligation_borrow"></a>

## Function `borrow`

Processes a borrow action from the obligation, ensuring the obligation remains healthy.

This function manages the borrowing of a specified amount from a reserve. It performs
several checks and updates to maintain the integrity of the obligation's financial
status. Key actions include:
- Finding or creating a borrow entry for the specified reserve.
- Ensuring the user is not borrowing and depositing the same asset.
- Updating the obligation's health metrics, including <code><a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a></code>,
<code><a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a></code>, and <code><a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a></code>.
- Updating the user's reward manager for liquidity mining incentives.
- Asserting that the obligation remains healthy (<code><a href="../suilend/obligation.md#suilend_obligation_is_healthy">is_healthy</a></code>) after the borrow.
- Enforcing rules for isolated assets to prevent co-mingling of borrows.


<a name="@Arguments_8"></a>

### Arguments


* <code><a href="../suilend/obligation.md#suilend_obligation">obligation</a></code>: A mutable reference to the <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a></code> from which to borrow.
* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code>: A mutable reference to the <code>Reserve</code> from which the asset is borrowed.
* <code>clock</code>: A reference to the <code>Clock</code> for timestamp-based calculations.
* <code>amount</code>: The amount of the asset to borrow.


<a name="@Panics_9"></a>

### Panics


* If the number of borrows exceeds <code><a href="../suilend/obligation.md#suilend_obligation_MAX_BORROWS">MAX_BORROWS</a></code>.
* If the obligation already has a deposit for the same asset as the
borrow (<code><a href="../suilend/obligation.md#suilend_obligation_ECannotDepositAndBorrowSameAsset">ECannotDepositAndBorrowSameAsset</a></code>).
* If the obligation is not healthy after the borrow (<code><a href="../suilend/obligation.md#suilend_obligation_EObligationIsNotHealthy">EObligationIsNotHealthy</a></code>).
* If borrowing an isolated asset when other borrows exist, or borrowing a
non-isolated asset when an isolated asset is already borrowed (<code><a href="../suilend/obligation.md#suilend_obligation_EIsolatedAssetViolation">EIsolatedAssetViolation</a></code>).
* If the <code>reserve_array_index</code> of the borrow is invalid or out of bounds for the <code>reserves</code> vector.
* If the <code>user_reward_manager_index</code> is invalid or out of bounds for the <code><a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a></code> vector.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> Reserve&lt;P&gt;,
    clock: &Clock,
    amount: u64,
) {
    <b>let</b> borrow_index = <a href="../suilend/obligation.md#suilend_obligation_find_or_add_borrow">find_or_add_borrow</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock);
    <b>assert</b>!(vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>) &lt;= <a href="../suilend/obligation.md#suilend_obligation_MAX_BORROWS">MAX_BORROWS</a>, <a href="../suilend/obligation.md#suilend_obligation_ETooManyBorrows">ETooManyBorrows</a>);
    <b>let</b> deposit_index = <a href="../suilend/obligation.md#suilend_obligation_find_deposit_index">find_deposit_index</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>assert</b>!(
        deposit_index == vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>),
        <a href="../suilend/obligation.md#suilend_obligation_ECannotDepositAndBorrowSameAsset">ECannotDepositAndBorrowSameAsset</a>,
    );
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>, borrow_index);
    <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a> = add(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(amount));
    // update health values
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_borrow_market_value">borrow_market_value</a> = <a href="../suilend/reserve.md#suilend_reserve_market_value">reserve::market_value</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(amount));
    <b>let</b> borrow_market_value_upper_bound = <a href="../suilend/reserve.md#suilend_reserve_market_value_upper_bound">reserve::market_value_upper_bound</a>(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(amount),
    );
    <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.market_value = add(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.market_value, <a href="../suilend/obligation.md#suilend_obligation_borrow_market_value">borrow_market_value</a>);
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a> =
        add(
            <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a>,
            <a href="../suilend/obligation.md#suilend_obligation_borrow_market_value">borrow_market_value</a>,
        );
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a> =
        add(
            <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>,
            mul(<a href="../suilend/obligation.md#suilend_obligation_borrow_market_value">borrow_market_value</a>, borrow_weight(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>))),
        );
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a> =
        add(
            <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>,
            mul(borrow_market_value_upper_bound, borrow_weight(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>))),
        );
    <b>let</b> user_reward_manager = vector::borrow_mut(
        &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>,
        <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.user_reward_manager_index,
    );
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_change_user_reward_manager_share">liquidity_mining::change_user_reward_manager_share</a>(
        <a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager_mut">reserve::borrows_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        user_reward_manager,
        <a href="../suilend/obligation.md#suilend_obligation_liability_shares">liability_shares</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>),
        clock,
    );
    <b>assert</b>!(<a href="../suilend/obligation.md#suilend_obligation_is_healthy">is_healthy</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>), <a href="../suilend/obligation.md#suilend_obligation_EObligationIsNotHealthy">EObligationIsNotHealthy</a>);
    <b>if</b> (isolated(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)) || <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowing_isolated_asset">borrowing_isolated_asset</a>) {
        <b>assert</b>!(vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>) == 1, <a href="../suilend/obligation.md#suilend_obligation_EIsolatedAssetViolation">EIsolatedAssetViolation</a>);
    };
    <a href="../suilend/obligation.md#suilend_obligation_log_obligation_data">log_obligation_data</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>);
}
</code></pre>



</details>

<a name="suilend_obligation_repay"></a>

## Function `repay`

Processes a repay action on a borrow within the obligation.

This function handles the repayment of a borrowed asset. It first ensures that the
reserve's interest is up-to-date before proceeding. The function locates the
corresponding borrow in the obligation, compounds the debt to the current time,
and then calculates the amount to be repaid, capped by <code>max_repay_amount</code>.

After reducing the borrowed amount, it updates the obligation's health metrics.
If the full borrow is repaid, the borrow entry is removed from the obligation.
The user's reward manager share is also updated to reflect the change in their
liability.


<a name="@Arguments_10"></a>

### Arguments


* <code><a href="../suilend/obligation.md#suilend_obligation">obligation</a></code>: A mutable reference to the <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a></code> containing the borrow.
* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code>: A mutable reference to the <code>Reserve</code> of the asset being repaid.
* <code>clock</code>: A reference to the <code>Clock</code> for timestamp-based calculations.
* <code>max_repay_amount</code>: The maximum amount to repay, specified as a <code>Decimal</code>.


<a name="@Returns_11"></a>

### Returns


* <code>Decimal</code>: The actual amount that was repaid.


<a name="@Panics_12"></a>

### Panics


* If the obligation does not have a borrow for the specified reserve (<code><a href="../suilend/obligation.md#suilend_obligation_EBorrowNotFound">EBorrowNotFound</a></code>).
* If the <code>reserve_array_index</code> of the borrow is invalid or out of bounds
for the <code>reserves</code> vector.
* If the <code>user_reward_manager_index</code> is invalid or out of bounds for the
<code><a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a></code> vector.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_repay">repay</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, max_repay_amount: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_repay">repay</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> Reserve&lt;P&gt;,
    clock: &Clock,
    max_repay_amount: Decimal,
): Decimal {
    <b>let</b> borrow_index = <a href="../suilend/obligation.md#suilend_obligation_find_borrow_index">find_borrow_index</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>assert</b>!(borrow_index &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>), <a href="../suilend/obligation.md#suilend_obligation_EBorrowNotFound">EBorrowNotFound</a>);
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>, borrow_index);
    <b>let</b> old_borrow_amount = <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>;
    <a href="../suilend/obligation.md#suilend_obligation_compound_debt">compound_debt</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>let</b> repay_amount = min(max_repay_amount, <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>);
    <b>let</b> interest_diff = sub(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>, old_borrow_amount);
    <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a> = sub(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>, repay_amount);
    // update other health values. note that we don't enforce price freshness here. this is purely
    // to make offchain accounting easier. any operation that requires price
    // freshness (<a href="../suilend/obligation.md#suilend_obligation_withdraw">withdraw</a>, <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>, <a href="../suilend/obligation.md#suilend_obligation_liquidate">liquidate</a>) will <a href="../suilend/obligation.md#suilend_obligation_refresh">refresh</a> the <a href="../suilend/obligation.md#suilend_obligation">obligation</a> right before.
    <b>if</b> (le(interest_diff, repay_amount)) {
        <b>let</b> diff = saturating_sub(repay_amount, interest_diff);
        <b>let</b> repay_value = <a href="../suilend/reserve.md#suilend_reserve_market_value">reserve::market_value</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, diff);
        <b>let</b> repay_value_upper_bound = <a href="../suilend/reserve.md#suilend_reserve_market_value_upper_bound">reserve::market_value_upper_bound</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, diff);
        <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.market_value = saturating_sub(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.market_value, repay_value);
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a> =
            saturating_sub(
                <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a>,
                repay_value,
            );
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a> =
            saturating_sub(
                <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>,
                mul(repay_value, borrow_weight(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>))),
            );
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a> =
            saturating_sub(
                <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>,
                mul(repay_value_upper_bound, borrow_weight(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>))),
            );
    } <b>else</b> {
        <b>let</b> additional_borrow_amount = saturating_sub(interest_diff, repay_amount);
        <b>let</b> additional_borrow_value = <a href="../suilend/reserve.md#suilend_reserve_market_value">reserve::market_value</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, additional_borrow_amount);
        <b>let</b> additional_borrow_value_upper_bound = <a href="../suilend/reserve.md#suilend_reserve_market_value_upper_bound">reserve::market_value_upper_bound</a>(
            <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
            additional_borrow_amount,
        );
        <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.market_value = add(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.market_value, additional_borrow_value);
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a> =
            add(
                <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a>,
                additional_borrow_value,
            );
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a> =
            add(
                <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>,
                mul(additional_borrow_value, borrow_weight(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>))),
            );
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a> =
            add(
                <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>,
                mul(additional_borrow_value_upper_bound, borrow_weight(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>))),
            );
    };
    <b>let</b> user_reward_manager = vector::borrow_mut(
        &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>,
        <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.user_reward_manager_index,
    );
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_change_user_reward_manager_share">liquidity_mining::change_user_reward_manager_share</a>(
        <a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager_mut">reserve::borrows_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        user_reward_manager,
        <a href="../suilend/obligation.md#suilend_obligation_liability_shares">liability_shares</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>),
        clock,
    );
    <b>if</b> (eq(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0))) {
        <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_Borrow">Borrow</a> {
            coin_type: _,
            reserve_array_index: _,
            <a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>: _,
            cumulative_borrow_rate: _,
            market_value: _,
            user_reward_manager_index: _,
        } = vector::remove(&<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>, borrow_index);
    };
    <a href="../suilend/obligation.md#suilend_obligation_log_obligation_data">log_obligation_data</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>);
    repay_amount
}
</code></pre>



</details>

<a name="suilend_obligation_withdraw"></a>

## Function `withdraw`

Processes a withdrawal from the obligation, ensuring the obligation remains healthy.

This function handles the withdrawal of a specified amount of ctokens from a reserve.
It first checks for stale oracle prices, allowing the withdrawal to proceed without
fresh prices only if the obligation has no borrows. Otherwise, it asserts that
oracle prices are not stale.

The core withdrawal logic is handled by <code><a href="../suilend/obligation.md#suilend_obligation_withdraw_unchecked">withdraw_unchecked</a></code>, which updates the
obligation's health metrics. After the withdrawal, this function asserts that the
obligation is still healthy (<code><a href="../suilend/obligation.md#suilend_obligation_is_healthy">is_healthy</a></code>) to prevent under-collateralization.


<a name="@Arguments_13"></a>

### Arguments


* <code><a href="../suilend/obligation.md#suilend_obligation">obligation</a></code>: A mutable reference to the <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a></code> from which to withdraw.
* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code>: A mutable reference to the <code>Reserve</code> of the asset being withdrawn.
* <code>clock</code>: A reference to the <code>Clock</code> for timestamp-based calculations.
* <code>ctoken_amount</code>: The amount of ctokens to withdraw.
* <code>stale_oracles</code>: An <code>Option&lt;<a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">ExistStaleOracles</a>&gt;</code> indicating if oracle prices are stale.


<a name="@Panics_14"></a>

### Panics


* If <code>stale_oracles</code> is <code>Some</code> and the obligation has borrows (<code><a href="../suilend/obligation.md#suilend_obligation_EOraclesAreStale">EOraclesAreStale</a></code>).
* If the obligation does not have a deposit for the specified reserve (<code><a href="../suilend/obligation.md#suilend_obligation_EDepositNotFound">EDepositNotFound</a></code>).
* If the obligation is not healthy after the withdrawal (<code><a href="../suilend/obligation.md#suilend_obligation_EObligationIsNotHealthy">EObligationIsNotHealthy</a></code>).
* If the <code>reserve_array_index</code> of the deposit is invalid or out of bounds for the <code>reserves</code> vector.
* If the <code>user_reward_manager_index</code> is invalid or out of bounds for the <code><a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a></code> vector.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_withdraw">withdraw</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctoken_amount: u64, stale_oracles: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">suilend::obligation::ExistStaleOracles</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_withdraw">withdraw</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> Reserve&lt;P&gt;,
    clock: &Clock,
    ctoken_amount: u64,
    stale_oracles: Option&lt;<a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">ExistStaleOracles</a>&gt;,
) {
    <b>if</b> (stale_oracles.is_some() && vector::is_empty(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>)) {
        <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">ExistStaleOracles</a> {} = option::destroy_some(stale_oracles);
    } <b>else</b> {
        <a href="../suilend/obligation.md#suilend_obligation_assert_no_stale_oracles">assert_no_stale_oracles</a>(stale_oracles);
    };
    <a href="../suilend/obligation.md#suilend_obligation_withdraw_unchecked">withdraw_unchecked</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock, ctoken_amount);
    <b>assert</b>!(<a href="../suilend/obligation.md#suilend_obligation_is_healthy">is_healthy</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>), <a href="../suilend/obligation.md#suilend_obligation_EObligationIsNotHealthy">EObligationIsNotHealthy</a>);
    <a href="../suilend/obligation.md#suilend_obligation_log_obligation_data">log_obligation_data</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>);
}
</code></pre>



</details>

<a name="suilend_obligation_liquidate"></a>

## Function `liquidate`

Liquidates a portion of an unhealthy obligation, repaying a borrowed asset and seizing
collateral.

This function is called by a liquidator when an obligation's health factor falls below
the liquidation threshold (<code><a href="../suilend/obligation.md#suilend_obligation_is_liquidatable">is_liquidatable</a></code> returns <code><b>true</b></code>). The liquidator repays a
portion of a borrowed asset and receives a discounted amount of collateral in return.
The amount of collateral seized includes a liquidation bonus and a protocol fee.

The amount to be repaid is capped by a close factor, ensuring that only a portion of
the debt can be liquidated in a single transaction, unless the borrow value is very small.


<a name="@Arguments_15"></a>

### Arguments


* <code><a href="../suilend/obligation.md#suilend_obligation">obligation</a></code>: A mutable reference to the <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a></code> being liquidated.
* <code>reserves</code>: A mutable reference to the <code>vector&lt;Reserve&lt;P&gt;&gt;</code> from the lending market.
* <code>repay_reserve_array_index</code>: The array index of the reserve for the asset being repaid.
* <code>withdraw_reserve_array_index</code>: The array index of the reserve for the collateral being seized.
* <code>clock</code>: A reference to the <code>Clock</code> for timestamp-based calculations.
* <code>repay_amount</code>: The amount of the borrowed asset that the liquidator intends to repay.


<a name="@Returns_16"></a>

### Returns


* <code>(u64, Decimal)</code>: A tuple containing:
- The amount of ctokens withdrawn from the collateral reserve.
- The actual amount of the borrowed asset that was repaid.


<a name="@Panics_17"></a>

### Panics


This function will panic under the following conditions:
* If the obligation is not liquidatable (i.e., <code><a href="../suilend/obligation.md#suilend_obligation_is_liquidatable">is_liquidatable</a></code> is <code><b>false</b></code>).
* If the <code>repay_reserve_array_index</code> or <code>withdraw_reserve_array_index</code> are out of bounds for the <code>reserves</code> vector.
* If the obligation does not have a borrow for the specified repay reserve.
* If the obligation does not have a deposit for the specified withdraw reserve.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_liquidate">liquidate</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, reserves: &<b>mut</b> vector&lt;<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;&gt;, repay_reserve_array_index: u64, withdraw_reserve_array_index: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, repay_amount: u64): (u64, <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_liquidate">liquidate</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    reserves: &<b>mut</b> vector&lt;Reserve&lt;P&gt;&gt;,
    repay_reserve_array_index: u64,
    withdraw_reserve_array_index: u64,
    clock: &Clock,
    repay_amount: u64,
): (u64, Decimal) {
    <b>assert</b>!(<a href="../suilend/obligation.md#suilend_obligation_is_liquidatable">is_liquidatable</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>), <a href="../suilend/obligation.md#suilend_obligation_EObligationIsNotLiquidatable">EObligationIsNotLiquidatable</a>);
    <b>let</b> repay_reserve = vector::borrow(reserves, repay_reserve_array_index);
    <b>let</b> withdraw_reserve = vector::borrow(reserves, withdraw_reserve_array_index);
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a> = <a href="../suilend/obligation.md#suilend_obligation_find_borrow">find_borrow</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, repay_reserve);
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a> = <a href="../suilend/obligation.md#suilend_obligation_find_deposit">find_deposit</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, withdraw_reserve);
    // <b>invariant</b>: repay_amount &lt;= <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>
    <b>let</b> repay_amount = <b>if</b> (le(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.market_value, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1))) {
        // full liquidation
        min(
            <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>,
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(repay_amount),
        )
    } <b>else</b> {
        // partial liquidation
        <b>let</b> max_repay_value = min(
            mul(
                <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>,
                <a href="../suilend/decimal.md#suilend_decimal_from_percent">decimal::from_percent</a>(<a href="../suilend/obligation.md#suilend_obligation_CLOSE_FACTOR_PCT">CLOSE_FACTOR_PCT</a>),
            ),
            <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.market_value,
        );
        // &lt;= 1
        <b>let</b> max_repay_pct = div(max_repay_value, <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.market_value);
        min(
            mul(max_repay_pct, <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>),
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(repay_amount),
        )
    };
    <b>let</b> repay_value = <a href="../suilend/reserve.md#suilend_reserve_market_value">reserve::market_value</a>(repay_reserve, repay_amount);
    <b>let</b> bonus = add(
        liquidation_bonus(config(withdraw_reserve)),
        protocol_liquidation_fee(config(withdraw_reserve)),
    );
    <b>let</b> withdraw_value = mul(
        repay_value,
        add(<a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1), bonus),
    );
    // <a href="../suilend/obligation.md#suilend_obligation_repay">repay</a> amount, but in decimals. called settle amount to keep logic in line with
    // spl-lending
    <b>let</b> final_settle_amount;
    <b>let</b> final_withdraw_amount;
    <b>if</b> (lt(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.market_value, withdraw_value)) {
        <b>let</b> repay_pct = div(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.market_value, withdraw_value);
        final_settle_amount = mul(repay_amount, repay_pct);
        final_withdraw_amount = <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>;
    } <b>else</b> {
        <b>let</b> withdraw_pct = div(withdraw_value, <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.market_value);
        final_settle_amount = repay_amount;
        final_withdraw_amount =
            floor(
                mul(<a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>), withdraw_pct),
            );
    };
    <a href="../suilend/obligation.md#suilend_obligation_repay">repay</a>(
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
        vector::borrow_mut(reserves, repay_reserve_array_index),
        clock,
        final_settle_amount,
    );
    <a href="../suilend/obligation.md#suilend_obligation_withdraw_unchecked">withdraw_unchecked</a>(
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
        vector::borrow_mut(reserves, withdraw_reserve_array_index),
        clock,
        final_withdraw_amount,
    );
    <a href="../suilend/obligation.md#suilend_obligation_log_obligation_data">log_obligation_data</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>);
    (final_withdraw_amount, final_settle_amount)
}
</code></pre>



</details>

<a name="suilend_obligation_forgive"></a>

## Function `forgive`

Forgives a portion of a borrow for an obligation that has no deposits.

This function is used to handle bad debt, where an obligation has outstanding borrows
but no collateral (deposits) to seize. It effectively allows for the reduction of
a borrow amount without requiring repayment from the borrower. The forgiven amount
is capped by <code>max_forgive_amount</code>.


<a name="@Arguments_18"></a>

### Arguments


* <code><a href="../suilend/obligation.md#suilend_obligation">obligation</a></code>: A mutable reference to the <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a></code> whose debt is being forgiven.
* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code>: A mutable reference to the <code>Reserve</code> of the asset being forgiven.
* <code>clock</code>: A reference to the <code>Clock</code> for timestamp-based calculations.
* <code>max_forgive_amount</code>: The maximum amount to forgive, specified as a <code>Decimal</code>.


<a name="@Returns_19"></a>

### Returns


* <code>Decimal</code>: The actual amount that was forgiven.


<a name="@Panics_20"></a>

### Panics


This function will panic under the following conditions:
* If the obligation is not forgivable (i.e., it still has deposits).
* If the obligation does not have a borrow for the specified reserve.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_forgive">forgive</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, max_forgive_amount: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_forgive">forgive</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> Reserve&lt;P&gt;,
    clock: &Clock,
    max_forgive_amount: Decimal,
): Decimal {
    <b>assert</b>!(<a href="../suilend/obligation.md#suilend_obligation_is_forgivable">is_forgivable</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>), <a href="../suilend/obligation.md#suilend_obligation_EObligationIsNotForgivable">EObligationIsNotForgivable</a>);
    // not logging here because it logs inside <a href="../suilend/obligation.md#suilend_obligation_repay">repay</a> instead
    <a href="../suilend/obligation.md#suilend_obligation_repay">repay</a>&lt;P&gt;(
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
        clock,
        max_forgive_amount,
    )
}
</code></pre>



</details>

<a name="suilend_obligation_claim_rewards"></a>

## Function `claim_rewards`

Claims liquidity mining rewards for an obligation from a specific reward pool.

This function locates the user's reward manager corresponding to the provided
<code>pool_reward_manager</code> within the obligation. It then calls the <code><a href="../suilend/obligation.md#suilend_obligation_claim_rewards">claim_rewards</a></code>
function from the <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining">liquidity_mining</a></code> module to process the reward claim.


<a name="@Arguments_21"></a>

### Arguments


* <code><a href="../suilend/obligation.md#suilend_obligation">obligation</a></code>: A mutable reference to the <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a></code> for which to claim rewards.
* <code>pool_reward_manager</code>: A mutable reference to the <code>PoolRewardManager</code> from which
rewards are being claimed.
* <code>clock</code>: A reference to the <code>Clock</code> for timestamp-based calculations.
* <code>reward_index</code>: The index of the reward to claim within the pool.


<a name="@Returns_22"></a>

### Returns


* <code>Balance&lt;T&gt;</code>: A <code>Balance</code> object containing the claimed reward tokens of type <code>T</code>.


<a name="@Panics_23"></a>

### Panics


This function will panic under the following conditions:
* If a <code>user_reward_manager</code> corresponding to the <code>pool_reward_manager</code> is not found
in the obligation.
* If the <code>reward_index</code> is out of bounds for the rewards in the <code>pool_reward_manager</code>.
* It will also propagate any panics from <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_claim_rewards">liquidity_mining::claim_rewards</a></code>.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_claim_rewards">claim_rewards</a>&lt;P, T&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, reward_index: u64): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_claim_rewards">claim_rewards</a>&lt;P, T&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    pool_reward_manager: &<b>mut</b> PoolRewardManager,
    clock: &Clock,
    reward_index: u64,
): Balance&lt;T&gt; {
    <b>let</b> user_reward_manager_index = <a href="../suilend/obligation.md#suilend_obligation_find_user_reward_manager_index">find_user_reward_manager_index</a>(
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
        pool_reward_manager,
    );
    <b>let</b> user_reward_manager = vector::borrow_mut(
        &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>,
        user_reward_manager_index,
    );
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_claim_rewards">liquidity_mining::claim_rewards</a>&lt;T&gt;(
        pool_reward_manager,
        user_reward_manager,
        clock,
        reward_index,
    )
}
</code></pre>



</details>

<a name="suilend_obligation_deposits"></a>

## Function `deposits`

Get the deposits of the obligation.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): &vector&lt;<a href="../suilend/obligation.md#suilend_obligation_Deposit">suilend::obligation::Deposit</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): &vector&lt;<a href="../suilend/obligation.md#suilend_obligation_Deposit">Deposit</a>&gt; {
    &<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>
}
</code></pre>



</details>

<a name="suilend_obligation_borrows"></a>

## Function `borrows`

Get the borrows of the obligation.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): &vector&lt;<a href="../suilend/obligation.md#suilend_obligation_Borrow">suilend::obligation::Borrow</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): &vector&lt;<a href="../suilend/obligation.md#suilend_obligation_Borrow">Borrow</a>&gt; {
    &<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>
}
</code></pre>



</details>

<a name="suilend_obligation_deposited_value_usd"></a>

## Function `deposited_value_usd`

Get the deposited value in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): Decimal {
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a>
}
</code></pre>



</details>

<a name="suilend_obligation_allowed_borrow_value_usd"></a>

## Function `allowed_borrow_value_usd`

Get the allowed borrow value in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): Decimal {
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>
}
</code></pre>



</details>

<a name="suilend_obligation_unhealthy_borrow_value_usd"></a>

## Function `unhealthy_borrow_value_usd`

Get the unhealthy borrow value in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): Decimal {
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a>
}
</code></pre>



</details>

<a name="suilend_obligation_unweighted_borrowed_value_usd"></a>

## Function `unweighted_borrowed_value_usd`

Get the unweighted borrowed value in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): Decimal {
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a>
}
</code></pre>



</details>

<a name="suilend_obligation_weighted_borrowed_value_usd"></a>

## Function `weighted_borrowed_value_usd`

Get the weighted borrowed value in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): Decimal {
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>
}
</code></pre>



</details>

<a name="suilend_obligation_weighted_borrowed_value_upper_bound_usd"></a>

## Function `weighted_borrowed_value_upper_bound_usd`

Get the weighted borrowed value upper bound in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): Decimal {
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>
}
</code></pre>



</details>

<a name="suilend_obligation_borrowing_isolated_asset"></a>

## Function `borrowing_isolated_asset`

Whether the obligation is borrowing an isolated asset.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrowing_isolated_asset">borrowing_isolated_asset</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrowing_isolated_asset">borrowing_isolated_asset</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): bool {
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowing_isolated_asset">borrowing_isolated_asset</a>
}
</code></pre>



</details>

<a name="suilend_obligation_user_reward_managers"></a>

## Function `user_reward_managers`

Get the user reward managers of the obligation.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): &vector&lt;<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">suilend::liquidity_mining::UserRewardManager</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): &vector&lt;UserRewardManager&gt; {
    &<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>
}
</code></pre>



</details>

<a name="suilend_obligation_deposit_coin_type"></a>

## Function `deposit_coin_type`

Get the coin type of the deposit.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposit_coin_type">deposit_coin_type</a>(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>: &<a href="../suilend/obligation.md#suilend_obligation_Deposit">suilend::obligation::Deposit</a>): <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposit_coin_type">deposit_coin_type</a>(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>: &<a href="../suilend/obligation.md#suilend_obligation_Deposit">Deposit</a>): TypeName {
    <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.coin_type
}
</code></pre>



</details>

<a name="suilend_obligation_deposit_reserve_array_index"></a>

## Function `deposit_reserve_array_index`

Get the reserve array index of the deposit.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposit_reserve_array_index">deposit_reserve_array_index</a>(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>: &<a href="../suilend/obligation.md#suilend_obligation_Deposit">suilend::obligation::Deposit</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposit_reserve_array_index">deposit_reserve_array_index</a>(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>: &<a href="../suilend/obligation.md#suilend_obligation_Deposit">Deposit</a>): u64 {
    <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.reserve_array_index
}
</code></pre>



</details>

<a name="suilend_obligation_deposit_deposited_ctoken_amount"></a>

## Function `deposit_deposited_ctoken_amount`

Get the deposited ctoken amount of the deposit.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposit_deposited_ctoken_amount">deposit_deposited_ctoken_amount</a>(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>: &<a href="../suilend/obligation.md#suilend_obligation_Deposit">suilend::obligation::Deposit</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposit_deposited_ctoken_amount">deposit_deposited_ctoken_amount</a>(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>: &<a href="../suilend/obligation.md#suilend_obligation_Deposit">Deposit</a>): u64 {
    <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>
}
</code></pre>



</details>

<a name="suilend_obligation_deposit_market_value"></a>

## Function `deposit_market_value`

Get the market value of the deposit.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposit_market_value">deposit_market_value</a>(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>: &<a href="../suilend/obligation.md#suilend_obligation_Deposit">suilend::obligation::Deposit</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposit_market_value">deposit_market_value</a>(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>: &<a href="../suilend/obligation.md#suilend_obligation_Deposit">Deposit</a>): Decimal {
    <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.market_value
}
</code></pre>



</details>

<a name="suilend_obligation_deposit_user_reward_manager_index"></a>

## Function `deposit_user_reward_manager_index`

Get the user reward manager index of the deposit.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposit_user_reward_manager_index">deposit_user_reward_manager_index</a>(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>: &<a href="../suilend/obligation.md#suilend_obligation_Deposit">suilend::obligation::Deposit</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposit_user_reward_manager_index">deposit_user_reward_manager_index</a>(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>: &<a href="../suilend/obligation.md#suilend_obligation_Deposit">Deposit</a>): u64 {
    <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.user_reward_manager_index
}
</code></pre>



</details>

<a name="suilend_obligation_borrow_coin_type"></a>

## Function `borrow_coin_type`

Get the coin type of the borrow.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow_coin_type">borrow_coin_type</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">suilend::obligation::Borrow</a>): <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow_coin_type">borrow_coin_type</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">Borrow</a>): TypeName {
    <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.coin_type
}
</code></pre>



</details>

<a name="suilend_obligation_borrow_reserve_array_index"></a>

## Function `borrow_reserve_array_index`

Get the reserve array index of the borrow.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow_reserve_array_index">borrow_reserve_array_index</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">suilend::obligation::Borrow</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow_reserve_array_index">borrow_reserve_array_index</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">Borrow</a>): u64 {
    <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.reserve_array_index
}
</code></pre>



</details>

<a name="suilend_obligation_borrow_borrowed_amount"></a>

## Function `borrow_borrowed_amount`

Get the borrowed amount of the borrow.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow_borrowed_amount">borrow_borrowed_amount</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">suilend::obligation::Borrow</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow_borrowed_amount">borrow_borrowed_amount</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">Borrow</a>): Decimal {
    <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>
}
</code></pre>



</details>

<a name="suilend_obligation_borrow_cumulative_borrow_rate"></a>

## Function `borrow_cumulative_borrow_rate`

Get the cumulative borrow rate of the borrow.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow_cumulative_borrow_rate">borrow_cumulative_borrow_rate</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">suilend::obligation::Borrow</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow_cumulative_borrow_rate">borrow_cumulative_borrow_rate</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">Borrow</a>): Decimal {
    <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.cumulative_borrow_rate
}
</code></pre>



</details>

<a name="suilend_obligation_borrow_market_value"></a>

## Function `borrow_market_value`

Get the market value of the borrow.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow_market_value">borrow_market_value</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">suilend::obligation::Borrow</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow_market_value">borrow_market_value</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">Borrow</a>): Decimal {
    <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.market_value
}
</code></pre>



</details>

<a name="suilend_obligation_borrow_user_reward_manager_index"></a>

## Function `borrow_user_reward_manager_index`

Get the user reward manager index of the borrow.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow_user_reward_manager_index">borrow_user_reward_manager_index</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">suilend::obligation::Borrow</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrow_user_reward_manager_index">borrow_user_reward_manager_index</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">Borrow</a>): u64 {
    <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.user_reward_manager_index
}
</code></pre>



</details>

<a name="suilend_obligation_deposited_ctoken_amount"></a>

## Function `deposited_ctoken_amount`

Get the deposited ctoken amount of a specific coin type.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>&lt;P, T&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>&lt;P, T&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): u64 {
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>)) {
        <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a> = vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>, i);
        <b>if</b> (<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.coin_type == type_name::get&lt;T&gt;()) {
            <b>return</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>
        };
        i = i + 1;
    };
    0
}
</code></pre>



</details>

<a name="suilend_obligation_borrowed_amount"></a>

## Function `borrowed_amount`

Get the borrowed amount of a specific coin type.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>&lt;P, T&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>&lt;P, T&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): Decimal {
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>)) {
        <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a> = vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>, i);
        <b>if</b> (<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.coin_type == type_name::get&lt;T&gt;()) {
            <b>return</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>
        };
        i = i + 1;
    };
    <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0)
}
</code></pre>



</details>

<a name="suilend_obligation_is_healthy"></a>

## Function `is_healthy`

Whether the obligation is healthy.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_is_healthy">is_healthy</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_is_healthy">is_healthy</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): bool {
    le(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>, <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>)
}
</code></pre>



</details>

<a name="suilend_obligation_is_liquidatable"></a>

## Function `is_liquidatable`

Whether the obligation is liquidatable.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_is_liquidatable">is_liquidatable</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_is_liquidatable">is_liquidatable</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): bool {
    gt(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>, <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a>)
}
</code></pre>



</details>

<a name="suilend_obligation_is_forgivable"></a>

## Function `is_forgivable`

Whether the obligation is forgivable.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_is_forgivable">is_forgivable</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_is_forgivable">is_forgivable</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): bool {
    vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>) == 0
}
</code></pre>



</details>

<a name="suilend_obligation_max_borrow_amount"></a>

## Function `max_borrow_amount`

Calculates the maximum amount of a token that can be borrowed from a reserve
without exceeding the obligation's borrowing limit.

This function determines the remaining borrowing capacity in USD, adjusts it by the
asset's borrow weight, and converts it to the corresponding token amount using a
conservative price estimate.


<a name="@Arguments_24"></a>

### Arguments


* <code><a href="../suilend/obligation.md#suilend_obligation">obligation</a></code>: A reference to the <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a></code> for which to calculate the borrow limit.
* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code>: A reference to the <code>Reserve</code> of the asset to be borrowed.


<a name="@Returns_25"></a>

### Returns


* <code>u64</code>: The maximum amount of the token that can be borrowed, floored to the nearest integer.


<a name="@Panics_26"></a>

### Panics


* If the <code>borrow_weight</code> of the reserve is zero, as this would lead to division by zero.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_max_borrow_amount">max_borrow_amount</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_max_borrow_amount">max_borrow_amount</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &Reserve&lt;P&gt;,
): u64 {
    floor(
        <a href="../suilend/reserve.md#suilend_reserve_usd_to_token_amount_lower_bound">reserve::usd_to_token_amount_lower_bound</a>(
            <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
            div(
                saturating_sub(
                    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>,
                    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>,
                ),
                borrow_weight(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)),
            ),
        ),
    )
}
</code></pre>



</details>

<a name="suilend_obligation_max_withdraw_amount"></a>

## Function `max_withdraw_amount`

Calculates the maximum amount of ctokens that can be withdrawn from a reserve
without making the obligation unhealthy.

This function determines the remaining borrowing capacity in USD, converts it to the
equivalent value of the collateral asset, and then finds the corresponding ctoken amount.
The result is capped by the actual amount of ctokens deposited. If the obligation has
no borrows, the full deposit amount can be withdrawn.


<a name="@Arguments_27"></a>

### Arguments


* <code><a href="../suilend/obligation.md#suilend_obligation">obligation</a></code>: A reference to the <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a></code> from which to withdraw.
* <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code>: A reference to the <code>Reserve</code> of the asset being withdrawn.


<a name="@Returns_28"></a>

### Returns


* <code>u64</code>: The maximum amount of ctokens that can be withdrawn.


<a name="@Panics_29"></a>

### Panics


* Panics with <code><a href="../suilend/obligation.md#suilend_obligation_EDepositNotFound">EDepositNotFound</a></code> if the obligation does not have a deposit for the
specified <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code>.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_max_withdraw_amount">max_withdraw_amount</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_max_withdraw_amount">max_withdraw_amount</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &Reserve&lt;P&gt;,
): u64 {
    <b>let</b> deposit_index = <a href="../suilend/obligation.md#suilend_obligation_find_deposit_index">find_deposit_index</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>assert</b>!(deposit_index &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>), <a href="../suilend/obligation.md#suilend_obligation_EDepositNotFound">EDepositNotFound</a>);
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a> = vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>, deposit_index);
    <b>if</b> (
        open_ltv(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)) == <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0) || vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>) == 0
    ) {
        <b>return</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>
    };
    <b>let</b> max_withdraw_value = div(
        saturating_sub(
            <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>,
            <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>,
        ),
        open_ltv(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)),
    );
    <b>let</b> max_withdraw_token_amount = <a href="../suilend/reserve.md#suilend_reserve_usd_to_token_amount_upper_bound">reserve::usd_to_token_amount_upper_bound</a>(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
        max_withdraw_value,
    );
    floor(
        min(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>),
            div(
                max_withdraw_token_amount,
                <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">reserve::ctoken_ratio</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
            ),
        ),
    )
}
</code></pre>



</details>

<a name="suilend_obligation_assert_no_stale_oracles"></a>

## Function `assert_no_stale_oracles`

Asserts that no stale oracles were detected during an obligation refresh.

This function is a utility to ensure that operations requiring fresh oracle prices
do not proceed if any of the relevant prices are stale. It takes an <code>Option&lt;<a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">ExistStaleOracles</a>&gt;</code>
which is returned by the <code><a href="../suilend/obligation.md#suilend_obligation_refresh">refresh</a></code> function.


<a name="@Arguments_30"></a>

### Arguments


* <code>exist_stale_oracles</code>: An <code>Option&lt;<a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">ExistStaleOracles</a>&gt;</code> which is <code>Some</code> if stale oracles
were found, and <code>None</code> otherwise.


<a name="@Panics_31"></a>

### Panics


* Panics with <code><a href="../suilend/obligation.md#suilend_obligation_EOraclesAreStale">EOraclesAreStale</a></code> if <code>exist_stale_oracles</code> is <code>Some</code>.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_assert_no_stale_oracles">assert_no_stale_oracles</a>(exist_stale_oracles: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">suilend::obligation::ExistStaleOracles</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_assert_no_stale_oracles">assert_no_stale_oracles</a>(exist_stale_oracles: Option&lt;<a href="../suilend/obligation.md#suilend_obligation_ExistStaleOracles">ExistStaleOracles</a>&gt;) {
    <b>assert</b>!(option::is_none(&exist_stale_oracles), <a href="../suilend/obligation.md#suilend_obligation_EOraclesAreStale">EOraclesAreStale</a>);
    option::destroy_none(exist_stale_oracles);
}
</code></pre>



</details>

<a name="suilend_obligation_zero_out_rewards_if_looped"></a>

## Function `zero_out_rewards_if_looped`

Checks if an obligation is in a "looped" state and zeroes out its liquidity mining
rewards if it is.

A looped state is defined by specific pairings of deposits and borrows that are
disallowed to prevent reward farming exploits. This function calls <code><a href="../suilend/obligation.md#suilend_obligation_is_looped">is_looped</a></code> to
determine if the obligation matches any of these patterns. If it does, it calls
<code><a href="../suilend/obligation.md#suilend_obligation_zero_out_rewards">zero_out_rewards</a></code> to set the reward shares for all deposits and borrows in the
obligation to zero.


<a name="@Arguments_32"></a>

### Arguments


* <code><a href="../suilend/obligation.md#suilend_obligation">obligation</a></code>: A mutable reference to the <code><a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a></code> to be checked.
* <code>reserves</code>: A mutable reference to the <code>vector&lt;Reserve&lt;P&gt;&gt;</code> from the lending market.
* <code>clock</code>: A reference to the <code>Clock</code> for timestamp-based calculations.


<a name="@Panics_33"></a>

### Panics


* This function will propagate panics from <code><a href="../suilend/obligation.md#suilend_obligation_zero_out_rewards">zero_out_rewards</a></code>. This can occur if a
deposit or borrow in the obligation has an invalid <code>reserve_array_index</code> or
<code>user_reward_manager_index</code> that is out of bounds for the <code>reserves</code> or
<code><a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a></code> vectors, respectively.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_zero_out_rewards_if_looped">zero_out_rewards_if_looped</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, reserves: &<b>mut</b> vector&lt;<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_zero_out_rewards_if_looped">zero_out_rewards_if_looped</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    reserves: &<b>mut</b> vector&lt;Reserve&lt;P&gt;&gt;,
    clock: &Clock,
) {
    <b>if</b> (<a href="../suilend/obligation.md#suilend_obligation_is_looped">is_looped</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>)) {
        <a href="../suilend/obligation.md#suilend_obligation_zero_out_rewards">zero_out_rewards</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, reserves, clock);
    };
}
</code></pre>



</details>

<a name="suilend_obligation_is_looped"></a>

## Function `is_looped`

Checks if an obligation is in a "looped" state.

A looped state is defined as having a deposit and borrow of the same asset,
or having a deposit and borrow of a disabled pair of assets. This is to prevent
reward farming exploits.


<a name="@Panics_34"></a>

### Panics

* If the internal <code>target_reserve_array_indices</code> and <code>disabled_pairings_map</code> vectors
have inconsistent lengths, leading to an out-of-bounds access.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_is_looped">is_looped</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_is_looped">is_looped</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;): bool {
    <b>let</b> target_reserve_array_indices = vector[1, 2, 5, 7, 19, 20, 3, 9];
    // The vector target_reserve_array_indices maps to disabled_pairings_map
    // by corresponding indices of each element
    // target_reserve_index --&gt; pairings disabled
    <b>let</b> disabled_pairings_map = vector[
        vector[2, 5, 7, 19, 20], // 1 --&gt; [2, 5, 7, 19, 20]
        vector[1, 5, 7, 19, 20], // 2 --&gt; [1, 5, 7, 19, 20]
        vector[1, 2, 7, 19, 20], // 5 --&gt; [1, 2, 7, 19, 20]
        vector[1, 2, 5, 19, 20], // 7 --&gt; [1, 2, 5, 19, 20]
        vector[1, 2, 5, 7, 20], // 19 --&gt; [1, 2, 5, 7, 20]
        vector[1, 2, 5, 7, 19], // 20 --&gt; [1, 2, 5, 7, 19]
        vector[9], // 3 --&gt; [9]
        vector[3], // 9 --&gt; [3]
    ];
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>)) {
        <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a> = vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>, i);
        // Check <b>if</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>-<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> match
        <b>let</b> deposit_index = <a href="../suilend/obligation.md#suilend_obligation_find_deposit_index_by_reserve_array_index">find_deposit_index_by_reserve_array_index</a>(
            <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
            <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.reserve_array_index,
        );
        <b>if</b> (deposit_index &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>)) {
            <b>return</b> <b>true</b>
        };
        <b>let</b> (has_target_borrow_idx, target_borrow_idx) = vector::index_of(
            &target_reserve_array_indices,
            &<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.reserve_array_index,
        );
        // If the borrowing is over a targetted <a href="../suilend/reserve.md#suilend_reserve">reserve</a>
        // we check <b>if</b> the <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> is a disabled pair
        <b>if</b> (has_target_borrow_idx) {
            <b>let</b> disabled_pairs = vector::borrow(&disabled_pairings_map, target_borrow_idx);
            <b>let</b> pair_count = vector::length(disabled_pairs);
            <b>let</b> <b>mut</b> i = 0;
            <b>while</b> (i &lt; pair_count) {
                <b>let</b> disabled_reserve_array_index = *vector::borrow(disabled_pairs, i);
                <b>let</b> deposit_index = <a href="../suilend/obligation.md#suilend_obligation_find_deposit_index_by_reserve_array_index">find_deposit_index_by_reserve_array_index</a>(
                    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
                    disabled_reserve_array_index,
                );
                <b>if</b> (deposit_index &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>)) {
                    <b>return</b> <b>true</b>
                };
                i = i +1;
            };
        };
        i = i + 1;
    };
    <b>false</b>
}
</code></pre>



</details>

<a name="suilend_obligation_zero_out_rewards"></a>

## Function `zero_out_rewards`



<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_zero_out_rewards">zero_out_rewards</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, reserves: &<b>mut</b> vector&lt;<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_zero_out_rewards">zero_out_rewards</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    reserves: &<b>mut</b> vector&lt;Reserve&lt;P&gt;&gt;,
    clock: &Clock,
) {
    {
        <b>let</b> <b>mut</b> i = 0;
        <b>while</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>)) {
            <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a> = vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>, i);
            <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(reserves, <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.reserve_array_index);
            <b>let</b> user_reward_manager = vector::borrow_mut(
                &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>,
                <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.user_reward_manager_index,
            );
            <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_change_user_reward_manager_share">liquidity_mining::change_user_reward_manager_share</a>(
                <a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager_mut">reserve::deposits_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
                user_reward_manager,
                0,
                clock,
            );
            i = i + 1;
        };
    };
    {
        <b>let</b> <b>mut</b> i = 0;
        <b>while</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>)) {
            <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a> = vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>, i);
            <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(reserves, <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.reserve_array_index);
            <b>let</b> user_reward_manager = vector::borrow_mut(
                &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>,
                <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.user_reward_manager_index,
            );
            <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_change_user_reward_manager_share">liquidity_mining::change_user_reward_manager_share</a>(
                <a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager_mut">reserve::borrows_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
                user_reward_manager,
                0,
                clock,
            );
            i = i + 1;
        };
    };
}
</code></pre>



</details>

<a name="suilend_obligation_log_obligation_data"></a>

## Function `log_obligation_data`



<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_log_obligation_data">log_obligation_data</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_log_obligation_data">log_obligation_data</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;) {
    event::emit(<a href="../suilend/obligation.md#suilend_obligation_ObligationDataEvent">ObligationDataEvent</a> {
        lending_market_id: object::id_to_address(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.lending_market_id),
        obligation_id: object::uid_to_address(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.id),
        <a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>: {
            <b>let</b> <b>mut</b> i = 0;
            <b>let</b> <b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a> = vector::empty&lt;<a href="../suilend/obligation.md#suilend_obligation_DepositRecord">DepositRecord</a>&gt;();
            <b>while</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>)) {
                <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a> = vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>, i);
                vector::push_back(
                    &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>,
                    <a href="../suilend/obligation.md#suilend_obligation_DepositRecord">DepositRecord</a> {
                        coin_type: <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.coin_type,
                        reserve_array_index: <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.reserve_array_index,
                        <a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>: <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>,
                        market_value: <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.market_value,
                        user_reward_manager_index: <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.user_reward_manager_index,
                        attributed_borrow_value: <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.attributed_borrow_value,
                    },
                );
                i = i + 1;
            };
            <a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>
        },
        <a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>: {
            <b>let</b> <b>mut</b> i = 0;
            <b>let</b> <b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a> = vector::empty&lt;<a href="../suilend/obligation.md#suilend_obligation_BorrowRecord">BorrowRecord</a>&gt;();
            <b>while</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>)) {
                <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a> = vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>, i);
                vector::push_back(
                    &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>,
                    <a href="../suilend/obligation.md#suilend_obligation_BorrowRecord">BorrowRecord</a> {
                        coin_type: <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.coin_type,
                        reserve_array_index: <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.reserve_array_index,
                        <a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>: <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>,
                        cumulative_borrow_rate: <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.cumulative_borrow_rate,
                        market_value: <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.market_value,
                        user_reward_manager_index: <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.user_reward_manager_index,
                    },
                );
                i = i + 1;
            };
            <a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>
        },
        <a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a>: <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a>,
        <a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>: <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>,
        <a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a>: <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a>,
        super_unhealthy_borrow_value_usd: <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.super_unhealthy_borrow_value_usd,
        <a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a>: <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unweighted_borrowed_value_usd">unweighted_borrowed_value_usd</a>,
        <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>: <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_usd">weighted_borrowed_value_usd</a>,
        <a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>: <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_weighted_borrowed_value_upper_bound_usd">weighted_borrowed_value_upper_bound_usd</a>,
        <a href="../suilend/obligation.md#suilend_obligation_borrowing_isolated_asset">borrowing_isolated_asset</a>: <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowing_isolated_asset">borrowing_isolated_asset</a>,
        bad_debt_usd: <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.bad_debt_usd,
        closable: <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.closable,
    });
}
</code></pre>



</details>

<a name="suilend_obligation_liability_shares"></a>

## Function `liability_shares`



<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_liability_shares">liability_shares</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">suilend::obligation::Borrow</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_liability_shares">liability_shares</a>(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<a href="../suilend/obligation.md#suilend_obligation_Borrow">Borrow</a>): u64 {
    floor(
        div(
            <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>,
            <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.cumulative_borrow_rate,
        ),
    )
}
</code></pre>



</details>

<a name="suilend_obligation_withdraw_unchecked"></a>

## Function `withdraw_unchecked`

Withdraw without checking if the obligation is healthy.


<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_withdraw_unchecked">withdraw_unchecked</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctoken_amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_withdraw_unchecked">withdraw_unchecked</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> Reserve&lt;P&gt;,
    clock: &Clock,
    ctoken_amount: u64,
) {
    <b>let</b> deposit_index = <a href="../suilend/obligation.md#suilend_obligation_find_deposit_index">find_deposit_index</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>assert</b>!(deposit_index &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>), <a href="../suilend/obligation.md#suilend_obligation_EDepositNotFound">EDepositNotFound</a>);
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>, deposit_index);
    <b>let</b> withdraw_market_value = <a href="../suilend/reserve.md#suilend_reserve_ctoken_market_value">reserve::ctoken_market_value</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, ctoken_amount);
    // update health values
    <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.market_value = sub(<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.market_value, withdraw_market_value);
    <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a> = <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a> - ctoken_amount;
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a> = sub(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_value_usd">deposited_value_usd</a>, withdraw_market_value);
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a> =
        sub(
            <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_allowed_borrow_value_usd">allowed_borrow_value_usd</a>,
            mul(
                <a href="../suilend/reserve.md#suilend_reserve_ctoken_market_value_lower_bound">reserve::ctoken_market_value_lower_bound</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, ctoken_amount),
                open_ltv(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)),
            ),
        );
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a> =
        sub(
            <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_unhealthy_borrow_value_usd">unhealthy_borrow_value_usd</a>,
            mul(
                withdraw_market_value,
                close_ltv(config(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)),
            ),
        );
    <b>let</b> user_reward_manager = vector::borrow_mut(
        &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>,
        <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.user_reward_manager_index,
    );
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_change_user_reward_manager_share">liquidity_mining::change_user_reward_manager_share</a>(
        <a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager_mut">reserve::deposits_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        user_reward_manager,
        <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>,
        clock,
    );
    <b>if</b> (<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.<a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a> == 0) {
        <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_Deposit">Deposit</a> {
            coin_type: _,
            reserve_array_index: _,
            <a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>: _,
            market_value: _,
            attributed_borrow_value: _,
            user_reward_manager_index: _,
        } = vector::remove(&<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>, deposit_index);
    };
}
</code></pre>



</details>

<a name="suilend_obligation_compound_debt"></a>

## Function `compound_debt`

Compound the debt on a borrow object


<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_compound_debt">compound_debt</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Borrow">suilend::obligation::Borrow</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_compound_debt">compound_debt</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Borrow">Borrow</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &Reserve&lt;P&gt;) {
    <b>let</b> new_cumulative_borrow_rate = <a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">reserve::cumulative_borrow_rate</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>let</b> compounded_interest_rate = div(
        new_cumulative_borrow_rate,
        <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.cumulative_borrow_rate,
    );
    <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a> =
        mul(
            <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>,
            compounded_interest_rate,
        );
    <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.cumulative_borrow_rate = new_cumulative_borrow_rate;
}
</code></pre>



</details>

<a name="suilend_obligation_find_deposit_index"></a>

## Function `find_deposit_index`



<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_deposit_index">find_deposit_index</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_deposit_index">find_deposit_index</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &Reserve&lt;P&gt;): u64 {
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>)) {
        <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a> = vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>, i);
        <b>if</b> (<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.reserve_array_index == <a href="../suilend/reserve.md#suilend_reserve_array_index">reserve::array_index</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)) {
            <b>return</b> i
        };
        i = i + 1;
    };
    i
}
</code></pre>



</details>

<a name="suilend_obligation_find_deposit_index_by_reserve_array_index"></a>

## Function `find_deposit_index_by_reserve_array_index`



<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_deposit_index_by_reserve_array_index">find_deposit_index_by_reserve_array_index</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, reserve_array_index: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_deposit_index_by_reserve_array_index">find_deposit_index_by_reserve_array_index</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    reserve_array_index: u64,
): u64 {
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>)) {
        <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a> = vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>, i);
        <b>if</b> (<a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>.reserve_array_index == reserve_array_index) {
            <b>return</b> i
        };
        i = i + 1;
    };
    i
}
</code></pre>



</details>

<a name="suilend_obligation_find_borrow_index"></a>

## Function `find_borrow_index`



<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_borrow_index">find_borrow_index</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_borrow_index">find_borrow_index</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &Reserve&lt;P&gt;): u64 {
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>)) {
        <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a> = vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>, i);
        <b>if</b> (<a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>.reserve_array_index == <a href="../suilend/reserve.md#suilend_reserve_array_index">reserve::array_index</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)) {
            <b>return</b> i
        };
        i = i + 1;
    };
    i
}
</code></pre>



</details>

<a name="suilend_obligation_find_borrow"></a>

## Function `find_borrow`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_borrow">find_borrow</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): &<a href="../suilend/obligation.md#suilend_obligation_Borrow">suilend::obligation::Borrow</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_borrow">find_borrow</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &Reserve&lt;P&gt;): &<a href="../suilend/obligation.md#suilend_obligation_Borrow">Borrow</a> {
    <b>let</b> i = <a href="../suilend/obligation.md#suilend_obligation_find_borrow_index">find_borrow_index</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>assert</b>!(i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>), <a href="../suilend/obligation.md#suilend_obligation_EBorrowNotFound">EBorrowNotFound</a>);
    vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>, i)
}
</code></pre>



</details>

<a name="suilend_obligation_find_deposit"></a>

## Function `find_deposit`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_deposit">find_deposit</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;): &<a href="../suilend/obligation.md#suilend_obligation_Deposit">suilend::obligation::Deposit</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_deposit">find_deposit</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &Reserve&lt;P&gt;,
): &<a href="../suilend/obligation.md#suilend_obligation_Deposit">Deposit</a> {
    <b>let</b> i = <a href="../suilend/obligation.md#suilend_obligation_find_deposit_index">find_deposit_index</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>assert</b>!(i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>), <a href="../suilend/obligation.md#suilend_obligation_EDepositNotFound">EDepositNotFound</a>);
    vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>, i)
}
</code></pre>



</details>

<a name="suilend_obligation_find_or_add_borrow"></a>

## Function `find_or_add_borrow`



<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_or_add_borrow">find_or_add_borrow</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_or_add_borrow">find_or_add_borrow</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> Reserve&lt;P&gt;,
    clock: &Clock,
): u64 {
    <b>let</b> i = <a href="../suilend/obligation.md#suilend_obligation_find_borrow_index">find_borrow_index</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>if</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>)) {
        <b>return</b> i
    };
    <b>let</b> (user_reward_manager_index, _) = <a href="../suilend/obligation.md#suilend_obligation_find_or_add_user_reward_manager">find_or_add_user_reward_manager</a>(
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
        <a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager_mut">reserve::borrows_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        clock,
    );
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a> = <a href="../suilend/obligation.md#suilend_obligation_Borrow">Borrow</a> {
        coin_type: <a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        reserve_array_index: <a href="../suilend/reserve.md#suilend_reserve_array_index">reserve::array_index</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        <a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">borrowed_amount</a>: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        cumulative_borrow_rate: <a href="../suilend/reserve.md#suilend_reserve_cumulative_borrow_rate">reserve::cumulative_borrow_rate</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        market_value: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        user_reward_manager_index,
    };
    vector::push_back(&<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>, <a href="../suilend/obligation.md#suilend_obligation_borrow">borrow</a>);
    vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_borrows">borrows</a>) - 1
}
</code></pre>



</details>

<a name="suilend_obligation_find_or_add_deposit"></a>

## Function `find_or_add_deposit`



<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_or_add_deposit">find_or_add_deposit</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> <a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_or_add_deposit">find_or_add_deposit</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<b>mut</b> Reserve&lt;P&gt;,
    clock: &Clock,
): u64 {
    <b>let</b> i = <a href="../suilend/obligation.md#suilend_obligation_find_deposit_index">find_deposit_index</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
    <b>if</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>)) {
        <b>return</b> i
    };
    <b>let</b> (user_reward_manager_index, _) = <a href="../suilend/obligation.md#suilend_obligation_find_or_add_user_reward_manager">find_or_add_user_reward_manager</a>(
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
        <a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager_mut">reserve::deposits_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        clock,
    );
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a> = <a href="../suilend/obligation.md#suilend_obligation_Deposit">Deposit</a> {
        coin_type: <a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        reserve_array_index: <a href="../suilend/reserve.md#suilend_reserve_array_index">reserve::array_index</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        <a href="../suilend/obligation.md#suilend_obligation_deposited_ctoken_amount">deposited_ctoken_amount</a>: 0,
        market_value: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        user_reward_manager_index,
        attributed_borrow_value: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
    };
    vector::push_back(&<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>, <a href="../suilend/obligation.md#suilend_obligation_deposit">deposit</a>);
    vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_deposits">deposits</a>) - 1
}
</code></pre>



</details>

<a name="suilend_obligation_find_user_reward_manager_index"></a>

## Function `find_user_reward_manager_index`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_user_reward_manager_index">find_user_reward_manager_index</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, pool_reward_manager: &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_user_reward_manager_index">find_user_reward_manager_index</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    pool_reward_manager: &PoolRewardManager,
): u64 {
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>)) {
        <b>let</b> user_reward_manager = vector::borrow(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>, i);
        <b>if</b> (
            <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_manager_id">liquidity_mining::pool_reward_manager_id</a>(user_reward_manager) == object::id(pool_reward_manager)
        ) {
            <b>return</b> i
        };
        i = i + 1;
    };
    i
}
</code></pre>



</details>

<a name="suilend_obligation_find_or_add_user_reward_manager"></a>

## Function `find_or_add_user_reward_manager`



<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_or_add_user_reward_manager">find_or_add_user_reward_manager</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (u64, &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">suilend::liquidity_mining::UserRewardManager</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/obligation.md#suilend_obligation_find_or_add_user_reward_manager">find_or_add_user_reward_manager</a>&lt;P&gt;(
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation_Obligation">Obligation</a>&lt;P&gt;,
    pool_reward_manager: &<b>mut</b> PoolRewardManager,
    clock: &Clock,
): (u64, &<b>mut</b> UserRewardManager) {
    <b>let</b> i = <a href="../suilend/obligation.md#suilend_obligation_find_user_reward_manager_index">find_user_reward_manager_index</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, pool_reward_manager);
    <b>if</b> (i &lt; vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>)) {
        <b>return</b> (i, vector::borrow_mut(&<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>, i))
    };
    <b>let</b> user_reward_manager = <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_new_user_reward_manager">liquidity_mining::new_user_reward_manager</a>(
        pool_reward_manager,
        clock,
    );
    vector::push_back(&<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>, user_reward_manager);
    <b>let</b> length = vector::length(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>);
    (length - 1, vector::borrow_mut(&<b>mut</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>.<a href="../suilend/obligation.md#suilend_obligation_user_reward_managers">user_reward_managers</a>, length - 1))
}
</code></pre>



</details>
