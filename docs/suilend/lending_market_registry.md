
<a name="suilend_lending_market_registry"></a>

# Module `suilend::lending_market_registry`

Top level object that tracks all lending markets.
Ensures that there is only one LendingMarket of each type.
Anyone can create a new LendingMarket via the registry.


-  [Struct `Registry`](#suilend_lending_market_registry_Registry)
-  [Struct `LENDING_MARKET_2`](#suilend_lending_market_registry_LENDING_MARKET_2)
-  [Constants](#@Constants_0)
-  [Function `init`](#suilend_lending_market_registry_init)
-  [Function `create_lending_market`](#suilend_lending_market_registry_create_lending_market)
    -  [Arguments](#@Arguments_1)
    -  [Returns](#@Returns_2)
    -  [Panics](#@Panics_3)


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
<b>use</b> <a href="../suilend/lending_market.md#suilend_lending_market">suilend::lending_market</a>;
<b>use</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining">suilend::liquidity_mining</a>;
<b>use</b> <a href="../suilend/obligation.md#suilend_obligation">suilend::obligation</a>;
<b>use</b> <a href="../suilend/oracles.md#suilend_oracles">suilend::oracles</a>;
<b>use</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter">suilend::rate_limiter</a>;
<b>use</b> <a href="../suilend/reserve.md#suilend_reserve">suilend::reserve</a>;
<b>use</b> <a href="../suilend/reserve_config.md#suilend_reserve_config">suilend::reserve_config</a>;
<b>use</b> <a href="../suilend/staker.md#suilend_staker">suilend::staker</a>;
</code></pre>



<a name="suilend_lending_market_registry_Registry"></a>

## Struct `Registry`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_Registry">Registry</a> <b>has</b> key
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
<code>lending_markets: <a href="../dependencies/sui/table.md#sui_table_Table">sui::table::Table</a>&lt;<a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_lending_market_registry_LENDING_MARKET_2"></a>

## Struct `LENDING_MARKET_2`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_LENDING_MARKET_2">LENDING_MARKET_2</a>
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="suilend_lending_market_registry_EIncorrectVersion"></a>



<pre><code><b>const</b> <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_EIncorrectVersion">EIncorrectVersion</a>: u64 = 1;
</code></pre>



<a name="suilend_lending_market_registry_CURRENT_VERSION"></a>



<pre><code><b>const</b> <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_CURRENT_VERSION">CURRENT_VERSION</a>: u64 = 1;
</code></pre>



<a name="suilend_lending_market_registry_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_init">init</a>(ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_init">init</a>(ctx: &<b>mut</b> TxContext) {
    <b>let</b> registry = <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_Registry">Registry</a> {
        id: object::new(ctx),
        version: <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_CURRENT_VERSION">CURRENT_VERSION</a>,
        lending_markets: table::new(ctx),
    };
    transfer::share_object(registry);
}
</code></pre>



</details>

<a name="suilend_lending_market_registry_create_lending_market"></a>

## Function `create_lending_market`

Creates a new lending market and registers it.

This function allows anyone to create a new <code>LendingMarket</code> of a specific type <code>P</code>.
It ensures that a lending market for the given type <code>P</code> does not already exist in the
registry before creating a new one. The newly created lending market's ID is then
added to the registry.


<a name="@Arguments_1"></a>

### Arguments


* <code>registry</code> - A mutable reference to the <code><a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_Registry">Registry</a></code> object.


<a name="@Returns_2"></a>

### Returns


* <code>(LendingMarketOwnerCap&lt;P&gt;, LendingMarket&lt;P&gt;)</code> - A tuple containing the ownership
capability and the newly created <code>LendingMarket</code> object.


<a name="@Panics_3"></a>

### Panics


This function will panic if:
* The <code>registry</code> version is not <code><a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_CURRENT_VERSION">CURRENT_VERSION</a></code> (EIncorrectVersion).
* A lending market of type <code>P</code> already exists in the registry. This will cause an
abort from the underlying <code>table::add</code> call.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_create_lending_market">create_lending_market</a>&lt;P&gt;(registry: &<b>mut</b> <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_Registry">suilend::lending_market_registry::Registry</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../suilend/lending_market.md#suilend_lending_market_LendingMarketOwnerCap">suilend::lending_market::LendingMarketOwnerCap</a>&lt;P&gt;, <a href="../suilend/lending_market.md#suilend_lending_market_LendingMarket">suilend::lending_market::LendingMarket</a>&lt;P&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_create_lending_market">create_lending_market</a>&lt;P&gt;(
    registry: &<b>mut</b> <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_Registry">Registry</a>,
    ctx: &<b>mut</b> TxContext,
): (LendingMarketOwnerCap&lt;P&gt;, LendingMarket&lt;P&gt;) {
    <b>assert</b>!(registry.version == <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_CURRENT_VERSION">CURRENT_VERSION</a>, <a href="../suilend/lending_market_registry.md#suilend_lending_market_registry_EIncorrectVersion">EIncorrectVersion</a>);
    <b>let</b> (owner_cap, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>) = <a href="../suilend/lending_market.md#suilend_lending_market_create_lending_market">lending_market::create_lending_market</a>&lt;P&gt;(ctx);
    table::add(&<b>mut</b> registry.lending_markets, type_name::get&lt;P&gt;(), object::id(&<a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>));
    (owner_cap, <a href="../suilend/lending_market.md#suilend_lending_market">lending_market</a>)
}
</code></pre>



</details>
