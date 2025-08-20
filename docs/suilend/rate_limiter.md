
<a name="suilend_rate_limiter"></a>

# Module `suilend::rate_limiter`



-  [Struct `RateLimiter`](#suilend_rate_limiter_RateLimiter)
-  [Struct `RateLimiterConfig`](#suilend_rate_limiter_RateLimiterConfig)
-  [Constants](#@Constants_0)
-  [Function `new_config`](#suilend_rate_limiter_new_config)
    -  [Arguments](#@Arguments_1)
    -  [Returns](#@Returns_2)
    -  [Panics](#@Panics_3)
-  [Function `new`](#suilend_rate_limiter_new)
    -  [Arguments](#@Arguments_4)
    -  [Returns](#@Returns_5)
-  [Function `update_internal`](#suilend_rate_limiter_update_internal)
    -  [Arguments](#@Arguments_6)
    -  [Panics](#@Panics_7)
-  [Function `current_outflow`](#suilend_rate_limiter_current_outflow)
    -  [Arguments](#@Arguments_8)
    -  [Returns](#@Returns_9)
    -  [Panics](#@Panics_10)
-  [Function `process_qty`](#suilend_rate_limiter_process_qty)
    -  [Arguments](#@Arguments_11)
    -  [Panics](#@Panics_12)
-  [Function `remaining_outflow`](#suilend_rate_limiter_remaining_outflow)
    -  [Arguments](#@Arguments_13)
    -  [Returns](#@Returns_14)
    -  [Panics](#@Panics_15)


<pre><code><b>use</b> <a href="../suilend/decimal.md#suilend_decimal">suilend::decimal</a>;
</code></pre>



<a name="suilend_rate_limiter_RateLimiter"></a>

## Struct `RateLimiter`

A structure to manage rate limiting for outflows within a specified time window.


<pre><code><b>public</b> <b>struct</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">RateLimiter</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>config: <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiterConfig">suilend::rate_limiter::RateLimiterConfig</a></code>
</dt>
<dd>
 Configuration parameters for the rate limiter.
</dd>
<dt>
<code>prev_qty: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 The sum of all outflows from the previous window.
</dd>
<dt>
<code>window_start: u64</code>
</dt>
<dd>
 The timestamp (in milliseconds) when the current window started.
</dd>
<dt>
<code>cur_qty: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a></code>
</dt>
<dd>
 The sum of all outflows in the current window.
</dd>
</dl>


</details>

<a name="suilend_rate_limiter_RateLimiterConfig"></a>

## Struct `RateLimiterConfig`

Configuration for the rate limiter, defining the window duration and maximum outflow.


<pre><code><b>public</b> <b>struct</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiterConfig">RateLimiterConfig</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>window_duration: u64</code>
</dt>
<dd>
 The duration of the rate limiter window in milliseconds.
</dd>
<dt>
<code>max_outflow: u64</code>
</dt>
<dd>
 The maximum allowed outflow in a single window.
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="suilend_rate_limiter_EInvalidConfig"></a>



<pre><code><b>const</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_EInvalidConfig">EInvalidConfig</a>: u64 = 0;
</code></pre>



<a name="suilend_rate_limiter_EInvalidTime"></a>



<pre><code><b>const</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_EInvalidTime">EInvalidTime</a>: u64 = 1;
</code></pre>



<a name="suilend_rate_limiter_ERateLimitExceeded"></a>



<pre><code><b>const</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_ERateLimitExceeded">ERateLimitExceeded</a>: u64 = 2;
</code></pre>



<a name="suilend_rate_limiter_new_config"></a>

## Function `new_config`

Creates a new rate limiter configuration.


<a name="@Arguments_1"></a>

### Arguments


* <code>window_duration</code> - The duration of the rate limiter window in milliseconds.
* <code>max_outflow</code> - The maximum allowed outflow in a single window.


<a name="@Returns_2"></a>

### Returns


* <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiterConfig">RateLimiterConfig</a></code> - A new configuration instance for the rate limiter.


<a name="@Panics_3"></a>

### Panics


* If <code>window_duration</code> is zero (<code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_EInvalidConfig">EInvalidConfig</a></code>).


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_new_config">new_config</a>(window_duration: u64, max_outflow: u64): <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiterConfig">suilend::rate_limiter::RateLimiterConfig</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_new_config">new_config</a>(window_duration: u64, max_outflow: u64): <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiterConfig">RateLimiterConfig</a> {
    <b>assert</b>!(window_duration &gt; 0, <a href="../suilend/rate_limiter.md#suilend_rate_limiter_EInvalidConfig">EInvalidConfig</a>);
    <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiterConfig">RateLimiterConfig</a> {
        window_duration,
        max_outflow,
    }
}
</code></pre>



</details>

<a name="suilend_rate_limiter_new"></a>

## Function `new`

Creates a new rate limiter with the specified configuration and current time.

Initializes the rate limiter with zero previous and current quantities, setting the
window start to the provided time.


<a name="@Arguments_4"></a>

### Arguments


* <code>config</code> - The <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiterConfig">RateLimiterConfig</a></code> defining the window duration and max outflow.
* <code>cur_time</code> - The current timestamp in milliseconds.


<a name="@Returns_5"></a>

### Returns


* <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">RateLimiter</a></code> - A new rate limiter instance.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_new">new</a>(config: <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiterConfig">suilend::rate_limiter::RateLimiterConfig</a>, cur_time: u64): <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">suilend::rate_limiter::RateLimiter</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_new">new</a>(config: <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiterConfig">RateLimiterConfig</a>, cur_time: u64): <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">RateLimiter</a> {
    <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">RateLimiter</a> {
        config,
        prev_qty: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
        window_start: cur_time,
        cur_qty: <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0),
    }
}
</code></pre>



</details>

<a name="suilend_rate_limiter_update_internal"></a>

## Function `update_internal`

Updates the rate limiter's state based on the current time.

This internal function shifts the window forward if the current time exceeds the
current window's end. It moves the current quantity to the previous quantity and
resets the current quantity if within the next window, or clears both if the time
is beyond two windows.


<a name="@Arguments_6"></a>

### Arguments


* <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a></code> - A mutable reference to the <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">RateLimiter</a></code> to update.
* <code>cur_time</code> - The current timestamp in milliseconds.


<a name="@Panics_7"></a>

### Panics


* If <code>cur_time</code> is less than the rate limiter's <code>window_start</code> (<code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_EInvalidTime">EInvalidTime</a></code>).


<pre><code><b>fun</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_update_internal">update_internal</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: &<b>mut</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">suilend::rate_limiter::RateLimiter</a>, cur_time: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_update_internal">update_internal</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: &<b>mut</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">RateLimiter</a>, cur_time: u64) {
    <b>assert</b>!(cur_time &gt;= <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.window_start, <a href="../suilend/rate_limiter.md#suilend_rate_limiter_EInvalidTime">EInvalidTime</a>);
    // |&lt;-prev window-&gt;|&lt;-cur window (cur_slot is in here)-&gt;|
    <b>if</b> (cur_time &lt; <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.window_start + <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.config.window_duration) {
        <b>return</b>
    } <b>else</b> // |&lt;-prev window-&gt;|&lt;-cur window-&gt;| (cur_slot is in here) |
    <b>if</b> (cur_time &lt; <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.window_start + 2 * <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.config.window_duration) {
        <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.prev_qty = <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.cur_qty;
        <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.window_start =
            <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.window_start + <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.config.window_duration;
        <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.cur_qty = <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0);
    } <b>else</b> // |&lt;-prev window-&gt;|&lt;-cur window-&gt;|&lt;-cur window + 1-&gt;| ... | (cur_slot is in here) |
    {
        <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.prev_qty = <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0);
        <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.window_start = cur_time;
        <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.cur_qty = <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(0);
    }
}
</code></pre>



</details>

<a name="suilend_rate_limiter_current_outflow"></a>

## Function `current_outflow`

Calculates the current outflow for the rate limiter.

This function assumes an even distribution of the previous window's outflow and
combines it with the current window's outflow, weighted by the time remaining in
the previous window. Must be called after <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_update_internal">update_internal</a></code>.


<a name="@Arguments_8"></a>

### Arguments


* <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a></code> - A reference to the <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">RateLimiter</a></code> to query.
* <code>cur_time</code> - The current timestamp in milliseconds.


<a name="@Returns_9"></a>

### Returns


* <code>Decimal</code> - The calculated current outflow, combining weighted previous and current quantities.


<a name="@Panics_10"></a>

### Panics


* If the <code>window_duration</code> is zero, as this would lead to division by zero.


<pre><code><b>fun</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_current_outflow">current_outflow</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: &<a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">suilend::rate_limiter::RateLimiter</a>, cur_time: u64): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_current_outflow">current_outflow</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: &<a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">RateLimiter</a>, cur_time: u64): Decimal {
    // assume the prev_window's outflow is even distributed across the window
    // this isn't <b>true</b>, but it's a good enough approximation
    <b>let</b> prev_weight = div(
        sub(
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.config.window_duration),
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(cur_time - <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.window_start + 1),
        ),
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.config.window_duration),
    );
    add(
        mul(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.prev_qty, prev_weight),
        <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.cur_qty,
    )
}
</code></pre>



</details>

<a name="suilend_rate_limiter_process_qty"></a>

## Function `process_qty`

Processes a new outflow quantity, updating the rate limiter and checking the limit.

Updates the rate limiter's state and adds the specified quantity to the current
window's outflow. It ensures the total outflow does not exceed the configured maximum.


<a name="@Arguments_11"></a>

### Arguments


* <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a></code> - A mutable reference to the <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">RateLimiter</a></code> to update.
* <code>cur_time</code> - The current timestamp in milliseconds.
* <code>qty</code> - The outflow quantity to process, as a <code>Decimal</code>.


<a name="@Panics_12"></a>

### Panics


* If <code>cur_time</code> is less than the rate limiter's <code>window_start</code> (<code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_EInvalidTime">EInvalidTime</a></code>).
* If the total outflow exceeds the configured <code>max_outflow</code> (<code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_ERateLimitExceeded">ERateLimitExceeded</a></code>).
* If the <code>window_duration</code> is zero, as this would lead to division by zero in <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_current_outflow">current_outflow</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_process_qty">process_qty</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: &<b>mut</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">suilend::rate_limiter::RateLimiter</a>, cur_time: u64, qty: <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_process_qty">process_qty</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: &<b>mut</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">RateLimiter</a>, cur_time: u64, qty: Decimal) {
    <a href="../suilend/rate_limiter.md#suilend_rate_limiter_update_internal">update_internal</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>, cur_time);
    <a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.cur_qty = add(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.cur_qty, qty);
    <b>assert</b>!(
        le(
            <a href="../suilend/rate_limiter.md#suilend_rate_limiter_current_outflow">current_outflow</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>, cur_time),
            <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.config.max_outflow),
        ),
        <a href="../suilend/rate_limiter.md#suilend_rate_limiter_ERateLimitExceeded">ERateLimitExceeded</a>,
    );
}
</code></pre>



</details>

<a name="suilend_rate_limiter_remaining_outflow"></a>

## Function `remaining_outflow`

Calculates the remaining outflow capacity in the current window.

Updates the rate limiter's state and returns the difference between the maximum
allowed outflow and the current outflow, ensuring non-negative results.


<a name="@Arguments_13"></a>

### Arguments


* <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a></code> - A mutable reference to the <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">RateLimiter</a></code> to query.
* <code>cur_time</code> - The current timestamp in milliseconds.


<a name="@Returns_14"></a>

### Returns


* <code>Decimal</code> - The remaining outflow capacity in the current window.


<a name="@Panics_15"></a>

### Panics


* If <code>cur_time</code> is less than the rate limiter's <code>window_start</code> (<code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_EInvalidTime">EInvalidTime</a></code>).
* If the <code>window_duration</code> is zero, as this would lead to division by zero in <code><a href="../suilend/rate_limiter.md#suilend_rate_limiter_current_outflow">current_outflow</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_remaining_outflow">remaining_outflow</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: &<b>mut</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">suilend::rate_limiter::RateLimiter</a>, cur_time: u64): <a href="../suilend/decimal.md#suilend_decimal_Decimal">suilend::decimal::Decimal</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_remaining_outflow">remaining_outflow</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>: &<b>mut</b> <a href="../suilend/rate_limiter.md#suilend_rate_limiter_RateLimiter">RateLimiter</a>, cur_time: u64): Decimal {
    <a href="../suilend/rate_limiter.md#suilend_rate_limiter_update_internal">update_internal</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>, cur_time);
    saturating_sub(
        <a href="../suilend/decimal.md#suilend_decimal_from">decimal::from</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>.config.max_outflow),
        <a href="../suilend/rate_limiter.md#suilend_rate_limiter_current_outflow">current_outflow</a>(<a href="../suilend/rate_limiter.md#suilend_rate_limiter">rate_limiter</a>, cur_time),
    )
}
</code></pre>



</details>
