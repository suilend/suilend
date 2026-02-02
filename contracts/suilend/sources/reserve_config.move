/// parameters for a Reserve.
module suilend::reserve_config {
    use sui::bag::{Self, Bag};
    use suilend::decimal::{Self, Decimal, add, sub, mul, div, ge, le};

    #[test_only]
    use sui::test_scenario::{Self};

    const EInvalidReserveConfig: u64 = 0;
    const EInvalidUtil: u64 = 1;

    /// Configuration parameters for a reserve in the lending market.
    public struct ReserveConfig has store {
        // Risk parameters
        //
        // Loan-to-value percentage for opening positions
        open_ltv_pct: u8,
        // Loan-to-value percentage for closing positions
        close_ltv_pct: u8,
        // Maximum close LTV percentage (unused)
        max_close_ltv_pct: u8,
        // Borrow weight in basis points
        borrow_weight_bps: u64,
        // Limits
        //
        // Maximum deposit amount in token units
        deposit_limit: u64,
        // Maximum borrow amount in token units
        borrow_limit: u64,
        // Liquidation parameters
        //
        // Bonus for liquidators in basis points
        liquidation_bonus_bps: u64,
        // Maximum liquidation bonus (unused)
        max_liquidation_bonus_bps: u64,
        // Maximum deposit amount in USD
        deposit_limit_usd: u64,
        // Maximum borrow amount in USD
        borrow_limit_usd: u64,
        // Interest rate parameters
        //
        // Utilization rates for interest rate calculation
        interest_rate_utils: vector<u8>,
        // Annual percentage rates corresponding to utilizations
        interest_rate_aprs: vector<u64>,
        // Fees
        //
        // Fee for borrowing in basis points
        borrow_fee_bps: u64,
        // Spread fee in basis points
        spread_fee_bps: u64,
        // Protocol fee on liquidations in basis points
        protocol_liquidation_fee_bps: u64,
        // Isolation flag
        // If true, asset cannot be used as collateral and can only be borrowed in isolation
        isolated: bool,
        // Unused fields
        //
        // Open attributed borrow limit in USD
        open_attributed_borrow_limit_usd: u64,
        // Close attributed borrow limit in USD
        close_attributed_borrow_limit_usd: u64,
        // Additional fields for extensibility
        additional_fields: Bag,
    }

    /// Builder struct for constructing a ReserveConfig.
    public struct ReserveConfigBuilder has store {
        fields: Bag,
    }

    /// Creates a new reserve configuration with the specified parameters.
    ///
    /// Validates the configuration to ensure it meets all required constraints before returning.
    ///
    /// # Arguments
    ///
    /// * `open_ltv_pct` - Loan-to-value percentage for opening positions (0-100).
    /// * `close_ltv_pct` - Loan-to-value percentage for closing positions (0-100).
    /// * `max_close_ltv_pct` - Maximum close LTV percentage (unused, 0-100).
    /// * `borrow_weight_bps` - Borrow weight in basis points (minimum 10,000).
    /// * `deposit_limit` - Maximum deposit amount in token units.
    /// * `borrow_limit` - Maximum borrow amount in token units.
    /// * `liquidation_bonus_bps` - Bonus for liquidators in basis points.
    /// * `max_liquidation_bonus_bps` - Maximum liquidation bonus in basis points (unused).
    /// * `deposit_limit_usd` - Maximum deposit amount in USD.
    /// * `borrow_limit_usd` - Maximum borrow amount in USD.
    /// * `borrow_fee_bps` - Fee for borrowing in basis points (maximum 10,000).
    /// * `spread_fee_bps` - Spread fee in basis points (maximum 10,000).
    /// * `protocol_liquidation_fee_bps` - Protocol fee on liquidations in basis points.
    /// * `interest_rate_utils` - Vector of utilization rates for interest rate calculation (0-100).
    /// * `interest_rate_aprs` - Vector of APRs corresponding to utilization rates.
    /// * `isolated` - If true, asset is isolated (cannot be collateral, only borrowed in isolation).
    /// * `open_attributed_borrow_limit_usd` - Open attributed borrow limit in USD (unused).
    /// * `close_attributed_borrow_limit_usd` - Close attributed borrow limit in USD (unused).
    ///
    /// # Returns
    ///
    /// * `ReserveConfig` - A validated reserve configuration.
    ///
    /// # Panics
    ///
    /// * If `open_ltv_pct`, `close_ltv_pct`, or `max_close_ltv_pct` exceeds 100 (`EInvalidReserveConfig`).
    /// * If `open_ltv_pct` is greater than `close_ltv_pct` (`EInvalidReserveConfig`).
    /// * If `close_ltv_pct` is greater than `max_close_ltv_pct` (`EInvalidReserveConfig`).
    /// * If `borrow_weight_bps` is less than 10,000 (`EInvalidReserveConfig`).
    /// * If `liquidation_bonus_bps` exceeds `max_liquidation_bonus_bps` (`EInvalidReserveConfig`).
    /// * If `liquidation_bonus_bps + protocol_liquidation_fee_bps` exceeds 2,000 (`EInvalidReserveConfig`).
    /// * If `isolated` is true and `open_ltv_pct` or `close_ltv_pct` is non-zero (`EInvalidReserveConfig`).
    /// * If `borrow_fee_bps` or `spread_fee_bps` exceeds 10,000 (`EInvalidReserveConfig`).
    /// * If `open_attributed_borrow_limit_usd` exceeds `close_attributed_borrow_limit_usd` (`EInvalidReserveConfig`).
    /// * If `interest_rate_utils` has fewer than 2 elements, does not start with 0, or end with 100 (`EInvalidReserveConfig`).
    /// * If `interest_rate_utils` and `interest_rate_aprs` have different lengths (`EInvalidReserveConfig`).
    /// * If `interest_rate_utils` is not strictly increasing or `interest_rate_aprs` is not monotonically increasing (`EInvalidReserveConfig`).
    public fun create_reserve_config(
        open_ltv_pct: u8,
        close_ltv_pct: u8,
        max_close_ltv_pct: u8,
        borrow_weight_bps: u64,
        deposit_limit: u64,
        borrow_limit: u64,
        liquidation_bonus_bps: u64,
        max_liquidation_bonus_bps: u64,
        deposit_limit_usd: u64,
        borrow_limit_usd: u64,
        borrow_fee_bps: u64,
        spread_fee_bps: u64,
        protocol_liquidation_fee_bps: u64,
        interest_rate_utils: vector<u8>,
        interest_rate_aprs: vector<u64>,
        isolated: bool,
        open_attributed_borrow_limit_usd: u64,
        close_attributed_borrow_limit_usd: u64,
        ctx: &mut TxContext,
    ): ReserveConfig {
        let config = ReserveConfig {
            open_ltv_pct,
            close_ltv_pct,
            max_close_ltv_pct,
            borrow_weight_bps,
            deposit_limit,
            borrow_limit,
            liquidation_bonus_bps,
            max_liquidation_bonus_bps,
            deposit_limit_usd,
            borrow_limit_usd,
            interest_rate_utils,
            interest_rate_aprs,
            borrow_fee_bps,
            spread_fee_bps,
            protocol_liquidation_fee_bps,
            isolated,
            open_attributed_borrow_limit_usd,
            close_attributed_borrow_limit_usd,
            additional_fields: bag::new(ctx),
        };

        validate_reserve_config(&config);
        config
    }

    /// Validates the reserve configuration to ensure it meets all constraints.
    ///
    /// Checks various parameters for correctness, including LTVs, borrow weight, liquidation bonuses,
    /// fees, and interest rate vectors.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to validate.
    ///
    /// # Panics
    ///
    /// * If `open_ltv_pct`, `close_ltv_pct`, or `max_close_ltv_pct` exceeds 100 (`EInvalidReserveConfig`).
    /// * If `open_ltv_pct` is greater than `close_ltv_pct` (`EInvalidReserveConfig`).
    /// * If `close_ltv_pct` is greater than `max_close_ltv_pct` (`EInvalidReserveConfig`).
    /// * If `borrow_weight_bps` is less than 10,000 (`EInvalidReserveConfig`).
    /// * If `liquidation_bonus_bps` exceeds `max_liquidation_bonus_bps` (`EInvalidReserveConfig`).
    /// * If `liquidation_bonus_bps + protocol_liquidation_fee_bps` exceeds 2,000 (`EInvalidReserveConfig`).
    /// * If `isolated` is true and `open_ltv_pct` or `close_ltv_pct` is non-zero (`EInvalidReserveConfig`).
    /// * If `borrow_fee_bps` or `spread_fee_bps` exceeds 10,000 (`EInvalidReserveConfig`).
    /// * If `open_attributed_borrow_limit_usd` exceeds `close_attributed_borrow_limit_usd` (`EInvalidReserveConfig`).
    /// * If `interest_rate_utils` has fewer than 2 elements, does not start with 0, or end with 100 (`EInvalidReserveConfig`).
    /// * If `interest_rate_utils` and `interest_rate_aprs` have different lengths (`EInvalidReserveConfig`).
    /// * If `interest_rate_utils` is not strictly increasing or `interest_rate_aprs` is not monotonically increasing (`EInvalidReserveConfig`).
    fun validate_reserve_config(config: &ReserveConfig) {
        assert!(config.open_ltv_pct <= 100, EInvalidReserveConfig);
        assert!(config.close_ltv_pct <= 100, EInvalidReserveConfig);
        assert!(config.max_close_ltv_pct <= 100, EInvalidReserveConfig);

        assert!(config.open_ltv_pct <= config.close_ltv_pct, EInvalidReserveConfig);
        assert!(config.close_ltv_pct <= config.max_close_ltv_pct, EInvalidReserveConfig);

        assert!(config.borrow_weight_bps >= 10_000, EInvalidReserveConfig);
        assert!(
            config.liquidation_bonus_bps <= config.max_liquidation_bonus_bps,
            EInvalidReserveConfig,
        );
        assert!(
            config.max_liquidation_bonus_bps + config.protocol_liquidation_fee_bps <= 2_000,
            EInvalidReserveConfig,
        );

        if (config.isolated) {
            assert!(config.open_ltv_pct == 0 && config.close_ltv_pct == 0, EInvalidReserveConfig);
        };

        assert!(config.borrow_fee_bps <= 10_000, EInvalidReserveConfig);
        assert!(config.spread_fee_bps <= 10_000, EInvalidReserveConfig);

        assert!(
            config.open_attributed_borrow_limit_usd <= config.close_attributed_borrow_limit_usd,
            EInvalidReserveConfig,
        );

        validate_utils_and_aprs(&config.interest_rate_utils, &config.interest_rate_aprs);
    }

    /// Validates the interest rate utilization and APR vectors.
    ///
    /// Ensures the utilization rates are strictly increasing, start at 0, end at 100, and
    /// match the length of the APR vector, which must be monotonically increasing.
    ///
    /// # Arguments
    ///
    /// * `utils` - A reference to the vector of utilization rates (0-100).
    /// * `aprs` - A reference to the vector of APRs in basis points.
    ///
    /// # Panics
    ///
    /// * If `utils` has fewer than 2 elements (`EInvalidReserveConfig`).
    /// * If `utils` and `aprs` have different lengths (`EInvalidReserveConfig`).
    /// * If `utils` does not start with 0 or end with 100 (`EInvalidReserveConfig`).
    /// * If `utils` is not strictly increasing (`EInvalidReserveConfig`).
    /// * If `aprs` is not monotonically increasing (`EInvalidReserveConfig`).
    fun validate_utils_and_aprs(utils: &vector<u8>, aprs: &vector<u64>) {
        assert!(vector::length(utils) >= 2, EInvalidReserveConfig);
        assert!(vector::length(utils) == vector::length(aprs), EInvalidReserveConfig);

        let length = vector::length(utils);
        assert!(*vector::borrow(utils, 0) == 0, EInvalidReserveConfig);
        assert!(*vector::borrow(utils, length-1) == 100, EInvalidReserveConfig);

        // check that:
        // - utils is strictly increasing
        // - aprs is monotonically increasing
        let mut i = 1;
        while (i < length) {
            assert!(
                *vector::borrow(utils, i - 1) < *vector::borrow(utils, i),
                EInvalidReserveConfig,
            );
            assert!(
                *vector::borrow(aprs, i - 1) <= *vector::borrow(aprs, i),
                EInvalidReserveConfig,
            );

            i = i + 1;
        }
    }

    /// Gets the open loan-to-value (LTV) ratio as a decimal.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The open LTV ratio as a decimal (e.g., 50% = 0.5).
    public fun open_ltv(config: &ReserveConfig): Decimal {
        decimal::from_percent(config.open_ltv_pct)
    }

    /// Gets the close loan-to-value (LTV) ratio as a decimal.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The close LTV ratio as a decimal (e.g., 50% = 0.5).
    public fun close_ltv(config: &ReserveConfig): Decimal {
        decimal::from_percent(config.close_ltv_pct)
    }

    /// Gets the borrow weight as a decimal.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The borrow weight as a decimal (e.g., 10,000 bps = 1.0).
    public fun borrow_weight(config: &ReserveConfig): Decimal {
        decimal::from_bps(config.borrow_weight_bps)
    }

    /// Gets the deposit limit in token units.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The maximum deposit amount in token units.
    public fun deposit_limit(config: &ReserveConfig): u64 {
        config.deposit_limit
    }

    /// Gets the borrow limit in token units.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The maximum borrow amount in token units.
    public fun borrow_limit(config: &ReserveConfig): u64 {
        config.borrow_limit
    }

    /// Gets the liquidation bonus as a decimal.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The liquidation bonus as a decimal (e.g., 500 bps = 0.05).
    public fun liquidation_bonus(config: &ReserveConfig): Decimal {
        decimal::from_bps(config.liquidation_bonus_bps)
    }

    /// Gets the deposit limit in USD.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The maximum deposit amount in USD.
    public fun deposit_limit_usd(config: &ReserveConfig): u64 {
        config.deposit_limit_usd
    }

    /// Gets the borrow limit in USD.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The maximum borrow amount in USD.
    public fun borrow_limit_usd(config: &ReserveConfig): u64 {
        config.borrow_limit_usd
    }

    /// Gets the borrow fee as a decimal.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The borrow fee as a decimal (e.g., 10 bps = 0.001).
    public fun borrow_fee(config: &ReserveConfig): Decimal {
        decimal::from_bps(config.borrow_fee_bps)
    }

    /// Gets the protocol liquidation fee as a decimal.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The protocol liquidation fee as a decimal (e.g., 300 bps = 0.03).
    public fun protocol_liquidation_fee(config: &ReserveConfig): Decimal {
        decimal::from_bps(config.protocol_liquidation_fee_bps)
    }

    /// Gets the isolation status of the reserve.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to query.
    ///
    /// # Returns
    ///
    /// * `bool` - True if the asset is isolated, false otherwise.
    public fun isolated(config: &ReserveConfig): bool {
        config.isolated
    }

    /// Gets the spread fee as a decimal.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The spread fee as a decimal (e.g., 2000 bps = 0.2).
    public fun spread_fee(config: &ReserveConfig): Decimal {
        decimal::from_bps(config.spread_fee_bps)
    }

    /// Calculates the annual percentage rate (APR) based on the current utilization.
    ///
    /// Interpolates the APR based on the utilization rate using the provided `interest_rate_utils`
    /// and `interest_rate_aprs` vectors.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` containing the interest rate data.
    /// * `cur_util` - The current utilization rate as a decimal (0 to 1).
    ///
    /// # Returns
    ///
    /// * `Decimal` - The calculated APR as a decimal.
    ///
    /// # Panics
    ///
    /// * If `cur_util` is greater than 1 (`EInvalidUtil`).
    /// * If the interpolation logic fails due to invalid configuration (`EInvalidReserveConfig`).
    public fun calculate_apr(config: &ReserveConfig, cur_util: Decimal): Decimal {
        assert!(le(cur_util, decimal::from(1)), EInvalidUtil);

        let length = vector::length(&config.interest_rate_utils);

        let mut i = 1;
        while (i < length) {
            let left_util = decimal::from_percent(
                *vector::borrow(&config.interest_rate_utils, i - 1),
            );
            let right_util = decimal::from_percent(*vector::borrow(&config.interest_rate_utils, i));

            if (ge(cur_util, left_util) && le(cur_util, right_util)) {
                let left_apr = decimal::from_bps(
                    *vector::borrow(&config.interest_rate_aprs, i - 1),
                );
                let right_apr = decimal::from_bps(*vector::borrow(&config.interest_rate_aprs, i));

                let weight = div(
                    sub(cur_util, left_util),
                    sub(right_util, left_util),
                );

                let apr_diff = sub(right_apr, left_apr);
                return add(
                        left_apr,
                        mul(weight, apr_diff),
                    )
            };

            i = i + 1;
        };

        // should never get here
        assert!(1 == 0, EInvalidReserveConfig);
        decimal::from(0)
    }

    /// Calculates the supply APR based on the current utilization and borrow APR.
    ///
    /// Applies the spread fee to the borrow APR and scales it by the utilization rate.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` containing the spread fee.
    /// * `cur_util` - The current utilization rate as a decimal (0 to 1).
    /// * `borrow_apr` - The borrow APR as a decimal.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The calculated supply APR as a decimal.
    public fun calculate_supply_apr(
        config: &ReserveConfig,
        cur_util: Decimal,
        borrow_apr: Decimal,
    ): Decimal {
        let spread_fee = spread_fee(config);
        mul(mul(sub(decimal::from(1), spread_fee), borrow_apr), cur_util)
    }

    /// Destroys a reserve configuration, ensuring the additional fields bag is empty.
    ///
    /// # Arguments
    ///
    /// * `config` - The `ReserveConfig` to destroy.
    ///
    /// # Panics
    ///
    /// * If the `additional_fields` bag is not empty.
    public fun destroy(config: ReserveConfig) {
        let ReserveConfig {
            open_ltv_pct: _,
            close_ltv_pct: _,
            max_close_ltv_pct: _,
            borrow_weight_bps: _,
            deposit_limit: _,
            borrow_limit: _,
            liquidation_bonus_bps: _,
            max_liquidation_bonus_bps: _,
            deposit_limit_usd: _,
            borrow_limit_usd: _,
            interest_rate_utils: _,
            interest_rate_aprs: _,
            borrow_fee_bps: _,
            spread_fee_bps: _,
            protocol_liquidation_fee_bps: _,
            isolated: _,
            open_attributed_borrow_limit_usd: _,
            close_attributed_borrow_limit_usd: _,
            additional_fields,
        } = config;

        bag::destroy_empty(additional_fields);
    }

    /// Creates a new reserve configuration builder from an existing configuration.
    ///
    /// Initializes a `ReserveConfigBuilder` with the fields from the provided `ReserveConfig`.
    ///
    /// # Arguments
    ///
    /// * `config` - A reference to the `ReserveConfig` to initialize the builder from.
    ///
    /// # Returns
    ///
    /// * `ReserveConfigBuilder` - A new builder initialized with the config's fields.
    public fun from(config: &ReserveConfig, ctx: &mut TxContext): ReserveConfigBuilder {
        let mut builder = ReserveConfigBuilder { fields: bag::new(ctx) };
        set_open_ltv_pct(&mut builder, config.open_ltv_pct);
        set_close_ltv_pct(&mut builder, config.close_ltv_pct);
        set_max_close_ltv_pct(&mut builder, config.max_close_ltv_pct);
        set_borrow_weight_bps(&mut builder, config.borrow_weight_bps);
        set_deposit_limit(&mut builder, config.deposit_limit);
        set_borrow_limit(&mut builder, config.borrow_limit);
        set_liquidation_bonus_bps(&mut builder, config.liquidation_bonus_bps);
        set_max_liquidation_bonus_bps(&mut builder, config.max_liquidation_bonus_bps);
        set_deposit_limit_usd(&mut builder, config.deposit_limit_usd);
        set_borrow_limit_usd(&mut builder, config.borrow_limit_usd);

        set_interest_rate_utils(&mut builder, config.interest_rate_utils);
        set_interest_rate_aprs(&mut builder, config.interest_rate_aprs);

        set_borrow_fee_bps(&mut builder, config.borrow_fee_bps);
        set_spread_fee_bps(&mut builder, config.spread_fee_bps);
        set_protocol_liquidation_fee_bps(&mut builder, config.protocol_liquidation_fee_bps);
        set_isolated(&mut builder, config.isolated);
        set_open_attributed_borrow_limit_usd(&mut builder, config.open_attributed_borrow_limit_usd);
        set_close_attributed_borrow_limit_usd(
            &mut builder,
            config.close_attributed_borrow_limit_usd,
        );

        builder
    }

    /// Sets a field in the reserve configuration builder.
    ///
    /// Updates an existing field or adds a new one to the builder's fields bag.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `field` - The key for the field to set.
    /// * `value` - The value to set for the field.
    fun set<K: copy + drop + store, V: store + drop>(
        builder: &mut ReserveConfigBuilder,
        field: K,
        value: V,
    ) {
        if (bag::contains(&builder.fields, field)) {
            let val: &mut V = bag::borrow_mut(&mut builder.fields, field);
            *val = value;
        } else {
            bag::add(&mut builder.fields, field, value);
        }
    }

    /// Sets the open LTV percentage in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `open_ltv_pct` - The open LTV percentage to set.
    public fun set_open_ltv_pct(builder: &mut ReserveConfigBuilder, open_ltv_pct: u8) {
        set(builder, b"open_ltv_pct", open_ltv_pct);
    }

    /// Sets the close LTV percentage in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `close_ltv_pct` - The close LTV percentage to set.
    public fun set_close_ltv_pct(builder: &mut ReserveConfigBuilder, close_ltv_pct: u8) {
        set(builder, b"close_ltv_pct", close_ltv_pct);
    }

    /// Sets the maximum close LTV percentage in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `max_close_ltv_pct` - The maximum close LTV percentage to set.
    public fun set_max_close_ltv_pct(builder: &mut ReserveConfigBuilder, max_close_ltv_pct: u8) {
        set(builder, b"max_close_ltv_pct", max_close_ltv_pct);
    }

    /// Sets the borrow weight in basis points in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `borrow_weight_bps` - The borrow weight in basis points to set.
    public fun set_borrow_weight_bps(builder: &mut ReserveConfigBuilder, borrow_weight_bps: u64) {
        set(builder, b"borrow_weight_bps", borrow_weight_bps);
    }

    /// Sets the deposit limit in token units in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `deposit_limit` - The deposit limit in token units to set.
    public fun set_deposit_limit(builder: &mut ReserveConfigBuilder, deposit_limit: u64) {
        set(builder, b"deposit_limit", deposit_limit);
    }

    /// Sets the borrow limit in token units in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `borrow_limit` - The borrow limit in token units to set.
    public fun set_borrow_limit(builder: &mut ReserveConfigBuilder, borrow_limit: u64) {
        set(builder, b"borrow_limit", borrow_limit);
    }

    /// Sets the liquidation bonus in basis points in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `liquidation_bonus_bps` - The liquidation bonus in basis points to set.
    public fun set_liquidation_bonus_bps(
        builder: &mut ReserveConfigBuilder,
        liquidation_bonus_bps: u64,
    ) {
        set(builder, b"liquidation_bonus_bps", liquidation_bonus_bps);
    }

    /// Sets the maximum liquidation bonus in basis points in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `max_liquidation_bonus_bps` - The maximum liquidation bonus in basis points to set.
    public fun set_max_liquidation_bonus_bps(
        builder: &mut ReserveConfigBuilder,
        max_liquidation_bonus_bps: u64,
    ) {
        set(builder, b"max_liquidation_bonus_bps", max_liquidation_bonus_bps);
    }

    /// Sets the deposit limit in USD in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `deposit_limit_usd` - The deposit limit in USD to set.
    public fun set_deposit_limit_usd(builder: &mut ReserveConfigBuilder, deposit_limit_usd: u64) {
        set(builder, b"deposit_limit_usd", deposit_limit_usd);
    }

    /// Sets the borrow limit in USD in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `borrow_limit_usd` - The borrow limit in USD to set.
    public fun set_borrow_limit_usd(builder: &mut ReserveConfigBuilder, borrow_limit_usd: u64) {
        set(builder, b"borrow_limit_usd", borrow_limit_usd);
    }

    /// Sets the interest rate utilization vector in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `interest_rate_utils` - The vector of utilization rates to set.
    public fun set_interest_rate_utils(
        builder: &mut ReserveConfigBuilder,
        interest_rate_utils: vector<u8>,
    ) {
        set(builder, b"interest_rate_utils", interest_rate_utils);
    }

    /// Sets the interest rate APR vector in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `interest_rate_aprs` - The vector of APRs to set.
    public fun set_interest_rate_aprs(
        builder: &mut ReserveConfigBuilder,
        interest_rate_aprs: vector<u64>,
    ) {
        set(builder, b"interest_rate_aprs", interest_rate_aprs);
    }

    /// Sets the borrow fee in basis points in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `borrow_fee_bps` - The borrow fee in basis points to set.
    public fun set_borrow_fee_bps(builder: &mut ReserveConfigBuilder, borrow_fee_bps: u64) {
        set(builder, b"borrow_fee_bps", borrow_fee_bps);
    }

    /// Sets the spread fee in basis points in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `spread_fee_bps` - The spread fee in basis points to set.
    public fun set_spread_fee_bps(builder: &mut ReserveConfigBuilder, spread_fee_bps: u64) {
        set(builder, b"spread_fee_bps", spread_fee_bps);
    }

    /// Sets the protocol liquidation fee in basis points in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `protocol_liquidation_fee_bps` - The protocol liquidation fee in basis points to set.
    public fun set_protocol_liquidation_fee_bps(
        builder: &mut ReserveConfigBuilder,
        protocol_liquidation_fee_bps: u64,
    ) {
        set(builder, b"protocol_liquidation_fee_bps", protocol_liquidation_fee_bps);
    }

    /// Sets the isolation status in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `isolated` - The isolation status to set.
    public fun set_isolated(builder: &mut ReserveConfigBuilder, isolated: bool) {
        set(builder, b"isolated", isolated);
    }

    /// Sets the open attributed borrow limit in USD in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `open_attributed_borrow_limit_usd` - The open attributed borrow limit in USD to set.
    public fun set_open_attributed_borrow_limit_usd(
        builder: &mut ReserveConfigBuilder,
        open_attributed_borrow_limit_usd: u64,
    ) {
        set(builder, b"open_attributed_borrow_limit_usd", open_attributed_borrow_limit_usd);
    }

    /// Sets the close attributed borrow limit in USD in the builder.
    ///
    /// # Arguments
    ///
    /// * `builder` - A mutable reference to the `ReserveConfigBuilder`.
    /// * `close_attributed_borrow_limit_usd` - The close attributed borrow limit in USD to set.
    public fun set_close_attributed_borrow_limit_usd(
        builder: &mut ReserveConfigBuilder,
        close_attributed_borrow_limit_usd: u64,
    ) {
        set(builder, b"close_attributed_borrow_limit_usd", close_attributed_borrow_limit_usd);
    }

    /// Builds a reserve configuration from the builder.
    ///
    /// Constructs a `ReserveConfig` by extracting all fields from the builder's bag and
    /// validating the resulting configuration.
    ///
    /// # Arguments
    ///
    /// * `builder` - The `ReserveConfigBuilder` to build from.
    ///
    /// # Returns
    ///
    /// * `ReserveConfig` - The constructed and validated reserve configuration.
    ///
    /// # Panics
    ///
    /// * If any required field is missing from the builder's bag.
    /// * If the constructed configuration fails validation (see `validate_reserve_config` for details).
    public fun build(mut builder: ReserveConfigBuilder, tx_context: &mut TxContext): ReserveConfig {
        let config = create_reserve_config(
            bag::remove(&mut builder.fields, b"open_ltv_pct"),
            bag::remove(&mut builder.fields, b"close_ltv_pct"),
            bag::remove(&mut builder.fields, b"max_close_ltv_pct"),
            bag::remove(&mut builder.fields, b"borrow_weight_bps"),
            bag::remove(&mut builder.fields, b"deposit_limit"),
            bag::remove(&mut builder.fields, b"borrow_limit"),
            bag::remove(&mut builder.fields, b"liquidation_bonus_bps"),
            bag::remove(&mut builder.fields, b"max_liquidation_bonus_bps"),
            bag::remove(&mut builder.fields, b"deposit_limit_usd"),
            bag::remove(&mut builder.fields, b"borrow_limit_usd"),
            bag::remove(&mut builder.fields, b"borrow_fee_bps"),
            bag::remove(&mut builder.fields, b"spread_fee_bps"),
            bag::remove(&mut builder.fields, b"protocol_liquidation_fee_bps"),
            bag::remove(&mut builder.fields, b"interest_rate_utils"),
            bag::remove(&mut builder.fields, b"interest_rate_aprs"),
            bag::remove(&mut builder.fields, b"isolated"),
            bag::remove(&mut builder.fields, b"open_attributed_borrow_limit_usd"),
            bag::remove(&mut builder.fields, b"close_attributed_borrow_limit_usd"),
            tx_context,
        );

        let ReserveConfigBuilder { fields } = builder;
        bag::destroy_empty(fields);
        config
    }

    // === Tests ==

    #[test]
    fun test_calculate_apr() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let mut config = default_reserve_config(scenario.ctx());
        config.interest_rate_utils = {
                let mut v = vector::empty();
                vector::push_back(&mut v, 0);
                vector::push_back(&mut v, 10);
                vector::push_back(&mut v, 100);
                v
            };
        config.interest_rate_aprs = {
                let mut v = vector::empty();
                vector::push_back(&mut v, 0);
                vector::push_back(&mut v, 10000);
                vector::push_back(&mut v, 100000);
                v
            };

        assert!(calculate_apr(&config, decimal::from_percent(0)) == decimal::from(0));
        assert!(calculate_apr(&config, decimal::from_percent(5)) == decimal::from_percent(50));
        assert!(calculate_apr(&config, decimal::from_percent(10)) == decimal::from_percent(100));
        assert!(
            calculate_apr(&config, decimal::from_percent(55)) == decimal::from_percent_u64(550)
        );
        assert!(
            calculate_apr(&config, decimal::from_percent(100)) == decimal::from_percent_u64(1000)
        );

        destroy(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_valid_reserve_config() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let mut utils = vector::empty();
        vector::push_back(&mut utils, 0);
        vector::push_back(&mut utils, 100);

        let mut aprs = vector::empty();
        vector::push_back(&mut aprs, 0);
        vector::push_back(&mut aprs, 100);

        let config = create_reserve_config(
            10,
            10,
            10,
            10_000,
            1,
            1,
            5,
            5,
            100000,
            100000,
            10,
            2000,
            30,
            utils,
            aprs,
            false,
            0,
            0,
            test_scenario::ctx(&mut scenario),
        );

        destroy(config);
        test_scenario::end(scenario);
    }

    // TODO: there are so many other invalid states to test
    #[test]
    #[expected_failure(abort_code = EInvalidReserveConfig)]
    fun test_invalid_reserve_config() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let config = create_reserve_config(
            // open ltv pct
            10,
            // close ltv pct
            9,
            // max close ltv pct
            10,
            // borrow weight bps
            10_000,
            // deposit_limit
            1,
            // borrow_limit
            1,
            // liquidation bonus pct
            5,
            // max liquidation bonus pct
            5,
            10,
            10,
            // borrow fee bps
            10,
            // spread fee bps
            2000,
            // liquidation fee bps
            3000,
            // utils
            {
                let mut v = vector::empty();
                vector::push_back(&mut v, 0);
                vector::push_back(&mut v, 100);
                v
            },
            // aprs
            {
                let mut v = vector::empty();
                vector::push_back(&mut v, 0);
                vector::push_back(&mut v, 100);
                v
            },
            false,
            0,
            0,
            test_scenario::ctx(&mut scenario),
        );

        destroy(config);
        test_scenario::end(scenario);
    }

    #[test_only]
    public fun default_reserve_config(ctx: &mut TxContext): ReserveConfig {
        let config = create_reserve_config(
            // open ltv pct
            0,
            // close ltv pct
            0,
            // max close ltv pct
            0,
            // borrow weight bps
            10_000,
            // deposit_limit
            18_446_744_073_709_551_615,
            // borrow_limit
            18_446_744_073_709_551_615,
            // liquidation bonus pct
            0,
            // max liquidation bonus pct
            0,
            // deposit_limit_usd
            18_446_744_073_709_551_615,
            // borrow_limit_usd
            18_446_744_073_709_551_615,
            // borrow fee bps
            0,
            // spread fee bps
            0,
            // liquidation fee bps
            0,
            // utils
            {
                let mut v = vector::empty();
                vector::push_back(&mut v, 0);
                vector::push_back(&mut v, 100);
                v
            },
            // aprs
            {
                let mut v = vector::empty();
                vector::push_back(&mut v, 0);
                vector::push_back(&mut v, 0);
                v
            },
            false,
            18_446_744_073_709_551_615,
            18_446_744_073_709_551_615,
            ctx,
        );

        config
    }
}
