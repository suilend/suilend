
<a name="suilend_liquidity_mining"></a>

# Module `suilend::liquidity_mining`

A user_reward_manager farms pool_rewards to receive rewards proportional to their stake in the pool.


-  [Struct `PoolRewardManager`](#suilend_liquidity_mining_PoolRewardManager)
-  [Struct `PoolReward`](#suilend_liquidity_mining_PoolReward)
-  [Struct `RewardBalance`](#suilend_liquidity_mining_RewardBalance)
-  [Struct `UserRewardManager`](#suilend_liquidity_mining_UserRewardManager)
-  [Struct `UserReward`](#suilend_liquidity_mining_UserReward)
-  [Constants](#@Constants_0)
-  [Function `pool_reward_manager_id`](#suilend_liquidity_mining_pool_reward_manager_id)
-  [Function `shares`](#suilend_liquidity_mining_shares)
-  [Function `last_update_time_ms`](#suilend_liquidity_mining_last_update_time_ms)
-  [Function `pool_reward_id`](#suilend_liquidity_mining_pool_reward_id)
-  [Function `pool_reward`](#suilend_liquidity_mining_pool_reward)
-  [Function `end_time_ms`](#suilend_liquidity_mining_end_time_ms)
-  [Function `new_pool_reward_manager`](#suilend_liquidity_mining_new_pool_reward_manager)
    -  [Returns](#@Returns_1)
-  [Function `add_pool_reward`](#suilend_liquidity_mining_add_pool_reward)
    -  [Arguments](#@Arguments_2)
    -  [Panics](#@Panics_3)
-  [Function `close_pool_reward`](#suilend_liquidity_mining_close_pool_reward)
    -  [Arguments](#@Arguments_4)
    -  [Returns](#@Returns_5)
    -  [Panics](#@Panics_6)
-  [Function `cancel_pool_reward`](#suilend_liquidity_mining_cancel_pool_reward)
    -  [Arguments](#@Arguments_7)
    -  [Returns](#@Returns_8)
-  [Function `update_pool_reward_manager`](#suilend_liquidity_mining_update_pool_reward_manager)
    -  [Arguments](#@Arguments_9)
-  [Function `update_user_reward_manager`](#suilend_liquidity_mining_update_user_reward_manager)
    -  [Arguments](#@Arguments_10)
    -  [Panics](#@Panics_11)
-  [Function `new_user_reward_manager`](#suilend_liquidity_mining_new_user_reward_manager)
    -  [Arguments](#@Arguments_12)
    -  [Returns](#@Returns_13)
-  [Function `change_user_reward_manager_share`](#suilend_liquidity_mining_change_user_reward_manager_share)
    -  [Arguments](#@Arguments_14)
-  [Function `claim_rewards`](#suilend_liquidity_mining_claim_rewards)
    -  [Arguments](#@Arguments_15)
    -  [Returns](#@Returns_16)
    -  [Panics](#@Panics_17)
-  [Function `find_available_index`](#suilend_liquidity_mining_find_available_index)
    -  [Arguments](#@Arguments_18)
    -  [Returns](#@Returns_19)


<pre><code><b>use</b> <a href="../dependencies/std/address.md#std_address">std::address</a>;
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
<b>use</b> <a href="../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../suilend/decimal.md#suilend_decimal">suilend::decimal</a>;
</code></pre>



<a name="suilend_liquidity_mining_PoolRewardManager"></a>

## Struct `PoolRewardManager`

This struct manages all pool_rewards for a given stake pool.


<pre><code><b>public</b> <b>struct</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a> <b>has</b> key, store
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
<code>total_shares: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>pool_rewards: vector&lt;<a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolReward">suilend::liquidity_mining::PoolReward</a>&gt;&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a>: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_liquidity_mining_PoolReward"></a>

## Struct `PoolReward`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolReward">PoolReward</a> <b>has</b> key, store
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
<code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_manager_id">pool_reward_manager_id</a>: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>coin_type: <a href="../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>start_time_ms: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>total_rewards: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>allocated_rewards: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 amount of rewards that have been earned by users
</dd>
<dt>
<code>cumulative_rewards_per_share: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>num_user_reward_managers: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>additional_fields: <a href="../dependencies/sui/bag.md#sui_bag_Bag">sui::bag::Bag</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_liquidity_mining_RewardBalance"></a>

## Struct `RewardBalance`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_RewardBalance">RewardBalance</a>&lt;<b>phantom</b> T&gt; <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="suilend_liquidity_mining_UserRewardManager"></a>

## Struct `UserRewardManager`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_manager_id">pool_reward_manager_id</a>: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>share: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>rewards: vector&lt;<a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserReward">suilend::liquidity_mining::UserReward</a>&gt;&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a>: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_liquidity_mining_UserReward"></a>

## Struct `UserReward`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserReward">UserReward</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_id">pool_reward_id</a>: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>earned_rewards: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
<dt>
<code>cumulative_rewards_per_share: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="suilend_liquidity_mining_EIdMismatch"></a>



<pre><code><b>const</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_EIdMismatch">EIdMismatch</a>: u64 = 0;
</code></pre>



<a name="suilend_liquidity_mining_EInvalidTime"></a>



<pre><code><b>const</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_EInvalidTime">EInvalidTime</a>: u64 = 1;
</code></pre>



<a name="suilend_liquidity_mining_EInvalidType"></a>



<pre><code><b>const</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_EInvalidType">EInvalidType</a>: u64 = 2;
</code></pre>



<a name="suilend_liquidity_mining_EMaxConcurrentPoolRewardsViolated"></a>



<pre><code><b>const</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_EMaxConcurrentPoolRewardsViolated">EMaxConcurrentPoolRewardsViolated</a>: u64 = 3;
</code></pre>



<a name="suilend_liquidity_mining_ENotAllRewardsClaimed"></a>



<pre><code><b>const</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_ENotAllRewardsClaimed">ENotAllRewardsClaimed</a>: u64 = 4;
</code></pre>



<a name="suilend_liquidity_mining_EPoolRewardPeriodNotOver"></a>



<pre><code><b>const</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_EPoolRewardPeriodNotOver">EPoolRewardPeriodNotOver</a>: u64 = 5;
</code></pre>



<a name="suilend_liquidity_mining_MAX_REWARDS"></a>



<pre><code><b>const</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_MAX_REWARDS">MAX_REWARDS</a>: u64 = 50;
</code></pre>



<a name="suilend_liquidity_mining_MIN_REWARD_PERIOD_MS"></a>



<pre><code><b>const</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_MIN_REWARD_PERIOD_MS">MIN_REWARD_PERIOD_MS</a>: u64 = 3600000;
</code></pre>



<a name="suilend_liquidity_mining_pool_reward_manager_id"></a>

## Function `pool_reward_manager_id`

Retrieves the ID of the pool reward manager associated with a user reward manager.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_manager_id">pool_reward_manager_id</a>(user_reward_manager: &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">suilend::liquidity_mining::UserRewardManager</a>): <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_manager_id">pool_reward_manager_id</a>(user_reward_manager: &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a>): ID {
    user_reward_manager.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_manager_id">pool_reward_manager_id</a>
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_shares"></a>

## Function `shares`

Retrieves the share amount of a user reward manager.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_shares">shares</a>(user_reward_manager: &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">suilend::liquidity_mining::UserRewardManager</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_shares">shares</a>(user_reward_manager: &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a>): u64 {
    user_reward_manager.share
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_last_update_time_ms"></a>

## Function `last_update_time_ms`

Retrieves the last update time in milliseconds for a user reward manager.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a>(user_reward_manager: &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">suilend::liquidity_mining::UserRewardManager</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a>(user_reward_manager: &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a>): u64 {
    user_reward_manager.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a>
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_pool_reward_id"></a>

## Function `pool_reward_id`

Retrieves the ID of a pool reward at a specified index in the pool reward manager.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_id">pool_reward_id</a>(pool_reward_manager: &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>, index: u64): <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_id">pool_reward_id</a>(pool_reward_manager: &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a>, index: u64): ID {
    <b>let</b> optional_pool_reward = vector::borrow(&pool_reward_manager.pool_rewards, index);
    <b>let</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a> = option::borrow(optional_pool_reward);
    object::id(<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>)
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_pool_reward"></a>

## Function `pool_reward`

Retrieves a reference to a pool reward option at a specified index in the pool reward manager.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>(pool_reward_manager: &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>, index: u64): &<a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolReward">suilend::liquidity_mining::PoolReward</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>(
    pool_reward_manager: &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a>,
    index: u64,
): &Option&lt;<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolReward">PoolReward</a>&gt; {
    vector::borrow(&pool_reward_manager.pool_rewards, index)
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_end_time_ms"></a>

## Function `end_time_ms`

Retrieves the end time in milliseconds of a pool reward.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a>(<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>: &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolReward">suilend::liquidity_mining::PoolReward</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a>(<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>: &<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolReward">PoolReward</a>): u64 {
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a>
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_new_pool_reward_manager"></a>

## Function `new_pool_reward_manager`

Creates a new pool reward manager with an empty rewards vector and zero shares.


<a name="@Returns_1"></a>

### Returns


* <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a></code> - A new <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a></code> instance.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_new_pool_reward_manager">new_pool_reward_manager</a>(ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_new_pool_reward_manager">new_pool_reward_manager</a>(ctx: &<b>mut</b> TxContext): <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a> {
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a> {
        id: object::new(ctx),
        total_shares: 0,
        pool_rewards: vector::empty(),
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a>: 0,
    }
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_add_pool_reward"></a>

## Function `add_pool_reward`

Adds a new pool reward to the pool reward manager with the specified parameters.

The function ensures the reward period is valid and adds the reward to an available index
in the <code>pool_rewards</code> vector. The reward is stored with its associated balance in a <code>Bag</code>.


<a name="@Arguments_2"></a>

### Arguments


* <code>pool_reward_manager</code> - A mutable reference to the <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a></code> to modify.
* <code>rewards</code> - The <code>Balance&lt;T&gt;</code> containing the reward amount.
* <code>start_time_ms</code> - The start time (in milliseconds) of the reward period.
* <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a></code> - The end time (in milliseconds) of the reward period.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based validation.


<a name="@Panics_3"></a>

### Panics


* If the reward period is less than <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_MIN_REWARD_PERIOD_MS">MIN_REWARD_PERIOD_MS</a></code>.
* If the maximum number of concurrent pool rewards (<code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_MAX_REWARDS">MAX_REWARDS</a></code>) is exceeded.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_add_pool_reward">add_pool_reward</a>&lt;T&gt;(pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>, rewards: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;, start_time_ms: u64, <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a>: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_add_pool_reward">add_pool_reward</a>&lt;T&gt;(
    pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a>,
    rewards: Balance&lt;T&gt;,
    start_time_ms: u64,
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a>: u64,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
) {
    <b>let</b> start_time_ms = <a href="../dependencies/std/u64.md#std_u64_max">std::u64::max</a>(start_time_ms, clock::timestamp_ms(clock));
    <b>assert</b>!(<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a> - start_time_ms &gt;= <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_MIN_REWARD_PERIOD_MS">MIN_REWARD_PERIOD_MS</a>, <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_EInvalidTime">EInvalidTime</a>);
    <b>let</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a> = <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolReward">PoolReward</a> {
        id: object::new(ctx),
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_manager_id">pool_reward_manager_id</a>: object::id(pool_reward_manager),
        coin_type: type_name::get&lt;T&gt;(),
        start_time_ms,
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a>,
        total_rewards: balance::value(&rewards),
        allocated_rewards: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        cumulative_rewards_per_share: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        num_user_reward_managers: 0,
        additional_fields: {
            <b>let</b> <b>mut</b> bag = bag::new(ctx);
            bag::add(&<b>mut</b> bag, <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_RewardBalance">RewardBalance</a>&lt;T&gt; {}, rewards);
            bag
        },
    };
    <b>let</b> i = <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_find_available_index">find_available_index</a>(pool_reward_manager);
    <b>assert</b>!(i &lt; <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_MAX_REWARDS">MAX_REWARDS</a>, <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_EMaxConcurrentPoolRewardsViolated">EMaxConcurrentPoolRewardsViolated</a>);
    <b>let</b> optional_pool_reward = vector::borrow_mut(&<b>mut</b> pool_reward_manager.pool_rewards, i);
    option::fill(optional_pool_reward, <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>);
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_close_pool_reward"></a>

## Function `close_pool_reward`

Closes a pool reward campaign, claims remaining rewards, and destroys the pool reward object.

This function can only be called after the reward period has ended and all user rewards
have been claimed. It extracts and returns any remaining reward balance.


<a name="@Arguments_4"></a>

### Arguments


* <code>pool_reward_manager</code> - A mutable reference to the <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a></code> to modify.
* <code>index</code> - The index of the pool reward to close.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp validation.


<a name="@Returns_5"></a>

### Returns


* <code>Balance&lt;T&gt;</code> - The remaining reward balance from the closed pool reward.


<a name="@Panics_6"></a>

### Panics


* If the current time is before the pool reward's end time.
* If there are still user reward managers associated with the pool reward.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_close_pool_reward">close_pool_reward</a>&lt;T&gt;(pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>, index: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_close_pool_reward">close_pool_reward</a>&lt;T&gt;(
    pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a>,
    index: u64,
    clock: &Clock,
): Balance&lt;T&gt; {
    <b>let</b> optional_pool_reward = vector::borrow_mut(&<b>mut</b> pool_reward_manager.pool_rewards, index);
    <b>let</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolReward">PoolReward</a> {
        id,
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_manager_id">pool_reward_manager_id</a>: _,
        coin_type: _,
        start_time_ms: _,
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a>,
        total_rewards: _,
        allocated_rewards: _,
        cumulative_rewards_per_share: _,
        num_user_reward_managers,
        <b>mut</b> additional_fields,
    } = option::extract(optional_pool_reward);
    object::delete(id);
    <b>let</b> cur_time_ms = clock::timestamp_ms(clock);
    <b>assert</b>!(cur_time_ms &gt;= <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a>, <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_EPoolRewardPeriodNotOver">EPoolRewardPeriodNotOver</a>);
    <b>assert</b>!(num_user_reward_managers == 0, <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_ENotAllRewardsClaimed">ENotAllRewardsClaimed</a>);
    <b>let</b> reward_balance: Balance&lt;T&gt; = bag::remove(
        &<b>mut</b> additional_fields,
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_RewardBalance">RewardBalance</a>&lt;T&gt; {},
    );
    bag::destroy_empty(additional_fields);
    reward_balance
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_cancel_pool_reward"></a>

## Function `cancel_pool_reward`

Cancels a pool reward campaign, claims unallocated rewards, and sets the end time to the current time.

The function updates the pool reward manager, calculates unallocated rewards, and returns
them as a balance. The pool reward's total rewards are set to zero.


<a name="@Arguments_7"></a>

### Arguments


* <code>pool_reward_manager</code> - A mutable reference to the <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a></code> to modify.
* <code>index</code> - The index of the pool reward to cancel.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based calculations.


<a name="@Returns_8"></a>

### Returns


* <code>Balance&lt;T&gt;</code> - The unallocated rewards from the canceled pool reward.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_cancel_pool_reward">cancel_pool_reward</a>&lt;T&gt;(pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>, index: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_cancel_pool_reward">cancel_pool_reward</a>&lt;T&gt;(
    pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a>,
    index: u64,
    clock: &Clock,
): Balance&lt;T&gt; {
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_update_pool_reward_manager">update_pool_reward_manager</a>(pool_reward_manager, clock);
    <b>let</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a> = option::borrow_mut(
        vector::borrow_mut(&<b>mut</b> pool_reward_manager.pool_rewards, index),
    );
    <b>let</b> cur_time_ms = clock::timestamp_ms(clock);
    <b>let</b> unallocated_rewards = floor(
        sub(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.total_rewards),
            <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.allocated_rewards,
        ),
    );
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a> = cur_time_ms;
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.total_rewards = 0;
    <b>let</b> reward_balance: &<b>mut</b> Balance&lt;T&gt; = bag::borrow_mut(
        &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.additional_fields,
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_RewardBalance">RewardBalance</a>&lt;T&gt; {},
    );
    balance::split(reward_balance, unallocated_rewards)
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_update_pool_reward_manager"></a>

## Function `update_pool_reward_manager`

Updates the pool reward manager's state based on the current time and reward schedules.

This function calculates unlocked rewards for each active pool reward based on the time
elapsed since the last update and updates the cumulative rewards per share.


<a name="@Arguments_9"></a>

### Arguments


* <code>pool_reward_manager</code> - A mutable reference to the <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a></code> to update.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based calculations.


<pre><code><b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_update_pool_reward_manager">update_pool_reward_manager</a>(pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_update_pool_reward_manager">update_pool_reward_manager</a>(pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a>, clock: &Clock) {
    <b>let</b> cur_time_ms = clock::timestamp_ms(clock);
    <b>if</b> (cur_time_ms == pool_reward_manager.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a>) {
        <b>return</b>
    };
    <b>if</b> (pool_reward_manager.total_shares == 0) {
        pool_reward_manager.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a> = cur_time_ms;
        <b>return</b>
    };
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; vector::length(&pool_reward_manager.pool_rewards)) {
        <b>let</b> optional_pool_reward = vector::borrow_mut(&<b>mut</b> pool_reward_manager.pool_rewards, i);
        <b>if</b> (option::is_none(optional_pool_reward)) {
            i = i + 1;
            <b>continue</b>
        };
        <b>let</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a> = option::borrow_mut(optional_pool_reward);
        <b>if</b> (
            cur_time_ms &lt; <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.start_time_ms ||
            pool_reward_manager.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a> &gt;= <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a>
        ) {
            i = i + 1;
            <b>continue</b>
        };
        <b>let</b> time_passed_ms =
            <a href="../dependencies/std/u64.md#std_u64_min">std::u64::min</a>(cur_time_ms, <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a>) -
            <a href="../dependencies/std/u64.md#std_u64_max">std::u64::max</a>(<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.start_time_ms, pool_reward_manager.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a>);
        <b>let</b> unlocked_rewards = div(
            mul(
                <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.total_rewards),
                <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(time_passed_ms),
            ),
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a> - <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.start_time_ms),
        );
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.allocated_rewards = add(<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.allocated_rewards, unlocked_rewards);
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.cumulative_rewards_per_share =
            add(
                <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.cumulative_rewards_per_share,
                div(
                    unlocked_rewards,
                    <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(pool_reward_manager.total_shares),
                ),
            );
        i = i + 1;
    };
    pool_reward_manager.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a> = cur_time_ms;
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_update_user_reward_manager"></a>

## Function `update_user_reward_manager`

Updates a user reward manager's state, synchronizing rewards with the pool reward manager.

This function ensures the user reward manager's rewards vector is aligned with the pool
reward manager's rewards and calculates any new rewards earned based on the user's share.


<a name="@Arguments_10"></a>

### Arguments


* <code>pool_reward_manager</code> - A mutable reference to the <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a></code> to synchronize with.
* <code>user_reward_manager</code> - A mutable reference to the <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a></code> to update.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based calculations.
* <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_new_user_reward_manager">new_user_reward_manager</a></code> - A boolean indicating if this is a new user reward manager.


<a name="@Panics_11"></a>

### Panics


* If the <code>pool_reward_manager</code> ID does not match the <code>user_reward_manager</code>'s ID.


<pre><code><b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_update_user_reward_manager">update_user_reward_manager</a>(pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>, user_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">suilend::liquidity_mining::UserRewardManager</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_new_user_reward_manager">new_user_reward_manager</a>: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_update_user_reward_manager">update_user_reward_manager</a>(
    pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a>,
    user_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a>,
    clock: &Clock,
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_new_user_reward_manager">new_user_reward_manager</a>: bool,
) {
    <b>assert</b>!(
        object::id(pool_reward_manager) == user_reward_manager.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_manager_id">pool_reward_manager_id</a>,
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_EIdMismatch">EIdMismatch</a>,
    );
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_update_pool_reward_manager">update_pool_reward_manager</a>(pool_reward_manager, clock);
    <b>let</b> cur_time_ms = clock::timestamp_ms(clock);
    <b>if</b> (!<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_new_user_reward_manager">new_user_reward_manager</a> && cur_time_ms == user_reward_manager.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a>) {
        <b>return</b>
    };
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; vector::length(&pool_reward_manager.pool_rewards)) {
        <b>let</b> optional_pool_reward = vector::borrow_mut(&<b>mut</b> pool_reward_manager.pool_rewards, i);
        <b>if</b> (option::is_none(optional_pool_reward)) {
            i = i + 1;
            <b>continue</b>
        };
        <b>let</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a> = option::borrow_mut(optional_pool_reward);
        <b>while</b> (vector::length(&user_reward_manager.rewards) &lt;= i) {
            vector::push_back(&<b>mut</b> user_reward_manager.rewards, option::none());
        };
        <b>let</b> optional_reward = vector::borrow_mut(&<b>mut</b> user_reward_manager.rewards, i);
        <b>if</b> (option::is_none(optional_reward)) {
            <b>if</b> (user_reward_manager.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a> &lt;= <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a>) {
                option::fill(
                    optional_reward,
                    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserReward">UserReward</a> {
                        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_id">pool_reward_id</a>: object::id(<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>),
                        earned_rewards: {
                            <b>if</b> (
                                user_reward_manager.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a> &lt;= <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.start_time_ms
                            ) {
                                mul(
                                    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.cumulative_rewards_per_share,
                                    <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(user_reward_manager.share),
                                )
                            } <b>else</b> {
                                <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0)
                            }
                        },
                        cumulative_rewards_per_share: <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.cumulative_rewards_per_share,
                    },
                );
                <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.num_user_reward_managers = <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.num_user_reward_managers + 1;
            };
        } <b>else</b> {
            <b>let</b> reward = option::borrow_mut(optional_reward);
            <b>let</b> new_rewards = mul(
                sub(
                    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.cumulative_rewards_per_share,
                    reward.cumulative_rewards_per_share,
                ),
                <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(user_reward_manager.share),
            );
            reward.earned_rewards = add(reward.earned_rewards, new_rewards);
            reward.cumulative_rewards_per_share = <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.cumulative_rewards_per_share;
        };
        i = i + 1;
    };
    user_reward_manager.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a> = cur_time_ms;
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_new_user_reward_manager"></a>

## Function `new_user_reward_manager`

Creates a new user reward manager with zero share and initializes its rewards vector.

The function synchronizes the new user reward manager with the pool reward manager to
populate the rewards vector.


<a name="@Arguments_12"></a>

### Arguments


* <code>pool_reward_manager</code> - A mutable reference to the <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a></code> to associate with.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based initialization.


<a name="@Returns_13"></a>

### Returns


* <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a></code> - A new <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a></code> instance.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_new_user_reward_manager">new_user_reward_manager</a>(pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">suilend::liquidity_mining::UserRewardManager</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_new_user_reward_manager">new_user_reward_manager</a>(
    pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a>,
    clock: &Clock,
): <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a> {
    <b>let</b> <b>mut</b> user_reward_manager = <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a> {
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_manager_id">pool_reward_manager_id</a>: object::id(pool_reward_manager),
        share: 0,
        rewards: vector::empty(),
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_last_update_time_ms">last_update_time_ms</a>: clock::timestamp_ms(clock),
    };
    // needed to populate the rewards vector
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_update_user_reward_manager">update_user_reward_manager</a>(pool_reward_manager, &<b>mut</b> user_reward_manager, clock, <b>true</b>);
    user_reward_manager
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_change_user_reward_manager_share"></a>

## Function `change_user_reward_manager_share`

Updates the share amount for a user reward manager and adjusts the total shares in the pool.

The function first updates the user reward manager's state and then adjusts the share
amounts in both the user and pool reward managers.


<a name="@Arguments_14"></a>

### Arguments


* <code>pool_reward_manager</code> - A mutable reference to the <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a></code> to update.
* <code>user_reward_manager</code> - A mutable reference to the <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a></code> to update.
* <code>new_share</code> - The new share amount for the user reward manager.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based updates.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_change_user_reward_manager_share">change_user_reward_manager_share</a>(pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>, user_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">suilend::liquidity_mining::UserRewardManager</a>, new_share: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_change_user_reward_manager_share">change_user_reward_manager_share</a>(
    pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a>,
    user_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a>,
    new_share: u64,
    clock: &Clock,
) {
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_update_user_reward_manager">update_user_reward_manager</a>(pool_reward_manager, user_reward_manager, clock, <b>false</b>);
    pool_reward_manager.total_shares =
        pool_reward_manager.total_shares - user_reward_manager.share + new_share;
    user_reward_manager.share = new_share;
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_claim_rewards"></a>

## Function `claim_rewards`

Claims rewards for a user from a specific pool reward and updates the reward state.

The function updates the user reward manager, claims the earned rewards, and reduces the
number of user reward managers if the reward period has ended.


<a name="@Arguments_15"></a>

### Arguments


* <code>pool_reward_manager</code> - A mutable reference to the <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a></code> to update.
* <code>user_reward_manager</code> - A mutable reference to the <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a></code> to update.
* <code>clock</code> - A reference to the <code>Clock</code> for timestamp-based updates.
* <code>reward_index</code> - The index of the pool reward from which to claim rewards.


<a name="@Returns_16"></a>

### Returns


* <code>Balance&lt;T&gt;</code> - The claimed reward amount.


<a name="@Panics_17"></a>

### Panics


* If the coin type of the pool reward does not match the expected type <code>T</code>.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_claim_rewards">claim_rewards</a>&lt;T&gt;(pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>, user_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">suilend::liquidity_mining::UserRewardManager</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, reward_index: u64): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_claim_rewards">claim_rewards</a>&lt;T&gt;(
    pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a>,
    user_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserRewardManager">UserRewardManager</a>,
    clock: &Clock,
    reward_index: u64,
): Balance&lt;T&gt; {
    <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_update_user_reward_manager">update_user_reward_manager</a>(pool_reward_manager, user_reward_manager, clock, <b>false</b>);
    <b>let</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a> = option::borrow_mut(
        vector::borrow_mut(&<b>mut</b> pool_reward_manager.pool_rewards, reward_index),
    );
    <b>assert</b>!(<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.coin_type == type_name::get&lt;T&gt;(), <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_EInvalidType">EInvalidType</a>);
    <b>let</b> optional_reward = vector::borrow_mut(&<b>mut</b> user_reward_manager.rewards, reward_index);
    <b>let</b> reward = option::borrow_mut(optional_reward);
    <b>let</b> claimable_rewards = floor(reward.earned_rewards);
    reward.earned_rewards = sub(reward.earned_rewards, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(claimable_rewards));
    <b>let</b> reward_balance: &<b>mut</b> Balance&lt;T&gt; = bag::borrow_mut(
        &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.additional_fields,
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_RewardBalance">RewardBalance</a>&lt;T&gt; {},
    );
    <b>if</b> (clock::timestamp_ms(clock) &gt;= <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_end_time_ms">end_time_ms</a>) {
        <b>let</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_UserReward">UserReward</a> {
            <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward_id">pool_reward_id</a>: _,
            earned_rewards: _,
            cumulative_rewards_per_share: _,
        } = option::extract(optional_reward);
        <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.num_user_reward_managers = <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_pool_reward">pool_reward</a>.num_user_reward_managers - 1;
    };
    balance::split(reward_balance, claimable_rewards)
}
</code></pre>



</details>

<a name="suilend_liquidity_mining_find_available_index"></a>

## Function `find_available_index`

Finds an available index in the pool reward manager's rewards vector for a new pool reward.

If no empty slot is found, a new <code>Option&lt;<a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolReward">PoolReward</a>&gt;</code> is appended to the vector.


<a name="@Arguments_18"></a>

### Arguments


* <code>pool_reward_manager</code> - A mutable reference to the <code><a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a></code> to search.


<a name="@Returns_19"></a>

### Returns


* <code>u64</code> - The index of an available slot or the newly appended slot.


<pre><code><b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_find_available_index">find_available_index</a>(pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">suilend::liquidity_mining::PoolRewardManager</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_find_available_index">find_available_index</a>(pool_reward_manager: &<b>mut</b> <a href="../suilend/liquidity_mining.md#suilend_liquidity_mining_PoolRewardManager">PoolRewardManager</a>): u64 {
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; vector::length(&pool_reward_manager.pool_rewards)) {
        <b>let</b> optional_pool_reward = vector::borrow(&pool_reward_manager.pool_rewards, i);
        <b>if</b> (option::is_none(optional_pool_reward)) {
            <b>return</b> i
        };
        i = i + 1;
    };
    vector::push_back(&<b>mut</b> pool_reward_manager.pool_rewards, option::none());
    i
}
</code></pre>



</details>
