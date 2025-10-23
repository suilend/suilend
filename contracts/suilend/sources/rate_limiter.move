module suilend::rate_limiter {
    use suilend::decimal::{Self, Decimal, add, sub, mul, div, le, saturating_sub};

    const EInvalidConfig: u64 = 0;
    const EInvalidTime: u64 = 1;
    const ERateLimitExceeded: u64 = 2;

    /// A structure to manage rate limiting for outflows within a specified time window.
    public struct RateLimiter has copy, drop, store {
        /// Configuration parameters for the rate limiter.
        config: RateLimiterConfig,
        /// The sum of all outflows from the previous window.
        prev_qty: Decimal,
        /// The timestamp (in milliseconds) when the current window started.
        window_start: u64,
        /// The sum of all outflows in the current window.
        cur_qty: Decimal,
    }

    /// Configuration for the rate limiter, defining the window duration and maximum outflow.
    public struct RateLimiterConfig has copy, drop, store {
        /// The duration of the rate limiter window in milliseconds.
        window_duration: u64,
        /// The maximum allowed outflow in a single window.
        max_outflow: u64,
    }

    /// Creates a new rate limiter configuration.
    ///
    /// # Arguments
    ///
    /// * `window_duration` - The duration of the rate limiter window in milliseconds.
    /// * `max_outflow` - The maximum allowed outflow in a single window.
    ///
    /// # Returns
    ///
    /// * `RateLimiterConfig` - A new configuration instance for the rate limiter.
    ///
    /// # Panics
    ///
    /// * If `window_duration` is zero (`EInvalidConfig`).
    public fun new_config(window_duration: u64, max_outflow: u64): RateLimiterConfig {
        assert!(window_duration > 0, EInvalidConfig);
        RateLimiterConfig {
            window_duration,
            max_outflow,
        }
    }

    /// Creates a new rate limiter with the specified configuration and current time.
    ///
    /// Initializes the rate limiter with zero previous and current quantities, setting the
    /// window start to the provided time.
    ///
    /// # Arguments
    ///
    /// * `config` - The `RateLimiterConfig` defining the window duration and max outflow.
    /// * `cur_time` - The current timestamp in milliseconds.
    ///
    /// # Returns
    ///
    /// * `RateLimiter` - A new rate limiter instance.
    public fun new(config: RateLimiterConfig, cur_time: u64): RateLimiter {
        RateLimiter {
            config,
            prev_qty: decimal::from(0),
            window_start: cur_time,
            cur_qty: decimal::from(0),
        }
    }

    /// Updates the rate limiter's state based on the current time.
    ///
    /// This internal function shifts the window forward if the current time exceeds the
    /// current window's end. It moves the current quantity to the previous quantity and
    /// resets the current quantity if within the next window, or clears both if the time
    /// is beyond two windows.
    ///
    /// # Arguments
    ///
    /// * `rate_limiter` - A mutable reference to the `RateLimiter` to update.
    /// * `cur_time` - The current timestamp in milliseconds.
    ///
    /// # Panics
    ///
    /// * If `cur_time` is less than the rate limiter's `window_start` (`EInvalidTime`).
    #[allow(lint(unneeded_return))]
    fun update_internal(rate_limiter: &mut RateLimiter, cur_time: u64) {
        assert!(cur_time >= rate_limiter.window_start, EInvalidTime);

        // |<-prev window->|<-cur window (cur_slot is in here)->|
        if (cur_time < rate_limiter.window_start + rate_limiter.config.window_duration) {
            return
        } else // |<-prev window->|<-cur window->| (cur_slot is in here) |
        if (cur_time < rate_limiter.window_start + 2 * rate_limiter.config.window_duration) {
            rate_limiter.prev_qty = rate_limiter.cur_qty;
            rate_limiter.window_start =
                rate_limiter.window_start + rate_limiter.config.window_duration;
            rate_limiter.cur_qty = decimal::from(0);
        } else // |<-prev window->|<-cur window->|<-cur window + 1->| ... | (cur_slot is in here) |
        {
            rate_limiter.prev_qty = decimal::from(0);
            rate_limiter.window_start = cur_time;
            rate_limiter.cur_qty = decimal::from(0);
        }
    }

    /// Calculates the current outflow for the rate limiter.
    ///
    /// This function assumes an even distribution of the previous window's outflow and
    /// combines it with the current window's outflow, weighted by the time remaining in
    /// the previous window. Must be called after `update_internal`.
    ///
    /// # Arguments
    ///
    /// * `rate_limiter` - A reference to the `RateLimiter` to query.
    /// * `cur_time` - The current timestamp in milliseconds.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The calculated current outflow, combining weighted previous and current quantities.
    ///
    /// # Panics
    ///
    /// * If the `window_duration` is zero, as this would lead to division by zero.
    fun current_outflow(rate_limiter: &RateLimiter, cur_time: u64): Decimal {
        // assume the prev_window's outflow is even distributed across the window
        // this isn't true, but it's a good enough approximation
        let prev_weight = div(
            sub(
                decimal::from(rate_limiter.config.window_duration),
                decimal::from(cur_time - rate_limiter.window_start + 1),
            ),
            decimal::from(rate_limiter.config.window_duration),
        );

        add(
            mul(rate_limiter.prev_qty, prev_weight),
            rate_limiter.cur_qty,
        )
    }

    /// Processes a new outflow quantity, updating the rate limiter and checking the limit.
    ///
    /// Updates the rate limiter's state and adds the specified quantity to the current
    /// window's outflow. It ensures the total outflow does not exceed the configured maximum.
    ///
    /// # Arguments
    ///
    /// * `rate_limiter` - A mutable reference to the `RateLimiter` to update.
    /// * `cur_time` - The current timestamp in milliseconds.
    /// * `qty` - The outflow quantity to process, as a `Decimal`.
    ///
    /// # Panics
    ///
    /// * If `cur_time` is less than the rate limiter's `window_start` (`EInvalidTime`).
    /// * If the total outflow exceeds the configured `max_outflow` (`ERateLimitExceeded`).
    /// * If the `window_duration` is zero, as this would lead to division by zero in `current_outflow`.
    public fun process_qty(rate_limiter: &mut RateLimiter, cur_time: u64, qty: Decimal) {
        update_internal(rate_limiter, cur_time);

        rate_limiter.cur_qty = add(rate_limiter.cur_qty, qty);

        assert!(
            le(
                current_outflow(rate_limiter, cur_time),
                decimal::from(rate_limiter.config.max_outflow),
            ),
            ERateLimitExceeded,
        );
    }

    /// Calculates the remaining outflow capacity in the current window.
    ///
    /// Updates the rate limiter's state and returns the difference between the maximum
    /// allowed outflow and the current outflow, ensuring non-negative results.
    ///
    /// # Arguments
    ///
    /// * `rate_limiter` - A mutable reference to the `RateLimiter` to query.
    /// * `cur_time` - The current timestamp in milliseconds.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The remaining outflow capacity in the current window.
    ///
    /// # Panics
    ///
    /// * If `cur_time` is less than the rate limiter's `window_start` (`EInvalidTime`).
    /// * If the `window_duration` is zero, as this would lead to division by zero in `current_outflow`.
    public fun remaining_outflow(rate_limiter: &mut RateLimiter, cur_time: u64): Decimal {
        update_internal(rate_limiter, cur_time);
        saturating_sub(
            decimal::from(rate_limiter.config.max_outflow),
            current_outflow(rate_limiter, cur_time),
        )
    }

    #[test]
    fun test_rate_limiter() {
        let mut rate_limiter = new(
            RateLimiterConfig {
                window_duration: 10,
                max_outflow: 100,
            },
            0,
        );

        process_qty(&mut rate_limiter, 0, decimal::from(100));

        let mut i = 0;
        while (i < 10) {
            assert!(current_outflow(&rate_limiter, i) == decimal::from(100));
            i = i + 1;
        };

        i = 10;
        while (i < 19) {
            process_qty(&mut rate_limiter, i, decimal::from(10));
            assert!(current_outflow(&rate_limiter, i) == decimal::from(100));
            assert!(remaining_outflow(&mut rate_limiter, i) == decimal::from(0));
            i = i + 1;
        };

        process_qty(&mut rate_limiter, 100, decimal::from(100));
    }
}
