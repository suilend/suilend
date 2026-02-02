/// The reserve module holds the coins of a certain type for a given lending market.
module suilend::reserve {
    // === Imports ===
    use sui::sui::SUI;
    use std::type_name::{Self, TypeName};
    use sui::dynamic_field::{Self};
    use sui::balance::{Self, Balance, Supply};
    use suilend::cell::{Self, Cell};
    use sui::event::{Self};
    use suilend::oracles::{Self};
    use suilend::decimal::{Decimal, Self, add, sub, mul, div, eq, floor, pow, le, ceil, min, max, saturating_sub};
    use sui::clock::{Self, Clock};
    use sui::coin::{TreasuryCap};
    use pyth::price_identifier::{PriceIdentifier};
    use pyth::price_info::{PriceInfoObject};
    use suilend::reserve_config::{
        Self, 
        ReserveConfig, 
        calculate_apr, 
        calculate_supply_apr,
        deposit_limit, 
        deposit_limit_usd, 
        borrow_limit, 
        borrow_limit_usd, 
        borrow_fee,
        protocol_liquidation_fee,
        spread_fee,
        liquidation_bonus
    };
    use suilend::liquidity_mining::{Self, PoolRewardManager};
    use suilend::staker::{Self, Staker};
    use sui_system::sui_system::{SuiSystemState};
    use sprungsui::sprungsui::SPRUNGSUI;

    // === Errors ===
    const EPriceStale: u64 = 0;
    const EPriceIdentifierMismatch: u64 = 1;
    const EDepositLimitExceeded: u64 = 2;
    const EBorrowLimitExceeded: u64 = 3;
    const EInvalidPrice: u64 = 4;
    const EMinAvailableAmountViolated: u64 = 5;
    const EInvalidRepayBalance: u64 = 6;
    const EWrongType: u64 = 7;
    const EStakerAlreadyInitialized: u64 = 8;
    const EStakerNotInitialized: u64 = 9;

    // === Constants ===
    const PRICE_STALENESS_THRESHOLD_S: u64 = 0;
    // to prevent certain rounding bug attacks, we make sure that X amount of the underlying token amount
    // can never be withdrawn or borrowed.
    const MIN_AVAILABLE_AMOUNT: u64 = 100; 

    // === Public Structs ===

    public struct Reserve<phantom P> has key, store {
        id: UID,
        lending_market_id: ID,
        // array index in lending market's reserve array
        array_index: u64,
        coin_type: TypeName,

        config: Cell<ReserveConfig>,
        mint_decimals: u8,

        // oracles
        price_identifier: PriceIdentifier,

        price: Decimal,
        smoothed_price: Decimal,
        price_last_update_timestamp_s: u64,

        available_amount: u64,
        ctoken_supply: u64,
        borrowed_amount: Decimal,

        cumulative_borrow_rate: Decimal,
        interest_last_update_timestamp_s: u64,

        unclaimed_spread_fees: Decimal,

        /// unused
        attributed_borrow_value: Decimal,

        deposits_pool_reward_manager: PoolRewardManager,
        borrows_pool_reward_manager: PoolRewardManager,
    }

    /// Interest bearing token on the underlying Coin<T>. The ctoken can be redeemed for 
    /// the underlying token + any interest earned.
    public struct CToken<phantom P, phantom T> has drop {}

    /// A request to withdraw liquidity from the reserve. This is a hot potato object.
    public struct LiquidityRequest<phantom P, phantom T> {
        amount: u64, // includes fee
        fee: u64,
    }

    // === Dynamic Field Keys ===
    public struct BalanceKey has copy, drop, store {}
    public struct StakerKey has copy, drop, store {}

    /// Balances are stored in a dynamic field to avoid typing the Reserve with CoinType
    public struct Balances<phantom P, phantom T> has store {
        available_amount: Balance<T>,
        ctoken_supply: Supply<CToken<P, T>>,
        fees: Balance<T>,
        ctoken_fees: Balance<CToken<P, T>>,
        deposited_ctokens: Balance<CToken<P, T>>
    }

    // === Events ===
    public struct InterestUpdateEvent has drop, copy {
        lending_market_id: address,
        coin_type: TypeName,
        reserve_id: address,
        cumulative_borrow_rate: Decimal,
        available_amount: u64,
        borrowed_amount: Decimal,
        unclaimed_spread_fees: Decimal,
        ctoken_supply: u64,

        // data for sui
        borrow_interest_paid: Decimal,
        spread_fee: Decimal,
        supply_interest_earned: Decimal,
        borrow_interest_paid_usd_estimate: Decimal,
        protocol_fee_usd_estimate: Decimal,
        supply_interest_earned_usd_estimate: Decimal,
    }

    public struct ReserveAssetDataEvent has drop, copy {
        lending_market_id: address,
        coin_type: TypeName,
        reserve_id: address,
        available_amount: Decimal,
        supply_amount: Decimal,
        borrowed_amount: Decimal,
        available_amount_usd_estimate: Decimal,
        supply_amount_usd_estimate: Decimal,
        borrowed_amount_usd_estimate: Decimal,
        borrow_apr: Decimal,
        supply_apr: Decimal,

        ctoken_supply: u64,
        cumulative_borrow_rate: Decimal,
        price: Decimal,
        smoothed_price: Decimal,
        price_last_update_timestamp_s: u64,
    }

    public struct ClaimStakingRewardsEvent has drop, copy {
        lending_market_id: address,
        coin_type: TypeName,
        reserve_id: address,
        amount: u64,
    }

    // === Constructor ===

    /// Creates a new reserve for a lending market.
    ///
    /// Initializes a reserve with the specified configuration, price information, and coin type.
    /// Sets up initial balances and pool reward managers for deposits and borrows.
    ///
    /// # Arguments
    ///
    /// * `lending_market_id` - The ID of the lending market associated with the reserve.
    /// * `config` - The `ReserveConfig` specifying the reserve's parameters.
    /// * `array_index` - The index of the reserve in the lending market's reserve array.
    /// * `mint_decimals` - The number of decimals for the coin type.
    /// * `price_info_obj` - The price information object for the reserve's oracle.
    /// * `clock` - A reference to the `Clock` for timestamp-based calculations.
    ///
    /// # Returns
    ///
    /// * `Reserve<P>` - A new reserve instance.
    ///
    /// # Panics
    ///
    /// * If the price information is invalid or missing (`EInvalidPrice`).
    public(package) fun create_reserve<P, T>(
        lending_market_id: ID,
        config: ReserveConfig, 
        array_index: u64,
        mint_decimals: u8,
        price_info_obj: &PriceInfoObject, 
        clock: &Clock, 
        ctx: &mut TxContext
    ): Reserve<P> {

        let (mut price_decimal, smoothed_price_decimal, price_identifier) = oracles::get_pyth_price_and_identifier(price_info_obj, clock);
        assert!(option::is_some(&price_decimal), EInvalidPrice);

        let mut reserve = Reserve {
            id: object::new(ctx),
            lending_market_id,
            array_index,
            coin_type: type_name::with_defining_ids<T>(),
            config: cell::new(config),
            mint_decimals,
            price_identifier,
            price: option::extract(&mut price_decimal),
            smoothed_price: smoothed_price_decimal,
            price_last_update_timestamp_s: clock::timestamp_ms(clock) / 1000,
            available_amount: 0,
            ctoken_supply: 0,
            borrowed_amount: decimal::from(0),
            cumulative_borrow_rate: decimal::from(1),
            interest_last_update_timestamp_s: clock::timestamp_ms(clock) / 1000,
            unclaimed_spread_fees: decimal::from(0),
            attributed_borrow_value: decimal::from(0),
            deposits_pool_reward_manager: liquidity_mining::new_pool_reward_manager(ctx),
            borrows_pool_reward_manager: liquidity_mining::new_pool_reward_manager(ctx)
        };

        dynamic_field::add(
            &mut reserve.id,
            BalanceKey {},
            Balances<P, T> {
                available_amount: balance::zero<T>(),
                ctoken_supply: balance::create_supply(CToken<P, T> {}),
                fees: balance::zero<T>(),
                ctoken_fees: balance::zero<CToken<P, T>>(),
                deposited_ctokens: balance::zero<CToken<P, T>>()
            }
        );

        reserve
    }

    // === Public-View Functions ===

    /// Gets the price identifier for the reserve's oracle.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `&PriceIdentifier` - A reference to the reserve's price identifier.
    public fun price_identifier<P>(reserve: &Reserve<P>): &PriceIdentifier {
        &reserve.price_identifier
    }
    
    /// Gets the pool reward manager for deposits.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `&PoolRewardManager` - A reference to the deposits pool reward manager.
    public fun borrows_pool_reward_manager<P>(reserve: &Reserve<P>): &PoolRewardManager {
        &reserve.borrows_pool_reward_manager
    }

    /// Gets the pool reward manager for borrows.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `&PoolRewardManager` - A reference to the borrows pool reward manager.
    public fun deposits_pool_reward_manager<P>(reserve: &Reserve<P>): &PoolRewardManager {
        &reserve.deposits_pool_reward_manager
    }

    /// Gets the array index of the reserve in the lending market's reserve array.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The array index of the reserve.
    public fun array_index<P>(reserve: &Reserve<P>): u64 {
        reserve.array_index
    }

    /// Gets the available amount of tokens in the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The available amount of tokens.
    public fun available_amount<P>(reserve: &Reserve<P>): u64 {
        reserve.available_amount
    }

    /// Gets the total borrowed amount in the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The total borrowed amount as a decimal.
    public fun borrowed_amount<P>(reserve: &Reserve<P>): Decimal {
        reserve.borrowed_amount
    }

    /// Gets the coin type of the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `TypeName` - The coin type of the reserve.
    public fun coin_type<P>(reserve: &Reserve<P>): TypeName {
        reserve.coin_type
    }

    /// Asserts that the reserve's price is fresh based on the staleness threshold.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to check.
    /// * `clock` - A reference to the `Clock` for timestamp-based validation.
    ///
    /// # Panics
    ///
    /// * If the price is stale based on the `PRICE_STALENESS_THRESHOLD_S` (`EPriceStale`).
    public fun assert_price_is_fresh<P>(reserve: &Reserve<P>, clock: &Clock) {
        assert!(is_price_fresh(reserve, clock), EPriceStale);
    }

    /// Checks if the reserve's price is fresh based on the staleness threshold.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to check.
    /// * `clock` - A reference to the `Clock` for timestamp-based validation.
    ///
    /// # Returns
    ///
    /// * `bool` - True if the price is fresh, false otherwise.
    public(package) fun is_price_fresh<P>(reserve: &Reserve<P>, clock: &Clock): bool {
        let cur_time_s = clock::timestamp_ms(clock) / 1000;

        cur_time_s - reserve.price_last_update_timestamp_s <= PRICE_STALENESS_THRESHOLD_S
    }

    /// Gets the current price of the reserve's underlying asset.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The current price as a decimal.
    public fun price<P>(reserve: &Reserve<P>): Decimal {
        reserve.price
    }

    /// Gets the lower bound of the reserve's price (minimum of price and smoothed price).
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The lower bound price as a decimal.
    public fun price_lower_bound<P>(reserve: &Reserve<P>): Decimal {
        min(reserve.price, reserve.smoothed_price)
    }

    /// Gets the upper bound of the reserve's price (maximum of price and smoothed price).
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The upper bound price as a decimal.
    public fun price_upper_bound<P>(reserve: &Reserve<P>): Decimal {
        max(reserve.price, reserve.smoothed_price)
    }

    /// Calculates the market value of a given liquidity amount in USD.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    /// * `liquidity_amount` - The amount of liquidity as a decimal.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The market value in USD.
    public fun market_value<P>(
        reserve: &Reserve<P>, 
        liquidity_amount: Decimal
    ): Decimal {
        div(
            mul(
                price(reserve),
                liquidity_amount
            ),
            decimal::from(std::u64::pow(10, reserve.mint_decimals))
        )
    }

    /// Calculates the lower bound market value of a given liquidity amount in USD.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    /// * `liquidity_amount` - The amount of liquidity as a decimal.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The lower bound market value in USD.
    public fun market_value_lower_bound<P>(
        reserve: &Reserve<P>, 
        liquidity_amount: Decimal
    ): Decimal {
        div(
            mul(
                price_lower_bound(reserve),
                liquidity_amount
            ),
            decimal::from(std::u64::pow(10, reserve.mint_decimals))
        )
    }

    /// Calculates the upper bound market value of a given liquidity amount in USD.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    /// * `liquidity_amount` - The amount of liquidity as a decimal.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The upper bound market value in USD.
    public fun market_value_upper_bound<P>(
        reserve: &Reserve<P>, 
        liquidity_amount: Decimal
    ): Decimal {
        div(
            mul(
                price_upper_bound(reserve),
                liquidity_amount
            ),
            decimal::from(std::u64::pow(10, reserve.mint_decimals))
        )
    }

    /// Calculates the market value of a given ctoken amount in USD.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    /// * `ctoken_amount` - The amount of ctokens.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The market value in USD.
    public fun ctoken_market_value<P>(
        reserve: &Reserve<P>, 
        ctoken_amount: u64
    ): Decimal {
        // TODO should i floor here?
        let liquidity_amount = mul(
            decimal::from(ctoken_amount),
            ctoken_ratio(reserve)
        );

        market_value(reserve, liquidity_amount)
    }

    /// Calculates the lower bound market value of a given ctoken amount in USD.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    /// * `ctoken_amount` - The amount of ctokens.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The lower bound market value in USD.
    public fun ctoken_market_value_lower_bound<P>(
        reserve: &Reserve<P>, 
        ctoken_amount: u64
    ): Decimal {
        // TODO should i floor here?
        let liquidity_amount = mul(
            decimal::from(ctoken_amount),
            ctoken_ratio(reserve)
        );

        market_value_lower_bound(reserve, liquidity_amount)
    }

    /// Calculates the upper bound market value of a given ctoken amount in USD.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    /// * `ctoken_amount` - The amount of ctokens.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The upper bound market value in USD.
    public fun ctoken_market_value_upper_bound<P>(
        reserve: &Reserve<P>, 
        ctoken_amount: u64
    ): Decimal {
        // TODO should i floor here?
        let liquidity_amount = mul(
            decimal::from(ctoken_amount),
            ctoken_ratio(reserve)
        );

        market_value_upper_bound(reserve, liquidity_amount)
    }

    /// Converts a USD amount to the equivalent token amount using the market price.
    /// E.g. how much sui can i get for 1000 USDC
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    /// * `usd_amount` - The USD amount to convert.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The equivalent token amount.
    public fun usd_to_token_amount<P>(
        reserve: &Reserve<P>, 
        usd_amount: Decimal
    ): Decimal {
        decimal::from(10u64.pow(reserve.mint_decimals)).mul(usd_amount).div(reserve.price)
    }

    /// Converts a USD amount to the equivalent token amount using the lower bound price.
    /// E.g. how much sui can i get for 1000 USDC
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    /// * `usd_amount` - The USD amount to convert.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The equivalent token amount.
    public fun usd_to_token_amount_lower_bound<P>(
        reserve: &Reserve<P>, 
        usd_amount: Decimal
    ): Decimal {
        div(
            mul(
                decimal::from(std::u64::pow(10, reserve.mint_decimals)),
                usd_amount
            ),
            price_upper_bound(reserve)
        )
    }

    /// Converts a USD amount to the equivalent token amount using the upper bound price.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    /// * `usd_amount` - The USD amount to convert.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The equivalent token amount.
    public fun usd_to_token_amount_upper_bound<P>(
        reserve: &Reserve<P>, 
        usd_amount: Decimal
    ): Decimal {
        div(
            mul(
                decimal::from(std::u64::pow(10, reserve.mint_decimals)),
                usd_amount
            ),
            price_lower_bound(reserve)
        )
    }

    /// Gets the cumulative borrow rate of the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The cumulative borrow rate as a decimal.
    public fun cumulative_borrow_rate<P>(reserve: &Reserve<P>): Decimal {
        reserve.cumulative_borrow_rate
    }

    /// Calculates the total supply of the reserve, excluding unclaimed spread fees.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The total supply as a decimal.
    public fun total_supply<P>(reserve: &Reserve<P>): Decimal {
        sub(
            add(
                decimal::from(reserve.available_amount),
                reserve.borrowed_amount
            ),
            reserve.unclaimed_spread_fees
        )
    }
    
    /// Simulates the total supply of the reserve with compounded interest.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    /// * `clock` - A reference to the `Clock` for timestamp-based calculations.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The simulated total supply as a decimal.
    fun simulated_total_supply<P>(reserve: &Reserve<P>, clock: &Clock): Decimal {
        let (
            borrowed_amount,
            unclaimed_spread_fees,
        ) = reserve.simulated_compound_interest(clock);

        sub(
            add(
                decimal::from(reserve.available_amount),
                borrowed_amount
            ),
            unclaimed_spread_fees
        )
    }

    /// Calculates the utilization rate of the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The utilization rate as a decimal (0 to 1).
    public fun calculate_utilization_rate<P>(reserve: &Reserve<P>): Decimal {
        let total_supply_excluding_fees = add(
            decimal::from(reserve.available_amount),
            reserve.borrowed_amount
        );

        if (eq(total_supply_excluding_fees, decimal::from(0))) {
            decimal::from(0)
        }
        else {
            div(reserve.borrowed_amount, total_supply_excluding_fees)
        }
    }

    /// Calculates the ctoken ratio (tokens per ctoken).
    /// Always greater than or equal to one.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The ctoken ratio as a decimal (at least 1).
    public fun ctoken_ratio<P>(reserve: &Reserve<P>): Decimal {
        let total_supply = total_supply(reserve);

        // this branch is only used once -- when the reserve is first initialized and has 
        // zero deposits. after that, borrows and redemptions won't let the ctoken supply fall 
        // below MIN_AVAILABLE_AMOUNT
        if (reserve.ctoken_supply == 0) {
            decimal::from(1)
        }
        else {
            div(
                total_supply,
                decimal::from(reserve.ctoken_supply)
            )
        }
    }
    
    /// Simulates the ctoken ratio with compounded interest.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    /// * `clock` - A reference to the `Clock` for timestamp-based calculations.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The simulated ctoken ratio as a decimal (at least 1).
    public fun simulated_ctoken_ratio<P>(reserve: &Reserve<P>, clock: &Clock): Decimal {
        let total_supply = simulated_total_supply(reserve, clock);

        // this branch is only used once -- when the reserve is first initialized and has 
        // zero deposits. after that, borrows and redemptions won't let the ctoken supply fall 
        // below MIN_AVAILABLE_AMOUNT
        if (reserve.ctoken_supply == 0) {
            decimal::from(1)
        }
        else {
            div(
                total_supply,
                decimal::from(reserve.ctoken_supply)
            )
        }
    }

    /// Gets the reserve's configuration.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `&ReserveConfig` - A reference to the reserve's configuration.
    public fun config<P>(reserve: &Reserve<P>): &ReserveConfig {
        cell::get(&reserve.config)
    }

    /// Calculates the borrow fee for a given amount.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    /// * `borrow_amount` - The amount to borrow.
    ///
    /// # Returns
    ///
    /// * `u64` - The borrow fee in token units, ceilinged to the nearest integer.
    public fun calculate_borrow_fee<P>(
        reserve: &Reserve<P>,
        borrow_amount: u64
    ): u64 {
        ceil(mul(decimal::from(borrow_amount), borrow_fee(config(reserve))))
    }

    /// Calculates the maximum amount that can be borrowed from the reserve.
    /// Aaximum amount that can be borrowed from the reserve. does not account for fees!
    ///
    /// Accounts for available amount, borrow limit, and USD borrow limit, excluding fees.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The maximum borrowable amount in token units.
    public fun max_borrow_amount<P>(reserve: &Reserve<P>): u64 {
        floor(min(
            saturating_sub(
                decimal::from(reserve.available_amount),
                decimal::from(MIN_AVAILABLE_AMOUNT)
            ),
            min(
                // borrow limit
                saturating_sub(
                    decimal::from(borrow_limit(config(reserve))),
                    reserve.borrowed_amount
                ),
                // usd borrow limit
                usd_to_token_amount_lower_bound(
                    reserve,
                    saturating_sub(
                        decimal::from(borrow_limit_usd(config(reserve))),
                        market_value_upper_bound(reserve, reserve.borrowed_amount)
                    )
                )
            )
        ))
    }

    /// Calculates the maximum amount of ctokens that can be redeemed.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The maximum redeemable ctoken amount.
    public fun max_redeem_amount<P>(reserve: &Reserve<P>): u64 {
        floor(div(
            sub(
                decimal::from(reserve.available_amount),
                decimal::from(MIN_AVAILABLE_AMOUNT)
            ),
            ctoken_ratio(reserve)
        ))
    }

    /// Gets the total ctoken supply of the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The total ctoken supply.
    public fun ctoken_supply<P>(reserve: &Reserve<P>): u64 {
        reserve.ctoken_supply
    }

    /// Gets the unclaimed spread fees of the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `Decimal` - The unclaimed spread fees as a decimal.
    public fun unclaimed_spread_fees<P>(reserve: &Reserve<P>): Decimal {
        reserve.unclaimed_spread_fees
    }

    /// Gets the balances of the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `&Balances<P, T>` - A reference to the reserve's balances.
    ///
    /// # Panics
    ///
    /// * If the `BalanceKey` dynamic field is not found.
    public fun balances<P, T>(reserve: &Reserve<P>): &Balances<P, T> {
        dynamic_field::borrow(&reserve.id, BalanceKey {})
    }

    public use fun balances_available_amount as Balances.available_amount;

    /// Gets the available amount balance from the reserve's balances.
    ///
    /// # Arguments
    ///
    /// * `balances` - A reference to the `Balances` struct.
    ///
    /// # Returns
    ///
    /// * `&Balance<T>` - A reference to the available amount balance.
    public fun balances_available_amount<P, T>(balances: &Balances<P, T>): &Balance<T> {
        &balances.available_amount
    }

    public use fun balances_ctoken_supply as Balances.ctoken_supply;

    /// Gets the ctoken supply from the reserve's balances.
    ///
    /// # Arguments
    ///
    /// * `balances` - A reference to the `Balances` struct.
    ///
    /// # Returns
    ///
    /// * `&Supply<CToken<P, T>>` - A reference to the ctoken supply.
    public fun balances_ctoken_supply<P, T>(balances: &Balances<P, T>): &Supply<CToken<P, T>> {
        &balances.ctoken_supply
    }

    public use fun balances_fees as Balances.fees;

    /// Gets the fees balance from the reserve's balances.
    ///
    /// # Arguments
    ///
    /// * `balances` - A reference to the `Balances` struct.
    ///
    /// # Returns
    ///
    /// * `&Balance<T>` - A reference to the fees balance.
    public fun balances_fees<P, T>(balances: &Balances<P, T>): &Balance<T> {
        &balances.fees
    }

    public use fun balances_ctoken_fees as Balances.ctoken_fees;

    /// Gets the ctoken fees balance from the reserve's balances.
    ///
    /// # Arguments
    ///
    /// * `balances` - A reference to the `Balances` struct.
    ///
    /// # Returns
    ///
    /// * `&Balance<CToken<P, T>>` - A reference to the ctoken fees balance.
    public fun balances_ctoken_fees<P, T>(balances: &Balances<P, T>): &Balance<CToken<P, T>> {
        &balances.ctoken_fees
    }

    /// Gets the amount from a liquidity request.
    ///
    /// # Arguments
    ///
    /// * `request` - A reference to the `LiquidityRequest` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The amount in the liquidity request (includes fee).
    public(package) fun liquidity_request_amount<P, T>(request: &LiquidityRequest<P, T>): u64 {
        request.amount
    }

    /// Gets the fee from a liquidity request.
    ///
    /// # Arguments
    ///
    /// * `request` - A reference to the `LiquidityRequest` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The fee in the liquidity request.
    public(package) fun liquidity_request_fee<P, T>(request: &LiquidityRequest<P, T>): u64 {
        request.fee
    }

    /// Gets the staker associated with the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `&Staker<S>` - A reference to the staker.
    ///
    /// # Panics
    ///
    /// * If the `StakerKey` dynamic field is not found.
    public fun staker<P, S>(reserve: &Reserve<P>): &Staker<S> {
        dynamic_field::borrow(&reserve.id, StakerKey {})
    }

    // === Public-Mutative Functions ===

    /// Gets a mutable reference to the deposits pool reward manager.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    ///
    /// # Returns
    ///
    /// * `&mut PoolRewardManager` - A mutable reference to the deposits pool reward manager.
    public(package) fun deposits_pool_reward_manager_mut<P>(reserve: &mut Reserve<P>): &mut PoolRewardManager {
        &mut reserve.deposits_pool_reward_manager
    }

    /// Gets a mutable reference to the borrows pool reward manager.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    ///
    /// # Returns
    ///
    /// * `&mut PoolRewardManager` - A mutable reference to the borrows pool reward manager.
    public(package) fun borrows_pool_reward_manager_mut<P>(reserve: &mut Reserve<P>): &mut PoolRewardManager {
        &mut reserve.borrows_pool_reward_manager
    }

    /// Deducts liquidation fees from ctokens during liquidation.
    ///
    /// Splits the ctoken amount into protocol fees and liquidator bonus based on configuration.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `ctokens` - A mutable reference to the ctoken balance to deduct from.
    ///
    /// # Returns
    ///
    /// * `(u64, u64)` - A tuple containing the protocol fee amount and liquidator bonus amount.
    ///
    /// # Panics
    ///
    /// * If the `BalanceKey` dynamic field is not found.
    public(package) fun deduct_liquidation_fee<P, T>(
        reserve: &mut Reserve<P>,
        ctokens: &mut Balance<CToken<P, T>>,
    ): (u64, u64) {
        let bonus = liquidation_bonus(config(reserve));
        let protocol_liquidation_fee = protocol_liquidation_fee(config(reserve));
        let take_rate = div(
            protocol_liquidation_fee,
            add(add(decimal::from(1), bonus), protocol_liquidation_fee)
        );
        let protocol_fee_amount = ceil(mul(take_rate, decimal::from(balance::value(ctokens))));

        let balances: &mut Balances<P, T> = dynamic_field::borrow_mut(&mut reserve.id, BalanceKey {});
        balance::join(&mut balances.ctoken_fees, balance::split(ctokens, protocol_fee_amount));

        let bonus_rate = div(
            bonus,
            add(add(decimal::from(1), bonus), protocol_liquidation_fee)
        );
        let liquidator_bonus_amount = ceil(mul(bonus_rate, decimal::from(balance::value(ctokens))));

        (protocol_fee_amount, liquidator_bonus_amount)
    }

    /// Joins fees to the reserve's fee balance.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `fees` - The balance of fees to join.
    ///
    /// # Panics
    ///
    /// * If the `BalanceKey` dynamic field is not found.
    public(package) fun join_fees<P, T>(reserve: &mut Reserve<P>, fees: Balance<T>) {
        let balances: &mut Balances<P, T> = dynamic_field::borrow_mut(&mut reserve.id, BalanceKey {});
        balance::join(&mut balances.fees, fees);
    }

    /// Updates the reserve's configuration.
    ///
    /// Replaces the current configuration with a new one and destroys the old configuration.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `config` - The new `ReserveConfig` to set.
    public(package) fun update_reserve_config<P>(
        reserve: &mut Reserve<P>, 
        config: ReserveConfig, 
    ) {
        let old = cell::set(&mut reserve.config, config);
        reserve_config::destroy(old);
    }

    /// Updates the reserve's price using the provided price information.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `clock` - A reference to the `Clock` for timestamp-based calculations.
    /// * `price_info_obj` - The price information object to update from.
    ///
    /// # Panics
    ///
    /// * If the price identifier does not match the reserve's (`EPriceIdentifierMismatch`).
    /// * If the price information is invalid or missing (`EInvalidPrice`).
    public(package) fun update_price<P>(
        reserve: &mut Reserve<P>, 
        clock: &Clock,
        price_info_obj: &PriceInfoObject
    ) {
        let (mut price_decimal, ema_price_decimal, price_identifier) = oracles::get_pyth_price_and_identifier(price_info_obj, clock);
        assert!(price_identifier == reserve.price_identifier, EPriceIdentifierMismatch);
        assert!(option::is_some(&price_decimal), EInvalidPrice);

        reserve.price = option::extract(&mut price_decimal);
        reserve.smoothed_price = ema_price_decimal;
        reserve.price_last_update_timestamp_s = clock::timestamp_ms(clock) / 1000;
    }

    /// Compounds interest and debt for the reserve.
    ///
    /// Updates the cumulative borrow rate, borrowed amount, and unclaimed spread fees based
    /// on the elapsed time and APR.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `clock` - A reference to the `Clock` for timestamp-based calculations.
    public(package) fun compound_interest<P>(reserve: &mut Reserve<P>, clock: &Clock) {
        let cur_time_s = clock::timestamp_ms(clock) / 1000;
        let time_elapsed_s = cur_time_s - reserve.interest_last_update_timestamp_s;
        if (time_elapsed_s == 0) {
            return
        };

        // I(t + n) = I(t) * (1 + apr()/SECONDS_IN_YEAR) ^ n
        let utilization_rate = calculate_utilization_rate(reserve);
        let compounded_borrow_rate = pow(
            add(
                decimal::from(1),
                div(
                    calculate_apr(config(reserve), utilization_rate),
                    decimal::from(365 * 24 * 60 * 60)
                )
            ),
            time_elapsed_s
        );

        reserve.cumulative_borrow_rate = mul(
            reserve.cumulative_borrow_rate,
            compounded_borrow_rate
        );

        let net_new_debt = mul(
            reserve.borrowed_amount,
            sub(compounded_borrow_rate, decimal::from(1))
        );

        let spread_fee = mul(net_new_debt, spread_fee(config(reserve)));

        reserve.unclaimed_spread_fees = add(
            reserve.unclaimed_spread_fees,
            spread_fee
        );

        reserve.borrowed_amount = add(
            reserve.borrowed_amount,
            net_new_debt 
        );

        reserve.interest_last_update_timestamp_s = cur_time_s;

        event::emit(InterestUpdateEvent {
            lending_market_id: object::id_to_address(&reserve.lending_market_id),
            coin_type: reserve.coin_type,
            reserve_id: object::uid_to_address(&reserve.id),
            cumulative_borrow_rate: reserve.cumulative_borrow_rate,
            available_amount: reserve.available_amount,
            borrowed_amount: reserve.borrowed_amount,
            unclaimed_spread_fees: reserve.unclaimed_spread_fees,
            ctoken_supply: reserve.ctoken_supply,

            borrow_interest_paid: net_new_debt,
            spread_fee: spread_fee,
            supply_interest_earned: sub(net_new_debt, spread_fee),
            borrow_interest_paid_usd_estimate: market_value(reserve, net_new_debt),
            protocol_fee_usd_estimate: market_value(reserve, spread_fee),
            supply_interest_earned_usd_estimate: market_value(reserve, sub(net_new_debt, spread_fee)),
        });
    }
    
    /// Simulates compounding interest and debt for the reserve.
    ///
    /// Calculates the updated borrowed amount and unclaimed spread fees without modifying the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    /// * `clock` - A reference to the `Clock` for timestamp-based calculations.
    ///
    /// # Returns
    ///
    /// * `(Decimal, Decimal)` - A tuple containing the simulated borrowed amount and unclaimed spread fees.
    fun simulated_compound_interest<P>(reserve: &Reserve<P>, clock: &Clock): (Decimal, Decimal) {
        let cur_time_s = clock::timestamp_ms(clock) / 1000;
        let time_elapsed_s = cur_time_s - reserve.interest_last_update_timestamp_s;
        if (time_elapsed_s == 0) {
            return (
                reserve.borrowed_amount,
                reserve.unclaimed_spread_fees
            )
        };

        // I(t + n) = I(t) * (1 + apr()/SECONDS_IN_YEAR) ^ n
        let utilization_rate = calculate_utilization_rate(reserve);
        let compounded_borrow_rate = pow(
            add(
                decimal::from(1),
                div(
                    calculate_apr(config(reserve), utilization_rate),
                    decimal::from(365 * 24 * 60 * 60)
                )
            ),
            time_elapsed_s
        );

        let net_new_debt = mul(
            reserve.borrowed_amount,
            sub(compounded_borrow_rate, decimal::from(1))
        );

        let spread_fee = mul(net_new_debt, spread_fee(config(reserve)));

        (
            reserve.borrowed_amount.add(net_new_debt),
            reserve.unclaimed_spread_fees.add(spread_fee)
        )
    }

    /// Claims accumulated fees from the reserve.
    ///
    /// Withdraws all fees and ctoken fees, and claims unclaimed spread fees if sufficient liquidity is available.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `system_state` - A mutable reference to the `SuiSystemState` for staking operations.
    ///
    /// # Returns
    ///
    /// * `(Balance<CToken<P, T>>, Balance<T>)` - A tuple containing the ctoken fees and token fees.
    ///
    /// # Panics
    ///
    /// * If the `BalanceKey` dynamic field is not found.
    /// * If the reserve's coin type is SUI and a staker is initialized but the staker type is incorrect (`EWrongType`).
    public(package) fun claim_fees<P, T>(
        reserve: &mut Reserve<P>, 
        system_state: &mut SuiSystemState, 
        ctx: &mut TxContext
    ): (Balance<CToken<P, T>>, Balance<T>) {
        let balances: &mut Balances<P, T> = dynamic_field::borrow_mut(&mut reserve.id, BalanceKey {});
        let mut fees = balance::withdraw_all(&mut balances.fees);
        let ctoken_fees = balance::withdraw_all(&mut balances.ctoken_fees);

        // spread fees
        if (reserve.available_amount >= MIN_AVAILABLE_AMOUNT) {
            let claimable_spread_fees = floor(min(
                reserve.unclaimed_spread_fees,
                decimal::from(reserve.available_amount - MIN_AVAILABLE_AMOUNT)
            ));

            let spread_fees = {
                let liquidity_request = LiquidityRequest<P, T> { amount: claimable_spread_fees, fee: 0 };

                if (type_name::with_defining_ids<T>() == type_name::with_defining_ids<SUI>()) {
                    unstake_sui_from_staker(reserve, &liquidity_request, system_state, ctx);
                };

                fulfill_liquidity_request(reserve, liquidity_request)
            };

            reserve.unclaimed_spread_fees = sub(
                reserve.unclaimed_spread_fees, 
                decimal::from(balance::value(&spread_fees))
            );
            reserve.available_amount = reserve.available_amount - balance::value(&spread_fees);

            balance::join(&mut fees, spread_fees);
        };

        (ctoken_fees, fees)
    }

    /// Deposits liquidity into the reserve and mints corresponding ctokens.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `liquidity` - The balance of tokens to deposit.
    ///
    /// # Returns
    ///
    /// * `Balance<CToken<P, T>>` - The minted ctoken balance.
    ///
    /// # Panics
    ///
    /// * If the total supply exceeds the deposit limit (`EDepositLimitExceeded`).
    /// * If the total supply in USD exceeds the USD deposit limit (`EDepositLimitExceeded`).
    /// * If the `BalanceKey` dynamic field is not found.
    public(package) fun deposit_liquidity_and_mint_ctokens<P, T>(
        reserve: &mut Reserve<P>,
        liquidity: Balance<T>,
    ): Balance<CToken<P, T>> {
        let new_ctokens = if (reserve.ctoken_supply == 0) {
            liquidity.value()
        } else {
            // (liquidity * ctoken_supply) / total_supply
            decimal::from(liquidity.value())
                .mul(
                    decimal::from(reserve.ctoken_supply),
                )
                .div(reserve.total_supply())
                .floor()
        };

        reserve.available_amount = reserve.available_amount + balance::value(&liquidity);
        reserve.ctoken_supply = reserve.ctoken_supply + new_ctokens;

        let total_supply = total_supply(reserve);
        assert!(
            le(total_supply, decimal::from(deposit_limit(config(reserve)))), 
            EDepositLimitExceeded
        );

        let total_supply_usd = market_value_upper_bound(reserve, total_supply);
        assert!(
            le(total_supply_usd, decimal::from(deposit_limit_usd(config(reserve)))), 
            EDepositLimitExceeded
        );

        log_reserve_data(reserve);
        let balances: &mut Balances<P, T> = dynamic_field::borrow_mut(
            &mut reserve.id, 
            BalanceKey {}
        );

        balance::join(&mut balances.available_amount, liquidity);
        balance::increase_supply(&mut balances.ctoken_supply, new_ctokens)
    }

    /// Redeems ctokens for liquidity from the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `ctokens` - The ctoken balance to redeem.
    ///
    /// # Returns
    ///
    /// * `LiquidityRequest<P, T>` - A liquidity request for the redeemed amount.
    ///
    /// # Panics
    ///
    /// * If the available amount or ctoken supply falls below `MIN_AVAILABLE_AMOUNT` after redemption (`EMinAvailableAmountViolated`).
    /// * If the `BalanceKey` dynamic field is not found.
    public(package) fun redeem_ctokens<P, T>(
        reserve: &mut Reserve<P>, 
        ctokens: Balance<CToken<P, T>>
    ): LiquidityRequest<P, T> {
        let ctoken_ratio = ctoken_ratio(reserve);
        let liquidity_amount = floor(mul(
            decimal::from(balance::value(&ctokens)),
            ctoken_ratio
        ));

        reserve.available_amount = reserve.available_amount - liquidity_amount;
        reserve.ctoken_supply = reserve.ctoken_supply - balance::value(&ctokens);

        assert!(
            reserve.available_amount >= MIN_AVAILABLE_AMOUNT && reserve.ctoken_supply >= MIN_AVAILABLE_AMOUNT, 
            EMinAvailableAmountViolated
        );

        log_reserve_data(reserve);
        let balances: &mut Balances<P, T> = dynamic_field::borrow_mut(
            &mut reserve.id, 
            BalanceKey {}
        );

        balance::decrease_supply(&mut balances.ctoken_supply, ctokens);

        LiquidityRequest<P, T> {
            amount: liquidity_amount,
            fee: 0
        }
    }

    /// Fulfills a liquidity request by splitting the requested amount from the reserve's balance.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `request` - The `LiquidityRequest` to fulfill.
    ///
    /// # Returns
    ///
    /// * `Balance<T>` - The fulfilled liquidity amount.
    ///
    /// # Panics
    ///
    /// * If the `BalanceKey` dynamic field is not found.
    public(package) fun fulfill_liquidity_request<P, T>(
        reserve: &mut Reserve<P>,
        request: LiquidityRequest<P, T>,
    ): Balance<T> {
        let LiquidityRequest { amount, fee } = request;

        let balances: &mut Balances<P, T> = dynamic_field::borrow_mut(
            &mut reserve.id, 
            BalanceKey {}
        );

        let mut liquidity = balance::split(&mut balances.available_amount, amount);
        balance::join(&mut balances.fees, balance::split(&mut liquidity, fee));

        liquidity
    }

    /// Initializes a staker for the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `treasury_cap` - The treasury cap for the staker's coin type.
    ///
    /// # Panics
    ///
    /// * If a staker is already initialized (`EStakerAlreadyInitialized`).
    /// * If the staker's coin type is not SPRUNGSUI (`EWrongType`).
    public(package) fun init_staker<P, S: drop>(
        reserve: &mut Reserve<P>,
        treasury_cap: TreasuryCap<S>,
        ctx: &mut TxContext
    ) {
        assert!(!dynamic_field::exists_(&reserve.id, StakerKey {}), EStakerAlreadyInitialized);
        assert!(type_name::with_defining_ids<S>() == type_name::with_defining_ids<SPRUNGSUI>(), EWrongType);

        let staker = staker::create_staker(treasury_cap, ctx);
        dynamic_field::add(&mut reserve.id, StakerKey {}, staker);
    }

    /// Rebalances the staker and claims staking fees.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `system_state` - A mutable reference to the `SuiSystemState` for staking operations.
    ///
    /// # Panics
    ///
    /// * If a staker is not initialized (`EStakerNotInitialized`).
    /// * If the `BalanceKey` dynamic field is not found.
    public(package) fun rebalance_staker<P>(
        reserve: &mut Reserve<P>,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext
    ) {
        assert!(dynamic_field::exists_(&reserve.id, StakerKey {}), EStakerNotInitialized);
        let balances: &mut Balances<P, SUI> = dynamic_field::borrow_mut(
            &mut reserve.id, 
            BalanceKey {}
        );
        let sui = balance::withdraw_all(&mut balances.available_amount);

        let staker: &mut Staker<SPRUNGSUI> = dynamic_field::borrow_mut(&mut reserve.id, StakerKey {});

        staker::deposit(staker, sui);
        staker::rebalance(staker, system_state, ctx);

        let fees = staker::claim_fees(staker, system_state, ctx);
        if (balance::value(&fees) > 0) {
            event::emit(ClaimStakingRewardsEvent {
                lending_market_id: object::id_to_address(&reserve.lending_market_id),
                coin_type: reserve.coin_type,
                reserve_id: object::uid_to_address(&reserve.id),
                amount: balance::value(&fees),
            });

            let balances: &mut Balances<P, SUI> = dynamic_field::borrow_mut(
                &mut reserve.id,
                BalanceKey {}
            );

            balance::join(&mut balances.fees, fees);
        }
        else {
            balance::destroy_zero(fees);
        };
    }

    /// Unstakes SUI from the staker to fulfill a liquidity request if necessary.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `liquidity_request` - A reference to the `LiquidityRequest` to fulfill.
    /// * `system_state` - A mutable reference to the `SuiSystemState` for staking operations.
    ///
    /// # Panics
    ///
    /// * If the reserve's coin type or liquidity request type is not SUI (`EWrongType`).
    /// * If the `BalanceKey` dynamic field is not found.
    /// * If the `StakerKey` dynamic field is found but the staker type is incorrect.
    public(package) fun unstake_sui_from_staker<P, T>(
        reserve: &mut Reserve<P>,
        liquidity_request: &LiquidityRequest<P, T>,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext
    ) {
        assert!(reserve.coin_type == type_name::with_defining_ids<SUI>() && type_name::with_defining_ids<T>() == type_name::with_defining_ids<SUI>(), EWrongType);
        if (!dynamic_field::exists_(&reserve.id, StakerKey {})) {
            return
        };

        let balances: &Balances<P, SUI> = dynamic_field::borrow(&reserve.id, BalanceKey {});
        if (liquidity_request.amount <= balance::value(&balances.available_amount)) {
            return
        };
        let withdraw_amount = liquidity_request.amount - balance::value(&balances.available_amount);

        let staker: &mut Staker<SPRUNGSUI> = dynamic_field::borrow_mut(&mut reserve.id, StakerKey {});
        let sui = staker::withdraw(
            staker,
            withdraw_amount, 
            system_state, 
            ctx
        );

        let balances: &mut Balances<P, SUI> = dynamic_field::borrow_mut(
            &mut reserve.id, 
            BalanceKey {}
        );
        balance::join(&mut balances.available_amount, sui);
    }

    /// Borrows liquidity from the reserve with a fee.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `amount` - The amount to borrow.
    ///
    /// # Returns
    ///
    /// * `LiquidityRequest<P, T>` - A liquidity request for the borrowed amount including fees.
    ///
    /// # Panics
    ///
    /// * If the borrowed amount exceeds the borrow limit (`EBorrowLimitExceeded`).
    /// * If the borrowed amount in USD exceeds the USD borrow limit (`EBorrowLimitExceeded`).
    /// * If the available amount or ctoken supply falls below `MIN_AVAILABLE_AMOUNT` after borrowing (`EMinAvailableAmountViolated`).
    public(package) fun borrow_liquidity<P, T>(
        reserve: &mut Reserve<P>, 
        amount: u64
    ): LiquidityRequest<P, T> {
        let borrow_fee = calculate_borrow_fee(reserve, amount);
        let borrow_amount_with_fees = amount + borrow_fee;

        reserve.available_amount = reserve.available_amount - borrow_amount_with_fees;
        reserve.borrowed_amount = add(reserve.borrowed_amount, decimal::from(borrow_amount_with_fees));

        assert!(
            le(reserve.borrowed_amount, decimal::from(borrow_limit(config(reserve)))), 
            EBorrowLimitExceeded 
        );

        let borrowed_amount = reserve.borrowed_amount;
        assert!(
            le(
                market_value_upper_bound(reserve, borrowed_amount), 
                decimal::from(borrow_limit_usd(config(reserve)))
            ), 
            EBorrowLimitExceeded
        );

        assert!(
            reserve.available_amount >= MIN_AVAILABLE_AMOUNT && reserve.ctoken_supply >= MIN_AVAILABLE_AMOUNT,
            EMinAvailableAmountViolated
        );

        log_reserve_data(reserve);

        LiquidityRequest<P, T> {
            amount: borrow_amount_with_fees,
            fee: borrow_fee
        }
    }

    /// Repays liquidity to the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `liquidity` - The balance of tokens to repay.
    /// * `settle_amount` - The amount to settle as a decimal.
    ///
    /// # Panics
    ///
    /// * If the liquidity amount does not match the ceiling of the settle amount (`EInvalidRepayBalance`).
    /// * If the `BalanceKey` dynamic field is not found.
    public(package) fun repay_liquidity<P, T>(
        reserve: &mut Reserve<P>, 
        liquidity: Balance<T>,
        settle_amount: Decimal
    ) {
        assert!(balance::value(&liquidity) == ceil(settle_amount), EInvalidRepayBalance);

        reserve.available_amount = reserve.available_amount + balance::value(&liquidity);
        reserve.borrowed_amount = saturating_sub(
            reserve.borrowed_amount, 
            settle_amount
        );

        log_reserve_data(reserve);
        let balances: &mut Balances<P, T> = dynamic_field::borrow_mut(&mut reserve.id, BalanceKey {});
        balance::join(&mut balances.available_amount, liquidity);
    }

    /// Forgives a portion of the reserve's debt.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `forgive_amount` - The amount of debt to forgive as a decimal.
    public(package) fun forgive_debt<P>(
        reserve: &mut Reserve<P>, 
        forgive_amount: Decimal
    ) {
        reserve.borrowed_amount = saturating_sub(
            reserve.borrowed_amount, 
            forgive_amount
        );

        log_reserve_data(reserve);
    }

    /// Deposits ctokens into the reserve's deposited ctokens balance.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `ctokens` - The ctoken balance to deposit.
    ///
    /// # Panics
    ///
    /// * If the `BalanceKey` dynamic field is not found.
    public(package) fun deposit_ctokens<P, T>(
        reserve: &mut Reserve<P>, 
        ctokens: Balance<CToken<P, T>>
    ) {
        log_reserve_data(reserve);
        let balances: &mut Balances<P, T> = dynamic_field::borrow_mut(&mut reserve.id, BalanceKey {});
        balance::join(&mut balances.deposited_ctokens, ctokens);
    }

    /// Withdraws ctokens from the reserve's deposited ctokens balance.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `amount` - The amount of ctokens to withdraw.
    ///
    /// # Returns
    ///
    /// * `Balance<CToken<P, T>>` - The withdrawn ctoken balance.
    ///
    /// # Panics
    ///
    /// * If the `BalanceKey` dynamic field is not found.
    public(package) fun withdraw_ctokens<P, T>(
        reserve: &mut Reserve<P>, 
        amount: u64
    ): Balance<CToken<P, T>> {
        log_reserve_data(reserve);
        let balances: &mut Balances<P, T> = dynamic_field::borrow_mut(&mut reserve.id, BalanceKey {});
        balance::split(&mut balances.deposited_ctokens, amount)
    }

    /// Changes the price feed for the reserve.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A mutable reference to the `Reserve` to modify.
    /// * `price_info_obj` - The new price information object.
    /// * `clock` - A reference to the `Clock` for timestamp-based calculations.
    public(package) fun change_price_feed<P>(
        reserve: &mut Reserve<P>,
        price_info_obj: &PriceInfoObject,
        clock: &Clock,
    ){
        let (_, _, price_identifier) = oracles::get_pyth_price_and_identifier(price_info_obj, clock);
        reserve.price_identifier = price_identifier;
    }

    // === View Functions ===

    /// Gets the timestamp of the last interest update in seconds.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The timestamp of the last interest update in seconds.
    public fun interest_last_update_timestamp_s<P>(reserve: &Reserve<P>): u64 {
        reserve.interest_last_update_timestamp_s
    }
    
    // === Private Functions ===

    /// Logs the reserve's data as an event.
    ///
    /// Emits a `ReserveAssetDataEvent` with the current state of the reserve, including amounts, prices, and APRs.
    ///
    /// # Arguments
    ///
    /// * `reserve` - A reference to the `Reserve` whose data is to be logged.
    fun log_reserve_data<P>(reserve: &Reserve<P>) {
        let available_amount_decimal = decimal::from(reserve.available_amount);
        let supply_amount = total_supply(reserve);
        let cur_util = calculate_utilization_rate(reserve);
        let borrow_apr = calculate_apr(config(reserve), cur_util);
        let supply_apr = calculate_supply_apr(config(reserve), cur_util, borrow_apr);

        event::emit(ReserveAssetDataEvent {
            lending_market_id: object::id_to_address(&reserve.lending_market_id),
            coin_type: reserve.coin_type,
            reserve_id: object::uid_to_address(&reserve.id),
            available_amount: available_amount_decimal,
            supply_amount: supply_amount,
            borrowed_amount: reserve.borrowed_amount,
            available_amount_usd_estimate: market_value(reserve, available_amount_decimal),
            supply_amount_usd_estimate: market_value(reserve, supply_amount),
            borrowed_amount_usd_estimate: market_value(reserve, reserve.borrowed_amount),
            borrow_apr: borrow_apr,
            supply_apr: supply_apr,

            ctoken_supply: reserve.ctoken_supply,
            cumulative_borrow_rate: reserve.cumulative_borrow_rate,
            price: reserve.price,
            smoothed_price: reserve.smoothed_price,
            price_last_update_timestamp_s: reserve.price_last_update_timestamp_s,
        });
    }

    // === Test Functions ===

    #[test_only]
    public fun update_price_for_testing<P>(
        reserve: &mut Reserve<P>, 
        clock: &Clock,
        price_decimal: Decimal,
        smoothed_price_decimal: Decimal
    ) {
        reserve.price = price_decimal;
        reserve.smoothed_price = smoothed_price_decimal;
        reserve.price_last_update_timestamp_s = clock::timestamp_ms(clock) / 1000;
    }

    #[test_only]
    use pyth::price_identifier::{Self};

    #[test_only]
    fun example_price_identifier(): PriceIdentifier {
        let mut v = vector::empty();
        let mut i = 0;
        while (i < 32) {
            vector::push_back(&mut v, i);
            i = i + 1;
        };

        price_identifier::from_byte_vec(v)
    }

    #[test_only]
    public fun burn_ctokens_for_testing<P, T>(
        reserve: &mut Reserve<P>, 
        ctokens: Balance<CToken<P, T>>
    ) {
        reserve.ctoken_supply = reserve.ctoken_supply - balance::value(&ctokens);

        let balances: &mut Balances<P, T> = dynamic_field::borrow_mut(
            &mut reserve.id, 
            BalanceKey {}
        );

        balance::decrease_supply(&mut balances.ctoken_supply, ctokens);
    }

    #[test]
    fun test_accessors() {
        use sui::test_scenario::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);

        let id = object::new(test_scenario::ctx(&mut scenario));

        let reserve = Reserve<TEST_USDC> {
            id: object::new(test_scenario::ctx(&mut scenario)),
            lending_market_id: object::uid_to_inner(&id),
            array_index: 0,
            coin_type: type_name::with_defining_ids<TEST_USDC>(),
            config: cell::new(default_reserve_config(scenario.ctx())),
            mint_decimals: 9,
            price_identifier: example_price_identifier(),
            price: decimal::from(1),
            smoothed_price: decimal::from(2),
            price_last_update_timestamp_s: 0,
            available_amount: 500,
            ctoken_supply: 200,
            borrowed_amount: decimal::from(500),
            cumulative_borrow_rate: decimal::from(1),
            interest_last_update_timestamp_s: 0,
            unclaimed_spread_fees: decimal::from(0),
            attributed_borrow_value: decimal::from(0),
            deposits_pool_reward_manager: liquidity_mining::new_pool_reward_manager(test_scenario::ctx(&mut scenario)),
            borrows_pool_reward_manager: liquidity_mining::new_pool_reward_manager(test_scenario::ctx(&mut scenario))
        };

        assert!(market_value(&reserve, decimal::from(10_000_000_000)) == decimal::from(10));
        assert!(ctoken_market_value(&reserve, 10_000_000_000) == decimal::from(50));
        assert!(cumulative_borrow_rate(&reserve) == decimal::from(1));
        assert!(total_supply(&reserve) == decimal::from(1000));
        assert!(calculate_utilization_rate(&reserve) == decimal::from_percent(50));
        assert!(ctoken_ratio(&reserve) == decimal::from(5));

        sui::test_utils::destroy(id);
        sui::test_utils::destroy(reserve);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_compound_interest() {
        use suilend::test_usdc::{TEST_USDC};
        use sui::test_scenario::{Self};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));

        let mut reserve = Reserve<TEST_USDC> {
            id: object::new(test_scenario::ctx(&mut scenario)),
            lending_market_id: object::uid_to_inner(&lending_market_id),
            array_index: 0,
            coin_type: type_name::with_defining_ids<TEST_USDC>(),
            config: cell::new({
                let config = default_reserve_config(scenario.ctx());
                let mut builder = reserve_config::from(&config, test_scenario::ctx(&mut scenario));
                reserve_config::set_spread_fee_bps(&mut builder, 2_000);
                reserve_config::set_interest_rate_utils(&mut builder, {
                    let mut v = vector::empty();
                    vector::push_back(&mut v, 0);
                    vector::push_back(&mut v, 100);
                    v
                });
                reserve_config::set_interest_rate_aprs(&mut builder, {
                    let mut v = vector::empty();
                    vector::push_back(&mut v, 0);
                    vector::push_back(&mut v, 3153600000);
                    v
                });

                sui::test_utils::destroy(config);
                reserve_config::build(builder, test_scenario::ctx(&mut scenario))
            }),
            mint_decimals: 9,
            price_identifier: example_price_identifier(),
            price: decimal::from(1),
            smoothed_price: decimal::from(1),
            price_last_update_timestamp_s: 0,
            available_amount: 500,
            ctoken_supply: 200,
            borrowed_amount: decimal::from(500),
            cumulative_borrow_rate: decimal::from(1),
            interest_last_update_timestamp_s: 0,
            unclaimed_spread_fees: decimal::from(0),
            attributed_borrow_value: decimal::from(0),
            deposits_pool_reward_manager: liquidity_mining::new_pool_reward_manager(test_scenario::ctx(&mut scenario)),
            borrows_pool_reward_manager: liquidity_mining::new_pool_reward_manager(test_scenario::ctx(&mut scenario))
        };

        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 1000); 

        compound_interest(&mut reserve, &clock);

        assert!(cumulative_borrow_rate(&reserve) == decimal::from_bps(10_050));
        assert!(reserve.borrowed_amount == add(decimal::from(500), decimal::from_percent(250)));
        assert!(reserve.unclaimed_spread_fees == decimal::from_percent(50));
        assert!(ctoken_ratio(&reserve) == decimal::from_percent_u64(501));
        assert!(reserve.interest_last_update_timestamp_s == 1);


        // test idempotency

        compound_interest(&mut reserve, &clock);

        assert!(cumulative_borrow_rate(&reserve) == decimal::from_bps(10_050));
        assert!(reserve.borrowed_amount == add(decimal::from(500), decimal::from_percent(250)));
        assert!(reserve.unclaimed_spread_fees == decimal::from_percent(50));
        assert!(reserve.interest_last_update_timestamp_s == 1);

        sui::test_utils::destroy(lending_market_id);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(reserve);

        test_scenario::end(scenario);
    }


    #[test_only]
    public fun create_for_testing<P, T>(
        config: ReserveConfig,
        array_index: u64,
        mint_decimals: u8,
        price: Decimal,
        price_last_update_timestamp_s: u64,
        available_amount: u64,
        ctoken_supply: u64,
        borrowed_amount: Decimal,
        cumulative_borrow_rate: Decimal,
        interest_last_update_timestamp_s: u64,
        ctx: &mut TxContext
    ): Reserve<P> {
        let lending_market_id = object::new(ctx);

        let mut reserve = Reserve<P> {
            id: object::new(ctx),
            lending_market_id: object::uid_to_inner(&lending_market_id),
            array_index,
            coin_type: type_name::with_defining_ids<T>(),
            config: cell::new(config),
            mint_decimals,
            price_identifier: {
                let mut v = vector::empty();
                let mut i = 0;
                while (i < 32) {
                    vector::push_back(&mut v, 0);
                    i = i + 1;
                };

                price_identifier::from_byte_vec(v)
            },
            price,
            smoothed_price: price,
            price_last_update_timestamp_s,
            available_amount,
            ctoken_supply,
            borrowed_amount,
            cumulative_borrow_rate,
            interest_last_update_timestamp_s,
            unclaimed_spread_fees: decimal::from(0),
            attributed_borrow_value: decimal::from(0),
            deposits_pool_reward_manager: liquidity_mining::new_pool_reward_manager(ctx),
            borrows_pool_reward_manager: liquidity_mining::new_pool_reward_manager(ctx)
        };

        dynamic_field::add(
            &mut reserve.id,
            BalanceKey {},
            Balances<P, T> {
                available_amount: balance::create_for_testing(available_amount),
                ctoken_supply: {
                    let mut supply = balance::create_supply(CToken<P, T> {});
                    let tokens = balance::increase_supply(&mut supply, ctoken_supply);
                    sui::test_utils::destroy(tokens);
                    supply
                },
                fees: balance::zero<T>(),
                ctoken_fees: balance::zero<CToken<P, T>>(),
                deposited_ctokens: balance::zero<CToken<P, T>>()
            }
        );

        sui::test_utils::destroy(lending_market_id);

        reserve
    }

    #[test_only]
    public fun borrow_staker_for_testing<P>(
        reserve: &mut Reserve<P>,
    ): &mut Staker<SPRUNGSUI> {
        dynamic_field::borrow_mut(&mut reserve.id, StakerKey {})
    }

    #[test_only]
    public fun init_staker_for_testing<P, S: drop>(
        reserve: &mut Reserve<P>,
        treasury_cap: TreasuryCap<S>,
        ctx: &mut TxContext
    ) {
        init_staker(reserve, treasury_cap, ctx);
    }
    
    #[test_only]
    public fun mock_for_testing<P, T>(
        lending_market_id: ID,
        config: ReserveConfig,
        array_index: u64,
        mint_decimals: u8,
        price_identifier: vector<u8>,
        price: Decimal,
        price_last_update_timestamp_s: u64,
        available_amount: u64,
        ctoken_supply: u64,
        borrowed_amount: Decimal,
        cumulative_borrow_rate: Decimal,
        interest_last_update_timestamp_s: u64,
        unclaimed_spread_fees: Decimal,
        attributed_borrow_value: Decimal,
        deposits_pool_reward_manager: PoolRewardManager,
        borrows_pool_reward_manager: PoolRewardManager,
        // Balances
        available_amount_in_balances: u64,
        balance_fees: u64,
        ctoken_fees: u64,
        deposited_ctokens: u64,
        ctx: &mut TxContext
    ): Reserve<P> {

        let mut reserve = Reserve<P> {
            id: object::new(ctx),
            lending_market_id,
            array_index,
            coin_type: type_name::with_defining_ids<T>(),
            config: cell::new(config),
            mint_decimals,
            price_identifier: price_identifier::from_byte_vec(price_identifier),
            price,
            smoothed_price: price,
            price_last_update_timestamp_s,
            available_amount,
            ctoken_supply,
            borrowed_amount,
            cumulative_borrow_rate,
            interest_last_update_timestamp_s,
            unclaimed_spread_fees,
            attributed_borrow_value,
            deposits_pool_reward_manager,
            borrows_pool_reward_manager,
        };

        dynamic_field::add(
            &mut reserve.id,
            BalanceKey {},
            Balances<P, T> {
                available_amount: balance::create_for_testing(available_amount_in_balances),
                ctoken_supply: {
                    let mut supply = balance::create_supply(CToken<P, T> {});
                    let tokens = balance::increase_supply(&mut supply, ctoken_supply);
                    sui::test_utils::destroy(tokens);
                    supply
                },
                fees: balance::create_for_testing(balance_fees),
                ctoken_fees: balance::create_for_testing(ctoken_fees),
                deposited_ctokens: balance::create_for_testing(deposited_ctokens),
            }
        );

        reserve
    }

    /// Test that the ctoken ratio never decreases after a deposit (monotonicity invariant)
    #[test]
    fun test_ctoken_ratio_monotonicity_on_deposit() {
        use sui::test_scenario::{Self};
        use suilend::test_usdc::{TEST_USDC};
        use suilend::reserve_config::{default_reserve_config};

        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        let lending_market_id = object::new(test_scenario::ctx(&mut scenario));

        // Create a reserve:
        // total_supply = 2*WAD + 1, ctoken_supply = 2*WAD
        let mut reserve = Reserve<TEST_USDC> {
            id: object::new(test_scenario::ctx(&mut scenario)),
            lending_market_id: object::uid_to_inner(&lending_market_id),
            array_index: 0,
            coin_type: type_name::with_defining_ids<TEST_USDC>(),
            config: cell::new(default_reserve_config(scenario.ctx())),
            mint_decimals: 6,
            price_identifier: example_price_identifier(),
            price: decimal::from(1),
            smoothed_price: decimal::from(1),
            price_last_update_timestamp_s: 0,
            available_amount: 2_000_000_000_000_000_001, // 2*WAD + 1
            ctoken_supply: 2_000_000_000_000_000_000, // 2*WAD
            borrowed_amount: decimal::from(0),
            cumulative_borrow_rate: decimal::from(1),
            interest_last_update_timestamp_s: 0,
            unclaimed_spread_fees: decimal::from(0),
            attributed_borrow_value: decimal::from(0),
            deposits_pool_reward_manager: liquidity_mining::new_pool_reward_manager(
                test_scenario::ctx(&mut scenario),
            ),
            borrows_pool_reward_manager: liquidity_mining::new_pool_reward_manager(
                test_scenario::ctx(&mut scenario),
            ),
        };

        // Add the balances dynamic field
        dynamic_field::add(
            &mut reserve.id,
            BalanceKey {},
            Balances<TEST_USDC, TEST_USDC> {
                available_amount: balance::create_for_testing(2_000_000_000_000_000_001),
                ctoken_supply: {
                    let mut supply = balance::create_supply(CToken<TEST_USDC, TEST_USDC> {});
                    let tokens = balance::increase_supply(&mut supply, 2_000_000_000_000_000_000);
                    std::unit_test::destroy(tokens);
                    supply
                },
                fees: balance::zero(),
                ctoken_fees: balance::zero(),
                deposited_ctokens: balance::zero(),
            },
        );

        // Record the ctoken ratio before deposit
        let ratio_before = ctoken_ratio(&reserve);

        // Deposit 1 token - this should mint 0 ctokens
        let liquidity = balance::create_for_testing<TEST_USDC>(1);
        let ctokens = deposit_liquidity_and_mint_ctokens(&mut reserve, liquidity);

        // Record the ctoken ratio after deposit
        let ratio_after = ctoken_ratio(&reserve);

        // Key invariant: ratio should not decrease after a deposit
        assert!(ratio_after.ge(ratio_before));

        // Verify that 0 ctokens were minted
        assert!(ctokens.value() == 0);

        std::unit_test::destroy(lending_market_id);
        std::unit_test::destroy(reserve);
        std::unit_test::destroy(ctokens);
        test_scenario::end(scenario);
    }
}
