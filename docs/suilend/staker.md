
<a name="suilend_staker"></a>

# Module `suilend::staker`

Stake unlent Sui.


-  [Struct `Staker`](#suilend_staker_Staker)
-  [Constants](#@Constants_0)
-  [Function `liabilities`](#suilend_staker_liabilities)
    -  [Arguments](#@Arguments_1)
    -  [Returns](#@Returns_2)
-  [Function `lst_balance`](#suilend_staker_lst_balance)
    -  [Arguments](#@Arguments_3)
    -  [Returns](#@Returns_4)
-  [Function `sui_balance`](#suilend_staker_sui_balance)
    -  [Arguments](#@Arguments_5)
    -  [Returns](#@Returns_6)
-  [Function `total_sui_supply`](#suilend_staker_total_sui_supply)
    -  [Arguments](#@Arguments_7)
    -  [Returns](#@Returns_8)
-  [Function `liquid_staking_info`](#suilend_staker_liquid_staking_info)
    -  [Arguments](#@Arguments_9)
    -  [Returns](#@Returns_10)
-  [Function `create_staker`](#suilend_staker_create_staker)
    -  [Arguments](#@Arguments_11)
    -  [Returns](#@Returns_12)
    -  [Panics](#@Panics_13)
-  [Function `deposit`](#suilend_staker_deposit)
    -  [Arguments](#@Arguments_14)
-  [Function `withdraw`](#suilend_staker_withdraw)
    -  [Arguments](#@Arguments_15)
    -  [Returns](#@Returns_16)
-  [Function `rebalance`](#suilend_staker_rebalance)
    -  [Arguments](#@Arguments_17)
-  [Function `claim_fees`](#suilend_staker_claim_fees)
    -  [Arguments](#@Arguments_18)
    -  [Returns](#@Returns_19)
    -  [Panics](#@Panics_20)
-  [Function `unstake_n_sui`](#suilend_staker_unstake_n_sui)


<pre><code><b>use</b> <a href="../dependencies/liquid_staking/cell.md#liquid_staking_cell">liquid_staking::cell</a>;
<b>use</b> <a href="../dependencies/liquid_staking/events.md#liquid_staking_events">liquid_staking::events</a>;
<b>use</b> <a href="../dependencies/liquid_staking/fees.md#liquid_staking_fees">liquid_staking::fees</a>;
<b>use</b> <a href="../dependencies/liquid_staking/liquid_staking.md#liquid_staking_liquid_staking">liquid_staking::liquid_staking</a>;
<b>use</b> <a href="../dependencies/liquid_staking/storage.md#liquid_staking_storage">liquid_staking::storage</a>;
<b>use</b> <a href="../dependencies/liquid_staking/version.md#liquid_staking_version">liquid_staking::version</a>;
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
</code></pre>



<a name="suilend_staker_Staker"></a>

## Struct `Staker`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/staker.md#suilend_staker_Staker">Staker</a>&lt;<b>phantom</b> P&gt; <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>admin: <a href="../dependencies/liquid_staking/liquid_staking.md#liquid_staking_liquid_staking_AdminCap">liquid_staking::liquid_staking::AdminCap</a>&lt;P&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>: <a href="../dependencies/liquid_staking/liquid_staking.md#liquid_staking_liquid_staking_LiquidStakingInfo">liquid_staking::liquid_staking::LiquidStakingInfo</a>&lt;P&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/staker.md#suilend_staker_lst_balance">lst_balance</a>: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;P&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/staker.md#suilend_staker_liabilities">liabilities</a>: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="suilend_staker_ETreasuryCapNonZeroSupply"></a>



<pre><code><b>const</b> <a href="../suilend/staker.md#suilend_staker_ETreasuryCapNonZeroSupply">ETreasuryCapNonZeroSupply</a>: u64 = 0;
</code></pre>



<a name="suilend_staker_EInvariantViolation"></a>



<pre><code><b>const</b> <a href="../suilend/staker.md#suilend_staker_EInvariantViolation">EInvariantViolation</a>: u64 = 1;
</code></pre>



<a name="suilend_staker_U64_MAX"></a>



<pre><code><b>const</b> <a href="../suilend/staker.md#suilend_staker_U64_MAX">U64_MAX</a>: u64 = 18446744073709551615;
</code></pre>



<a name="suilend_staker_SUILEND_VALIDATOR"></a>



<pre><code><b>const</b> <a href="../suilend/staker.md#suilend_staker_SUILEND_VALIDATOR">SUILEND_VALIDATOR</a>: <b>address</b> = 0xce8e537664ba5d1d5a6a857b17bd142097138706281882be6805e17065ecde89;
</code></pre>



<a name="suilend_staker_MIN_DEPLOY_AMOUNT"></a>



<pre><code><b>const</b> <a href="../suilend/staker.md#suilend_staker_MIN_DEPLOY_AMOUNT">MIN_DEPLOY_AMOUNT</a>: u64 = 1000000;
</code></pre>



<a name="suilend_staker_MIST_PER_SUI"></a>



<pre><code><b>const</b> <a href="../suilend/staker.md#suilend_staker_MIST_PER_SUI">MIST_PER_SUI</a>: u64 = 1000000000;
</code></pre>



<a name="suilend_staker_liabilities"></a>

## Function `liabilities`

Gets the total liabilities of the staker.


<a name="@Arguments_1"></a>

### Arguments


* <code><a href="../suilend/staker.md#suilend_staker">staker</a></code> - A reference to the <code><a href="../suilend/staker.md#suilend_staker_Staker">Staker</a></code> to query.


<a name="@Returns_2"></a>

### Returns


* <code>u64</code> - The total amount of SUI owed to the reserve.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_liabilities">liabilities</a>&lt;P&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<a href="../suilend/staker.md#suilend_staker_Staker">suilend::staker::Staker</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_liabilities">liabilities</a>&lt;P&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<a href="../suilend/staker.md#suilend_staker_Staker">Staker</a>&lt;P&gt;): u64 {
    <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liabilities">liabilities</a>
}
</code></pre>



</details>

<a name="suilend_staker_lst_balance"></a>

## Function `lst_balance`

Gets the balance of liquid staking tokens (LST).


<a name="@Arguments_3"></a>

### Arguments


* <code><a href="../suilend/staker.md#suilend_staker">staker</a></code> - A reference to the <code><a href="../suilend/staker.md#suilend_staker_Staker">Staker</a></code> to query.


<a name="@Returns_4"></a>

### Returns


* <code>&Balance&lt;P&gt;</code> - A reference to the LST balance.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_lst_balance">lst_balance</a>&lt;P&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<a href="../suilend/staker.md#suilend_staker_Staker">suilend::staker::Staker</a>&lt;P&gt;): &<a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;P&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_lst_balance">lst_balance</a>&lt;P&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<a href="../suilend/staker.md#suilend_staker_Staker">Staker</a>&lt;P&gt;): &Balance&lt;P&gt; {
    &<a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_lst_balance">lst_balance</a>
}
</code></pre>



</details>

<a name="suilend_staker_sui_balance"></a>

## Function `sui_balance`

Gets the balance of SUI held by the staker.


<a name="@Arguments_5"></a>

### Arguments


* <code><a href="../suilend/staker.md#suilend_staker">staker</a></code> - A reference to the <code><a href="../suilend/staker.md#suilend_staker_Staker">Staker</a></code> to query.


<a name="@Returns_6"></a>

### Returns


* <code>&Balance&lt;SUI&gt;</code> - A reference to the SUI balance.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>&lt;P&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<a href="../suilend/staker.md#suilend_staker_Staker">suilend::staker::Staker</a>&lt;P&gt;): &<a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>&lt;P&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<a href="../suilend/staker.md#suilend_staker_Staker">Staker</a>&lt;P&gt;): &Balance&lt;SUI&gt; {
    &<a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>
}
</code></pre>



</details>

<a name="suilend_staker_total_sui_supply"></a>

## Function `total_sui_supply`

Gets the total SUI supply, including staked and unstaked amounts.

Note: This value can be stale if the <code><a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a></code> has not been refreshed.


<a name="@Arguments_7"></a>

### Arguments


* <code><a href="../suilend/staker.md#suilend_staker">staker</a></code> - A reference to the <code><a href="../suilend/staker.md#suilend_staker_Staker">Staker</a></code> to query.


<a name="@Returns_8"></a>

### Returns


* <code>u64</code> - The total SUI supply, including both staked and unstaked SUI.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_total_sui_supply">total_sui_supply</a>&lt;P&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<a href="../suilend/staker.md#suilend_staker_Staker">suilend::staker::Staker</a>&lt;P&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_total_sui_supply">total_sui_supply</a>&lt;P&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<a href="../suilend/staker.md#suilend_staker_Staker">Staker</a>&lt;P&gt;): u64 {
    <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>.<a href="../suilend/staker.md#suilend_staker_total_sui_supply">total_sui_supply</a>() + <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>.value()
}
</code></pre>



</details>

<a name="suilend_staker_liquid_staking_info"></a>

## Function `liquid_staking_info`

Gets the liquid staking information.


<a name="@Arguments_9"></a>

### Arguments


* <code><a href="../suilend/staker.md#suilend_staker">staker</a></code> - A reference to the <code><a href="../suilend/staker.md#suilend_staker_Staker">Staker</a></code> to query.


<a name="@Returns_10"></a>

### Returns


* <code>&LiquidStakingInfo&lt;P&gt;</code> - A reference to the liquid staking information.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>&lt;P&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<a href="../suilend/staker.md#suilend_staker_Staker">suilend::staker::Staker</a>&lt;P&gt;): &<a href="../dependencies/liquid_staking/liquid_staking.md#liquid_staking_liquid_staking_LiquidStakingInfo">liquid_staking::liquid_staking::LiquidStakingInfo</a>&lt;P&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>&lt;P&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<a href="../suilend/staker.md#suilend_staker_Staker">Staker</a>&lt;P&gt;): &LiquidStakingInfo&lt;P&gt; {
    &<a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>
}
</code></pre>



</details>

<a name="suilend_staker_create_staker"></a>

## Function `create_staker`

Creates a new staker with the provided treasury cap.

Initializes a staker with a new liquid staking configuration and zero balances.


<a name="@Arguments_11"></a>

### Arguments


* <code>treasury_cap</code> - The treasury cap for the liquid staking token type.


<a name="@Returns_12"></a>

### Returns


* <code><a href="../suilend/staker.md#suilend_staker_Staker">Staker</a>&lt;P&gt;</code> - A new staker instance.


<a name="@Panics_13"></a>

### Panics


* If the treasury cap has a non-zero supply (<code><a href="../suilend/staker.md#suilend_staker_ETreasuryCapNonZeroSupply">ETreasuryCapNonZeroSupply</a></code>).


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_create_staker">create_staker</a>&lt;P: drop&gt;(treasury_cap: <a href="../dependencies/sui/coin.md#sui_coin_TreasuryCap">sui::coin::TreasuryCap</a>&lt;P&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../suilend/staker.md#suilend_staker_Staker">suilend::staker::Staker</a>&lt;P&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_create_staker">create_staker</a>&lt;P: drop&gt;(
    treasury_cap: TreasuryCap&lt;P&gt;,
    ctx: &<b>mut</b> TxContext,
): <a href="../suilend/staker.md#suilend_staker_Staker">Staker</a>&lt;P&gt; {
    <b>assert</b>!(coin::total_supply(&treasury_cap) == 0, <a href="../suilend/staker.md#suilend_staker_ETreasuryCapNonZeroSupply">ETreasuryCapNonZeroSupply</a>);
    <b>let</b> (admin_cap, <a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>) = liquid_staking::create_lst(
        fees::new_builder(ctx).to_fee_config(),
        treasury_cap,
        ctx,
    );
    <a href="../suilend/staker.md#suilend_staker_Staker">Staker</a> {
        admin: admin_cap,
        <a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>,
        <a href="../suilend/staker.md#suilend_staker_lst_balance">lst_balance</a>: balance::zero(),
        <a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>: balance::zero(),
        <a href="../suilend/staker.md#suilend_staker_liabilities">liabilities</a>: 0,
    }
}
</code></pre>



</details>

<a name="suilend_staker_deposit"></a>

## Function `deposit`

Deposits SUI into the staker.

Increases the staker's SUI balance and liabilities.


<a name="@Arguments_14"></a>

### Arguments


* <code><a href="../suilend/staker.md#suilend_staker">staker</a></code> - A mutable reference to the <code><a href="../suilend/staker.md#suilend_staker_Staker">Staker</a></code> to modify.
* <code>sui</code> - The SUI balance to deposit.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_deposit">deposit</a>&lt;P&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<b>mut</b> <a href="../suilend/staker.md#suilend_staker_Staker">suilend::staker::Staker</a>&lt;P&gt;, sui: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_deposit">deposit</a>&lt;P&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<b>mut</b> <a href="../suilend/staker.md#suilend_staker_Staker">Staker</a>&lt;P&gt;, sui: Balance&lt;SUI&gt;) {
    <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liabilities">liabilities</a> = <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liabilities">liabilities</a> + sui.value();
    <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>.join(sui);
}
</code></pre>



</details>

<a name="suilend_staker_withdraw"></a>

## Function `withdraw`

Withdraws SUI from the staker.

Unstakes SUI if necessary to fulfill the withdrawal request and updates liabilities.


<a name="@Arguments_15"></a>

### Arguments


* <code><a href="../suilend/staker.md#suilend_staker">staker</a></code> - A mutable reference to the <code><a href="../suilend/staker.md#suilend_staker_Staker">Staker</a></code> to modify.
* <code>withdraw_amount</code> - The amount of SUI to withdraw.
* <code>system_state</code> - A mutable reference to the <code>SuiSystemState</code> for staking operations.


<a name="@Returns_16"></a>

### Returns


* <code>Balance&lt;SUI&gt;</code> - The withdrawn SUI balance.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_withdraw">withdraw</a>&lt;P: drop&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<b>mut</b> <a href="../suilend/staker.md#suilend_staker_Staker">suilend::staker::Staker</a>&lt;P&gt;, withdraw_amount: u64, system_state: &<b>mut</b> <a href="../dependencies/sui_system/sui_system.md#sui_system_sui_system_SuiSystemState">sui_system::sui_system::SuiSystemState</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_withdraw">withdraw</a>&lt;P: drop&gt;(
    <a href="../suilend/staker.md#suilend_staker">staker</a>: &<b>mut</b> <a href="../suilend/staker.md#suilend_staker_Staker">Staker</a>&lt;P&gt;,
    withdraw_amount: u64,
    system_state: &<b>mut</b> SuiSystemState,
    ctx: &<b>mut</b> TxContext,
): Balance&lt;SUI&gt; {
    <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>.refresh(system_state, ctx);
    <b>if</b> (withdraw_amount &gt; <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>.value()) {
        <b>let</b> unstake_amount = withdraw_amount - <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>.value();
        <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_unstake_n_sui">unstake_n_sui</a>(system_state, unstake_amount, ctx);
    };
    <b>let</b> sui = <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>.split(withdraw_amount);
    <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liabilities">liabilities</a> = <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liabilities">liabilities</a> - sui.value();
    sui
}
</code></pre>



</details>

<a name="suilend_staker_rebalance"></a>

## Function `rebalance`

Rebalances the staker by staking available SUI.

Converts available SUI to liquid staking tokens (LST) and increases validator stake.


<a name="@Arguments_17"></a>

### Arguments


* <code><a href="../suilend/staker.md#suilend_staker">staker</a></code> - A mutable reference to the <code><a href="../suilend/staker.md#suilend_staker_Staker">Staker</a></code> to modify.
* <code>system_state</code> - A mutable reference to the <code>SuiSystemState</code> for staking operations.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_rebalance">rebalance</a>&lt;P: drop&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<b>mut</b> <a href="../suilend/staker.md#suilend_staker_Staker">suilend::staker::Staker</a>&lt;P&gt;, system_state: &<b>mut</b> <a href="../dependencies/sui_system/sui_system.md#sui_system_sui_system_SuiSystemState">sui_system::sui_system::SuiSystemState</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_rebalance">rebalance</a>&lt;P: drop&gt;(
    <a href="../suilend/staker.md#suilend_staker">staker</a>: &<b>mut</b> <a href="../suilend/staker.md#suilend_staker_Staker">Staker</a>&lt;P&gt;,
    system_state: &<b>mut</b> SuiSystemState,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>.refresh(system_state, ctx);
    <b>if</b> (<a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>.value() &lt; <a href="../suilend/staker.md#suilend_staker_MIN_DEPLOY_AMOUNT">MIN_DEPLOY_AMOUNT</a>) {
        <b>return</b>
    };
    <b>let</b> sui = <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>.withdraw_all();
    <b>let</b> lst = <a href="../suilend/staker.md#suilend_staker">staker</a>
        .<a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>
        .mint(
            system_state,
            coin::from_balance(sui, ctx),
            ctx,
        );
    <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_lst_balance">lst_balance</a>.join(lst.into_balance());
    <a href="../suilend/staker.md#suilend_staker">staker</a>
        .<a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>
        .increase_validator_stake(
            &<a href="../suilend/staker.md#suilend_staker">staker</a>.admin,
            system_state,
            <a href="../suilend/staker.md#suilend_staker_SUILEND_VALIDATOR">SUILEND_VALIDATOR</a>,
            <a href="../suilend/staker.md#suilend_staker_U64_MAX">U64_MAX</a>,
            ctx,
        );
}
</code></pre>



</details>

<a name="suilend_staker_claim_fees"></a>

## Function `claim_fees`

Claims excess SUI as fees from the staker.

Withdraws any SUI in excess of liabilities plus a buffer, unstaking if necessary.


<a name="@Arguments_18"></a>

### Arguments


* <code><a href="../suilend/staker.md#suilend_staker">staker</a></code> - A mutable reference to the <code><a href="../suilend/staker.md#suilend_staker_Staker">Staker</a></code> to modify.
* <code>system_state</code> - A mutable reference to the <code>SuiSystemState</code> for staking operations.


<a name="@Returns_19"></a>

### Returns


* <code>Balance&lt;SUI&gt;</code> - The claimed SUI fees.


<a name="@Panics_20"></a>

### Panics


* If the total SUI supply is less than the liabilities after claiming (<code><a href="../suilend/staker.md#suilend_staker_EInvariantViolation">EInvariantViolation</a></code>).


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_claim_fees">claim_fees</a>&lt;P: drop&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<b>mut</b> <a href="../suilend/staker.md#suilend_staker_Staker">suilend::staker::Staker</a>&lt;P&gt;, system_state: &<b>mut</b> <a href="../dependencies/sui_system/sui_system.md#sui_system_sui_system_SuiSystemState">sui_system::sui_system::SuiSystemState</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/staker.md#suilend_staker_claim_fees">claim_fees</a>&lt;P: drop&gt;(
    <a href="../suilend/staker.md#suilend_staker">staker</a>: &<b>mut</b> <a href="../suilend/staker.md#suilend_staker_Staker">Staker</a>&lt;P&gt;,
    system_state: &<b>mut</b> SuiSystemState,
    ctx: &<b>mut</b> TxContext,
): Balance&lt;SUI&gt; {
    <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>.refresh(system_state, ctx);
    <b>let</b> <a href="../suilend/staker.md#suilend_staker_total_sui_supply">total_sui_supply</a> = <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_total_sui_supply">total_sui_supply</a>();
    // leave 1 SUI extra, just in case
    <b>let</b> excess_sui = <b>if</b> (<a href="../suilend/staker.md#suilend_staker_total_sui_supply">total_sui_supply</a> &gt; <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liabilities">liabilities</a> + <a href="../suilend/staker.md#suilend_staker_MIST_PER_SUI">MIST_PER_SUI</a>) {
        <a href="../suilend/staker.md#suilend_staker_total_sui_supply">total_sui_supply</a> - <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liabilities">liabilities</a> - <a href="../suilend/staker.md#suilend_staker_MIST_PER_SUI">MIST_PER_SUI</a>
    } <b>else</b> {
        0
    };
    <b>if</b> (excess_sui &gt; <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>.value()) {
        <b>let</b> unstake_amount = excess_sui - <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>.value();
        <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_unstake_n_sui">unstake_n_sui</a>(system_state, unstake_amount, ctx);
    };
    <b>let</b> sui = <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>.split(excess_sui);
    <b>assert</b>!(<a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_total_sui_supply">total_sui_supply</a>() &gt;= <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liabilities">liabilities</a>, <a href="../suilend/staker.md#suilend_staker_EInvariantViolation">EInvariantViolation</a>);
    sui
}
</code></pre>



</details>

<a name="suilend_staker_unstake_n_sui"></a>

## Function `unstake_n_sui`



<pre><code><b>fun</b> <a href="../suilend/staker.md#suilend_staker_unstake_n_sui">unstake_n_sui</a>&lt;P: drop&gt;(<a href="../suilend/staker.md#suilend_staker">staker</a>: &<b>mut</b> <a href="../suilend/staker.md#suilend_staker_Staker">suilend::staker::Staker</a>&lt;P&gt;, system_state: &<b>mut</b> <a href="../dependencies/sui_system/sui_system.md#sui_system_sui_system_SuiSystemState">sui_system::sui_system::SuiSystemState</a>, sui_amount_out: u64, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/staker.md#suilend_staker_unstake_n_sui">unstake_n_sui</a>&lt;P: drop&gt;(
    <a href="../suilend/staker.md#suilend_staker">staker</a>: &<b>mut</b> <a href="../suilend/staker.md#suilend_staker_Staker">Staker</a>&lt;P&gt;,
    system_state: &<b>mut</b> SuiSystemState,
    sui_amount_out: u64,
    ctx: &<b>mut</b> TxContext,
) {
    <b>if</b> (sui_amount_out == 0) {
        <b>return</b>
    };
    <b>let</b> <a href="../suilend/staker.md#suilend_staker_total_sui_supply">total_sui_supply</a> = (<a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>.<a href="../suilend/staker.md#suilend_staker_total_sui_supply">total_sui_supply</a>() <b>as</b> u128);
    <b>let</b> total_lst_supply = (<a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>.total_lst_supply() <b>as</b> u128);
    // ceil lst redemption amount
    <b>let</b> lst_to_redeem =
        ((sui_amount_out <b>as</b> u128) * total_lst_supply + <a href="../suilend/staker.md#suilend_staker_total_sui_supply">total_sui_supply</a> - 1) / <a href="../suilend/staker.md#suilend_staker_total_sui_supply">total_sui_supply</a>;
    <b>let</b> lst = balance::split(&<b>mut</b> <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_lst_balance">lst_balance</a>, (lst_to_redeem <b>as</b> u64));
    <b>let</b> sui = liquid_staking::redeem(
        &<b>mut</b> <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_liquid_staking_info">liquid_staking_info</a>,
        coin::from_balance(lst, ctx),
        system_state,
        ctx,
    );
    <a href="../suilend/staker.md#suilend_staker">staker</a>.<a href="../suilend/staker.md#suilend_staker_sui_balance">sui_balance</a>.join(sui.into_balance());
}
</code></pre>



</details>
