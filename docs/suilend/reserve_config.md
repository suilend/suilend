
<a name="suilend_reserve_config"></a>

# Module `suilend::reserve_config`

parameters for a Reserve.


-  [Struct `ReserveConfig`](#suilend_reserve_config_ReserveConfig)
-  [Struct `ReserveConfigBuilder`](#suilend_reserve_config_ReserveConfigBuilder)
-  [Constants](#@Constants_0)
-  [Function `create_reserve_config`](#suilend_reserve_config_create_reserve_config)
    -  [Arguments](#@Arguments_1)
    -  [Returns](#@Returns_2)
    -  [Panics](#@Panics_3)
-  [Function `validate_reserve_config`](#suilend_reserve_config_validate_reserve_config)
    -  [Arguments](#@Arguments_4)
    -  [Panics](#@Panics_5)
-  [Function `validate_utils_and_aprs`](#suilend_reserve_config_validate_utils_and_aprs)
    -  [Arguments](#@Arguments_6)
    -  [Panics](#@Panics_7)
-  [Function `open_ltv`](#suilend_reserve_config_open_ltv)
    -  [Arguments](#@Arguments_8)
    -  [Returns](#@Returns_9)
-  [Function `close_ltv`](#suilend_reserve_config_close_ltv)
    -  [Arguments](#@Arguments_10)
    -  [Returns](#@Returns_11)
-  [Function `borrow_weight`](#suilend_reserve_config_borrow_weight)
    -  [Arguments](#@Arguments_12)
    -  [Returns](#@Returns_13)
-  [Function `deposit_limit`](#suilend_reserve_config_deposit_limit)
    -  [Arguments](#@Arguments_14)
    -  [Returns](#@Returns_15)
-  [Function `borrow_limit`](#suilend_reserve_config_borrow_limit)
    -  [Arguments](#@Arguments_16)
    -  [Returns](#@Returns_17)
-  [Function `liquidation_bonus`](#suilend_reserve_config_liquidation_bonus)
    -  [Arguments](#@Arguments_18)
    -  [Returns](#@Returns_19)
-  [Function `deposit_limit_usd`](#suilend_reserve_config_deposit_limit_usd)
    -  [Arguments](#@Arguments_20)
    -  [Returns](#@Returns_21)
-  [Function `borrow_limit_usd`](#suilend_reserve_config_borrow_limit_usd)
    -  [Arguments](#@Arguments_22)
    -  [Returns](#@Returns_23)
-  [Function `borrow_fee`](#suilend_reserve_config_borrow_fee)
    -  [Arguments](#@Arguments_24)
    -  [Returns](#@Returns_25)
-  [Function `protocol_liquidation_fee`](#suilend_reserve_config_protocol_liquidation_fee)
    -  [Arguments](#@Arguments_26)
    -  [Returns](#@Returns_27)
-  [Function `isolated`](#suilend_reserve_config_isolated)
    -  [Arguments](#@Arguments_28)
    -  [Returns](#@Returns_29)
-  [Function `spread_fee`](#suilend_reserve_config_spread_fee)
    -  [Arguments](#@Arguments_30)
    -  [Returns](#@Returns_31)
-  [Function `calculate_apr`](#suilend_reserve_config_calculate_apr)
    -  [Arguments](#@Arguments_32)
    -  [Returns](#@Returns_33)
    -  [Panics](#@Panics_34)
-  [Function `calculate_supply_apr`](#suilend_reserve_config_calculate_supply_apr)
    -  [Arguments](#@Arguments_35)
    -  [Returns](#@Returns_36)
-  [Function `destroy`](#suilend_reserve_config_destroy)
    -  [Arguments](#@Arguments_37)
    -  [Panics](#@Panics_38)
-  [Function `from`](#suilend_reserve_config_from)
    -  [Arguments](#@Arguments_39)
    -  [Returns](#@Returns_40)
-  [Function `set`](#suilend_reserve_config_set)
    -  [Arguments](#@Arguments_41)
-  [Function `set_open_ltv_pct`](#suilend_reserve_config_set_open_ltv_pct)
    -  [Arguments](#@Arguments_42)
-  [Function `set_close_ltv_pct`](#suilend_reserve_config_set_close_ltv_pct)
    -  [Arguments](#@Arguments_43)
-  [Function `set_max_close_ltv_pct`](#suilend_reserve_config_set_max_close_ltv_pct)
    -  [Arguments](#@Arguments_44)
-  [Function `set_borrow_weight_bps`](#suilend_reserve_config_set_borrow_weight_bps)
    -  [Arguments](#@Arguments_45)
-  [Function `set_deposit_limit`](#suilend_reserve_config_set_deposit_limit)
    -  [Arguments](#@Arguments_46)
-  [Function `set_borrow_limit`](#suilend_reserve_config_set_borrow_limit)
    -  [Arguments](#@Arguments_47)
-  [Function `set_liquidation_bonus_bps`](#suilend_reserve_config_set_liquidation_bonus_bps)
    -  [Arguments](#@Arguments_48)
-  [Function `set_max_liquidation_bonus_bps`](#suilend_reserve_config_set_max_liquidation_bonus_bps)
    -  [Arguments](#@Arguments_49)
-  [Function `set_deposit_limit_usd`](#suilend_reserve_config_set_deposit_limit_usd)
    -  [Arguments](#@Arguments_50)
-  [Function `set_borrow_limit_usd`](#suilend_reserve_config_set_borrow_limit_usd)
    -  [Arguments](#@Arguments_51)
-  [Function `set_interest_rate_utils`](#suilend_reserve_config_set_interest_rate_utils)
    -  [Arguments](#@Arguments_52)
-  [Function `set_interest_rate_aprs`](#suilend_reserve_config_set_interest_rate_aprs)
    -  [Arguments](#@Arguments_53)
-  [Function `set_borrow_fee_bps`](#suilend_reserve_config_set_borrow_fee_bps)
    -  [Arguments](#@Arguments_54)
-  [Function `set_spread_fee_bps`](#suilend_reserve_config_set_spread_fee_bps)
    -  [Arguments](#@Arguments_55)
-  [Function `set_protocol_liquidation_fee_bps`](#suilend_reserve_config_set_protocol_liquidation_fee_bps)
    -  [Arguments](#@Arguments_56)
-  [Function `set_isolated`](#suilend_reserve_config_set_isolated)
    -  [Arguments](#@Arguments_57)
-  [Function `set_open_attributed_borrow_limit_usd`](#suilend_reserve_config_set_open_attributed_borrow_limit_usd)
    -  [Arguments](#@Arguments_58)
-  [Function `set_close_attributed_borrow_limit_usd`](#suilend_reserve_config_set_close_attributed_borrow_limit_usd)
    -  [Arguments](#@Arguments_59)
-  [Function `build`](#suilend_reserve_config_build)
    -  [Arguments](#@Arguments_60)
    -  [Returns](#@Returns_61)
    -  [Panics](#@Panics_62)


<pre><code><b>use</b> <a href="../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../dependencies/sui/bag.md#sui_bag">sui::bag</a>;
<b>use</b> <a href="../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../suilend/decimal.md#suilend_decimal">suilend::decimal</a>;
</code></pre>



<a name="suilend_reserve_config_ReserveConfig"></a>

## Struct `ReserveConfig`

Configuration parameters for a reserve in the lending market.


<pre><code><b>public</b> <b>struct</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>open_ltv_pct: u8</code>
</dt>
<dd>
</dd>
<dt>
<code>close_ltv_pct: u8</code>
</dt>
<dd>
</dd>
<dt>
<code>max_close_ltv_pct: u8</code>
</dt>
<dd>
</dd>
<dt>
<code>borrow_weight_bps: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>liquidation_bonus_bps: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>max_liquidation_bonus_bps: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>interest_rate_utils: vector&lt;u8&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>interest_rate_aprs: vector&lt;u64&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>borrow_fee_bps: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>spread_fee_bps: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>protocol_liquidation_fee_bps: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>: bool</code>
</dt>
<dd>
</dd>
<dt>
<code>open_attributed_borrow_limit_usd: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>close_attributed_borrow_limit_usd: u64</code>
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

<a name="suilend_reserve_config_ReserveConfigBuilder"></a>

## Struct `ReserveConfigBuilder`

Builder struct for constructing a ReserveConfig.


<pre><code><b>public</b> <b>struct</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>fields: <a href="../dependencies/sui/bag.md#sui_bag_Bag">sui::bag::Bag</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="suilend_reserve_config_EInvalidReserveConfig"></a>



<pre><code><b>const</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>: u64 = 0;
</code></pre>



<a name="suilend_reserve_config_EInvalidUtil"></a>



<pre><code><b>const</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidUtil">EInvalidUtil</a>: u64 = 1;
</code></pre>



<a name="suilend_reserve_config_create_reserve_config"></a>

## Function `create_reserve_config`

Creates a new reserve configuration with the specified parameters.

Validates the configuration to ensure it meets all required constraints before returning.


<a name="@Arguments_1"></a>

### Arguments


* <code>open_ltv_pct</code> - Loan-to-value percentage for opening positions (0-100).
* <code>close_ltv_pct</code> - Loan-to-value percentage for closing positions (0-100).
* <code>max_close_ltv_pct</code> - Maximum close LTV percentage (unused, 0-100).
* <code>borrow_weight_bps</code> - Borrow weight in basis points (minimum 10,000).
* <code><a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a></code> - Maximum deposit amount in token units.
* <code><a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a></code> - Maximum borrow amount in token units.
* <code>liquidation_bonus_bps</code> - Bonus for liquidators in basis points.
* <code>max_liquidation_bonus_bps</code> - Maximum liquidation bonus in basis points (unused).
* <code><a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a></code> - Maximum deposit amount in USD.
* <code><a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a></code> - Maximum borrow amount in USD.
* <code>borrow_fee_bps</code> - Fee for borrowing in basis points (maximum 10,000).
* <code>spread_fee_bps</code> - Spread fee in basis points (maximum 10,000).
* <code>protocol_liquidation_fee_bps</code> - Protocol fee on liquidations in basis points.
* <code>interest_rate_utils</code> - Vector of utilization rates for interest rate calculation (0-100).
* <code>interest_rate_aprs</code> - Vector of APRs corresponding to utilization rates.
* <code><a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a></code> - If true, asset is isolated (cannot be collateral, only borrowed in isolation).
* <code>open_attributed_borrow_limit_usd</code> - Open attributed borrow limit in USD (unused).
* <code>close_attributed_borrow_limit_usd</code> - Close attributed borrow limit in USD (unused).


<a name="@Returns_2"></a>

### Returns


* <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> - A validated reserve configuration.


<a name="@Panics_3"></a>

### Panics


* If <code>open_ltv_pct</code>, <code>close_ltv_pct</code>, or <code>max_close_ltv_pct</code> exceeds 100 (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>open_ltv_pct</code> is greater than <code>close_ltv_pct</code> (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>close_ltv_pct</code> is greater than <code>max_close_ltv_pct</code> (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>borrow_weight_bps</code> is less than 10,000 (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>liquidation_bonus_bps</code> exceeds <code>max_liquidation_bonus_bps</code> (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>liquidation_bonus_bps + protocol_liquidation_fee_bps</code> exceeds 2,000 (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code><a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a></code> is true and <code>open_ltv_pct</code> or <code>close_ltv_pct</code> is non-zero (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>borrow_fee_bps</code> or <code>spread_fee_bps</code> exceeds 10,000 (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>open_attributed_borrow_limit_usd</code> exceeds <code>close_attributed_borrow_limit_usd</code> (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>interest_rate_utils</code> has fewer than 2 elements, does not start with 0, or end with 100 (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>interest_rate_utils</code> and <code>interest_rate_aprs</code> have different lengths (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>interest_rate_utils</code> is not strictly increasing or <code>interest_rate_aprs</code> is not monotonically increasing (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_create_reserve_config">create_reserve_config</a>(open_ltv_pct: u8, close_ltv_pct: u8, max_close_ltv_pct: u8, borrow_weight_bps: u64, <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>: u64, <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>: u64, liquidation_bonus_bps: u64, max_liquidation_bonus_bps: u64, <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>: u64, <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>: u64, borrow_fee_bps: u64, spread_fee_bps: u64, protocol_liquidation_fee_bps: u64, interest_rate_utils: vector&lt;u8&gt;, interest_rate_aprs: vector&lt;u64&gt;, <a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>: bool, open_attributed_borrow_limit_usd: u64, close_attributed_borrow_limit_usd: u64, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_create_reserve_config">create_reserve_config</a>(
    open_ltv_pct: u8,
    close_ltv_pct: u8,
    max_close_ltv_pct: u8,
    borrow_weight_bps: u64,
    <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>: u64,
    <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>: u64,
    liquidation_bonus_bps: u64,
    max_liquidation_bonus_bps: u64,
    <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>: u64,
    <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>: u64,
    borrow_fee_bps: u64,
    spread_fee_bps: u64,
    protocol_liquidation_fee_bps: u64,
    interest_rate_utils: vector&lt;u8&gt;,
    interest_rate_aprs: vector&lt;u64&gt;,
    <a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>: bool,
    open_attributed_borrow_limit_usd: u64,
    close_attributed_borrow_limit_usd: u64,
    ctx: &<b>mut</b> TxContext,
): <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a> {
    <b>let</b> config = <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a> {
        open_ltv_pct,
        close_ltv_pct,
        max_close_ltv_pct,
        borrow_weight_bps,
        <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>,
        <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>,
        liquidation_bonus_bps,
        max_liquidation_bonus_bps,
        <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>,
        <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>,
        interest_rate_utils,
        interest_rate_aprs,
        borrow_fee_bps,
        spread_fee_bps,
        protocol_liquidation_fee_bps,
        <a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>,
        open_attributed_borrow_limit_usd,
        close_attributed_borrow_limit_usd,
        additional_fields: bag::new(ctx),
    };
    <a href="../suilend/reserve_config.md#suilend_reserve_config_validate_reserve_config">validate_reserve_config</a>(&config);
    config
}
</code></pre>



</details>

<a name="suilend_reserve_config_validate_reserve_config"></a>

## Function `validate_reserve_config`

Validates the reserve configuration to ensure it meets all constraints.

Checks various parameters for correctness, including LTVs, borrow weight, liquidation bonuses,
fees, and interest rate vectors.


<a name="@Arguments_4"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to validate.


<a name="@Panics_5"></a>

### Panics


* If <code>open_ltv_pct</code>, <code>close_ltv_pct</code>, or <code>max_close_ltv_pct</code> exceeds 100 (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>open_ltv_pct</code> is greater than <code>close_ltv_pct</code> (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>close_ltv_pct</code> is greater than <code>max_close_ltv_pct</code> (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>borrow_weight_bps</code> is less than 10,000 (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>liquidation_bonus_bps</code> exceeds <code>max_liquidation_bonus_bps</code> (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>liquidation_bonus_bps + protocol_liquidation_fee_bps</code> exceeds 2,000 (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code><a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a></code> is true and <code>open_ltv_pct</code> or <code>close_ltv_pct</code> is non-zero (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>borrow_fee_bps</code> or <code>spread_fee_bps</code> exceeds 10,000 (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>open_attributed_borrow_limit_usd</code> exceeds <code>close_attributed_borrow_limit_usd</code> (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>interest_rate_utils</code> has fewer than 2 elements, does not start with 0, or end with 100 (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>interest_rate_utils</code> and <code>interest_rate_aprs</code> have different lengths (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>interest_rate_utils</code> is not strictly increasing or <code>interest_rate_aprs</code> is not monotonically increasing (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).


<pre><code><b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_validate_reserve_config">validate_reserve_config</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_validate_reserve_config">validate_reserve_config</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>) {
    <b>assert</b>!(config.open_ltv_pct &lt;= 100, <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    <b>assert</b>!(config.close_ltv_pct &lt;= 100, <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    <b>assert</b>!(config.max_close_ltv_pct &lt;= 100, <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    <b>assert</b>!(config.open_ltv_pct &lt;= config.close_ltv_pct, <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    <b>assert</b>!(config.close_ltv_pct &lt;= config.max_close_ltv_pct, <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    <b>assert</b>!(config.borrow_weight_bps &gt;= 10_000, <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    <b>assert</b>!(
        config.liquidation_bonus_bps &lt;= config.max_liquidation_bonus_bps,
        <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>,
    );
    <b>assert</b>!(
        config.max_liquidation_bonus_bps + config.protocol_liquidation_fee_bps &lt;= 2_000,
        <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>,
    );
    <b>if</b> (config.<a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>) {
        <b>assert</b>!(config.open_ltv_pct == 0 && config.close_ltv_pct == 0, <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    };
    <b>assert</b>!(config.borrow_fee_bps &lt;= 10_000, <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    <b>assert</b>!(config.spread_fee_bps &lt;= 10_000, <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    <b>assert</b>!(
        config.open_attributed_borrow_limit_usd &lt;= config.close_attributed_borrow_limit_usd,
        <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>,
    );
    <a href="../suilend/reserve_config.md#suilend_reserve_config_validate_utils_and_aprs">validate_utils_and_aprs</a>(&config.interest_rate_utils, &config.interest_rate_aprs);
}
</code></pre>



</details>

<a name="suilend_reserve_config_validate_utils_and_aprs"></a>

## Function `validate_utils_and_aprs`

Validates the interest rate utilization and APR vectors.

Ensures the utilization rates are strictly increasing, start at 0, end at 100, and
match the length of the APR vector, which must be monotonically increasing.


<a name="@Arguments_6"></a>

### Arguments


* <code>utils</code> - A reference to the vector of utilization rates (0-100).
* <code>aprs</code> - A reference to the vector of APRs in basis points.


<a name="@Panics_7"></a>

### Panics


* If <code>utils</code> has fewer than 2 elements (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>utils</code> and <code>aprs</code> have different lengths (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>utils</code> does not start with 0 or end with 100 (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>utils</code> is not strictly increasing (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).
* If <code>aprs</code> is not monotonically increasing (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).


<pre><code><b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_validate_utils_and_aprs">validate_utils_and_aprs</a>(utils: &vector&lt;u8&gt;, aprs: &vector&lt;u64&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_validate_utils_and_aprs">validate_utils_and_aprs</a>(utils: &vector&lt;u8&gt;, aprs: &vector&lt;u64&gt;) {
    <b>assert</b>!(vector::length(utils) &gt;= 2, <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    <b>assert</b>!(vector::length(utils) == vector::length(aprs), <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    <b>let</b> length = vector::length(utils);
    <b>assert</b>!(*vector::borrow(utils, 0) == 0, <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    <b>assert</b>!(*vector::borrow(utils, length-1) == 100, <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    // check that:
    // - utils is strictly increasing
    // - aprs is monotonically increasing
    <b>let</b> <b>mut</b> i = 1;
    <b>while</b> (i &lt; length) {
        <b>assert</b>!(
            *vector::borrow(utils, i - 1) &lt; *vector::borrow(utils, i),
            <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>,
        );
        <b>assert</b>!(
            *vector::borrow(aprs, i - 1) &lt;= *vector::borrow(aprs, i),
            <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>,
        );
        i = i + 1;
    }
}
</code></pre>



</details>

<a name="suilend_reserve_config_open_ltv"></a>

## Function `open_ltv`

Gets the open loan-to-value (LTV) ratio as a decimal.


<a name="@Arguments_8"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to query.


<a name="@Returns_9"></a>

### Returns


* <code>Decimal</code> - The open LTV ratio as a decimal (e.g., 50% = 0.5).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_open_ltv">open_ltv</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_open_ltv">open_ltv</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>): Decimal {
    <a href="../suilend/decimal.md#suilend_decimal_from_percent">decimal::from_percent</a>(config.open_ltv_pct)
}
</code></pre>



</details>

<a name="suilend_reserve_config_close_ltv"></a>

## Function `close_ltv`

Gets the close loan-to-value (LTV) ratio as a decimal.


<a name="@Arguments_10"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to query.


<a name="@Returns_11"></a>

### Returns


* <code>Decimal</code> - The close LTV ratio as a decimal (e.g., 50% = 0.5).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_close_ltv">close_ltv</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_close_ltv">close_ltv</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>): Decimal {
    <a href="../suilend/decimal.md#suilend_decimal_from_percent">decimal::from_percent</a>(config.close_ltv_pct)
}
</code></pre>



</details>

<a name="suilend_reserve_config_borrow_weight"></a>

## Function `borrow_weight`

Gets the borrow weight as a decimal.


<a name="@Arguments_12"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to query.


<a name="@Returns_13"></a>

### Returns


* <code>Decimal</code> - The borrow weight as a decimal (e.g., 10,000 bps = 1.0).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_weight">borrow_weight</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_weight">borrow_weight</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>): Decimal {
    <a href="../suilend/decimal.md#suilend_decimal_from_bps">decimal::from_bps</a>(config.borrow_weight_bps)
}
</code></pre>



</details>

<a name="suilend_reserve_config_deposit_limit"></a>

## Function `deposit_limit`

Gets the deposit limit in token units.


<a name="@Arguments_14"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to query.


<a name="@Returns_15"></a>

### Returns


* <code>u64</code> - The maximum deposit amount in token units.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>): u64 {
    config.<a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>
}
</code></pre>



</details>

<a name="suilend_reserve_config_borrow_limit"></a>

## Function `borrow_limit`

Gets the borrow limit in token units.


<a name="@Arguments_16"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to query.


<a name="@Returns_17"></a>

### Returns


* <code>u64</code> - The maximum borrow amount in token units.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>): u64 {
    config.<a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>
}
</code></pre>



</details>

<a name="suilend_reserve_config_liquidation_bonus"></a>

## Function `liquidation_bonus`

Gets the liquidation bonus as a decimal.


<a name="@Arguments_18"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to query.


<a name="@Returns_19"></a>

### Returns


* <code>Decimal</code> - The liquidation bonus as a decimal (e.g., 500 bps = 0.05).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_liquidation_bonus">liquidation_bonus</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_liquidation_bonus">liquidation_bonus</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>): Decimal {
    <a href="../suilend/decimal.md#suilend_decimal_from_bps">decimal::from_bps</a>(config.liquidation_bonus_bps)
}
</code></pre>



</details>

<a name="suilend_reserve_config_deposit_limit_usd"></a>

## Function `deposit_limit_usd`

Gets the deposit limit in USD.


<a name="@Arguments_20"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to query.


<a name="@Returns_21"></a>

### Returns


* <code>u64</code> - The maximum deposit amount in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>): u64 {
    config.<a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>
}
</code></pre>



</details>

<a name="suilend_reserve_config_borrow_limit_usd"></a>

## Function `borrow_limit_usd`

Gets the borrow limit in USD.


<a name="@Arguments_22"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to query.


<a name="@Returns_23"></a>

### Returns


* <code>u64</code> - The maximum borrow amount in USD.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>): u64 {
    config.<a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>
}
</code></pre>



</details>

<a name="suilend_reserve_config_borrow_fee"></a>

## Function `borrow_fee`

Gets the borrow fee as a decimal.


<a name="@Arguments_24"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to query.


<a name="@Returns_25"></a>

### Returns


* <code>Decimal</code> - The borrow fee as a decimal (e.g., 10 bps = 0.001).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_fee">borrow_fee</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_fee">borrow_fee</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>): Decimal {
    <a href="../suilend/decimal.md#suilend_decimal_from_bps">decimal::from_bps</a>(config.borrow_fee_bps)
}
</code></pre>



</details>

<a name="suilend_reserve_config_protocol_liquidation_fee"></a>

## Function `protocol_liquidation_fee`

Gets the protocol liquidation fee as a decimal.


<a name="@Arguments_26"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to query.


<a name="@Returns_27"></a>

### Returns


* <code>Decimal</code> - The protocol liquidation fee as a decimal (e.g., 300 bps = 0.03).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_protocol_liquidation_fee">protocol_liquidation_fee</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_protocol_liquidation_fee">protocol_liquidation_fee</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>): Decimal {
    <a href="../suilend/decimal.md#suilend_decimal_from_bps">decimal::from_bps</a>(config.protocol_liquidation_fee_bps)
}
</code></pre>



</details>

<a name="suilend_reserve_config_isolated"></a>

## Function `isolated`

Gets the isolation status of the reserve.


<a name="@Arguments_28"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to query.


<a name="@Returns_29"></a>

### Returns


* <code>bool</code> - True if the asset is isolated, false otherwise.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>): bool {
    config.<a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>
}
</code></pre>



</details>

<a name="suilend_reserve_config_spread_fee"></a>

## Function `spread_fee`

Gets the spread fee as a decimal.


<a name="@Arguments_30"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to query.


<a name="@Returns_31"></a>

### Returns


* <code>Decimal</code> - The spread fee as a decimal (e.g., 2000 bps = 0.2).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_spread_fee">spread_fee</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_spread_fee">spread_fee</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>): Decimal {
    <a href="../suilend/decimal.md#suilend_decimal_from_bps">decimal::from_bps</a>(config.spread_fee_bps)
}
</code></pre>



</details>

<a name="suilend_reserve_config_calculate_apr"></a>

## Function `calculate_apr`

Calculates the annual percentage rate (APR) based on the current utilization.

Interpolates the APR based on the utilization rate using the provided <code>interest_rate_utils</code>
and <code>interest_rate_aprs</code> vectors.


<a name="@Arguments_32"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> containing the interest rate data.
* <code>cur_util</code> - The current utilization rate as a decimal (0 to 1).


<a name="@Returns_33"></a>

### Returns


* <code>Decimal</code> - The calculated APR as a decimal.


<a name="@Panics_34"></a>

### Panics


* If <code>cur_util</code> is greater than 1 (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidUtil">EInvalidUtil</a></code>).
* If the interpolation logic fails due to invalid configuration (<code><a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a></code>).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_calculate_apr">calculate_apr</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>, cur_util: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_calculate_apr">calculate_apr</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>, cur_util: Decimal): Decimal {
    <b>assert</b>!(le(cur_util, <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1)), <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidUtil">EInvalidUtil</a>);
    <b>let</b> length = vector::length(&config.interest_rate_utils);
    <b>let</b> <b>mut</b> i = 1;
    <b>while</b> (i &lt; length) {
        <b>let</b> left_util = <a href="../suilend/decimal.md#suilend_decimal_from_percent">decimal::from_percent</a>(
            *vector::borrow(&config.interest_rate_utils, i - 1),
        );
        <b>let</b> right_util = <a href="../suilend/decimal.md#suilend_decimal_from_percent">decimal::from_percent</a>(*vector::borrow(&config.interest_rate_utils, i));
        <b>if</b> (ge(cur_util, left_util) && le(cur_util, right_util)) {
            <b>let</b> left_apr = <a href="../suilend/decimal.md#suilend_decimal_from_bps">decimal::from_bps</a>(
                *vector::borrow(&config.interest_rate_aprs, i - 1),
            );
            <b>let</b> right_apr = <a href="../suilend/decimal.md#suilend_decimal_from_bps">decimal::from_bps</a>(*vector::borrow(&config.interest_rate_aprs, i));
            <b>let</b> weight = div(
                sub(cur_util, left_util),
                sub(right_util, left_util),
            );
            <b>let</b> apr_diff = sub(right_apr, left_apr);
            <b>return</b> add(
                    left_apr,
                    mul(weight, apr_diff),
                )
        };
        i = i + 1;
    };
    // should never get here
    <b>assert</b>!(1 == 0, <a href="../suilend/reserve_config.md#suilend_reserve_config_EInvalidReserveConfig">EInvalidReserveConfig</a>);
    <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0)
}
</code></pre>



</details>

<a name="suilend_reserve_config_calculate_supply_apr"></a>

## Function `calculate_supply_apr`

Calculates the supply APR based on the current utilization and borrow APR.

Applies the spread fee to the borrow APR and scales it by the utilization rate.


<a name="@Arguments_35"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> containing the spread fee.
* <code>cur_util</code> - The current utilization rate as a decimal (0 to 1).
* <code>borrow_apr</code> - The borrow APR as a decimal.


<a name="@Returns_36"></a>

### Returns


* <code>Decimal</code> - The calculated supply APR as a decimal.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_calculate_supply_apr">calculate_supply_apr</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>, cur_util: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, borrow_apr: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_calculate_supply_apr">calculate_supply_apr</a>(
    config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>,
    cur_util: Decimal,
    borrow_apr: Decimal,
): Decimal {
    <b>let</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_spread_fee">spread_fee</a> = <a href="../suilend/reserve_config.md#suilend_reserve_config_spread_fee">spread_fee</a>(config);
    mul(mul(sub(<a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(1), <a href="../suilend/reserve_config.md#suilend_reserve_config_spread_fee">spread_fee</a>), borrow_apr), cur_util)
}
</code></pre>



</details>

<a name="suilend_reserve_config_destroy"></a>

## Function `destroy`

Destroys a reserve configuration, ensuring the additional fields bag is empty.


<a name="@Arguments_37"></a>

### Arguments


* <code>config</code> - The <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to destroy.


<a name="@Panics_38"></a>

### Panics


* If the <code>additional_fields</code> bag is not empty.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_destroy">destroy</a>(config: <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_destroy">destroy</a>(config: <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>) {
    <b>let</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a> {
        open_ltv_pct: _,
        close_ltv_pct: _,
        max_close_ltv_pct: _,
        borrow_weight_bps: _,
        <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>: _,
        <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>: _,
        liquidation_bonus_bps: _,
        max_liquidation_bonus_bps: _,
        <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>: _,
        <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>: _,
        interest_rate_utils: _,
        interest_rate_aprs: _,
        borrow_fee_bps: _,
        spread_fee_bps: _,
        protocol_liquidation_fee_bps: _,
        <a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>: _,
        open_attributed_borrow_limit_usd: _,
        close_attributed_borrow_limit_usd: _,
        additional_fields,
    } = config;
    bag::destroy_empty(additional_fields);
}
</code></pre>



</details>

<a name="suilend_reserve_config_from"></a>

## Function `from`

Creates a new reserve configuration builder from an existing configuration.

Initializes a <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code> with the fields from the provided <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code>.


<a name="@Arguments_39"></a>

### Arguments


* <code>config</code> - A reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> to initialize the builder from.


<a name="@Returns_40"></a>

### Returns


* <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code> - A new builder initialized with the config's fields.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_from">from</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_from">from</a>(config: &<a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a>, ctx: &<b>mut</b> TxContext): <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a> {
    <b>let</b> <b>mut</b> builder = <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a> { fields: bag::new(ctx) };
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_open_ltv_pct">set_open_ltv_pct</a>(&<b>mut</b> builder, config.open_ltv_pct);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_close_ltv_pct">set_close_ltv_pct</a>(&<b>mut</b> builder, config.close_ltv_pct);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_max_close_ltv_pct">set_max_close_ltv_pct</a>(&<b>mut</b> builder, config.max_close_ltv_pct);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_borrow_weight_bps">set_borrow_weight_bps</a>(&<b>mut</b> builder, config.borrow_weight_bps);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_deposit_limit">set_deposit_limit</a>(&<b>mut</b> builder, config.<a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_borrow_limit">set_borrow_limit</a>(&<b>mut</b> builder, config.<a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_liquidation_bonus_bps">set_liquidation_bonus_bps</a>(&<b>mut</b> builder, config.liquidation_bonus_bps);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_max_liquidation_bonus_bps">set_max_liquidation_bonus_bps</a>(&<b>mut</b> builder, config.max_liquidation_bonus_bps);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_deposit_limit_usd">set_deposit_limit_usd</a>(&<b>mut</b> builder, config.<a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_borrow_limit_usd">set_borrow_limit_usd</a>(&<b>mut</b> builder, config.<a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_interest_rate_utils">set_interest_rate_utils</a>(&<b>mut</b> builder, config.interest_rate_utils);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_interest_rate_aprs">set_interest_rate_aprs</a>(&<b>mut</b> builder, config.interest_rate_aprs);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_borrow_fee_bps">set_borrow_fee_bps</a>(&<b>mut</b> builder, config.borrow_fee_bps);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_spread_fee_bps">set_spread_fee_bps</a>(&<b>mut</b> builder, config.spread_fee_bps);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_protocol_liquidation_fee_bps">set_protocol_liquidation_fee_bps</a>(&<b>mut</b> builder, config.protocol_liquidation_fee_bps);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_isolated">set_isolated</a>(&<b>mut</b> builder, config.<a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_open_attributed_borrow_limit_usd">set_open_attributed_borrow_limit_usd</a>(&<b>mut</b> builder, config.open_attributed_borrow_limit_usd);
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set_close_attributed_borrow_limit_usd">set_close_attributed_borrow_limit_usd</a>(
        &<b>mut</b> builder,
        config.close_attributed_borrow_limit_usd,
    );
    builder
}
</code></pre>



</details>

<a name="suilend_reserve_config_set"></a>

## Function `set`

Sets a field in the reserve configuration builder.

Updates an existing field or adds a new one to the builder's fields bag.


<a name="@Arguments_41"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>field</code> - The key for the field to set.
* <code>value</code> - The value to set for the field.


<pre><code><b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>&lt;K: <b>copy</b>, drop, store, V: drop, store&gt;(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, field: K, value: V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>&lt;K: <b>copy</b> + drop + store, V: store + drop&gt;(
    builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>,
    field: K,
    value: V,
) {
    <b>if</b> (bag::contains(&builder.fields, field)) {
        <b>let</b> val: &<b>mut</b> V = bag::borrow_mut(&<b>mut</b> builder.fields, field);
        *val = value;
    } <b>else</b> {
        bag::add(&<b>mut</b> builder.fields, field, value);
    }
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_open_ltv_pct"></a>

## Function `set_open_ltv_pct`

Sets the open LTV percentage in the builder.


<a name="@Arguments_42"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>open_ltv_pct</code> - The open LTV percentage to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_open_ltv_pct">set_open_ltv_pct</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, open_ltv_pct: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_open_ltv_pct">set_open_ltv_pct</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>, open_ltv_pct: u8) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"open_ltv_pct", open_ltv_pct);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_close_ltv_pct"></a>

## Function `set_close_ltv_pct`

Sets the close LTV percentage in the builder.


<a name="@Arguments_43"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>close_ltv_pct</code> - The close LTV percentage to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_close_ltv_pct">set_close_ltv_pct</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, close_ltv_pct: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_close_ltv_pct">set_close_ltv_pct</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>, close_ltv_pct: u8) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"close_ltv_pct", close_ltv_pct);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_max_close_ltv_pct"></a>

## Function `set_max_close_ltv_pct`

Sets the maximum close LTV percentage in the builder.


<a name="@Arguments_44"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>max_close_ltv_pct</code> - The maximum close LTV percentage to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_max_close_ltv_pct">set_max_close_ltv_pct</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, max_close_ltv_pct: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_max_close_ltv_pct">set_max_close_ltv_pct</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>, max_close_ltv_pct: u8) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"max_close_ltv_pct", max_close_ltv_pct);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_borrow_weight_bps"></a>

## Function `set_borrow_weight_bps`

Sets the borrow weight in basis points in the builder.


<a name="@Arguments_45"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>borrow_weight_bps</code> - The borrow weight in basis points to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_borrow_weight_bps">set_borrow_weight_bps</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, borrow_weight_bps: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_borrow_weight_bps">set_borrow_weight_bps</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>, borrow_weight_bps: u64) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"borrow_weight_bps", borrow_weight_bps);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_deposit_limit"></a>

## Function `set_deposit_limit`

Sets the deposit limit in token units in the builder.


<a name="@Arguments_46"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code><a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a></code> - The deposit limit in token units to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_deposit_limit">set_deposit_limit</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_deposit_limit">set_deposit_limit</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>, <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>: u64) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"<a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>", <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_borrow_limit"></a>

## Function `set_borrow_limit`

Sets the borrow limit in token units in the builder.


<a name="@Arguments_47"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code><a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a></code> - The borrow limit in token units to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_borrow_limit">set_borrow_limit</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_borrow_limit">set_borrow_limit</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>, <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>: u64) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"<a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>", <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_liquidation_bonus_bps"></a>

## Function `set_liquidation_bonus_bps`

Sets the liquidation bonus in basis points in the builder.


<a name="@Arguments_48"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>liquidation_bonus_bps</code> - The liquidation bonus in basis points to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_liquidation_bonus_bps">set_liquidation_bonus_bps</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, liquidation_bonus_bps: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_liquidation_bonus_bps">set_liquidation_bonus_bps</a>(
    builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>,
    liquidation_bonus_bps: u64,
) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"liquidation_bonus_bps", liquidation_bonus_bps);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_max_liquidation_bonus_bps"></a>

## Function `set_max_liquidation_bonus_bps`

Sets the maximum liquidation bonus in basis points in the builder.


<a name="@Arguments_49"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>max_liquidation_bonus_bps</code> - The maximum liquidation bonus in basis points to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_max_liquidation_bonus_bps">set_max_liquidation_bonus_bps</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, max_liquidation_bonus_bps: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_max_liquidation_bonus_bps">set_max_liquidation_bonus_bps</a>(
    builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>,
    max_liquidation_bonus_bps: u64,
) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"max_liquidation_bonus_bps", max_liquidation_bonus_bps);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_deposit_limit_usd"></a>

## Function `set_deposit_limit_usd`

Sets the deposit limit in USD in the builder.


<a name="@Arguments_50"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code><a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a></code> - The deposit limit in USD to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_deposit_limit_usd">set_deposit_limit_usd</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_deposit_limit_usd">set_deposit_limit_usd</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>, <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>: u64) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"<a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>", <a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_borrow_limit_usd"></a>

## Function `set_borrow_limit_usd`

Sets the borrow limit in USD in the builder.


<a name="@Arguments_51"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code><a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a></code> - The borrow limit in USD to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_borrow_limit_usd">set_borrow_limit_usd</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_borrow_limit_usd">set_borrow_limit_usd</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>, <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>: u64) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"<a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>", <a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_interest_rate_utils"></a>

## Function `set_interest_rate_utils`

Sets the interest rate utilization vector in the builder.


<a name="@Arguments_52"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>interest_rate_utils</code> - The vector of utilization rates to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_interest_rate_utils">set_interest_rate_utils</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, interest_rate_utils: vector&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_interest_rate_utils">set_interest_rate_utils</a>(
    builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>,
    interest_rate_utils: vector&lt;u8&gt;,
) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"interest_rate_utils", interest_rate_utils);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_interest_rate_aprs"></a>

## Function `set_interest_rate_aprs`

Sets the interest rate APR vector in the builder.


<a name="@Arguments_53"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>interest_rate_aprs</code> - The vector of APRs to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_interest_rate_aprs">set_interest_rate_aprs</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, interest_rate_aprs: vector&lt;u64&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_interest_rate_aprs">set_interest_rate_aprs</a>(
    builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>,
    interest_rate_aprs: vector&lt;u64&gt;,
) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"interest_rate_aprs", interest_rate_aprs);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_borrow_fee_bps"></a>

## Function `set_borrow_fee_bps`

Sets the borrow fee in basis points in the builder.


<a name="@Arguments_54"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>borrow_fee_bps</code> - The borrow fee in basis points to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_borrow_fee_bps">set_borrow_fee_bps</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, borrow_fee_bps: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_borrow_fee_bps">set_borrow_fee_bps</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>, borrow_fee_bps: u64) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"borrow_fee_bps", borrow_fee_bps);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_spread_fee_bps"></a>

## Function `set_spread_fee_bps`

Sets the spread fee in basis points in the builder.


<a name="@Arguments_55"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>spread_fee_bps</code> - The spread fee in basis points to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_spread_fee_bps">set_spread_fee_bps</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, spread_fee_bps: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_spread_fee_bps">set_spread_fee_bps</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>, spread_fee_bps: u64) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"spread_fee_bps", spread_fee_bps);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_protocol_liquidation_fee_bps"></a>

## Function `set_protocol_liquidation_fee_bps`

Sets the protocol liquidation fee in basis points in the builder.


<a name="@Arguments_56"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>protocol_liquidation_fee_bps</code> - The protocol liquidation fee in basis points to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_protocol_liquidation_fee_bps">set_protocol_liquidation_fee_bps</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, protocol_liquidation_fee_bps: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_protocol_liquidation_fee_bps">set_protocol_liquidation_fee_bps</a>(
    builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>,
    protocol_liquidation_fee_bps: u64,
) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"protocol_liquidation_fee_bps", protocol_liquidation_fee_bps);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_isolated"></a>

## Function `set_isolated`

Sets the isolation status in the builder.


<a name="@Arguments_57"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code><a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a></code> - The isolation status to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_isolated">set_isolated</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, <a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_isolated">set_isolated</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>, <a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>: bool) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"<a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>", <a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_open_attributed_borrow_limit_usd"></a>

## Function `set_open_attributed_borrow_limit_usd`

Sets the open attributed borrow limit in USD in the builder.


<a name="@Arguments_58"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>open_attributed_borrow_limit_usd</code> - The open attributed borrow limit in USD to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_open_attributed_borrow_limit_usd">set_open_attributed_borrow_limit_usd</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, open_attributed_borrow_limit_usd: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_open_attributed_borrow_limit_usd">set_open_attributed_borrow_limit_usd</a>(
    builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>,
    open_attributed_borrow_limit_usd: u64,
) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"open_attributed_borrow_limit_usd", open_attributed_borrow_limit_usd);
}
</code></pre>



</details>

<a name="suilend_reserve_config_set_close_attributed_borrow_limit_usd"></a>

## Function `set_close_attributed_borrow_limit_usd`

Sets the close attributed borrow limit in USD in the builder.


<a name="@Arguments_59"></a>

### Arguments


* <code>builder</code> - A mutable reference to the <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code>.
* <code>close_attributed_borrow_limit_usd</code> - The close attributed borrow limit in USD to set.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_close_attributed_borrow_limit_usd">set_close_attributed_borrow_limit_usd</a>(builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, close_attributed_borrow_limit_usd: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_set_close_attributed_borrow_limit_usd">set_close_attributed_borrow_limit_usd</a>(
    builder: &<b>mut</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>,
    close_attributed_borrow_limit_usd: u64,
) {
    <a href="../suilend/reserve_config.md#suilend_reserve_config_set">set</a>(builder, b"close_attributed_borrow_limit_usd", close_attributed_borrow_limit_usd);
}
</code></pre>



</details>

<a name="suilend_reserve_config_build"></a>

## Function `build`

Builds a reserve configuration from the builder.

Constructs a <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> by extracting all fields from the builder's bag and
validating the resulting configuration.


<a name="@Arguments_60"></a>

### Arguments


* <code>builder</code> - The <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a></code> to build from.


<a name="@Returns_61"></a>

### Returns


* <code><a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a></code> - The constructed and validated reserve configuration.


<a name="@Panics_62"></a>

### Panics


* If any required field is missing from the builder's bag.
* If the constructed configuration fails validation (see <code><a href="../suilend/reserve_config.md#suilend_reserve_config_validate_reserve_config">validate_reserve_config</a></code> for details).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_build">build</a>(builder: <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">suilend::reserve_config::ReserveConfigBuilder</a>, tx_context: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">suilend::reserve_config::ReserveConfig</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_build">build</a>(<b>mut</b> builder: <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a>, tx_context: &<b>mut</b> TxContext): <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfig">ReserveConfig</a> {
    <b>let</b> config = <a href="../suilend/reserve_config.md#suilend_reserve_config_create_reserve_config">create_reserve_config</a>(
        bag::remove(&<b>mut</b> builder.fields, b"open_ltv_pct"),
        bag::remove(&<b>mut</b> builder.fields, b"close_ltv_pct"),
        bag::remove(&<b>mut</b> builder.fields, b"max_close_ltv_pct"),
        bag::remove(&<b>mut</b> builder.fields, b"borrow_weight_bps"),
        bag::remove(&<b>mut</b> builder.fields, b"<a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit">deposit_limit</a>"),
        bag::remove(&<b>mut</b> builder.fields, b"<a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit">borrow_limit</a>"),
        bag::remove(&<b>mut</b> builder.fields, b"liquidation_bonus_bps"),
        bag::remove(&<b>mut</b> builder.fields, b"max_liquidation_bonus_bps"),
        bag::remove(&<b>mut</b> builder.fields, b"<a href="../suilend/reserve_config.md#suilend_reserve_config_deposit_limit_usd">deposit_limit_usd</a>"),
        bag::remove(&<b>mut</b> builder.fields, b"<a href="../suilend/reserve_config.md#suilend_reserve_config_borrow_limit_usd">borrow_limit_usd</a>"),
        bag::remove(&<b>mut</b> builder.fields, b"borrow_fee_bps"),
        bag::remove(&<b>mut</b> builder.fields, b"spread_fee_bps"),
        bag::remove(&<b>mut</b> builder.fields, b"protocol_liquidation_fee_bps"),
        bag::remove(&<b>mut</b> builder.fields, b"interest_rate_utils"),
        bag::remove(&<b>mut</b> builder.fields, b"interest_rate_aprs"),
        bag::remove(&<b>mut</b> builder.fields, b"<a href="../suilend/reserve_config.md#suilend_reserve_config_isolated">isolated</a>"),
        bag::remove(&<b>mut</b> builder.fields, b"open_attributed_borrow_limit_usd"),
        bag::remove(&<b>mut</b> builder.fields, b"close_attributed_borrow_limit_usd"),
        tx_context,
    );
    <b>let</b> <a href="../suilend/reserve_config.md#suilend_reserve_config_ReserveConfigBuilder">ReserveConfigBuilder</a> { fields } = builder;
    bag::destroy_empty(fields);
    config
}
</code></pre>



</details>
