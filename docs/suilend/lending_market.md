
<a name="suilend_lending_market"></a>

# Module `suilend::lending_market`



-  [Struct `LENDING_MARKET`](#suilend_lending_market_LENDING_MARKET)
-  [Struct `LendingMarket`](#suilend_lending_market_LendingMarket)
-  [Struct `LendingMarketOwnerCap`](#suilend_lending_market_LendingMarketOwnerCap)
-  [Struct `ObligationOwnerCap`](#suilend_lending_market_ObligationOwnerCap)
-  [Struct `FeeReceiversKey`](#suilend_lending_market_FeeReceiversKey)
-  [Struct `FeeReceivers`](#suilend_lending_market_FeeReceivers)
-  [Struct `RateLimiterExemption`](#suilend_lending_market_RateLimiterExemption)
-  [Struct `MintEvent`](#suilend_lending_market_MintEvent)
-  [Struct `RedeemEvent`](#suilend_lending_market_RedeemEvent)
-  [Struct `DepositEvent`](#suilend_lending_market_DepositEvent)
-  [Struct `WithdrawEvent`](#suilend_lending_market_WithdrawEvent)
-  [Struct `BorrowEvent`](#suilend_lending_market_BorrowEvent)
-  [Struct `RepayEvent`](#suilend_lending_market_RepayEvent)
-  [Struct `ForgiveEvent`](#suilend_lending_market_ForgiveEvent)
-  [Struct `LiquidateEvent`](#suilend_lending_market_LiquidateEvent)
-  [Struct `ClaimRewardEvent`](#suilend_lending_market_ClaimRewardEvent)
-  [Constants](#@Constants_0)
-  [Function `init`](#suilend_lending_market_init)
-  [Function `create_lending_market`](#suilend_lending_market_create_lending_market)
    -  [Returns](#@Returns_1)
    -  [Panics](#@Panics_2)
-  [Function `refresh_reserve_price`](#suilend_lending_market_refresh_reserve_price)
    -  [Arguments](#@Arguments_3)
    -  [Panics](#@Panics_4)
-  [Function `create_obligation`](#suilend_lending_market_create_obligation)
-  [Function `deposit_liquidity_and_mint_ctokens`](#suilend_lending_market_deposit_liquidity_and_mint_ctokens)
    -  [Arguments](#@Arguments_5)
    -  [Returns](#@Returns_6)
    -  [Panics](#@Panics_7)
-  [Function `redeem_ctokens_and_withdraw_liquidity`](#suilend_lending_market_redeem_ctokens_and_withdraw_liquidity)
    -  [Arguments](#@Arguments_8)
    -  [Returns](#@Returns_9)
    -  [Panics](#@Panics_10)
-  [Function `redeem_ctokens_and_withdraw_liquidity_request`](#suilend_lending_market_redeem_ctokens_and_withdraw_liquidity_request)
    -  [Arguments](#@Arguments_11)
    -  [Returns](#@Returns_12)
    -  [Panics](#@Panics_13)
-  [Function `deposit_ctokens_into_obligation`](#suilend_lending_market_deposit_ctokens_into_obligation)
    -  [Arguments](#@Arguments_14)
    -  [Panics](#@Panics_15)
-  [Function `borrow`](#suilend_lending_market_borrow)
    -  [Arguments](#@Arguments_16)
    -  [Returns](#@Returns_17)
    -  [Panics](#@Panics_18)
-  [Function `compound_interest`](#suilend_lending_market_compound_interest)
-  [Function `borrow_request`](#suilend_lending_market_borrow_request)
    -  [Arguments](#@Arguments_19)
    -  [Returns](#@Returns_20)
    -  [Panics](#@Panics_21)
-  [Function `fulfill_liquidity_request`](#suilend_lending_market_fulfill_liquidity_request)
    -  [Arguments](#@Arguments_22)
    -  [Returns](#@Returns_23)
    -  [Panics](#@Panics_24)
-  [Function `withdraw_ctokens`](#suilend_lending_market_withdraw_ctokens)
    -  [Arguments](#@Arguments_25)
    -  [Returns](#@Returns_26)
    -  [Panics](#@Panics_27)
-  [Function `liquidate`](#suilend_lending_market_liquidate)
    -  [Arguments](#@Arguments_28)
    -  [Returns](#@Returns_29)
    -  [Panics](#@Panics_30)
-  [Function `repay`](#suilend_lending_market_repay)
    -  [Arguments](#@Arguments_31)
    -  [Panics](#@Panics_32)
-  [Function `forgive`](#suilend_lending_market_forgive)
    -  [Arguments](#@Arguments_33)
    -  [Panics](#@Panics_34)
-  [Function `claim_rewards`](#suilend_lending_market_claim_rewards)
    -  [Arguments](#@Arguments_35)
    -  [Returns](#@Returns_36)
    -  [Panics](#@Panics_37)
-  [Function `claim_rewards_and_deposit`](#suilend_lending_market_claim_rewards_and_deposit)
    -  [Arguments](#@Arguments_38)
    -  [Panics](#@Panics_39)
-  [Function `init_staker`](#suilend_lending_market_init_staker)
    -  [Arguments](#@Arguments_40)
    -  [Panics](#@Panics_41)
-  [Function `rebalance_staker`](#suilend_lending_market_rebalance_staker)
    -  [Arguments](#@Arguments_42)
    -  [Panics](#@Panics_43)
-  [Function `unstake_sui_from_staker`](#suilend_lending_market_unstake_sui_from_staker)
    -  [Arguments](#@Arguments_44)
    -  [Panics](#@Panics_45)
-  [Function `reserves`](#suilend_lending_market_reserves)
-  [Function `max_borrow_amount`](#suilend_lending_market_max_borrow_amount)
-  [Function `max_withdraw_amount`](#suilend_lending_market_max_withdraw_amount)
-  [Function `obligation_id`](#suilend_lending_market_obligation_id)
-  [Function `reserve_array_index`](#suilend_lending_market_reserve_array_index)
-  [Function `reserve`](#suilend_lending_market_reserve)
-  [Function `obligation`](#suilend_lending_market_obligation)
-  [Function `fee_receiver`](#suilend_lending_market_fee_receiver)
-  [Function `rate_limiter_exemption_amount`](#suilend_lending_market_rate_limiter_exemption_amount)
-  [Function `migrate`](#suilend_lending_market_migrate)
-  [Function `add_reserve`](#suilend_lending_market_add_reserve)
    -  [Arguments](#@Arguments_46)
    -  [Panics](#@Panics_47)
-  [Function `update_reserve_config`](#suilend_lending_market_update_reserve_config)
    -  [Arguments](#@Arguments_48)
    -  [Panics](#@Panics_49)
-  [Function `change_reserve_price_feed`](#suilend_lending_market_change_reserve_price_feed)
    -  [Arguments](#@Arguments_50)
    -  [Panics](#@Panics_51)
-  [Function `add_pool_reward`](#suilend_lending_market_add_pool_reward)
    -  [Arguments](#@Arguments_52)
    -  [Panics](#@Panics_53)
-  [Function `cancel_pool_reward`](#suilend_lending_market_cancel_pool_reward)
    -  [Arguments](#@Arguments_54)
    -  [Returns](#@Returns_55)
    -  [Panics](#@Panics_56)
-  [Function `close_pool_reward`](#suilend_lending_market_close_pool_reward)
    -  [Arguments](#@Arguments_57)
    -  [Returns](#@Returns_58)
    -  [Panics](#@Panics_59)
-  [Function `update_rate_limiter_config`](#suilend_lending_market_update_rate_limiter_config)
    -  [Arguments](#@Arguments_60)
    -  [Panics](#@Panics_61)
-  [Function `set_fee_receivers`](#suilend_lending_market_set_fee_receivers)
    -  [Arguments](#@Arguments_62)
    -  [Panics](#@Panics_63)
-  [Function `claim_fees`](#suilend_lending_market_claim_fees)
    -  [Arguments](#@Arguments_64)
    -  [Panics](#@Panics_65)
-  [Function `new_obligation_owner_cap`](#suilend_lending_market_new_obligation_owner_cap)
    -  [Arguments](#@Arguments_66)
    -  [Returns](#@Returns_67)
    -  [Panics](#@Panics_68)
-  [Function `deposit_ctokens_into_obligation_by_id`](#suilend_lending_market_deposit_ctokens_into_obligation_by_id)
-  [Function `claim_rewards_by_obligation_id`](#suilend_lending_market_claim_rewards_by_obligation_id)


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
<b>use</b> <a href="../dependencies/sui/object_table.md#sui_object_table">sui::object_table</a>;
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
<b>use</b> <a href="../suilend/obligation.md#suilend_obligation">suilend::obligation</a>;
<b>use</b> <a href="../suilend/oracles.md#suilend_oracles">suilend::oracles</a>;
<b>use</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter">suilend::rate_limiter</a>;
<b>use</b> <a href="../suilend/reserve.md#suilend_reserve">suilend::reserve</a>;
<b>use</b> <a href="../suilend/reserve_config.md#suilend_reserve_config">suilend::reserve_config</a>;
<b>use</b> <a href="../suilend/staker.md#suilend_staker">suilend::staker</a>;
</code></pre>



<a name="suilend_lending_market_LENDING_MARKET"></a>

## Struct `LENDING_MARKET`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_LENDING_MARKET">LENDING_MARKET</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="suilend_lending_market_LendingMarket"></a>

## Struct `LendingMarket`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;<b>phantom</b> P&gt; <b>has</b> key, store
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
<code>version: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>: vector&lt;<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>obligations: <a href="../dependencies/sui/object_table.md#sui_object_table_ObjectTable">sui::object_table::ObjectTable</a>&lt;<a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, <a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">suilend::rate_limiter::RateLimiter</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/lending_market.md#suilend_lending_market_fee_receiver">fee_receiver</a>: <b>address</b></code>
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
<code>bad_debt_limit_usd: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 unused
</dd>
</dl>


</details>

<a name="suilend_lending_market_LendingMarketOwnerCap"></a>

## Struct `LendingMarketOwnerCap`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;<b>phantom</b> P&gt; <b>has</b> key, store
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
</dl>


</details>

<a name="suilend_lending_market_ObligationOwnerCap"></a>

## Struct `ObligationOwnerCap`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a>&lt;<b>phantom</b> P&gt; <b>has</b> key, store
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
<code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_lending_market_FeeReceiversKey"></a>

## Struct `FeeReceiversKey`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_FeeReceiversKey">FeeReceiversKey</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="suilend_lending_market_FeeReceivers"></a>

## Struct `FeeReceivers`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_FeeReceivers">FeeReceivers</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>receivers: vector&lt;<b>address</b>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>weights: vector&lt;u64&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>total_weight: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_lending_market_RateLimiterExemption"></a>

## Struct `RateLimiterExemption`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_RateLimiterExemption">RateLimiterExemption</a>&lt;<b>phantom</b> P, <b>phantom</b> T&gt; <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>amount: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_lending_market_MintEvent"></a>

## Struct `MintEvent`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_MintEvent">MintEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>liquidity_amount: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>ctoken_amount: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_lending_market_RedeemEvent"></a>

## Struct `RedeemEvent`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_RedeemEvent">RedeemEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>ctoken_amount: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>liquidity_amount: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_lending_market_DepositEvent"></a>

## Struct `DepositEvent`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_DepositEvent">DepositEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>ctoken_amount: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_lending_market_WithdrawEvent"></a>

## Struct `WithdrawEvent`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_WithdrawEvent">WithdrawEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>ctoken_amount: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_lending_market_BorrowEvent"></a>

## Struct `BorrowEvent`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_BorrowEvent">BorrowEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>liquidity_amount: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>origination_fee_amount: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_lending_market_RepayEvent"></a>

## Struct `RepayEvent`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_RepayEvent">RepayEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>liquidity_amount: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_lending_market_ForgiveEvent"></a>

## Struct `ForgiveEvent`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_ForgiveEvent">ForgiveEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>reserve_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>liquidity_amount: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_lending_market_LiquidateEvent"></a>

## Struct `LiquidateEvent`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_LiquidateEvent">LiquidateEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>repay_reserve_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>withdraw_reserve_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>repay_coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>withdraw_coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>repay_amount: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>withdraw_amount: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>protocol_fee_amount: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>liquidator_bonus_amount: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_lending_market_ClaimRewardEvent"></a>

## Struct `ClaimRewardEvent`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market.md#suilend_lending_market_ClaimRewardEvent">ClaimRewardEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>reserve_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>is_deposit_reward: bool</code>
</dt>
<dd>
</dd>
<dt>
<code>pool_reward_id: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>liquidity_amount: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="suilend_lending_market_EIncorrectVersion"></a>



<pre><code><b>const</b> <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>: u64 = 1;
</code></pre>



<a name="suilend_lending_market_ETooSmall"></a>



<pre><code><b>const</b> <a href="../suilend/lending_market.md#suilend_lending_market_ETooSmall">ETooSmall</a>: u64 = 2;
</code></pre>



<a name="suilend_lending_market_EWrongType"></a>



<pre><code><b>const</b> <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>: u64 = 3;
</code></pre>



<a name="suilend_lending_market_EDuplicateReserve"></a>



<pre><code><b>const</b> <a href="../suilend/lending_market.md#suilend_lending_market_EDuplicateReserve">EDuplicateReserve</a>: u64 = 4;
</code></pre>



<a name="suilend_lending_market_ERewardPeriodNotOver"></a>



<pre><code><b>const</b> <a href="../suilend/lending_market.md#suilend_lending_market_ERewardPeriodNotOver">ERewardPeriodNotOver</a>: u64 = 5;
</code></pre>



<a name="suilend_lending_market_EInvalidObligationId"></a>



<pre><code><b>const</b> <a href="../suilend/lending_market.md#suilend_lending_market_EInvalidObligationId">EInvalidObligationId</a>: u64 = 6;
</code></pre>



<a name="suilend_lending_market_EInvalidFeeReceivers"></a>



<pre><code><b>const</b> <a href="../suilend/lending_market.md#suilend_lending_market_EInvalidFeeReceivers">EInvalidFeeReceivers</a>: u64 = 7;
</code></pre>



<a name="suilend_lending_market_CURRENT_VERSION"></a>



<pre><code><b>const</b> <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>: u64 = 7;
</code></pre>



<a name="suilend_lending_market_U64_MAX"></a>



<pre><code><b>const</b> <a href="../suilend/lending_market.md#suilend_lending_market_U64_MAX">U64_MAX</a>: u64 = 18446744073709551615;
</code></pre>



<a name="suilend_lending_market_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_init">init</a>(otw: <a href="../suilend/lending_market.md#suilend_lending_market_LENDING_MARKET">suilend::lending_market::LENDING_MARKET</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_init">init</a>(otw: <a href="../suilend/lending_market.md#suilend_lending_market_LENDING_MARKET">LENDING_MARKET</a>, ctx: &<b>mut</b> TxContext) {
    package::claim_and_keep(otw, ctx);
}
</code></pre>



</details>

<a name="suilend_lending_market_create_lending_market"></a>

## Function `create_lending_market`

Creates a new lending market, and sets the fee receivers.

The function initializes a <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code> object with empty reserves
and obligations, a default rate limiter, and the sender as the fee receiver.

It then calls the <code><a href="../suilend/lending_market.md#suilend_lending_market_set_fee_receivers">set_fee_receivers</a></code> function to set the initial fee receiver to the creator of the market with a weight of 100.


<a name="@Returns_1"></a>

### Returns


* <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;</code> - The ownership capability for the newly created lending market.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;</code> - The newly created lending market object.


<a name="@Panics_2"></a>

### Panics


This function calls <code><a href="../suilend/lending_market.md#suilend_lending_market_set_fee_receivers">set_fee_receivers</a></code>, which can panic under the following conditions:

* If the <code>receivers</code> and <code>weights</code> vectors do not have the same length (EInvalidFeeReceivers).
* If the <code>receivers</code> vector is empty (EInvalidFeeReceivers).
* If the sum of <code>weights</code> is zero (EInvalidFeeReceivers).


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_create_lending_market">create_lending_market</a>&lt;P&gt;(ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_create_lending_market">create_lending_market</a>&lt;P&gt;(
    ctx: &<b>mut</b> TxContext,
): (<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;) {
    <b>let</b> <b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a> = <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt; {
        id: object::new(ctx),
        version: <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>,
        <a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>: vector::empty(),
        obligations: object_table::new(ctx),
        <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: <a href="../suilend/rate_limiter.md#suilend_rate_limiter_new">rate_limiter::new</a>(
            <a href="../suilend/rate_limiter.md#suilend_rate_limiter_new_config">rate_limiter::new_config</a>(1, 18_446_744_073_709_551_615),
            0,
        ),
        <a href="../suilend/lending_market.md#suilend_lending_market_fee_receiver">fee_receiver</a>: tx_context::sender(ctx),
        bad_debt_usd: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        bad_debt_limit_usd: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
    };
    <b>let</b> owner_cap = <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt; {
        id: object::new(ctx),
        lending_market_id: object::id(&<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>),
    };
    <a href="../suilend/lending_market.md#suilend_lending_market_set_fee_receivers">set_fee_receivers</a>(
        &owner_cap,
        &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>,
        vector[tx_context::sender(ctx)],
        vector[100],
    );
    (owner_cap, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>)
}
</code></pre>



</details>

<a name="suilend_lending_market_refresh_reserve_price"></a>

## Function `refresh_reserve_price`

Updates a reserve's price and timestamp from a Pyth price feed.

This function is crucial for ensuring that the lending market has the most recent price
for a given asset before performing any operations that depend on the asset's value,
such as borrowing, withdrawing, or liquidating. It calls the <code>update_price</code> function
in the <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> module.


<a name="@Arguments_3"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to update in the lending market's reserves vector.
* <code>clock</code> - A reference to the <code>Clock</code> object to get the current timestamp.
* <code>price_info</code> - A reference to the <code>PriceInfoObject</code> from Pyth, containing the new price information.


<a name="@Panics_4"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.
* The <code>price_identifier</code> from the <code>price_info</code> object does not match the reserve's price identifier (<code>EPriceIdentifierMismatch</code> from the <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> module).
* The price from the <code>price_info</code> object is invalid (<code>EInvalidPrice</code> from the <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> module).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_refresh_reserve_price">refresh_reserve_price</a>&lt;P&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, price_info: &<a href="../dependencies/pyth/price_info.md#pyth_price_info_PriceInfoObject">pyth::price_info::PriceInfoObject</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_refresh_reserve_price">refresh_reserve_price</a>&lt;P&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    clock: &Clock,
    price_info: &PriceInfoObject,
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <a href="../suilend/reserve.md#suilend_reserve_update_price">reserve::update_price</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock, price_info);
}
</code></pre>



</details>

<a name="suilend_lending_market_create_obligation"></a>

## Function `create_obligation`

Creates a new obligation.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_create_obligation">create_obligation</a>&lt;P&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">suilend::lending_market::ObligationOwnerCap</a>&lt;P&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_create_obligation">create_obligation</a>&lt;P&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    ctx: &<b>mut</b> TxContext,
): <a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a>&lt;P&gt; {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a> = <a href="../suilend/obligation.md#suilend_obligation_create_obligation">obligation::create_obligation</a>&lt;P&gt;(object::id(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>), ctx);
    <b>let</b> cap = <a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a>&lt;P&gt; {
        id: object::new(ctx),
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: object::id(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>),
    };
    object_table::add(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.obligations, object::id(&<a href="../suilend/obligation.md#suilend_obligation">obligation</a>), <a href="../suilend/obligation.md#suilend_obligation">obligation</a>);
    cap
}
</code></pre>



</details>

<a name="suilend_lending_market_deposit_liquidity_and_mint_ctokens"></a>

## Function `deposit_liquidity_and_mint_ctokens`

Deposits liquidity into a reserve and mints cTokens in return.

This function allows a user to deposit a certain amount of a token into a reserve
and receive cTokens, which represent their share of the reserve's assets.
The amount of cTokens minted is proportional to the amount of liquidity deposited
and the current cToken ratio of the reserve.


<a name="@Arguments_5"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to deposit into.
* <code>clock</code> - A reference to the <code>Clock</code> to compound interest before depositing.
* <code>deposit</code> - The <code>Coin</code> object representing the liquidity to deposit.


<a name="@Returns_6"></a>

### Returns


* <code>Coin&lt;CToken&lt;P, T&gt;&gt;</code> - A <code>Coin</code> of cTokens representing the deposited liquidity and accrued interest.


<a name="@Panics_7"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The deposit amount is zero (ETooSmall).
* The <code>coin_type</code> of the reserve does not match the type of the deposited coin (EWrongType).
* The deposit would exceed the reserve's deposit limit (<code>EDepositLimitExceeded</code> from the <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> module).
* The minted cToken amount is zero (ETooSmall).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_deposit_liquidity_and_mint_ctokens">deposit_liquidity_and_mint_ctokens</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, deposit: <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;T&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_deposit_liquidity_and_mint_ctokens">deposit_liquidity_and_mint_ctokens</a>&lt;P, T&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    clock: &Clock,
    deposit: Coin&lt;T&gt;,
    ctx: &<b>mut</b> TxContext,
): Coin&lt;CToken&lt;P, T&gt;&gt; {
    <b>let</b> lending_market_id = object::id_address(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>);
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>assert</b>!(coin::value(&deposit) &gt; 0, <a href="../suilend/lending_market.md#suilend_lending_market_ETooSmall">ETooSmall</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;T&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <a href="../suilend/reserve.md#suilend_reserve_compound_interest">reserve::compound_interest</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock);
    <b>let</b> deposit_amount = coin::value(&deposit);
    <b>let</b> ctokens = <a href="../suilend/reserve.md#suilend_reserve_deposit_liquidity_and_mint_ctokens">reserve::deposit_liquidity_and_mint_ctokens</a>&lt;P, T&gt;(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
        coin::into_balance(deposit),
    );
    <b>assert</b>!(balance::value(&ctokens) &gt; 0, <a href="../suilend/lending_market.md#suilend_lending_market_ETooSmall">ETooSmall</a>);
    event::emit(<a href="../suilend/lending_market.md#suilend_lending_market_MintEvent">MintEvent</a> {
        lending_market_id,
        coin_type: type_name::get&lt;T&gt;(),
        reserve_id: object::id_address(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        liquidity_amount: deposit_amount,
        ctoken_amount: balance::value(&ctokens),
    });
    coin::from_balance(ctokens, ctx)
}
</code></pre>



</details>

<a name="suilend_lending_market_redeem_ctokens_and_withdraw_liquidity"></a>

## Function `redeem_ctokens_and_withdraw_liquidity`

Redeems cTokens for the underlying liquidity.

This function allows a user to redeem their cTokens for the underlying asset.
The amount of the underlying asset received depends on the amount of cTokens redeemed
and the current cToken ratio of the reserve.


<a name="@Arguments_8"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to redeem from.
* <code>clock</code> - A reference to the <code>Clock</code> to compound interest before redeeming.
* <code>ctokens</code> - The <code>Coin</code> of cTokens to redeem.
* <code>rate_limiter_exemption</code> - An optional exemption from the rate limiter.


<a name="@Returns_9"></a>

### Returns


* <code>Coin&lt;T&gt;</code> - A <code>Coin</code> of the underlying asset.


<a name="@Panics_10"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The amount of cTokens to redeem is zero (ETooSmall).
* The <code>coin_type</code> of the reserve does not match the type of the cTokens (EWrongType).
* The redemption would violate the minimum available amount of the reserve (<code>EMinAvailableAmountViolated</code> from the <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> module).
* The withdrawal amount exceeds the rate limit, and no exemption is provided.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_redeem_ctokens_and_withdraw_liquidity">redeem_ctokens_and_withdraw_liquidity</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctokens: <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;, rate_limiter_exemption: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../suilend/lending_market.md#suilend_lending_market_RateLimiterExemption">suilend::lending_market::RateLimiterExemption</a>&lt;P, T&gt;&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_redeem_ctokens_and_withdraw_liquidity">redeem_ctokens_and_withdraw_liquidity</a>&lt;P, T&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    clock: &Clock,
    ctokens: Coin&lt;CToken&lt;P, T&gt;&gt;,
    rate_limiter_exemption: Option&lt;<a href="../suilend/lending_market.md#suilend_lending_market_RateLimiterExemption">RateLimiterExemption</a>&lt;P, T&gt;&gt;,
    ctx: &<b>mut</b> TxContext,
): Coin&lt;T&gt; {
    <b>let</b> liquidity_request = <a href="../suilend/lending_market.md#suilend_lending_market_redeem_ctokens_and_withdraw_liquidity_request">redeem_ctokens_and_withdraw_liquidity_request</a>(
        <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>,
        <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>,
        clock,
        ctokens,
        rate_limiter_exemption,
        ctx,
    );
    <a href="../suilend/lending_market.md#suilend_lending_market_fulfill_liquidity_request">fulfill_liquidity_request</a>(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>, liquidity_request, ctx)
}
</code></pre>



</details>

<a name="suilend_lending_market_redeem_ctokens_and_withdraw_liquidity_request"></a>

## Function `redeem_ctokens_and_withdraw_liquidity_request`

Creates a liquidity request to withdraw liquidity by redeeming cTokens.

Initiates the process of redeeming cTokens for the underlying asset.
It checks for rate limit exemptions, processes the withdrawal against the rate limiter if necessary,
and then creates a <code>LiquidityRequest</code> by calling the <code>redeem_ctokens</code> function in the <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> module.


<a name="@Arguments_11"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to redeem from.
* <code>clock</code> - A reference to the <code>Clock</code> to compound interest before redeeming.
* <code>ctokens</code> - The <code>Coin</code> of cTokens to redeem.
* <code>rate_limiter_exemption</code> - An optional exemption from the rate limiter.


<a name="@Returns_12"></a>

### Returns


* <code>LiquidityRequest&lt;P, T&gt;</code> - A request to withdraw liquidity from the reserve.


<a name="@Panics_13"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The amount of cTokens to redeem is zero (ETooSmall).
* The <code>coin_type</code> of the reserve does not match the type of the cTokens (EWrongType).
* The redemption would violate the minimum available amount of the reserve (<code>EMinAvailableAmountViolated</code> from the <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> module).
* The withdrawal amount exceeds the rate limit, and no exemption is provided.
* The amount of liquidity requested is zero (ETooSmall).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_redeem_ctokens_and_withdraw_liquidity_request">redeem_ctokens_and_withdraw_liquidity_request</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctokens: <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;, rate_limiter_exemption: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../suilend/lending_market.md#suilend_lending_market_RateLimiterExemption">suilend::lending_market::RateLimiterExemption</a>&lt;P, T&gt;&gt;, _ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">suilend::reserve::LiquidityRequest</a>&lt;P, T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_redeem_ctokens_and_withdraw_liquidity_request">redeem_ctokens_and_withdraw_liquidity_request</a>&lt;P, T&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    clock: &Clock,
    ctokens: Coin&lt;CToken&lt;P, T&gt;&gt;,
    <b>mut</b> rate_limiter_exemption: Option&lt;<a href="../suilend/lending_market.md#suilend_lending_market_RateLimiterExemption">RateLimiterExemption</a>&lt;P, T&gt;&gt;,
    _ctx: &<b>mut</b> TxContext,
): LiquidityRequest&lt;P, T&gt; {
    <b>let</b> lending_market_id = object::id_address(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>);
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>assert</b>!(coin::value(&ctokens) &gt; 0, <a href="../suilend/lending_market.md#suilend_lending_market_ETooSmall">ETooSmall</a>);
    <b>let</b> ctoken_amount = coin::value(&ctokens);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;T&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <a href="../suilend/reserve.md#suilend_reserve_compound_interest">reserve::compound_interest</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock);
    <b>let</b> <b>mut</b> exempt_from_rate_limiter = <b>false</b>;
    <b>if</b> (option::is_some(&rate_limiter_exemption)) {
        <b>let</b> exemption = option::borrow_mut(&<b>mut</b> rate_limiter_exemption);
        <b>if</b> (exemption.amount &gt;= ctoken_amount) {
            exempt_from_rate_limiter = <b>true</b>;
        };
    };
    <b>if</b> (!exempt_from_rate_limiter) {
        <a href="../suilend/rate_limiter.md#suilend_rate_limiter_process_qty">rate_limiter::process_qty</a>(
            &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>,
            clock::timestamp_ms(clock) / 1000,
            <a href="../suilend/reserve.md#suilend_reserve_ctoken_market_value_upper_bound">reserve::ctoken_market_value_upper_bound</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, ctoken_amount),
        );
    };
    <b>let</b> liquidity_request = <a href="../suilend/reserve.md#suilend_reserve_redeem_ctokens">reserve::redeem_ctokens</a>&lt;P, T&gt;(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
        coin::into_balance(ctokens),
    );
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_liquidity_request_amount">reserve::liquidity_request_amount</a>(&liquidity_request) &gt; 0, <a href="../suilend/lending_market.md#suilend_lending_market_ETooSmall">ETooSmall</a>);
    event::emit(<a href="../suilend/lending_market.md#suilend_lending_market_RedeemEvent">RedeemEvent</a> {
        lending_market_id,
        coin_type: type_name::get&lt;T&gt;(),
        reserve_id: object::id_address(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        ctoken_amount,
        liquidity_amount: <a href="../suilend/reserve.md#suilend_reserve_liquidity_request_amount">reserve::liquidity_request_amount</a>(&liquidity_request),
    });
    liquidity_request
}
</code></pre>



</details>

<a name="suilend_lending_market_deposit_ctokens_into_obligation"></a>

## Function `deposit_ctokens_into_obligation`

Deposits cTokens into an obligation, which can be used as collateral for borrowing.


<a name="@Arguments_14"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve corresponding to the cTokens being deposited.
* <code>obligation_owner_cap</code> - The ownership capability for the obligation.
* <code>clock</code> - A reference to the <code>Clock</code>.
* <code>deposit</code> - The <code>Coin</code> of cTokens to deposit.


<a name="@Panics_15"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The deposit amount is zero (ETooSmall).
* The <code>coin_type</code> of the reserve does not match the type of the deposited cTokens (EWrongType).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a></code> is not a valid key in the <code>obligations</code> table.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_deposit_ctokens_into_obligation">deposit_ctokens_into_obligation</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, obligation_owner_cap: &<a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">suilend::lending_market::ObligationOwnerCap</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, deposit: <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_deposit_ctokens_into_obligation">deposit_ctokens_into_obligation</a>&lt;P, T&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    obligation_owner_cap: &<a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a>&lt;P&gt;,
    clock: &Clock,
    deposit: Coin&lt;CToken&lt;P, T&gt;&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <a href="../suilend/lending_market.md#suilend_lending_market_deposit_ctokens_into_obligation_by_id">deposit_ctokens_into_obligation_by_id</a>(
        <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>,
        <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>,
        obligation_owner_cap.<a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>,
        clock,
        deposit,
        ctx,
    )
}
</code></pre>



</details>

<a name="suilend_lending_market_borrow"></a>

## Function `borrow`

Borrows a specified amount of a token from a reserve. A fee is charged on the borrowed amount.


<a name="@Arguments_16"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to borrow from.
* <code>obligation_owner_cap</code> - The ownership capability for the obligation.
* <code>clock</code> - A reference to the <code>Clock</code>.
* <code>amount</code> - The amount to borrow.


<a name="@Returns_17"></a>

### Returns


* <code>Coin&lt;T&gt;</code> - A <code>Coin</code> of the borrowed asset.


<a name="@Panics_18"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The borrow amount is zero (ETooSmall).
* The <code>coin_type</code> of the reserve does not match the type of the asset being borrowed (EWrongType).
* The reserve's price is stale (<code>EPriceStale</code> from the <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> module).
* The borrow would exceed the reserve's borrow limit (<code>EBorrowLimitExceeded</code> from the <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> module).
* The borrow would violate the minimum available amount of the reserve (<code>EMinAvailableAmountViolated</code> from the <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> module).
* The obligation has stale oracle prices.
* The borrow amount exceeds the rate limit.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a></code> is not a valid key in the <code>obligations</code> table.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_borrow">borrow</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, obligation_owner_cap: &<a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">suilend::lending_market::ObligationOwnerCap</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, amount: u64, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_borrow">borrow</a>&lt;P, T&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    obligation_owner_cap: &<a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a>&lt;P&gt;,
    clock: &Clock,
    amount: u64,
    ctx: &<b>mut</b> TxContext,
): Coin&lt;T&gt; {
    <b>let</b> liquidity_request = <a href="../suilend/lending_market.md#suilend_lending_market_borrow_request">borrow_request</a>&lt;P, T&gt;(
        <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>,
        <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>,
        obligation_owner_cap,
        clock,
        amount,
    );
    <a href="../suilend/lending_market.md#suilend_lending_market_fulfill_liquidity_request">fulfill_liquidity_request</a>(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>, liquidity_request, ctx)
}
</code></pre>



</details>

<a name="suilend_lending_market_compound_interest"></a>

## Function `compound_interest`

Compound interest for reserve of type T


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_compound_interest">compound_interest</a>&lt;P&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_compound_interest">compound_interest</a>&lt;P&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    clock: &Clock,
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>.<a href="../suilend/lending_market.md#suilend_lending_market_compound_interest">compound_interest</a>(clock);
}
</code></pre>



</details>

<a name="suilend_lending_market_borrow_request"></a>

## Function `borrow_request`

Borrows a specified amount of a token from a reserve. A fee is charged on the borrowed amount.


<a name="@Arguments_19"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to borrow from.
* <code>obligation_owner_cap</code> - The ownership capability for the obligation.
* <code>clock</code> - A reference to the <code>Clock</code>.
* <code>amount</code> - The amount to borrow.


<a name="@Returns_20"></a>

### Returns


* <code>Coin&lt;T&gt;</code> - A <code>Coin</code> of the borrowed asset.


<a name="@Panics_21"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The borrow amount is zero (ETooSmall).
* The <code>coin_type</code> of the reserve does not match the type of the asset being borrowed (EWrongType).
* The reserve's price is stale (<code>EPriceStale</code> from the <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> module).
* The borrow would exceed the reserve's borrow limit (<code>EBorrowLimitExceeded</code> from the <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> module).
* The borrow would violate the minimum available amount of the reserve (<code>EMinAvailableAmountViolated</code> from the <code><a href="../suilend/reserve.md#suilend_reserve">reserve</a></code> module).
* The obligation has stale oracle prices.
* The borrow amount exceeds the rate limit.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a></code> is not a valid key in the <code>obligations</code> table.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_borrow_request">borrow_request</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, obligation_owner_cap: &<a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">suilend::lending_market::ObligationOwnerCap</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, amount: u64): <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">suilend::reserve::LiquidityRequest</a>&lt;P, T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_borrow_request">borrow_request</a>&lt;P, T&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    obligation_owner_cap: &<a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a>&lt;P&gt;,
    clock: &Clock,
    <b>mut</b> amount: u64,
): LiquidityRequest&lt;P, T&gt; {
    <b>let</b> lending_market_id = object::id_address(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>);
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>assert</b>!(amount &gt; 0, <a href="../suilend/lending_market.md#suilend_lending_market_ETooSmall">ETooSmall</a>);
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a> = object_table::borrow_mut(
        &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.obligations,
        obligation_owner_cap.<a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>,
    );
    <b>let</b> exist_stale_oracles = <a href="../suilend/obligation.md#suilend_obligation_refresh">obligation::refresh</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, clock);
    <a href="../suilend/obligation.md#suilend_obligation_assert_no_stale_oracles">obligation::assert_no_stale_oracles</a>(exist_stale_oracles);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;T&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <a href="../suilend/reserve.md#suilend_reserve_compound_interest">reserve::compound_interest</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock);
    <a href="../suilend/reserve.md#suilend_reserve_assert_price_is_fresh">reserve::assert_price_is_fresh</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock);
    <b>if</b> (amount == <a href="../suilend/lending_market.md#suilend_lending_market_U64_MAX">U64_MAX</a>) {
        amount = <a href="../suilend/lending_market.md#suilend_lending_market_max_borrow_amount">max_borrow_amount</a>&lt;P&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>, <a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock);
        <b>assert</b>!(amount &gt; 0, <a href="../suilend/lending_market.md#suilend_lending_market_ETooSmall">ETooSmall</a>);
    };
    <b>let</b> liquidity_request = <a href="../suilend/reserve.md#suilend_reserve_borrow_liquidity">reserve::borrow_liquidity</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, amount);
    <a href="../suilend/obligation.md#suilend_obligation_borrow">obligation::borrow</a>&lt;P&gt;(
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
        clock,
        <a href="../suilend/reserve.md#suilend_reserve_liquidity_request_amount">reserve::liquidity_request_amount</a>(&liquidity_request),
    );
    <b>let</b> borrow_value = <a href="../suilend/reserve.md#suilend_reserve_market_value_upper_bound">reserve::market_value_upper_bound</a>(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/reserve.md#suilend_reserve_liquidity_request_amount">reserve::liquidity_request_amount</a>(&liquidity_request)),
    );
    <a href="../suilend/rate_limiter.md#suilend_rate_limiter_process_qty">rate_limiter::process_qty</a>(
        &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>,
        clock::timestamp_ms(clock) / 1000,
        borrow_value,
    );
    event::emit(<a href="../suilend/lending_market.md#suilend_lending_market_BorrowEvent">BorrowEvent</a> {
        lending_market_id,
        coin_type: type_name::get&lt;T&gt;(),
        reserve_id: object::id_address(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: object::id_address(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>),
        liquidity_amount: <a href="../suilend/reserve.md#suilend_reserve_liquidity_request_amount">reserve::liquidity_request_amount</a>(&liquidity_request),
        origination_fee_amount: <a href="../suilend/reserve.md#suilend_reserve_liquidity_request_fee">reserve::liquidity_request_fee</a>(&liquidity_request),
    });
    <a href="../suilend/obligation.md#suilend_obligation_zero_out_rewards_if_looped">obligation::zero_out_rewards_if_looped</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, clock);
    liquidity_request
}
</code></pre>



</details>

<a name="suilend_lending_market_fulfill_liquidity_request"></a>

## Function `fulfill_liquidity_request`

Fulfills a liquidity request from a reserve.

This function is called after a liquidity request has been created by either
<code><a href="../suilend/lending_market.md#suilend_lending_market_redeem_ctokens_and_withdraw_liquidity_request">redeem_ctokens_and_withdraw_liquidity_request</a></code> or <code><a href="../suilend/lending_market.md#suilend_lending_market_borrow_request">borrow_request</a></code>. It takes the
<code>LiquidityRequest</code> and processes it, returning the requested amount of the
underlying asset as a <code>Coin</code>.


<a name="@Arguments_22"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to fulfill the request from.
* <code>liquidity_request</code> - The <code>LiquidityRequest</code> to be fulfilled.


<a name="@Returns_23"></a>

### Returns


* <code>Coin&lt;T&gt;</code> - A <code>Coin</code> of the underlying asset.


<a name="@Panics_24"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The <code>coin_type</code> of the reserve does not match the type of the liquidity request (EWrongType).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_fulfill_liquidity_request">fulfill_liquidity_request</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, liquidity_request: <a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">suilend::reserve::LiquidityRequest</a>&lt;P, T&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_fulfill_liquidity_request">fulfill_liquidity_request</a>&lt;P, T&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    liquidity_request: LiquidityRequest&lt;P, T&gt;,
    ctx: &<b>mut</b> TxContext,
): Coin&lt;T&gt; {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;T&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    coin::from_balance(
        <a href="../suilend/reserve.md#suilend_reserve_fulfill_liquidity_request">reserve::fulfill_liquidity_request</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, liquidity_request),
        ctx,
    )
}
</code></pre>



</details>

<a name="suilend_lending_market_withdraw_ctokens"></a>

## Function `withdraw_ctokens`

Withdraws cTokens from an obligation.

This function allows a user to withdraw their cTokens from an obligation,
making them available for redemption or transfer.


<a name="@Arguments_25"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve corresponding to the cTokens being withdrawn.
* <code>obligation_owner_cap</code> - The ownership capability for the obligation.
* <code>clock</code> - A reference to the <code>Clock</code>.
* <code>amount</code> - The amount of cTokens to withdraw. If <code><a href="../suilend/lending_market.md#suilend_lending_market_U64_MAX">U64_MAX</a></code> is provided, the maximum possible amount will be withdrawn.


<a name="@Returns_26"></a>

### Returns


* <code>Coin&lt;CToken&lt;P, T&gt;&gt;</code> - A <code>Coin</code> of the withdrawn cTokens.


<a name="@Panics_27"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The withdraw amount is zero (ETooSmall).
* The <code>coin_type</code> of the reserve does not match the type of the cTokens being withdrawn (EWrongType).
* The obligation has stale oracle prices.
* The withdrawal would leave the obligation in an unhealthy state.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a></code> is not a valid key in the <code>obligations</code> table.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_withdraw_ctokens">withdraw_ctokens</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, obligation_owner_cap: &<a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">suilend::lending_market::ObligationOwnerCap</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, amount: u64, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_withdraw_ctokens">withdraw_ctokens</a>&lt;P, T&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    obligation_owner_cap: &<a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a>&lt;P&gt;,
    clock: &Clock,
    <b>mut</b> amount: u64,
    ctx: &<b>mut</b> TxContext,
): Coin&lt;CToken&lt;P, T&gt;&gt; {
    <b>let</b> lending_market_id = object::id_address(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>);
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>assert</b>!(amount &gt; 0, <a href="../suilend/lending_market.md#suilend_lending_market_ETooSmall">ETooSmall</a>);
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a> = object_table::borrow_mut(
        &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.obligations,
        obligation_owner_cap.<a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>,
    );
    <b>let</b> exist_stale_oracles = <a href="../suilend/obligation.md#suilend_obligation_refresh">obligation::refresh</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, clock);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;T&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <b>if</b> (amount == <a href="../suilend/lending_market.md#suilend_lending_market_U64_MAX">U64_MAX</a>) {
        amount =
            <a href="../suilend/lending_market.md#suilend_lending_market_max_withdraw_amount">max_withdraw_amount</a>&lt;P&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>, <a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock);
    };
    <a href="../suilend/obligation.md#suilend_obligation_withdraw">obligation::withdraw</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock, amount, exist_stale_oracles);
    event::emit(<a href="../suilend/lending_market.md#suilend_lending_market_WithdrawEvent">WithdrawEvent</a> {
        lending_market_id,
        coin_type: type_name::get&lt;T&gt;(),
        reserve_id: object::id_address(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: object::id_address(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>),
        ctoken_amount: amount,
    });
    <b>let</b> ctoken_balance = <a href="../suilend/reserve.md#suilend_reserve_withdraw_ctokens">reserve::withdraw_ctokens</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, amount);
    <a href="../suilend/obligation.md#suilend_obligation_zero_out_rewards_if_looped">obligation::zero_out_rewards_if_looped</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, clock);
    coin::from_balance(ctoken_balance, ctx)
}
</code></pre>



</details>

<a name="suilend_lending_market_liquidate"></a>

## Function `liquidate`

Liquidates an unhealthy obligation by repaying a borrow and seizing collateral.

This function allows a liquidator to repay a portion of an unhealthy obligation's
debt in exchange for a discounted amount of their collateral. Any leftover repay
coins are returned to the liquidator.


<a name="@Arguments_28"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a></code> - The ID of the obligation to liquidate.
* <code>repay_reserve_array_index</code> - The index of the reserve to repay the debt to.
* <code>withdraw_reserve_array_index</code> - The index of the reserve to withdraw collateral from.
* <code>clock</code> - A reference to the <code>Clock</code>.
* <code>repay_coins</code> - A mutable reference to the <code>Coin</code> used to repay the debt.


<a name="@Returns_29"></a>

### Returns


* <code>(Coin&lt;CToken&lt;P, Withdraw&gt;&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_RateLimiterExemption">RateLimiterExemption</a>&lt;P, Withdraw&gt;)</code> - A tuple containing the withdrawn collateral as cTokens and a rate limiter exemption.


<a name="@Panics_30"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The repay amount is zero (ETooSmall).
* The obligation is not unhealthy.
* The obligation has stale oracle prices.
* The <code>coin_type</code> of the repay reserve does not match the type of the repay coin.
* The <code>coin_type</code> of the withdraw reserve does not match the type of the withdrawn cTokens.
* <code>repay_reserve_array_index</code> or <code>withdraw_reserve_array_index</code> are out of bounds.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a></code> is not a valid key in the <code>obligations</code> table.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_liquidate">liquidate</a>&lt;P, Repay, Withdraw&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, repay_reserve_array_index: u64, withdraw_reserve_array_index: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, repay_coins: &<b>mut</b> <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;Repay&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, Withdraw&gt;&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_RateLimiterExemption">suilend::lending_market::RateLimiterExemption</a>&lt;P, Withdraw&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_liquidate">liquidate</a>&lt;P, Repay, Withdraw&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: ID,
    repay_reserve_array_index: u64,
    withdraw_reserve_array_index: u64,
    clock: &Clock,
    repay_coins: &<b>mut</b> Coin&lt;Repay&gt;, // <b>mut</b> because we probably won't <b>use</b> all of it
    ctx: &<b>mut</b> TxContext,
): (Coin&lt;CToken&lt;P, Withdraw&gt;&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_RateLimiterExemption">RateLimiterExemption</a>&lt;P, Withdraw&gt;) {
    <b>let</b> lending_market_id = object::id_address(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>);
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>assert</b>!(coin::value(repay_coins) &gt; 0, <a href="../suilend/lending_market.md#suilend_lending_market_ETooSmall">ETooSmall</a>);
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a> = object_table::borrow_mut(
        &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.obligations,
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>,
    );
    <b>let</b> exist_stale_oracles = <a href="../suilend/obligation.md#suilend_obligation_refresh">obligation::refresh</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, clock);
    <a href="../suilend/obligation.md#suilend_obligation_assert_no_stale_oracles">obligation::assert_no_stale_oracles</a>(exist_stale_oracles);
    <b>let</b> (withdraw_ctoken_amount, required_repay_amount) = <a href="../suilend/obligation.md#suilend_obligation_liquidate">obligation::liquidate</a>&lt;P&gt;(
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
        &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>,
        repay_reserve_array_index,
        withdraw_reserve_array_index,
        clock,
        coin::value(repay_coins),
    );
    <b>assert</b>!(gt(required_repay_amount, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0)), <a href="../suilend/lending_market.md#suilend_lending_market_ETooSmall">ETooSmall</a>);
    <b>let</b> required_repay_coins = coin::split(repay_coins, ceil(required_repay_amount), ctx);
    <b>let</b> repay_reserve = vector::borrow_mut(
        &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>,
        repay_reserve_array_index,
    );
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(repay_reserve) == type_name::get&lt;Repay&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <a href="../suilend/reserve.md#suilend_reserve_repay_liquidity">reserve::repay_liquidity</a>&lt;P, Repay&gt;(
        repay_reserve,
        coin::into_balance(required_repay_coins),
        required_repay_amount,
    );
    <b>let</b> withdraw_reserve = vector::borrow_mut(
        &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>,
        withdraw_reserve_array_index,
    );
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(withdraw_reserve) == type_name::get&lt;Withdraw&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <b>let</b> <b>mut</b> ctokens = <a href="../suilend/reserve.md#suilend_reserve_withdraw_ctokens">reserve::withdraw_ctokens</a>&lt;P, Withdraw&gt;(
        withdraw_reserve,
        withdraw_ctoken_amount,
    );
    <b>let</b> (protocol_fee_amount, liquidator_bonus_amount) = <a href="../suilend/reserve.md#suilend_reserve_deduct_liquidation_fee">reserve::deduct_liquidation_fee</a>&lt;
        P,
        Withdraw,
    &gt;(withdraw_reserve, &<b>mut</b> ctokens);
    <b>let</b> repay_reserve = vector::borrow(&<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, repay_reserve_array_index);
    <b>let</b> withdraw_reserve = vector::borrow(
        &<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>,
        withdraw_reserve_array_index,
    );
    event::emit(<a href="../suilend/lending_market.md#suilend_lending_market_LiquidateEvent">LiquidateEvent</a> {
        lending_market_id,
        repay_reserve_id: object::id_address(repay_reserve),
        withdraw_reserve_id: object::id_address(withdraw_reserve),
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: object::id_address(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>),
        repay_coin_type: type_name::get&lt;Repay&gt;(),
        withdraw_coin_type: type_name::get&lt;Withdraw&gt;(),
        repay_amount: ceil(required_repay_amount),
        withdraw_amount: withdraw_ctoken_amount,
        protocol_fee_amount,
        liquidator_bonus_amount,
    });
    <a href="../suilend/obligation.md#suilend_obligation_zero_out_rewards_if_looped">obligation::zero_out_rewards_if_looped</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, clock);
    <b>let</b> exemption = <a href="../suilend/lending_market.md#suilend_lending_market_RateLimiterExemption">RateLimiterExemption</a>&lt;P, Withdraw&gt; { amount: balance::value(&ctokens) };
    (coin::from_balance(ctokens, ctx), exemption)
}
</code></pre>



</details>

<a name="suilend_lending_market_repay"></a>

## Function `repay`

Repays a borrow, reducing the obligation's debt and increasing the reserve's liquidity.

Any leftover repay coins are returned to the caller.


<a name="@Arguments_31"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to repay the debt to.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a></code> - The ID of the obligation to repay.
* <code>clock</code> - A reference to the <code>Clock</code>.
* <code>max_repay_coins</code> - A mutable reference to the <code>Coin</code> used to repay the debt.


<a name="@Panics_32"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The <code>coin_type</code> of the reserve does not match the type of the repay coin (EWrongType).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a></code> is not a valid key in the <code>obligations</code> table.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_repay">repay</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, max_repay_coins: &<b>mut</b> <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;T&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_repay">repay</a>&lt;P, T&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: ID,
    clock: &Clock,
    // <b>mut</b> because we might not <b>use</b> all of it and the amount we want to <b>use</b> is
    // hard to determine beforehand
    max_repay_coins: &<b>mut</b> Coin&lt;T&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <b>let</b> lending_market_id = object::id_address(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>);
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a> = object_table::borrow_mut(
        &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.obligations,
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>,
    );
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;T&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <a href="../suilend/reserve.md#suilend_reserve_compound_interest">reserve::compound_interest</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock);
    <b>let</b> repay_amount = <a href="../suilend/obligation.md#suilend_obligation_repay">obligation::repay</a>&lt;P&gt;(
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
        clock,
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(coin::value(max_repay_coins)),
    );
    <b>let</b> repay_coins = coin::split(max_repay_coins, ceil(repay_amount), ctx);
    <a href="../suilend/reserve.md#suilend_reserve_repay_liquidity">reserve::repay_liquidity</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, coin::into_balance(repay_coins), repay_amount);
    event::emit(<a href="../suilend/lending_market.md#suilend_lending_market_RepayEvent">RepayEvent</a> {
        lending_market_id,
        coin_type: type_name::get&lt;T&gt;(),
        reserve_id: object::id_address(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: object::id_address(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>),
        liquidity_amount: ceil(repay_amount),
    });
    <a href="../suilend/obligation.md#suilend_obligation_zero_out_rewards_if_looped">obligation::zero_out_rewards_if_looped</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, clock);
}
</code></pre>



</details>

<a name="suilend_lending_market_forgive"></a>

## Function `forgive`

Forgives a debt on an obligation, effectively reducing the borrow amount without requiring repayment.

This is an admin-only function that can be used to handle bad debt or other special circumstances.
It reduces the borrowed amount for a specific reserve within an obligation.


<a name="@Arguments_33"></a>

### Arguments


* <code>_</code> - The <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a></code> to authorize the operation.
* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve for which to forgive the debt.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a></code> - The ID of the obligation to forgive the debt for.
* <code>clock</code> - A reference to the <code>Clock</code>.
* <code>max_forgive_amount</code> - The maximum amount of debt to forgive.


<a name="@Panics_34"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a></code> is not a valid key in the <code>obligations</code> table.
* The obligation has stale oracle prices.
* The <code>coin_type</code> of the reserve does not match the type of the debt being forgiven (EWrongType).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_forgive">forgive</a>&lt;P, T&gt;(_: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, max_forgive_amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_forgive">forgive</a>&lt;P, T&gt;(
    _: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: ID,
    clock: &Clock,
    max_forgive_amount: u64,
) {
    <b>let</b> lending_market_id = object::id_address(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>);
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a> = object_table::borrow_mut(
        &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.obligations,
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>,
    );
    <b>let</b> exist_stale_oracles = <a href="../suilend/obligation.md#suilend_obligation_refresh">obligation::refresh</a>&lt;P&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, clock);
    <a href="../suilend/obligation.md#suilend_obligation_assert_no_stale_oracles">obligation::assert_no_stale_oracles</a>(exist_stale_oracles);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;T&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <b>let</b> forgive_amount = <a href="../suilend/obligation.md#suilend_obligation_forgive">obligation::forgive</a>&lt;P&gt;(
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
        clock,
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(max_forgive_amount),
    );
    <a href="../suilend/reserve.md#suilend_reserve_forgive_debt">reserve::forgive_debt</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, forgive_amount);
    event::emit(<a href="../suilend/lending_market.md#suilend_lending_market_ForgiveEvent">ForgiveEvent</a> {
        lending_market_id,
        coin_type: type_name::get&lt;T&gt;(),
        reserve_id: object::id_address(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: object::id_address(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>),
        liquidity_amount: ceil(forgive_amount),
    });
}
</code></pre>



</details>

<a name="suilend_lending_market_claim_rewards"></a>

## Function `claim_rewards`

Claims rewards earned by an obligation.

This function allows an obligation owner to claim rewards that have accrued
from either depositing or borrowing on a reserve.


<a name="@Arguments_35"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code>cap</code> - The <code><a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a></code> to authorize the operation.
* <code>clock</code> - A reference to the <code>Clock</code>.
* <code>reserve_id</code> - The array index of the reserve that is giving out the rewards.
* <code>reward_index</code> - The index of the reward pool to claim from.
* <code>is_deposit_reward</code> - A boolean indicating whether to claim deposit rewards (true) or borrow rewards (false).


<a name="@Returns_36"></a>

### Returns


* <code>Coin&lt;RewardType&gt;</code> - A <code>Coin</code> containing the claimed rewards.


<a name="@Panics_37"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* It will also panic if the underlying <code><a href="../suilend/lending_market.md#suilend_lending_market_claim_rewards_by_obligation_id">claim_rewards_by_obligation_id</a></code> panics.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_claim_rewards">claim_rewards</a>&lt;P, RewardType&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, cap: &<a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">suilend::lending_market::ObligationOwnerCap</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, reserve_id: u64, reward_index: u64, is_deposit_reward: bool, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;RewardType&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_claim_rewards">claim_rewards</a>&lt;P, RewardType&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    cap: &<a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a>&lt;P&gt;,
    clock: &Clock,
    reserve_id: u64,
    reward_index: u64,
    is_deposit_reward: bool,
    ctx: &<b>mut</b> TxContext,
): Coin&lt;RewardType&gt; {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <a href="../suilend/lending_market.md#suilend_lending_market_claim_rewards_by_obligation_id">claim_rewards_by_obligation_id</a>(
        <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>,
        cap.<a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>,
        clock,
        reserve_id,
        reward_index,
        is_deposit_reward,
        <b>false</b>,
        ctx,
    )
}
</code></pre>



</details>

<a name="suilend_lending_market_claim_rewards_and_deposit"></a>

## Function `claim_rewards_and_deposit`

Claims rewards earned by an obligation and deposits them back into the obligation.

This is a permissionless function that can be called by anyone to "crank" rewards for a given obligation.
It first claims the rewards from the specified reward pool and then, if the obligation has a borrow of the
same asset, it repays the borrow. Otherwise, it deposits the rewards into the specified reserve.


<a name="@Arguments_38"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a></code> - The ID of the obligation to claim rewards for and deposit into.
* <code>clock</code> - A reference to the <code>Clock</code>.
* <code>reward_reserve_id</code> - The array index of the reserve that is giving out the rewards.
* <code>reward_index</code> - The index of the reward pool to claim from.
* <code>is_deposit_reward</code> - A boolean indicating whether to claim deposit rewards (true) or borrow rewards (false).
* <code>deposit_reserve_id</code> - The array index of the reserve to deposit the claimed rewards into.


<a name="@Panics_39"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The reward period is not over.
* The <code>coin_type</code> of the deposit reserve does not match the type of the reward.
* It will also panic if the underlying <code><a href="../suilend/lending_market.md#suilend_lending_market_claim_rewards_by_obligation_id">claim_rewards_by_obligation_id</a></code> or <code><a href="../suilend/lending_market.md#suilend_lending_market_repay">repay</a></code> or <code><a href="../suilend/lending_market.md#suilend_lending_market_deposit_liquidity_and_mint_ctokens">deposit_liquidity_and_mint_ctokens</a></code> panics.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_claim_rewards_and_deposit">claim_rewards_and_deposit</a>&lt;P, RewardType&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, reward_reserve_id: u64, reward_index: u64, is_deposit_reward: bool, deposit_reserve_id: u64, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_claim_rewards_and_deposit">claim_rewards_and_deposit</a>&lt;P, RewardType&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: ID,
    clock: &Clock,
    // array index of <a href="../suilend/reserve.md#suilend_reserve">reserve</a> that is giving out the rewards
    reward_reserve_id: u64,
    reward_index: u64,
    is_deposit_reward: bool,
    // array index of <a href="../suilend/reserve.md#suilend_reserve">reserve</a> with type RewardType
    deposit_reserve_id: u64,
    ctx: &<b>mut</b> TxContext,
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <b>mut</b> rewards = <a href="../suilend/lending_market.md#suilend_lending_market_claim_rewards_by_obligation_id">claim_rewards_by_obligation_id</a>&lt;P, RewardType&gt;(
        <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>,
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>,
        clock,
        reward_reserve_id,
        reward_index,
        is_deposit_reward,
        <b>true</b>,
        ctx,
    );
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a> = object_table::borrow(&<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.obligations, <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>);
    <b>if</b> (gt(<a href="../suilend/obligation.md#suilend_obligation_borrowed_amount">obligation::borrowed_amount</a>&lt;P, RewardType&gt;(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>), <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0))) {
        <a href="../suilend/lending_market.md#suilend_lending_market_repay">repay</a>&lt;P, RewardType&gt;(
            <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>,
            deposit_reserve_id,
            <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>,
            clock,
            &<b>mut</b> rewards,
            ctx,
        );
    };
    <b>let</b> deposit_reserve = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, deposit_reserve_id);
    <b>let</b> expected_ctokens = {
        <b>assert</b>!(
            <a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(deposit_reserve) == type_name::get&lt;RewardType&gt;(),
            <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>,
        );
        floor(
            div(
                <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(coin::value(&rewards)),
                <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">reserve::ctoken_ratio</a>(deposit_reserve),
            ),
        )
    };
    <b>if</b> (expected_ctokens == 0) {
        <a href="../suilend/reserve.md#suilend_reserve_join_fees">reserve::join_fees</a>&lt;P, RewardType&gt;(deposit_reserve, coin::into_balance(rewards));
    } <b>else</b> {
        <b>let</b> ctokens = <a href="../suilend/lending_market.md#suilend_lending_market_deposit_liquidity_and_mint_ctokens">deposit_liquidity_and_mint_ctokens</a>&lt;P, RewardType&gt;(
            <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>,
            deposit_reserve_id,
            clock,
            rewards,
            ctx,
        );
        <a href="../suilend/lending_market.md#suilend_lending_market_deposit_ctokens_into_obligation_by_id">deposit_ctokens_into_obligation_by_id</a>&lt;P, RewardType&gt;(
            <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>,
            deposit_reserve_id,
            <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>,
            clock,
            ctokens,
            ctx,
        );
    }
}
</code></pre>



</details>

<a name="suilend_lending_market_init_staker"></a>

## Function `init_staker`

Initializes a staker for a SUI reserve.

This function is used to set up a staker for a SUI reserve, which allows the reserve
to participate in staking and earn rewards. It can only be called by the owner of the
lending market.


<a name="@Arguments_40"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code>_</code> - The <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a></code> to authorize the operation.
* <code>sui_reserve_array_index</code> - The index of the SUI reserve to initialize the staker for.
* <code>treasury_cap</code> - The <code>TreasuryCap</code> for the staker.


<a name="@Panics_41"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The reserve at <code>sui_reserve_array_index</code> is not a SUI reserve (EWrongType).
* <code>sui_reserve_array_index</code> is out of bounds.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_init_staker">init_staker</a>&lt;P, S: drop&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, _: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, sui_reserve_array_index: u64, treasury_cap: <a href="../dependencies/sui/coin.md#sui_coin_TreasuryCap">sui::coin::TreasuryCap</a>&lt;S&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_init_staker">init_staker</a>&lt;P, S: drop&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    _: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;,
    sui_reserve_array_index: u64,
    treasury_cap: TreasuryCap&lt;S&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, sui_reserve_array_index);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;SUI&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <a href="../suilend/reserve.md#suilend_reserve_init_staker">reserve::init_staker</a>&lt;P, S&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, treasury_cap, ctx);
}
</code></pre>



</details>

<a name="suilend_lending_market_rebalance_staker"></a>

## Function `rebalance_staker`

Rebalances a staker by staking or unstaking SUI to match the target staking amount.

This function is a wrapper around <code><a href="../suilend/reserve.md#suilend_reserve_rebalance_staker">reserve::rebalance_staker</a></code>. It ensures that the
lending market is on the correct version and that the specified reserve is a SUI
reserve before proceeding with the rebalancing.


<a name="@Arguments_42"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code>sui_reserve_array_index</code> - The index of the SUI reserve to rebalance.
* <code>system_state</code> - A mutable reference to the <code>SuiSystemState</code>.


<a name="@Panics_43"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The reserve at <code>sui_reserve_array_index</code> is not a SUI reserve (EWrongType).
* <code>sui_reserve_array_index</code> is out of bounds.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_rebalance_staker">rebalance_staker</a>&lt;P&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, sui_reserve_array_index: u64, system_state: &<b>mut</b> <a href="../dependencies/sui_system/sui_system.md#sui_system_sui_system_SuiSystemState">sui_system::sui_system::SuiSystemState</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_rebalance_staker">rebalance_staker</a>&lt;P&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    sui_reserve_array_index: u64,
    system_state: &<b>mut</b> SuiSystemState,
    ctx: &<b>mut</b> TxContext,
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, sui_reserve_array_index);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;SUI&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <a href="../suilend/reserve.md#suilend_reserve_rebalance_staker">reserve::rebalance_staker</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, system_state, ctx);
}
</code></pre>



</details>

<a name="suilend_lending_market_unstake_sui_from_staker"></a>

## Function `unstake_sui_from_staker`

Unstakes SUI from a staker.

This function is a wrapper around <code><a href="../suilend/reserve.md#suilend_reserve_unstake_sui_from_staker">reserve::unstake_sui_from_staker</a></code>. It ensures that the
lending market is on the correct version and that the specified reserve is a SUI
reserve before proceeding with the unstaking.


<a name="@Arguments_44"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code>sui_reserve_array_index</code> - The index of the SUI reserve to unstake from.
* <code>liquidity_request</code> - A reference to the <code>LiquidityRequest</code> for the unstake.
* <code>system_state</code> - A mutable reference to the <code>SuiSystemState</code>.


<a name="@Panics_45"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* <code>sui_reserve_array_index</code> is out of bounds.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_unstake_sui_from_staker">unstake_sui_from_staker</a>&lt;P&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, sui_reserve_array_index: u64, liquidity_request: &<a href="../suilend/reserve.md#suilend_reserve_LiquidityRequest">suilend::reserve::LiquidityRequest</a>&lt;P, <a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;, system_state: &<b>mut</b> <a href="../dependencies/sui_system/sui_system.md#sui_system_sui_system_SuiSystemState">sui_system::sui_system::SuiSystemState</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_unstake_sui_from_staker">unstake_sui_from_staker</a>&lt;P&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    sui_reserve_array_index: u64,
    liquidity_request: &LiquidityRequest&lt;P, SUI&gt;,
    system_state: &<b>mut</b> SuiSystemState,
    ctx: &<b>mut</b> TxContext,
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, sui_reserve_array_index);
    <b>if</b> (<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) != type_name::get&lt;SUI&gt;()) {
        <b>return</b>
    };
    <a href="../suilend/reserve.md#suilend_reserve_unstake_sui_from_staker">reserve::unstake_sui_from_staker</a>&lt;P, SUI&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, liquidity_request, system_state, ctx);
}
</code></pre>



</details>

<a name="suilend_lending_market_reserves"></a>

## Function `reserves`

Get a reference to the lending market's reserves vector.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>&lt;P&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;): &vector&lt;<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>&lt;P&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;): &vector&lt;Reserve&lt;P&gt;&gt; {
    &<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>
}
</code></pre>



</details>

<a name="suilend_lending_market_max_borrow_amount"></a>

## Function `max_borrow_amount`



<pre><code><b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_max_borrow_amount">max_borrow_amount</a>&lt;P&gt;(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">suilend::rate_limiter::RateLimiter</a>, <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_max_borrow_amount">max_borrow_amount</a>&lt;P&gt;(
    <b>mut</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: RateLimiter,
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &Obligation&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &Reserve&lt;P&gt;,
    clock: &Clock,
): u64 {
    <b>let</b> remaining_outflow_usd = <a href="../suilend/rate_limiter.md#suilend_rate_limiter_remaining_outflow">rate_limiter::remaining_outflow</a>(
        &<b>mut</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>,
        clock::timestamp_ms(clock) / 1000,
    );
    <b>let</b> rate_limiter_max_borrow_amount = saturating_floor(
        <a href="../suilend/reserve.md#suilend_reserve_usd_to_token_amount_lower_bound">reserve::usd_to_token_amount_lower_bound</a>(
            <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
            min(remaining_outflow_usd, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1_000_000_000)),
        ),
    );
    <b>let</b> max_borrow_amount_including_fees = <a href="../dependencies/std/u64.md#std_u64_min">std::u64::min</a>(
        <a href="../dependencies/std/u64.md#std_u64_min">std::u64::min</a>(
            <a href="../suilend/obligation.md#suilend_obligation_max_borrow_amount">obligation::max_borrow_amount</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
            <a href="../suilend/reserve.md#suilend_reserve_max_borrow_amount">reserve::max_borrow_amount</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        ),
        rate_limiter_max_borrow_amount,
    );
    // account <b>for</b> fee
    <b>let</b> <b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_max_borrow_amount">max_borrow_amount</a> = floor(
        div(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(max_borrow_amount_including_fees),
            add(<a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1), borrow_fee(<a href="../suilend/reserve.md#suilend_reserve_config">reserve::config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>))),
        ),
    );
    <b>let</b> fee = ceil(
        mul(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/lending_market.md#suilend_lending_market_max_borrow_amount">max_borrow_amount</a>),
            borrow_fee(<a href="../suilend/reserve.md#suilend_reserve_config">reserve::config</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)),
        ),
    );
    // since the fee is ceiling'd, we need to subtract 1 from the <a href="../suilend/lending_market.md#suilend_lending_market_max_borrow_amount">max_borrow_amount</a> in certain
    // cases
    <b>if</b> (<a href="../suilend/lending_market.md#suilend_lending_market_max_borrow_amount">max_borrow_amount</a> + fee &gt; max_borrow_amount_including_fees && <a href="../suilend/lending_market.md#suilend_lending_market_max_borrow_amount">max_borrow_amount</a> &gt; 0) {
        <a href="../suilend/lending_market.md#suilend_lending_market_max_borrow_amount">max_borrow_amount</a> = <a href="../suilend/lending_market.md#suilend_lending_market_max_borrow_amount">max_borrow_amount</a> - 1;
    };
    <a href="../suilend/lending_market.md#suilend_lending_market_max_borrow_amount">max_borrow_amount</a>
}
</code></pre>



</details>

<a name="suilend_lending_market_max_withdraw_amount"></a>

## Function `max_withdraw_amount`



<pre><code><b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_max_withdraw_amount">max_withdraw_amount</a>&lt;P&gt;(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">suilend::rate_limiter::RateLimiter</a>, <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_max_withdraw_amount">max_withdraw_amount</a>&lt;P&gt;(
    <b>mut</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: RateLimiter,
    <a href="../suilend/obligation.md#suilend_obligation">obligation</a>: &Obligation&lt;P&gt;,
    <a href="../suilend/reserve.md#suilend_reserve">reserve</a>: &Reserve&lt;P&gt;,
    clock: &Clock,
): u64 {
    <b>let</b> remaining_outflow_usd = <a href="../suilend/rate_limiter.md#suilend_rate_limiter_remaining_outflow">rate_limiter::remaining_outflow</a>(
        &<b>mut</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>,
        clock::timestamp_ms(clock) / 1000,
    );
    <b>let</b> rate_limiter_max_withdraw_amount = <a href="../suilend/reserve.md#suilend_reserve_usd_to_token_amount_lower_bound">reserve::usd_to_token_amount_lower_bound</a>(
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
        min(remaining_outflow_usd, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1_000_000_000)),
    );
    <b>let</b> rate_limiter_max_withdraw_ctoken_amount = floor(
        div(
            rate_limiter_max_withdraw_amount,
            <a href="../suilend/reserve.md#suilend_reserve_ctoken_ratio">reserve::ctoken_ratio</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        ),
    );
    <a href="../dependencies/std/u64.md#std_u64_min">std::u64::min</a>(
        <a href="../dependencies/std/u64.md#std_u64_min">std::u64::min</a>(
            <a href="../suilend/obligation.md#suilend_obligation_max_withdraw_amount">obligation::max_withdraw_amount</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
            rate_limiter_max_withdraw_ctoken_amount,
        ),
        <a href="../suilend/reserve.md#suilend_reserve_max_redeem_amount">reserve::max_redeem_amount</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
    )
}
</code></pre>



</details>

<a name="suilend_lending_market_obligation_id"></a>

## Function `obligation_id`

Get the obligation ID from an <code><a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>&lt;P&gt;(cap: &<a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">suilend::lending_market::ObligationOwnerCap</a>&lt;P&gt;): <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>&lt;P&gt;(cap: &<a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a>&lt;P&gt;): ID {
    cap.<a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>
}
</code></pre>



</details>

<a name="suilend_lending_market_reserve_array_index"></a>

## Function `reserve_array_index`

Get the array index of a reserve by its coin type.
slow function. use sparingly.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;): u64 {
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; vector::length(&<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>)) {
        <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow(&<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, i);
        <b>if</b> (<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;T&gt;()) {
            <b>return</b> i
        };
        i = i + 1;
    };
    i
}
</code></pre>



</details>

<a name="suilend_lending_market_reserve"></a>

## Function `reserve`

Get a reference to a reserve by its coin type.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;): &<a href="../suilend/reserve.md#suilend_reserve_Reserve">suilend::reserve::Reserve</a>&lt;P&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;): &Reserve&lt;P&gt; {
    <b>let</b> i = <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>);
    vector::borrow(&<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, i)
}
</code></pre>



</details>

<a name="suilend_lending_market_obligation"></a>

## Function `obligation`

Get a reference to an obligation by its ID.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>&lt;P&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>): &<a href="../suilend/obligation.md#suilend_obligation_Obligation">suilend::obligation::Obligation</a>&lt;P&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a>&lt;P&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: ID): &Obligation&lt;P&gt; {
    object_table::borrow(&<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.obligations, <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>)
}
</code></pre>



</details>

<a name="suilend_lending_market_fee_receiver"></a>

## Function `fee_receiver`

Get the fee receiver address.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_fee_receiver">fee_receiver</a>&lt;P&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_fee_receiver">fee_receiver</a>&lt;P&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;): <b>address</b> {
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_fee_receiver">fee_receiver</a>
}
</code></pre>



</details>

<a name="suilend_lending_market_rate_limiter_exemption_amount"></a>

## Function `rate_limiter_exemption_amount`

Get the amount of a rate limiter exemption.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_rate_limiter_exemption_amount">rate_limiter_exemption_amount</a>&lt;P, T&gt;(exemption: &<a href="../suilend/lending_market.md#suilend_lending_market_RateLimiterExemption">suilend::lending_market::RateLimiterExemption</a>&lt;P, T&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_rate_limiter_exemption_amount">rate_limiter_exemption_amount</a>&lt;P, T&gt;(exemption: &<a href="../suilend/lending_market.md#suilend_lending_market_RateLimiterExemption">RateLimiterExemption</a>&lt;P, T&gt;): u64 {
    exemption.amount
}
</code></pre>



</details>

<a name="suilend_lending_market_migrate"></a>

## Function `migrate`

Migrates the lending market to the current version.


<pre><code><b>entry</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_migrate">migrate</a>&lt;P&gt;(_: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_migrate">migrate</a>&lt;P&gt;(_: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version &lt;= <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a> - 1, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version = <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>;
}
</code></pre>



</details>

<a name="suilend_lending_market_add_reserve"></a>

## Function `add_reserve`

Adds a new reserve to the lending market.

This function creates a new reserve and adds it to the lending market's reserves vector.
It can only be called by the owner of the lending market.


<a name="@Arguments_46"></a>

### Arguments


* <code>_</code> - The <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a></code> to authorize the operation.
* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code>price_info</code> - The initial Pyth price feed for the new reserve.
* <code>config</code> - The configuration for the new reserve.
* <code>coin_metadata</code> - The metadata for the coin type of the new reserve.
* <code>clock</code> - A reference to the <code>Clock</code>.


<a name="@Panics_47"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* A reserve for the same coin type already exists (EDuplicateReserve).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_add_reserve">add_reserve</a>&lt;P, T&gt;(_: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, price_info: &<a href="../dependencies/pyth/price_info.md#pyth_price_info_PriceInfoObject">pyth::price_info::PriceInfoObject</a>, config: <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>, coin_metadata: &<a href="../dependencies/sui/coin.md#sui_coin_CoinMetadata">sui::coin::CoinMetadata</a>&lt;T&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_add_reserve">add_reserve</a>&lt;P, T&gt;(
    _: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    price_info: &PriceInfoObject,
    config: ReserveConfig,
    coin_metadata: &CoinMetadata&lt;T&gt;,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>assert</b>!(
        <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>) == vector::length(&<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>),
        <a href="../suilend/lending_market.md#suilend_lending_market_EDuplicateReserve">EDuplicateReserve</a>,
    );
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = <a href="../suilend/reserve.md#suilend_reserve_create_reserve">reserve::create_reserve</a>&lt;P, T&gt;(
        object::id(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>),
        config,
        vector::length(&<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>),
        coin::get_decimals(coin_metadata),
        price_info,
        clock,
        ctx,
    );
    vector::push_back(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/reserve.md#suilend_reserve">reserve</a>);
}
</code></pre>



</details>

<a name="suilend_lending_market_update_reserve_config"></a>

## Function `update_reserve_config`

Updates the configuration of a reserve.

This function allows the owner of the lending market to update the configuration of a specific reserve.
It can only be called by the owner of the lending market.


<a name="@Arguments_48"></a>

### Arguments


* <code>_</code> - The <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a></code> to authorize the operation.
* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to update.
* <code>config</code> - The new configuration for the reserve.


<a name="@Panics_49"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.
* The <code>coin_type</code> of the reserve does not match the type <code>T</code> (EWrongType).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_update_reserve_config">update_reserve_config</a>&lt;P, T&gt;(_: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, config: <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_update_reserve_config">update_reserve_config</a>&lt;P, T&gt;(
    _: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    config: ReserveConfig,
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;T&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <a href="../suilend/reserve.md#suilend_reserve_update_reserve_config">reserve::update_reserve_config</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, config);
}
</code></pre>



</details>

<a name="suilend_lending_market_change_reserve_price_feed"></a>

## Function `change_reserve_price_feed`

Changes the price feed of a reserve.

This function allows the owner of the lending market to update the Pyth price feed for a specific reserve.
It can only be called by the owner of the lending market.


<a name="@Arguments_50"></a>

### Arguments


* <code>_</code> - The <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a></code> to authorize the operation.
* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to update the price feed for.
* <code>price_info_obj</code> - The new Pyth price feed object.
* <code>clock</code> - A reference to the <code>Clock</code>.


<a name="@Panics_51"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.
* The <code>coin_type</code> of the reserve does not match the type <code>T</code> (EWrongType).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_change_reserve_price_feed">change_reserve_price_feed</a>&lt;P, T&gt;(_: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, price_info_obj: &<a href="../dependencies/pyth/price_info.md#pyth_price_info_PriceInfoObject">pyth::price_info::PriceInfoObject</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_change_reserve_price_feed">change_reserve_price_feed</a>&lt;P, T&gt;(
    _: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    price_info_obj: &PriceInfoObject,
    clock: &Clock,
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;T&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <a href="../suilend/reserve.md#suilend_reserve_change_price_feed">reserve::change_price_feed</a>&lt;P&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, price_info_obj, clock);
}
</code></pre>



</details>

<a name="suilend_lending_market_add_pool_reward"></a>

## Function `add_pool_reward`

Adds a new reward pool to a reserve for either deposits or borrows.

This function allows the owner of the lending market to incentivize users by adding rewards
to a specific reserve. The rewards are distributed over a specified time period.


<a name="@Arguments_52"></a>

### Arguments


* <code>_</code> - The <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a></code> to authorize the operation.
* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to add the reward pool to.
* <code>is_deposit_reward</code> - A boolean indicating whether the reward is for deposits (<code><b>true</b></code>) or borrows (<code><b>false</b></code>).
* <code>rewards</code> - The <code>Coin</code> containing the total amount of rewards to be distributed.
* <code>start_time_ms</code> - The timestamp in milliseconds when the reward distribution starts.
* <code>end_time_ms</code> - The timestamp in milliseconds when the reward distribution ends.
* <code>clock</code> - A reference to the <code>Clock</code>.


<a name="@Panics_53"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.
* The underlying <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_add_pool_reward">liquidity_mining::add_pool_reward</a></code> function panics (e.g., if <code>start_time_ms</code> >= <code>end_time_ms</code> or reward amount is zero).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_add_pool_reward">add_pool_reward</a>&lt;P, RewardType&gt;(_: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, is_deposit_reward: bool, rewards: <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;RewardType&gt;, start_time_ms: u64, end_time_ms: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_add_pool_reward">add_pool_reward</a>&lt;P, RewardType&gt;(
    _: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    is_deposit_reward: bool,
    rewards: Coin&lt;RewardType&gt;,
    start_time_ms: u64,
    end_time_ms: u64,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>let</b> pool_reward_manager = <b>if</b> (is_deposit_reward) {
        <a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager_mut">reserve::deposits_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    } <b>else</b> {
        <a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager_mut">reserve::borrows_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    };
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_add_pool_reward">liquidity_mining::add_pool_reward</a>&lt;RewardType&gt;(
        pool_reward_manager,
        coin::into_balance(rewards),
        start_time_ms,
        end_time_ms,
        clock,
        ctx,
    );
}
</code></pre>



</details>

<a name="suilend_lending_market_cancel_pool_reward"></a>

## Function `cancel_pool_reward`

Cancels a reward pool from a reserve.

This is an admin-only function that allows the lending market owner to cancel a reward pool
that is currently active. When a reward pool is cancelled, any unallocated rewards are
returned to the owner.


<a name="@Arguments_54"></a>

### Arguments


* <code>_</code> - The <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a></code> to authorize the operation.
* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to cancel the reward pool from.
* <code>is_deposit_reward</code> - A boolean indicating whether the reward is for deposits (<code><b>true</b></code>) or borrows (<code><b>false</b></code>).
* <code>reward_index</code> - The index of the reward pool to cancel.
* <code>clock</code> - A reference to the <code>Clock</code>.


<a name="@Returns_55"></a>

### Returns


* <code>Coin&lt;RewardType&gt;</code> - A <code>Coin</code> containing the unallocated rewards from the cancelled pool.


<a name="@Panics_56"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.
* The underlying <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_cancel_pool_reward">liquidity_mining::cancel_pool_reward</a></code> function panics.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_cancel_pool_reward">cancel_pool_reward</a>&lt;P, RewardType&gt;(_: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, is_deposit_reward: bool, reward_index: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;RewardType&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_cancel_pool_reward">cancel_pool_reward</a>&lt;P, RewardType&gt;(
    _: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    is_deposit_reward: bool,
    reward_index: u64,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): Coin&lt;RewardType&gt; {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>let</b> pool_reward_manager = <b>if</b> (is_deposit_reward) {
        <a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager_mut">reserve::deposits_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    } <b>else</b> {
        <a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager_mut">reserve::borrows_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    };
    <b>let</b> unallocated_rewards = <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_cancel_pool_reward">liquidity_mining::cancel_pool_reward</a>&lt;RewardType&gt;(
        pool_reward_manager,
        reward_index,
        clock,
    );
    coin::from_balance(unallocated_rewards, ctx)
}
</code></pre>



</details>

<a name="suilend_lending_market_close_pool_reward"></a>

## Function `close_pool_reward`

Closes a reward pool from a reserve after its distribution period has ended.

This is an admin-only function that allows the lending market owner to close a reward pool
that has finished distributing rewards. When a reward pool is closed, any unallocated rewards
due to rounding or other factors are returned to the owner. This function can only be called
after the pool's <code>end_time_ms</code> has passed.


<a name="@Arguments_57"></a>

### Arguments


* <code>_</code> - The <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a></code> to authorize the operation.
* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to close the reward pool from.
* <code>is_deposit_reward</code> - A boolean indicating whether the reward is for deposits (<code><b>true</b></code>) or borrows (<code><b>false</b></code>).
* <code>reward_index</code> - The index of the reward pool to close.
* <code>clock</code> - A reference to the <code>Clock</code>.


<a name="@Returns_58"></a>

### Returns


* <code>Coin&lt;RewardType&gt;</code> - A <code>Coin</code> containing the unallocated rewards from the closed pool.


<a name="@Panics_59"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.
* The underlying <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_close_pool_reward">liquidity_mining::close_pool_reward</a></code> function panics (e.g., if the reward period is not over).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_close_pool_reward">close_pool_reward</a>&lt;P, RewardType&gt;(_: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, is_deposit_reward: bool, reward_index: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;RewardType&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_close_pool_reward">close_pool_reward</a>&lt;P, RewardType&gt;(
    _: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    is_deposit_reward: bool,
    reward_index: u64,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): Coin&lt;RewardType&gt; {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>let</b> pool_reward_manager = <b>if</b> (is_deposit_reward) {
        <a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager_mut">reserve::deposits_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    } <b>else</b> {
        <a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager_mut">reserve::borrows_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    };
    <b>let</b> unallocated_rewards = <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_close_pool_reward">liquidity_mining::close_pool_reward</a>&lt;RewardType&gt;(
        pool_reward_manager,
        reward_index,
        clock,
    );
    coin::from_balance(unallocated_rewards, ctx)
}
</code></pre>



</details>

<a name="suilend_lending_market_update_rate_limiter_config"></a>

## Function `update_rate_limiter_config`

Updates the rate limiter configuration.

This is an admin-only function that allows the lending market owner to update the rate
limiter configuration. The new configuration will replace the existing one.


<a name="@Arguments_60"></a>

### Arguments


* <code>_</code> - The <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a></code> to authorize the operation.
* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code>clock</code> - A reference to the <code>Clock</code> to get the current timestamp.
* <code>config</code> - The new <code>RateLimiterConfig</code> to apply.


<a name="@Panics_61"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_update_rate_limiter_config">update_rate_limiter_config</a>&lt;P&gt;(_: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, config: <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiterConfig">suilend::rate_limiter::RateLimiterConfig</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_update_rate_limiter_config">update_rate_limiter_config</a>&lt;P&gt;(
    _: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    clock: &Clock,
    config: RateLimiterConfig,
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a> = <a href="../suilend/rate_limiter.md#suilend_rate_limiter_new">rate_limiter::new</a>(config, clock::timestamp_ms(clock) / 1000);
}
</code></pre>



</details>

<a name="suilend_lending_market_set_fee_receivers"></a>

## Function `set_fee_receivers`

Sets the fee receivers for the lending market.

This is an admin-only function that allows the lending market owner to set the fee receivers
and their respective weights for distributing protocol fees. The fees are distributed
proportionally based on these weights.


<a name="@Arguments_62"></a>

### Arguments


* <code>_</code> - The <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a></code> to authorize the operation.
* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code>receivers</code> - A vector of addresses that will receive the fees.
* <code>weights</code> - A vector of weights corresponding to each receiver.


<a name="@Panics_63"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The <code>receivers</code> and <code>weights</code> vectors do not have the same length (EInvalidFeeReceivers).
* The <code>receivers</code> vector is empty (EInvalidFeeReceivers).
* The sum of <code>weights</code> is zero (EInvalidFeeReceivers).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_set_fee_receivers">set_fee_receivers</a>&lt;P&gt;(_: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, receivers: vector&lt;<b>address</b>&gt;, weights: vector&lt;u64&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_set_fee_receivers">set_fee_receivers</a>&lt;P&gt;(
    _: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    receivers: vector&lt;<b>address</b>&gt;,
    weights: vector&lt;u64&gt;,
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>assert</b>!(vector::length(&receivers) == vector::length(&weights), <a href="../suilend/lending_market.md#suilend_lending_market_EInvalidFeeReceivers">EInvalidFeeReceivers</a>);
    <b>assert</b>!(vector::length(&receivers) &gt; 0, <a href="../suilend/lending_market.md#suilend_lending_market_EInvalidFeeReceivers">EInvalidFeeReceivers</a>);
    <b>let</b> total_weight = vector::fold!(weights, 0, |acc, weight| acc + weight);
    <b>assert</b>!(total_weight &gt; 0, <a href="../suilend/lending_market.md#suilend_lending_market_EInvalidFeeReceivers">EInvalidFeeReceivers</a>);
    <b>if</b> (dynamic_field::exists_(&<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.id, <a href="../suilend/lending_market.md#suilend_lending_market_FeeReceiversKey">FeeReceiversKey</a> {})) {
        <b>let</b> <a href="../suilend/lending_market.md#suilend_lending_market_FeeReceivers">FeeReceivers</a> { .. } = dynamic_field::remove&lt;<a href="../suilend/lending_market.md#suilend_lending_market_FeeReceiversKey">FeeReceiversKey</a>, <a href="../suilend/lending_market.md#suilend_lending_market_FeeReceivers">FeeReceivers</a>&gt;(
            &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.id,
            <a href="../suilend/lending_market.md#suilend_lending_market_FeeReceiversKey">FeeReceiversKey</a> {},
        );
    };
    dynamic_field::add(
        &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.id,
        <a href="../suilend/lending_market.md#suilend_lending_market_FeeReceiversKey">FeeReceiversKey</a> {},
        <a href="../suilend/lending_market.md#suilend_lending_market_FeeReceivers">FeeReceivers</a> { receivers, weights, total_weight },
    );
}
</code></pre>



</details>

<a name="suilend_lending_market_claim_fees"></a>

## Function `claim_fees`

Claims the fees from a reserve and distributes them to the fee receivers.

This is a permissionless entry function that can be called by anyone to trigger the
distribution of accumulated protocol fees from a specific reserve. The fees, which
can be in both the underlying asset and cTokens, are transferred to the fee receivers
according to the weights configured via <code><a href="../suilend/lending_market.md#suilend_lending_market_set_fee_receivers">set_fee_receivers</a></code>.


<a name="@Arguments_64"></a>

### Arguments


* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A mutable reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> - The index of the reserve to claim fees from.
* <code>system_state</code> - A mutable reference to the <code>SuiSystemState</code>, required for claiming staking rewards.


<a name="@Panics_65"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The generic type <code>T</code> does not match the coin type of the reserve at <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> (EWrongType).
* <code><a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a></code> is out of bounds.
* The <code><a href="../suilend/lending_market.md#suilend_lending_market_FeeReceivers">FeeReceivers</a></code> dynamic field has not been set on the lending market.


<pre><code><b>entry</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_claim_fees">claim_fees</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, system_state: &<b>mut</b> <a href="../dependencies/sui_system/sui_system.md#sui_system_sui_system_SuiSystemState">sui_system::sui_system::SuiSystemState</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_claim_fees">claim_fees</a>&lt;P, T&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    system_state: &<b>mut</b> SuiSystemState,
    ctx: &<b>mut</b> TxContext
) {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;T&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <b>let</b> (<b>mut</b> ctoken_fees, <b>mut</b> fees) = <a href="../suilend/reserve.md#suilend_reserve_claim_fees">reserve::claim_fees</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, system_state, ctx);
    <b>let</b> total_ctoken_fees = balance::value(&ctoken_fees);
    <b>let</b> total_fees = balance::value(&fees);
    <b>let</b> fee_receivers: &<a href="../suilend/lending_market.md#suilend_lending_market_FeeReceivers">FeeReceivers</a> = dynamic_field::borrow(
        &<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.id,
        <a href="../suilend/lending_market.md#suilend_lending_market_FeeReceiversKey">FeeReceiversKey</a> {},
    );
    <b>let</b> num_fee_receivers = vector::length(&fee_receivers.weights);
    num_fee_receivers.do!(|i| {
        <b>let</b> fee_amount =
            (total_fees <b>as</b> u128) * (fee_receivers.weights[i] <b>as</b> u128) / (fee_receivers.total_weight <b>as</b> u128);
        <b>let</b> fee = <b>if</b> (i == num_fee_receivers - 1) {
            balance::withdraw_all(&<b>mut</b> fees)
        } <b>else</b> {
            balance::split(&<b>mut</b> fees, fee_amount <b>as</b> u64)
        };
        <b>if</b> (balance::value(&fee) &gt; 0) {
            transfer::public_transfer(coin::from_balance(fee, ctx), fee_receivers.receivers[i]);
        } <b>else</b> {
            balance::destroy_zero(fee);
        };
        <b>let</b> ctoken_fee_amount =
            (total_ctoken_fees <b>as</b> u128) * (fee_receivers.weights[i] <b>as</b> u128) / (fee_receivers.total_weight <b>as</b> u128);
        <b>let</b> ctoken_fee = <b>if</b> (i == num_fee_receivers - 1) {
            balance::withdraw_all(&<b>mut</b> ctoken_fees)
        } <b>else</b> {
            balance::split(&<b>mut</b> ctoken_fees, ctoken_fee_amount <b>as</b> u64)
        };
        <b>if</b> (balance::value(&ctoken_fee) &gt; 0) {
            transfer::public_transfer(
                coin::from_balance(ctoken_fee, ctx),
                fee_receivers.receivers[i],
            );
        } <b>else</b> {
            balance::destroy_zero(ctoken_fee);
        };
    });
    balance::destroy_zero(fees);
    balance::destroy_zero(ctoken_fees);
}
</code></pre>



</details>

<a name="suilend_lending_market_new_obligation_owner_cap"></a>

## Function `new_obligation_owner_cap`

Creates a new obligation owner cap for an existing obligation.

This is an admin-only function that allows the lending market owner to create a new
<code><a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a></code> for an obligation that already exists. This can be useful for
recovery purposes or administrative actions where a new capability object is needed.


<a name="@Arguments_66"></a>

### Arguments


* <code>_</code> - The <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a></code> to authorize the operation.
* <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> - A reference to the <code><a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a></code>.
* <code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a></code> - The ID of the obligation to create a new owner cap for.


<a name="@Returns_67"></a>

### Returns


* <code><a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a>&lt;P&gt;</code> - The newly created ownership capability for the specified obligation.


<a name="@Panics_68"></a>

### Panics


This function will panic if:
* The <code><a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a></code> version is not <code><a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* The <code><a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a></code> is not found in the lending market's obligations (EInvalidObligationId).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_new_obligation_owner_cap">new_obligation_owner_cap</a>&lt;P&gt;(_: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">suilend::lending_market::ObligationOwnerCap</a>&lt;P&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_new_obligation_owner_cap">new_obligation_owner_cap</a>&lt;P&gt;(
    _: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">LendingMarketOwnerCap</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: ID,
    ctx: &<b>mut</b> TxContext,
): <a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a>&lt;P&gt; {
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>assert</b>!(
        object_table::contains(&<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.obligations, <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>),
        <a href="../suilend/lending_market.md#suilend_lending_market_EInvalidObligationId">EInvalidObligationId</a>,
    );
    <b>let</b> cap = <a href="../suilend/lending_market.md#suilend_lending_market_ObligationOwnerCap">ObligationOwnerCap</a>&lt;P&gt; {
        id: object::new(ctx),
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>,
    };
    cap
}
</code></pre>



</details>

<a name="suilend_lending_market_deposit_ctokens_into_obligation_by_id"></a>

## Function `deposit_ctokens_into_obligation_by_id`



<pre><code><b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_deposit_ctokens_into_obligation_by_id">deposit_ctokens_into_obligation_by_id</a>&lt;P, T&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64, <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, deposit: <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;<a href="../suilend/reserve.md#suilend_reserve_CToken">suilend::reserve::CToken</a>&lt;P, T&gt;&gt;, _ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_deposit_ctokens_into_obligation_by_id">deposit_ctokens_into_obligation_by_id</a>&lt;P, T&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>: u64,
    <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: ID,
    clock: &Clock,
    deposit: Coin&lt;CToken&lt;P, T&gt;&gt;,
    _ctx: &<b>mut</b> TxContext,
) {
    <b>let</b> lending_market_id = object::id_address(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>);
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    <b>assert</b>!(coin::value(&deposit) &gt; 0, <a href="../suilend/lending_market.md#suilend_lending_market_ETooSmall">ETooSmall</a>);
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, <a href="../suilend/lending_market.md#suilend_lending_market_reserve_array_index">reserve_array_index</a>);
    <b>assert</b>!(<a href="../suilend/reserve.md#suilend_reserve_coin_type">reserve::coin_type</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>) == type_name::get&lt;T&gt;(), <a href="../suilend/lending_market.md#suilend_lending_market_EWrongType">EWrongType</a>);
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a> = object_table::borrow_mut(
        &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.obligations,
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>,
    );
    event::emit(<a href="../suilend/lending_market.md#suilend_lending_market_DepositEvent">DepositEvent</a> {
        lending_market_id,
        coin_type: type_name::get&lt;T&gt;(),
        reserve_id: object::id_address(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: object::id_address(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>),
        ctoken_amount: coin::value(&deposit),
    });
    <a href="../suilend/obligation.md#suilend_obligation_deposit">obligation::deposit</a>&lt;P&gt;(
        <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
        <a href="../suilend/reserve.md#suilend_reserve">reserve</a>,
        clock,
        coin::value(&deposit),
    );
    <a href="../suilend/reserve.md#suilend_reserve_deposit_ctokens">reserve::deposit_ctokens</a>&lt;P, T&gt;(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, coin::into_balance(deposit));
    <a href="../suilend/obligation.md#suilend_obligation_zero_out_rewards_if_looped">obligation::zero_out_rewards_if_looped</a>(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>, &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, clock);
}
</code></pre>



</details>

<a name="suilend_lending_market_claim_rewards_by_obligation_id"></a>

## Function `claim_rewards_by_obligation_id`



<pre><code><b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_claim_rewards_by_obligation_id">claim_rewards_by_obligation_id</a>&lt;P, RewardType&gt;(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, reserve_id: u64, reward_index: u64, is_deposit_reward: bool, fail_if_reward_period_not_over: bool, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;RewardType&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/lending_market.md#suilend_lending_market_claim_rewards_by_obligation_id">claim_rewards_by_obligation_id</a>&lt;P, RewardType&gt;(
    <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>: &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">LendingMarket</a>&lt;P&gt;,
    <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: ID,
    clock: &Clock,
    reserve_id: u64,
    reward_index: u64,
    is_deposit_reward: bool,
    fail_if_reward_period_not_over: bool,
    ctx: &<b>mut</b> TxContext,
): Coin&lt;RewardType&gt; {
    <b>let</b> lending_market_id = object::id_address(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>);
    <b>assert</b>!(<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.version == <a href="../suilend/lending_market.md#suilend_lending_market_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market.md#suilend_lending_market_EIncorrectVersion">EIncorrectVersion</a>);
    // <b>assert</b>!(
    //     type_name::borrow_string(&type_name::get&lt;RewardType&gt;()) !=
    //     &ascii::string(b"97d2a76efce8e7cdf55b781bd3d23382237fb1d095f9b9cad0bf1fd5f7176b62::suilend_point_2::SUILEND_POINT_2"),
    //     ECannotClaimReward,
    // );
    <b>let</b> <a href="../suilend/obligation.md#suilend_obligation">obligation</a> = object_table::borrow_mut(
        &<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.obligations,
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>,
    );
    <b>let</b> <a href="../suilend/reserve.md#suilend_reserve">reserve</a> = vector::borrow_mut(&<b>mut</b> <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>.<a href="../suilend/lending_market.md#suilend_lending_market_reserves">reserves</a>, reserve_id);
    <a href="../suilend/reserve.md#suilend_reserve_compound_interest">reserve::compound_interest</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>, clock);
    <b>let</b> pool_reward_manager = <b>if</b> (is_deposit_reward) {
        <a href="../suilend/reserve.md#suilend_reserve_deposits_pool_reward_manager_mut">reserve::deposits_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    } <b>else</b> {
        <a href="../suilend/reserve.md#suilend_reserve_borrows_pool_reward_manager_mut">reserve::borrows_pool_reward_manager_mut</a>(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>)
    };
    <b>if</b> (fail_if_reward_period_not_over) {
        <b>let</b> pool_reward = option::borrow(
            <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">liquidity_mining::pool_reward</a>(pool_reward_manager, reward_index),
        );
        <b>assert</b>!(
            clock::timestamp_ms(clock) &gt;= <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">liquidity_mining::end_time_ms</a>(pool_reward),
            <a href="../suilend/lending_market.md#suilend_lending_market_ERewardPeriodNotOver">ERewardPeriodNotOver</a>,
        );
    };
    <b>let</b> rewards = coin::from_balance(
        <a href="../suilend/obligation.md#suilend_obligation_claim_rewards">obligation::claim_rewards</a>&lt;P, RewardType&gt;(
            <a href="../suilend/obligation.md#suilend_obligation">obligation</a>,
            pool_reward_manager,
            clock,
            reward_index,
        ),
        ctx,
    );
    <b>let</b> pool_reward_id = <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_id">liquidity_mining::pool_reward_id</a>(pool_reward_manager, reward_index);
    event::emit(<a href="../suilend/lending_market.md#suilend_lending_market_ClaimRewardEvent">ClaimRewardEvent</a> {
        lending_market_id,
        reserve_id: object::id_address(<a href="../suilend/reserve.md#suilend_reserve">reserve</a>),
        <a href="../suilend/lending_market.md#suilend_lending_market_obligation_id">obligation_id</a>: object::id_address(<a href="../suilend/obligation.md#suilend_obligation">obligation</a>),
        is_deposit_reward,
        pool_reward_id: object::id_to_address(&pool_reward_id),
        coin_type: type_name::get&lt;RewardType&gt;(),
        liquidity_amount: coin::value(&rewards),
    });
    rewards
}
</code></pre>



</details>
