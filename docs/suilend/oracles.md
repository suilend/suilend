
<a name="suilend_oracles"></a>

# Module `suilend::oracles`

This module contains logic for parsing pyth prices (and eventually switchboard prices)


-  [Constants](#@Constants_0)
-  [Function `get_pyth_price_and_identifier`](#suilend_oracles_get_pyth_price_and_identifier)
    -  [Arguments](#@Arguments_1)
    -  [Returns](#@Returns_2)
-  [Function `parse_price_to_decimal`](#suilend_oracles_parse_price_to_decimal)


<pre><code><b>use</b> <a href="../dependencies/pyth/i64.md#pyth_i64">pyth::i64</a>;
<b>use</b> <a href="../dependencies/pyth/price.md#pyth_price">pyth::price</a>;
<b>use</b> <a href="../dependencies/pyth/price_feed.md#pyth_price_feed">pyth::price_feed</a>;
<b>use</b> <a href="../dependencies/pyth/price_identifier.md#pyth_price_identifier">pyth::price_identifier</a>;
<b>use</b> <a href="../dependencies/pyth/price_info.md#pyth_price_info">pyth::price_info</a>;
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
<b>use</b> <a href="../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../dependencies/sui/sui.md#sui_sui">sui::sui</a>;
<b>use</b> <a href="../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
<b>use</b> <a href="../suilend/decimal.md#suilend_decimal">suilend::decimal</a>;
</code></pre>



<a name="@Constants_0"></a>

## Constants


<a name="suilend_oracles_MIN_CONFIDENCE_RATIO"></a>



<pre><code><b>const</b> <a href="../suilend/oracles.md#suilend_oracles_MIN_CONFIDENCE_RATIO">MIN_CONFIDENCE_RATIO</a>: u64 = 10;
</code></pre>



<a name="suilend_oracles_MAX_STALENESS_SECONDS"></a>



<pre><code><b>const</b> <a href="../suilend/oracles.md#suilend_oracles_MAX_STALENESS_SECONDS">MAX_STALENESS_SECONDS</a>: u64 = 60;
</code></pre>



<a name="suilend_oracles_get_pyth_price_and_identifier"></a>

## Function `get_pyth_price_and_identifier`

Parses a Pyth <code>PriceInfoObject</code> to extract the price, EMA price, and price identifier.

This function validates the Pyth price feed against two criteria:
1. **Confidence Interval Check**: The confidence interval must be less than a certain
percentage of the price, defined by <code><a href="../suilend/oracles.md#suilend_oracles_MIN_CONFIDENCE_RATIO">MIN_CONFIDENCE_RATIO</a></code>.
2. **Staleness Check**: The price timestamp must not be older than <code><a href="../suilend/oracles.md#suilend_oracles_MAX_STALENESS_SECONDS">MAX_STALENESS_SECONDS</a></code>
compared to the on-chain clock time.

If either of these checks fails, the function returns <code>None</code> for the spot price,
allowing the caller to handle the invalid price gracefully (e.g., by falling back to
a different oracle).


<a name="@Arguments_1"></a>

### Arguments


* <code>price_info_obj</code> - A reference to the <code>PriceInfoObject</code> from Pyth.
* <code>clock</code> - A reference to the <code>Clock</code> to check for price staleness.


<a name="@Returns_2"></a>

### Returns


* <code>(Option&lt;Decimal&gt;, Decimal, PriceIdentifier)</code> - A tuple containing:
- An <code>Option&lt;Decimal&gt;</code> for the spot price. <code>None</code> if the price is invalid.
- The EMA (Exponential Moving Average) price as a <code>Decimal</code>.
- The <code>PriceIdentifier</code> for the given price feed.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/oracles.md#suilend_oracles_get_pyth_price_and_identifier">get_pyth_price_and_identifier</a>(price_info_obj: &<a href="../dependencies/pyth/price_info.md#pyth_price_info_PriceInfoObject">pyth::price_info::PriceInfoObject</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (<a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>&gt;, <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, <a href="../dependencies/pyth/price_identifier.md#pyth_price_identifier_PriceIdentifier">pyth::price_identifier::PriceIdentifier</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/oracles.md#suilend_oracles_get_pyth_price_and_identifier">get_pyth_price_and_identifier</a>(
    price_info_obj: &PriceInfoObject,
    clock: &Clock,
): (Option&lt;Decimal&gt;, Decimal, PriceIdentifier) {
    <b>let</b> price_info = price_info::get_price_info_from_price_info_object(price_info_obj);
    <b>let</b> price_feed = price_info::get_price_feed(&price_info);
    <b>let</b> price_identifier = price_feed::get_price_identifier(price_feed);
    <b>let</b> ema_price = <a href="../suilend/oracles.md#suilend_oracles_parse_price_to_decimal">parse_price_to_decimal</a>(price_feed::get_ema_price(price_feed));
    <b>let</b> price = price_feed::get_price(price_feed);
    <b>let</b> price_mag = i64::get_magnitude_if_positive(&price::get_price(&price));
    <b>let</b> conf = price::get_conf(&price);
    // confidence interval check
    // we want to make sure conf / price &lt;= x%
    // -&gt; conf * (100 / x )&lt;= price
    <b>if</b> (conf * <a href="../suilend/oracles.md#suilend_oracles_MIN_CONFIDENCE_RATIO">MIN_CONFIDENCE_RATIO</a> &gt; price_mag) {
        <b>return</b> (option::none(), ema_price, price_identifier)
    };
    // check current sui time against pythnet publish time. there can be some issues that arise because the
    // timestamps are from different sources and may get out of sync, but that's why we have a fallback oracle
    <b>let</b> cur_time_s = clock::timestamp_ms(clock) / 1000;
    <b>if</b> (
        cur_time_s &gt; price::get_timestamp(&price) && // this is technically possible!
        cur_time_s - price::get_timestamp(&price) &gt; <a href="../suilend/oracles.md#suilend_oracles_MAX_STALENESS_SECONDS">MAX_STALENESS_SECONDS</a>
    ) {
        <b>return</b> (option::none(), ema_price, price_identifier)
    };
    <b>let</b> spot_price = <a href="../suilend/oracles.md#suilend_oracles_parse_price_to_decimal">parse_price_to_decimal</a>(price);
    (option::some(spot_price), ema_price, price_identifier)
}
</code></pre>



</details>

<a name="suilend_oracles_parse_price_to_decimal"></a>

## Function `parse_price_to_decimal`



<pre><code><b>fun</b> <a href="../suilend/oracles.md#suilend_oracles_parse_price_to_decimal">parse_price_to_decimal</a>(price: <a href="../dependencies/pyth/price.md#pyth_price_Price">pyth::price::Price</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/oracles.md#suilend_oracles_parse_price_to_decimal">parse_price_to_decimal</a>(price: Price): Decimal {
    // <a href="../suilend/suilend.md#suilend_suilend">suilend</a> doesn't support negative prices
    <b>let</b> price_mag = i64::get_magnitude_if_positive(&price::get_price(&price));
    <b>let</b> expo = price::get_expo(&price);
    <b>if</b> (i64::get_is_negative(&expo)) {
        div(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(price_mag),
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../dependencies/std/u64.md#std_u64_pow">std::u64::pow</a>(10, (i64::get_magnitude_if_negative(&expo) <b>as</b> u8))),
        )
    } <b>else</b> {
        mul(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(price_mag),
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../dependencies/std/u64.md#std_u64_pow">std::u64::pow</a>(10, (i64::get_magnitude_if_positive(&expo) <b>as</b> u8))),
        )
    }
}
</code></pre>



</details>
