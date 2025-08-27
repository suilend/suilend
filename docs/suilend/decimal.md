
<a name="suilend_decimal"></a>

# Module `suilend::decimal`

fixed point decimal representation. 18 decimal places are kept.


-  [Struct `Decimal`](#suilend_decimal_Decimal)
-  [Constants](#@Constants_0)
-  [Function `from`](#suilend_decimal_from)
-  [Function `from_u128`](#suilend_decimal_from_u128)
-  [Function `from_percent`](#suilend_decimal_from_percent)
-  [Function `from_percent_u64`](#suilend_decimal_from_percent_u64)
-  [Function `from_bps`](#suilend_decimal_from_bps)
-  [Function `from_scaled_val`](#suilend_decimal_from_scaled_val)
-  [Function `to_scaled_val`](#suilend_decimal_to_scaled_val)
-  [Function `add`](#suilend_decimal_add)
-  [Function `sub`](#suilend_decimal_sub)
-  [Function `saturating_sub`](#suilend_decimal_saturating_sub)
-  [Function `mul`](#suilend_decimal_mul)
-  [Function `div`](#suilend_decimal_div)
-  [Function `pow`](#suilend_decimal_pow)
-  [Function `floor`](#suilend_decimal_floor)
-  [Function `saturating_floor`](#suilend_decimal_saturating_floor)
-  [Function `ceil`](#suilend_decimal_ceil)
-  [Function `eq`](#suilend_decimal_eq)
-  [Function `ge`](#suilend_decimal_ge)
-  [Function `gt`](#suilend_decimal_gt)
-  [Function `le`](#suilend_decimal_le)
-  [Function `lt`](#suilend_decimal_lt)
-  [Function `min`](#suilend_decimal_min)
-  [Function `max`](#suilend_decimal_max)


<pre><code></code></pre>



<a name="suilend_decimal_Decimal"></a>

## Struct `Decimal`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>value: u256</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="suilend_decimal_WAD"></a>



<pre><code><b>const</b> <a href="../suilend/decimal.md#suilend_decimal_WAD">WAD</a>: u256 = 1000000000000000000;
</code></pre>



<a name="suilend_decimal_U64_MAX"></a>



<pre><code><b>const</b> <a href="../suilend/decimal.md#suilend_decimal_U64_MAX">U64_MAX</a>: u256 = 18446744073709551615;
</code></pre>



<a name="suilend_decimal_from"></a>

## Function `from`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_from">from</a>(v: u64): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_from">from</a>(v: u64): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
        value: (v <b>as</b> u256) * <a href="../suilend/decimal.md#suilend_decimal_WAD">WAD</a>,
    }
}
</code></pre>



</details>

<a name="suilend_decimal_from_u128"></a>

## Function `from_u128`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_from_u128">from_u128</a>(v: u128): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_from_u128">from_u128</a>(v: u128): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
        value: (v <b>as</b> u256) * <a href="../suilend/decimal.md#suilend_decimal_WAD">WAD</a>
    }
}
</code></pre>



</details>

<a name="suilend_decimal_from_percent"></a>

## Function `from_percent`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_from_percent">from_percent</a>(v: u8): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_from_percent">from_percent</a>(v: u8): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
        value: (v <b>as</b> u256) * <a href="../suilend/decimal.md#suilend_decimal_WAD">WAD</a> / 100,
    }
}
</code></pre>



</details>

<a name="suilend_decimal_from_percent_u64"></a>

## Function `from_percent_u64`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_from_percent_u64">from_percent_u64</a>(v: u64): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_from_percent_u64">from_percent_u64</a>(v: u64): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
        value: (v <b>as</b> u256) * <a href="../suilend/decimal.md#suilend_decimal_WAD">WAD</a> / 100,
    }
}
</code></pre>



</details>

<a name="suilend_decimal_from_bps"></a>

## Function `from_bps`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_from_bps">from_bps</a>(v: u64): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_from_bps">from_bps</a>(v: u64): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
        value: (v <b>as</b> u256) * <a href="../suilend/decimal.md#suilend_decimal_WAD">WAD</a> / 10_000,
    }
}
</code></pre>



</details>

<a name="suilend_decimal_from_scaled_val"></a>

## Function `from_scaled_val`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_from_scaled_val">from_scaled_val</a>(v: u256): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_from_scaled_val">from_scaled_val</a>(v: u256): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
        value: v,
    }
}
</code></pre>



</details>

<a name="suilend_decimal_to_scaled_val"></a>

## Function `to_scaled_val`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_to_scaled_val">to_scaled_val</a>(v: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_to_scaled_val">to_scaled_val</a>(v: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): u256 {
    v.value
}
</code></pre>



</details>

<a name="suilend_decimal_add"></a>

## Function `add`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_add">add</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_add">add</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
        value: a.value + b.value,
    }
}
</code></pre>



</details>

<a name="suilend_decimal_sub"></a>

## Function `sub`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_sub">sub</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_sub">sub</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
        value: a.value - b.value,
    }
}
</code></pre>



</details>

<a name="suilend_decimal_saturating_sub"></a>

## Function `saturating_sub`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_saturating_sub">saturating_sub</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_saturating_sub">saturating_sub</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <b>if</b> (a.value &lt; b.value) {
        <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> { value: 0 }
    } <b>else</b> {
        <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> { value: a.value - b.value }
    }
}
</code></pre>



</details>

<a name="suilend_decimal_mul"></a>

## Function `mul`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_mul">mul</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_mul">mul</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
        value: (a.value * b.value) / <a href="../suilend/decimal.md#suilend_decimal_WAD">WAD</a>,
    }
}
</code></pre>



</details>

<a name="suilend_decimal_div"></a>

## Function `div`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_div">div</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_div">div</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
        value: (a.value * <a href="../suilend/decimal.md#suilend_decimal_WAD">WAD</a>) / b.value,
    }
}
</code></pre>



</details>

<a name="suilend_decimal_pow"></a>

## Function `pow`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_pow">pow</a>(b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, e: u64): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_pow">pow</a>(b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>, <b>mut</b> e: u64): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <b>let</b> <b>mut</b> cur_base = b;
    <b>let</b> <b>mut</b> result = <a href="../suilend/decimal.md#suilend_decimal_from">from</a>(1);
    <b>while</b> (e &gt; 0) {
        <b>if</b> (e % 2 == 1) {
            result = <a href="../suilend/decimal.md#suilend_decimal_mul">mul</a>(result, cur_base);
        };
        cur_base = <a href="../suilend/decimal.md#suilend_decimal_mul">mul</a>(cur_base, cur_base);
        e = e / 2;
    };
    result
}
</code></pre>



</details>

<a name="suilend_decimal_floor"></a>

## Function `floor`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_floor">floor</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_floor">floor</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): u64 {
    ((a.value / <a href="../suilend/decimal.md#suilend_decimal_WAD">WAD</a>) <b>as</b> u64)
}
</code></pre>



</details>

<a name="suilend_decimal_saturating_floor"></a>

## Function `saturating_floor`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_saturating_floor">saturating_floor</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_saturating_floor">saturating_floor</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): u64 {
    <b>if</b> (a.value &gt; <a href="../suilend/decimal.md#suilend_decimal_U64_MAX">U64_MAX</a> * <a href="../suilend/decimal.md#suilend_decimal_WAD">WAD</a>) {
        (<a href="../suilend/decimal.md#suilend_decimal_U64_MAX">U64_MAX</a> <b>as</b> u64)
    } <b>else</b> {
        <a href="../suilend/decimal.md#suilend_decimal_floor">floor</a>(a)
    }
}
</code></pre>



</details>

<a name="suilend_decimal_ceil"></a>

## Function `ceil`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_ceil">ceil</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_ceil">ceil</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): u64 {
    (((a.value + <a href="../suilend/decimal.md#suilend_decimal_WAD">WAD</a> - 1) / <a href="../suilend/decimal.md#suilend_decimal_WAD">WAD</a>) <b>as</b> u64)
}
</code></pre>



</details>

<a name="suilend_decimal_eq"></a>

## Function `eq`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_eq">eq</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_eq">eq</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): bool {
    a.value == b.value
}
</code></pre>



</details>

<a name="suilend_decimal_ge"></a>

## Function `ge`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_ge">ge</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_ge">ge</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): bool {
    a.value &gt;= b.value
}
</code></pre>



</details>

<a name="suilend_decimal_gt"></a>

## Function `gt`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_gt">gt</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_gt">gt</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): bool {
    a.value &gt; b.value
}
</code></pre>



</details>

<a name="suilend_decimal_le"></a>

## Function `le`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_le">le</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_le">le</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): bool {
    a.value &lt;= b.value
}
</code></pre>



</details>

<a name="suilend_decimal_lt"></a>

## Function `lt`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_lt">lt</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_lt">lt</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): bool {
    a.value &lt; b.value
}
</code></pre>



</details>

<a name="suilend_decimal_min"></a>

## Function `min`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_min">min</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_min">min</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <b>if</b> (a.value &lt; b.value) {
        a
    } <b>else</b> {
        b
    }
}
</code></pre>



</details>

<a name="suilend_decimal_max"></a>

## Function `max`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_max">max</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/decimal.md#suilend_decimal_max">max</a>(a: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>, b: <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a>): <a href="../suilend/decimal.md#suilend_decimal_Decimal">Decimal</a> {
    <b>if</b> (a.value &gt; b.value) {
        a
    } <b>else</b> {
        b
    }
}
</code></pre>



</details>
