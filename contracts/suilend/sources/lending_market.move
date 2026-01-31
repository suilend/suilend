module suilend::lending_market {
    use pyth::price_info::PriceInfoObject;
    use std::type_name::{Self, TypeName};
    use sui::balance;
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin, CoinMetadata, TreasuryCap};
    use sui::dynamic_field;
    use sui::event;
    use sui::object_table::{Self, ObjectTable};
    use sui::package;
    use sui::sui::SUI;
    use sui_system::sui_system::SuiSystemState;
    use suilend::decimal::{Self, Decimal, mul, ceil, div, add, floor, gt, min, saturating_floor};
    use suilend::liquidity_mining;
    use suilend::obligation::{Self, Obligation};
    use suilend::rate_limiter::{Self, RateLimiter, RateLimiterConfig};
    use suilend::reserve::{Self, Reserve, CToken, LiquidityRequest};
    use suilend::reserve_config::{ReserveConfig, borrow_fee};

    // === Errors ===
    const EIncorrectVersion: u64 = 1;
    const ETooSmall: u64 = 2;
    const EWrongType: u64 = 3; // I don't think these assertions are necessary
    const EDuplicateReserve: u64 = 4;
    const ERewardPeriodNotOver: u64 = 5;
    const EInvalidObligationId: u64 = 6;
    const EInvalidFeeReceivers: u64 = 7;
    const EClaimRewardsWithBadDebt: u64 = 8;

    // === Constants ===
    const CURRENT_VERSION: u64 = 7;
    const U64_MAX: u64 = 18_446_744_073_709_551_615;

    // === One time Witness ===
    public struct LENDING_MARKET has drop {}

    fun init(otw: LENDING_MARKET, ctx: &mut TxContext) {
        package::claim_and_keep(otw, ctx);
    }

    // === Structs ===
    public struct LendingMarket<phantom P> has key, store {
        id: UID,
        version: u64,
        reserves: vector<Reserve<P>>,
        obligations: ObjectTable<ID, Obligation<P>>,
        // window duration is in seconds
        rate_limiter: RateLimiter,
        fee_receiver: address, // deprecated
        /// unused
        bad_debt_usd: Decimal,
        /// unused
        bad_debt_limit_usd: Decimal,
    }

    public struct LendingMarketOwnerCap<phantom P> has key, store {
        id: UID,
        lending_market_id: ID,
    }

    public struct ObligationOwnerCap<phantom P> has key, store {
        id: UID,
        obligation_id: ID,
    }

    // === Dynamic Fields ===
    public struct FeeReceiversKey has copy, drop, store {}

    public struct FeeReceivers has store {
        receivers: vector<address>,
        weights: vector<u64>,
        total_weight: u64,
    }

    // cTokens redemptions and borrows are rate limited to mitigate exploits. however,
    // on a liquidation we don't want to rate limit redemptions because we don't want liquidators to
    // get stuck holding cTokens. So the liquidate function issues this exemption
    // to the liquidator. This object can't' be stored or transferred -- only dropped or consumed
    // in the same tx block.
    public struct RateLimiterExemption<phantom P, phantom T> has drop {
        amount: u64,
    }

    // === Events ===
    public struct MintEvent has copy, drop {
        lending_market_id: address,
        coin_type: TypeName,
        reserve_id: address,
        liquidity_amount: u64,
        ctoken_amount: u64,
    }

    public struct RedeemEvent has copy, drop {
        lending_market_id: address,
        coin_type: TypeName,
        reserve_id: address,
        ctoken_amount: u64,
        liquidity_amount: u64,
    }

    public struct DepositEvent has copy, drop {
        lending_market_id: address,
        coin_type: TypeName,
        reserve_id: address,
        obligation_id: address,
        ctoken_amount: u64,
    }

    public struct WithdrawEvent has copy, drop {
        lending_market_id: address,
        coin_type: TypeName,
        reserve_id: address,
        obligation_id: address,
        ctoken_amount: u64,
    }

    public struct BorrowEvent has copy, drop {
        lending_market_id: address,
        coin_type: TypeName,
        reserve_id: address,
        obligation_id: address,
        liquidity_amount: u64,
        origination_fee_amount: u64,
    }

    public struct RepayEvent has copy, drop {
        lending_market_id: address,
        coin_type: TypeName,
        reserve_id: address,
        obligation_id: address,
        liquidity_amount: u64,
    }

    public struct ForgiveEvent has copy, drop {
        lending_market_id: address,
        coin_type: TypeName,
        reserve_id: address,
        obligation_id: address,
        liquidity_amount: u64,
    }

    public struct LiquidateEvent has copy, drop {
        lending_market_id: address,
        repay_reserve_id: address,
        withdraw_reserve_id: address,
        obligation_id: address,
        repay_coin_type: TypeName,
        withdraw_coin_type: TypeName,
        repay_amount: u64,
        withdraw_amount: u64,
        protocol_fee_amount: u64,
        liquidator_bonus_amount: u64,
    }

    public struct ClaimRewardEvent has copy, drop {
        lending_market_id: address,
        reserve_id: address,
        obligation_id: address,
        is_deposit_reward: bool,
        pool_reward_id: address,
        coin_type: TypeName,
        liquidity_amount: u64,
    }

    // === Public-Mutative Functions ===
    
    /// Creates a new lending market, and sets the fee receivers.
    ///
    /// The function initializes a `LendingMarket` object with empty reserves
    /// and obligations, a default rate limiter, and the sender as the fee receiver.
    ///
    /// It then calls the `set_fee_receivers` function to set the initial fee receiver to the creator of the market with a weight of 100.
    ///
    /// # Returns
    ///
    /// * `LendingMarketOwnerCap<P>` - The ownership capability for the newly created lending market.
    /// * `LendingMarket<P>` - The newly created lending market object.
    ///
    /// # Panics
    ///
    /// This function calls `set_fee_receivers`, which can panic under the following conditions:
    /// 
    /// * If the `receivers` and `weights` vectors do not have the same length (EInvalidFeeReceivers).
    /// * If the `receivers` vector is empty (EInvalidFeeReceivers).
    /// * If the sum of `weights` is zero (EInvalidFeeReceivers).
    public(package) fun create_lending_market<P>(
        ctx: &mut TxContext,
    ): (LendingMarketOwnerCap<P>, LendingMarket<P>) {
        let mut lending_market = LendingMarket<P> {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            reserves: vector::empty(),
            obligations: object_table::new(ctx),
            rate_limiter: rate_limiter::new(
                rate_limiter::new_config(1, 18_446_744_073_709_551_615),
                0,
            ),
            fee_receiver: tx_context::sender(ctx),
            bad_debt_usd: decimal::from(0),
            bad_debt_limit_usd: decimal::from(0),
        };

        let owner_cap = LendingMarketOwnerCap<P> {
            id: object::new(ctx),
            lending_market_id: object::id(&lending_market),
        };

        set_fee_receivers(
            &owner_cap,
            &mut lending_market,
            vector[tx_context::sender(ctx)],
            vector[100],
        );

        (owner_cap, lending_market)
    }

    /// Updates a reserve's price and timestamp from a Pyth price feed.
    ///
    /// This function is crucial for ensuring that the lending market has the most recent price
    /// for a given asset before performing any operations that depend on the asset's value,
    /// such as borrowing, withdrawing, or liquidating. It calls the `update_price` function
    /// in the `reserve` module.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to update in the lending market's reserves vector.
    /// * `clock` - A reference to the `Clock` object to get the current timestamp.
    /// * `price_info` - A reference to the `PriceInfoObject` from Pyth, containing the new price information.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * `reserve_array_index` is out of bounds.
    /// * The `price_identifier` from the `price_info` object does not match the reserve's price identifier (`EPriceIdentifierMismatch` from the `reserve` module).
    /// * The price from the `price_info` object is invalid (`EInvalidPrice` from the `reserve` module).
    public fun refresh_reserve_price<P>(
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        price_info: &PriceInfoObject,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        reserve::update_price<P>(reserve, clock, price_info);
    }

    /// Creates a new obligation.
    public fun create_obligation<P>(
        lending_market: &mut LendingMarket<P>,
        ctx: &mut TxContext,
    ): ObligationOwnerCap<P> {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        let obligation = obligation::create_obligation<P>(object::id(lending_market), ctx);
        let cap = ObligationOwnerCap<P> {
            id: object::new(ctx),
            obligation_id: object::id(&obligation),
        };

        object_table::add(&mut lending_market.obligations, object::id(&obligation), obligation);

        cap
    }

    /// Deposits liquidity into a reserve and mints cTokens in return.
    ///
    /// This function allows a user to deposit a certain amount of a token into a reserve
    /// and receive cTokens, which represent their share of the reserve's assets.
    /// The amount of cTokens minted is proportional to the amount of liquidity deposited
    /// and the current cToken ratio of the reserve.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to deposit into.
    /// * `clock` - A reference to the `Clock` to compound interest before depositing.
    /// * `deposit` - The `Coin` object representing the liquidity to deposit.
    ///
    /// # Returns
    ///
    /// * `Coin<CToken<P, T>>` - A `Coin` of cTokens representing the deposited liquidity and accrued interest.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The deposit amount is zero (ETooSmall).
    /// * The `coin_type` of the reserve does not match the type of the deposited coin (EWrongType).
    /// * The deposit would exceed the reserve's deposit limit (`EDepositLimitExceeded` from the `reserve` module).
    /// * The minted cToken amount is zero (ETooSmall).
    /// * `reserve_array_index` is out of bounds.
    public fun deposit_liquidity_and_mint_ctokens<P, T>(
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        deposit: Coin<T>,
        ctx: &mut TxContext,
    ): Coin<CToken<P, T>> {
        let lending_market_id = object::id_address(lending_market);
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(coin::value(&deposit) > 0, ETooSmall);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        assert!(reserve::coin_type(reserve) == type_name::with_defining_ids<T>(), EWrongType);
        reserve::compound_interest(reserve, clock);

        let deposit_amount = coin::value(&deposit);
        let ctokens = reserve::deposit_liquidity_and_mint_ctokens<P, T>(
            reserve,
            coin::into_balance(deposit),
        );

        assert!(balance::value(&ctokens) > 0, ETooSmall);

        event::emit(MintEvent {
            lending_market_id,
            coin_type: type_name::with_defining_ids<T>(),
            reserve_id: object::id_address(reserve),
            liquidity_amount: deposit_amount,
            ctoken_amount: balance::value(&ctokens),
        });

        coin::from_balance(ctokens, ctx)
    }

    /// Redeems cTokens for the underlying liquidity.
    ///
    /// This function allows a user to redeem their cTokens for the underlying asset.
    /// The amount of the underlying asset received depends on the amount of cTokens redeemed
    /// and the current cToken ratio of the reserve.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to redeem from.
    /// * `clock` - A reference to the `Clock` to compound interest before redeeming.
    /// * `ctokens` - The `Coin` of cTokens to redeem.
    /// * `rate_limiter_exemption` - An optional exemption from the rate limiter.
    ///
    /// # Returns
    ///
    /// * `Coin<T>` - A `Coin` of the underlying asset.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The amount of cTokens to redeem is zero (ETooSmall).
    /// * The `coin_type` of the reserve does not match the type of the cTokens (EWrongType).
    /// * The redemption would violate the minimum available amount of the reserve (`EMinAvailableAmountViolated` from the `reserve` module).
    /// * The withdrawal amount exceeds the rate limit, and no exemption is provided.
    /// * `reserve_array_index` is out of bounds.
    public fun redeem_ctokens_and_withdraw_liquidity<P, T>(
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        ctokens: Coin<CToken<P, T>>,
        rate_limiter_exemption: Option<RateLimiterExemption<P, T>>,
        ctx: &mut TxContext,
    ): Coin<T> {
        let liquidity_request = redeem_ctokens_and_withdraw_liquidity_request(
            lending_market,
            reserve_array_index,
            clock,
            ctokens,
            rate_limiter_exemption,
            ctx,
        );

        fulfill_liquidity_request(lending_market, reserve_array_index, liquidity_request, ctx)
    }

    /// Creates a liquidity request to withdraw liquidity by redeeming cTokens.
    ///
    /// Initiates the process of redeeming cTokens for the underlying asset.
    /// It checks for rate limit exemptions, processes the withdrawal against the rate limiter if necessary,
    /// and then creates a `LiquidityRequest` by calling the `redeem_ctokens` function in the `reserve` module.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to redeem from.
    /// * `clock` - A reference to the `Clock` to compound interest before redeeming.
    /// * `ctokens` - The `Coin` of cTokens to redeem.
    /// * `rate_limiter_exemption` - An optional exemption from the rate limiter.
    ///
    /// # Returns
    ///
    /// * `LiquidityRequest<P, T>` - A request to withdraw liquidity from the reserve.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The amount of cTokens to redeem is zero (ETooSmall).
    /// * The `coin_type` of the reserve does not match the type of the cTokens (EWrongType).
    /// * The redemption would violate the minimum available amount of the reserve (`EMinAvailableAmountViolated` from the `reserve` module).
    /// * The withdrawal amount exceeds the rate limit, and no exemption is provided.
    /// * The amount of liquidity requested is zero (ETooSmall).
    /// * `reserve_array_index` is out of bounds.
    public fun redeem_ctokens_and_withdraw_liquidity_request<P, T>(
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        ctokens: Coin<CToken<P, T>>,
        mut rate_limiter_exemption: Option<RateLimiterExemption<P, T>>,
        _ctx: &mut TxContext,
    ): LiquidityRequest<P, T> {
        let lending_market_id = object::id_address(lending_market);
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(coin::value(&ctokens) > 0, ETooSmall);

        let ctoken_amount = coin::value(&ctokens);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        assert!(reserve::coin_type(reserve) == type_name::with_defining_ids<T>(), EWrongType);

        reserve::compound_interest(reserve, clock);

        let mut exempt_from_rate_limiter = false;
        if (option::is_some(&rate_limiter_exemption)) {
            let exemption = option::borrow_mut(&mut rate_limiter_exemption);
            if (exemption.amount >= ctoken_amount) {
                exempt_from_rate_limiter = true;
            };
        };

        if (!exempt_from_rate_limiter) {
            rate_limiter::process_qty(
                &mut lending_market.rate_limiter,
                clock::timestamp_ms(clock) / 1000,
                reserve::ctoken_market_value_upper_bound(reserve, ctoken_amount),
            );
        };

        let liquidity_request = reserve::redeem_ctokens<P, T>(
            reserve,
            coin::into_balance(ctokens),
        );

        assert!(reserve::liquidity_request_amount(&liquidity_request) > 0, ETooSmall);

        event::emit(RedeemEvent {
            lending_market_id,
            coin_type: type_name::with_defining_ids<T>(),
            reserve_id: object::id_address(reserve),
            ctoken_amount,
            liquidity_amount: reserve::liquidity_request_amount(&liquidity_request),
        });

        liquidity_request
    }

    /// Deposits cTokens into an obligation, which can be used as collateral for borrowing.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve corresponding to the cTokens being deposited.
    /// * `obligation_owner_cap` - The ownership capability for the obligation.
    /// * `clock` - A reference to the `Clock`.
    /// * `deposit` - The `Coin` of cTokens to deposit.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The deposit amount is zero (ETooSmall).
    /// * The `coin_type` of the reserve does not match the type of the deposited cTokens (EWrongType).
    /// * `reserve_array_index` is out of bounds.
    /// * `obligation_id` is not a valid key in the `obligations` table.
    public fun deposit_ctokens_into_obligation<P, T>(
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        obligation_owner_cap: &ObligationOwnerCap<P>,
        clock: &Clock,
        deposit: Coin<CToken<P, T>>,
        ctx: &mut TxContext,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        deposit_ctokens_into_obligation_by_id(
            lending_market,
            reserve_array_index,
            obligation_owner_cap.obligation_id,
            clock,
            deposit,
            ctx,
        )
    }

    /// Borrows a specified amount of a token from a reserve. A fee is charged on the borrowed amount.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to borrow from.
    /// * `obligation_owner_cap` - The ownership capability for the obligation.
    /// * `clock` - A reference to the `Clock`.
    /// * `amount` - The amount to borrow.
    ///
    /// # Returns
    ///
    /// * `Coin<T>` - A `Coin` of the borrowed asset.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The borrow amount is zero (ETooSmall).
    /// * The `coin_type` of the reserve does not match the type of the asset being borrowed (EWrongType).
    /// * The reserve's price is stale (`EPriceStale` from the `reserve` module).
    /// * The borrow would exceed the reserve's borrow limit (`EBorrowLimitExceeded` from the `reserve` module).
    /// * The borrow would violate the minimum available amount of the reserve (`EMinAvailableAmountViolated` from the `reserve` module).
    /// * The obligation has stale oracle prices.
    /// * The borrow amount exceeds the rate limit.
    /// * `reserve_array_index` is out of bounds.
    /// * `obligation_id` is not a valid key in the `obligations` table.
    public fun borrow<P, T>(
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        obligation_owner_cap: &ObligationOwnerCap<P>,
        clock: &Clock,
        amount: u64,
        ctx: &mut TxContext,
    ): Coin<T> {
        let liquidity_request = borrow_request<P, T>(
            lending_market,
            reserve_array_index,
            obligation_owner_cap,
            clock,
            amount,
        );

        fulfill_liquidity_request(lending_market, reserve_array_index, liquidity_request, ctx)
    }

    /// Compound interest for reserve of type T
    public fun compound_interest<P>(
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);

        reserve.compound_interest(clock);
    }

    /// Refresh the obligation's state and assert no stale oracles
    public fun refresh_obligation<P>(
        lending_market: &mut LendingMarket<P>,
        obligation_id: ID,
        clock: &Clock,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        let obligation = lending_market.obligations.borrow_mut(obligation_id);

        let exist_stale_oracles = obligation.refresh(&mut lending_market.reserves, clock);
        obligation::assert_no_stale_oracles(exist_stale_oracles);
    }

    /// Borrows a specified amount of a token from a reserve. A fee is charged on the borrowed amount.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to borrow from.
    /// * `obligation_owner_cap` - The ownership capability for the obligation.
    /// * `clock` - A reference to the `Clock`.
    /// * `amount` - The amount to borrow.
    ///
    /// # Returns
    ///
    /// * `Coin<T>` - A `Coin` of the borrowed asset.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The borrow amount is zero (ETooSmall).
    /// * The `coin_type` of the reserve does not match the type of the asset being borrowed (EWrongType).
    /// * The reserve's price is stale (`EPriceStale` from the `reserve` module).
    /// * The borrow would exceed the reserve's borrow limit (`EBorrowLimitExceeded` from the `reserve` module).
    /// * The borrow would violate the minimum available amount of the reserve (`EMinAvailableAmountViolated` from the `reserve` module).
    /// * The obligation has stale oracle prices.
    /// * The borrow amount exceeds the rate limit.
    /// * `reserve_array_index` is out of bounds.
    /// * `obligation_id` is not a valid key in the `obligations` table.
    public fun borrow_request<P, T>(
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        obligation_owner_cap: &ObligationOwnerCap<P>,
        clock: &Clock,
        mut amount: u64,
    ): LiquidityRequest<P, T> {
        let lending_market_id = object::id_address(lending_market);
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(amount > 0, ETooSmall);

        let obligation = object_table::borrow_mut(
            &mut lending_market.obligations,
            obligation_owner_cap.obligation_id,
        );

        let exist_stale_oracles = obligation::refresh<P>(obligation, &mut lending_market.reserves, clock);
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        assert!(reserve::coin_type(reserve) == type_name::with_defining_ids<T>(), EWrongType);

        reserve::compound_interest(reserve, clock);
        reserve::assert_price_is_fresh(reserve, clock);

        if (amount == U64_MAX) {
            amount = max_borrow_amount<P>(lending_market.rate_limiter, obligation, reserve, clock);
            assert!(amount > 0, ETooSmall);
        };

        let liquidity_request = reserve::borrow_liquidity<P, T>(reserve, amount);
        obligation::borrow<P>(
            obligation,
            reserve,
            clock,
            reserve::liquidity_request_amount(&liquidity_request),
        );

        let borrow_value = reserve::market_value_upper_bound(
            reserve,
            decimal::from(reserve::liquidity_request_amount(&liquidity_request)),
        );
        rate_limiter::process_qty(
            &mut lending_market.rate_limiter,
            clock::timestamp_ms(clock) / 1000,
            borrow_value,
        );

        event::emit(BorrowEvent {
            lending_market_id,
            coin_type: type_name::with_defining_ids<T>(),
            reserve_id: object::id_address(reserve),
            obligation_id: object::id_address(obligation),
            liquidity_amount: reserve::liquidity_request_amount(&liquidity_request),
            origination_fee_amount: reserve::liquidity_request_fee(&liquidity_request),
        });

        obligation::zero_out_rewards_if_looped(obligation, &mut lending_market.reserves, clock);
        liquidity_request
    }

    /// Fulfills a liquidity request from a reserve.
    ///
    /// This function is called after a liquidity request has been created by either
    /// `redeem_ctokens_and_withdraw_liquidity_request` or `borrow_request`. It takes the
    /// `LiquidityRequest` and processes it, returning the requested amount of the
    /// underlying asset as a `Coin`.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to fulfill the request from.
    /// * `liquidity_request` - The `LiquidityRequest` to be fulfilled.
    ///
    /// # Returns
    ///
    /// * `Coin<T>` - A `Coin` of the underlying asset.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The `coin_type` of the reserve does not match the type of the liquidity request (EWrongType).
    /// * `reserve_array_index` is out of bounds.
    public fun fulfill_liquidity_request<P, T>(
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        liquidity_request: LiquidityRequest<P, T>,
        ctx: &mut TxContext,
    ): Coin<T> {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        assert!(reserve::coin_type(reserve) == type_name::with_defining_ids<T>(), EWrongType);

        coin::from_balance(
            reserve::fulfill_liquidity_request(reserve, liquidity_request),
            ctx,
        )
    }

    /// Withdraws cTokens from an obligation.
    ///
    /// This function allows a user to withdraw their cTokens from an obligation,
    /// making them available for redemption or transfer.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve corresponding to the cTokens being withdrawn.
    /// * `obligation_owner_cap` - The ownership capability for the obligation.
    /// * `clock` - A reference to the `Clock`.
    /// * `amount` - The amount of cTokens to withdraw. If `U64_MAX` is provided, the maximum possible amount will be withdrawn.
    ///
    /// # Returns
    ///
    /// * `Coin<CToken<P, T>>` - A `Coin` of the withdrawn cTokens.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The withdraw amount is zero (ETooSmall).
    /// * The `coin_type` of the reserve does not match the type of the cTokens being withdrawn (EWrongType).
    /// * The obligation has stale oracle prices.
    /// * The withdrawal would leave the obligation in an unhealthy state.
    /// * `reserve_array_index` is out of bounds.
    /// * `obligation_id` is not a valid key in the `obligations` table.
    public fun withdraw_ctokens<P, T>(
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        obligation_owner_cap: &ObligationOwnerCap<P>,
        clock: &Clock,
        mut amount: u64,
        ctx: &mut TxContext,
    ): Coin<CToken<P, T>> {
        let lending_market_id = object::id_address(lending_market);
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(amount > 0, ETooSmall);

        let obligation = object_table::borrow_mut(
            &mut lending_market.obligations,
            obligation_owner_cap.obligation_id,
        );

        let exist_stale_oracles = obligation::refresh<P>(obligation, &mut lending_market.reserves, clock);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        assert!(reserve::coin_type(reserve) == type_name::with_defining_ids<T>(), EWrongType);

        if (amount == U64_MAX) {
            amount =
                max_withdraw_amount<P>(lending_market.rate_limiter, obligation, reserve, clock);
        };

        obligation::withdraw<P>(obligation, reserve, clock, amount, exist_stale_oracles);

        event::emit(WithdrawEvent {
            lending_market_id,
            coin_type: type_name::with_defining_ids<T>(),
            reserve_id: object::id_address(reserve),
            obligation_id: object::id_address(obligation),
            ctoken_amount: amount,
        });

        let ctoken_balance = reserve::withdraw_ctokens<P, T>(reserve, amount);

        obligation::zero_out_rewards_if_looped(obligation, &mut lending_market.reserves, clock);
        coin::from_balance(ctoken_balance, ctx)
    }

    /// Liquidates an unhealthy obligation by repaying a borrow and seizing collateral.
    ///
    /// This function allows a liquidator to repay a portion of an unhealthy obligation's
    /// debt in exchange for a discounted amount of their collateral. Any leftover repay
    /// coins are returned to the liquidator.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `obligation_id` - The ID of the obligation to liquidate.
    /// * `repay_reserve_array_index` - The index of the reserve to repay the debt to.
    /// * `withdraw_reserve_array_index` - The index of the reserve to withdraw collateral from.
    /// * `clock` - A reference to the `Clock`.
    /// * `repay_coins` - A mutable reference to the `Coin` used to repay the debt.
    ///
    /// # Returns
    ///
    /// * `(Coin<CToken<P, Withdraw>>, RateLimiterExemption<P, Withdraw>)` - A tuple containing the withdrawn collateral as cTokens and a rate limiter exemption.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The repay amount is zero (ETooSmall).
    /// * The obligation is not unhealthy.
    /// * The obligation has stale oracle prices.
    /// * The `coin_type` of the repay reserve does not match the type of the repay coin.
    /// * The `coin_type` of the withdraw reserve does not match the type of the withdrawn cTokens.
    /// * `repay_reserve_array_index` or `withdraw_reserve_array_index` are out of bounds.
    /// * `obligation_id` is not a valid key in the `obligations` table.
    public fun liquidate<P, Repay, Withdraw>(
        lending_market: &mut LendingMarket<P>,
        obligation_id: ID,
        repay_reserve_array_index: u64,
        withdraw_reserve_array_index: u64,
        clock: &Clock,
        repay_coins: &mut Coin<Repay>, // mut because we probably won't use all of it
        ctx: &mut TxContext,
    ): (Coin<CToken<P, Withdraw>>, RateLimiterExemption<P, Withdraw>) {
        let lending_market_id = object::id_address(lending_market);
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(coin::value(repay_coins) > 0, ETooSmall);

        let obligation = object_table::borrow_mut(
            &mut lending_market.obligations,
            obligation_id,
        );

        let exist_stale_oracles = obligation::refresh<P>(obligation, &mut lending_market.reserves, clock);
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        let (withdraw_ctoken_amount, required_repay_amount) = obligation::liquidate<P>(
            obligation,
            &mut lending_market.reserves,
            repay_reserve_array_index,
            withdraw_reserve_array_index,
            clock,
            coin::value(repay_coins),
        );

        assert!(gt(required_repay_amount, decimal::from(0)), ETooSmall);

        let required_repay_coins = coin::split(repay_coins, ceil(required_repay_amount), ctx);
        let repay_reserve = vector::borrow_mut(
            &mut lending_market.reserves,
            repay_reserve_array_index,
        );
        assert!(reserve::coin_type(repay_reserve) == type_name::with_defining_ids<Repay>(), EWrongType);
        reserve::repay_liquidity<P, Repay>(
            repay_reserve,
            coin::into_balance(required_repay_coins),
            required_repay_amount,
        );

        let withdraw_reserve = vector::borrow_mut(
            &mut lending_market.reserves,
            withdraw_reserve_array_index,
        );
        assert!(reserve::coin_type(withdraw_reserve) == type_name::with_defining_ids<Withdraw>(), EWrongType);
        let mut ctokens = reserve::withdraw_ctokens<P, Withdraw>(
            withdraw_reserve,
            withdraw_ctoken_amount,
        );
        let (protocol_fee_amount, liquidator_bonus_amount) = reserve::deduct_liquidation_fee<
            P,
            Withdraw,
        >(withdraw_reserve, &mut ctokens);

        let repay_reserve = vector::borrow(&lending_market.reserves, repay_reserve_array_index);
        let withdraw_reserve = vector::borrow(
            &lending_market.reserves,
            withdraw_reserve_array_index,
        );

        event::emit(LiquidateEvent {
            lending_market_id,
            repay_reserve_id: object::id_address(repay_reserve),
            withdraw_reserve_id: object::id_address(withdraw_reserve),
            obligation_id: object::id_address(obligation),
            repay_coin_type: type_name::with_defining_ids<Repay>(),
            withdraw_coin_type: type_name::with_defining_ids<Withdraw>(),
            repay_amount: ceil(required_repay_amount),
            withdraw_amount: withdraw_ctoken_amount,
            protocol_fee_amount,
            liquidator_bonus_amount,
        });

        obligation::zero_out_rewards_if_looped(obligation, &mut lending_market.reserves, clock);

        let exemption = RateLimiterExemption<P, Withdraw> { amount: balance::value(&ctokens) };
        (coin::from_balance(ctokens, ctx), exemption)
    }

    /// Repays a borrow, reducing the obligation's debt and increasing the reserve's liquidity.
    ///
    /// Any leftover repay coins are returned to the caller.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to repay the debt to.
    /// * `obligation_id` - The ID of the obligation to repay.
    /// * `clock` - A reference to the `Clock`.
    /// * `max_repay_coins` - A mutable reference to the `Coin` used to repay the debt.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The `coin_type` of the reserve does not match the type of the repay coin (EWrongType).
    /// * `reserve_array_index` is out of bounds.
    /// * `obligation_id` is not a valid key in the `obligations` table.
    public fun repay<P, T>(
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        obligation_id: ID,
        clock: &Clock,
        // mut because we might not use all of it and the amount we want to use is
        // hard to determine beforehand
        max_repay_coins: &mut Coin<T>,
        ctx: &mut TxContext,
    ) {
        let lending_market_id = object::id_address(lending_market);
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        let obligation = object_table::borrow_mut(
            &mut lending_market.obligations,
            obligation_id,
        );

        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        assert!(reserve::coin_type(reserve) == type_name::with_defining_ids<T>(), EWrongType);

        reserve::compound_interest(reserve, clock);
        let repay_amount = obligation::repay<P>(
            obligation,
            reserve,
            clock,
            decimal::from(coin::value(max_repay_coins)),
        );

        let repay_coins = coin::split(max_repay_coins, ceil(repay_amount), ctx);
        reserve::repay_liquidity<P, T>(reserve, coin::into_balance(repay_coins), repay_amount);

        event::emit(RepayEvent {
            lending_market_id,
            coin_type: type_name::with_defining_ids<T>(),
            reserve_id: object::id_address(reserve),
            obligation_id: object::id_address(obligation),
            liquidity_amount: ceil(repay_amount),
        });

        obligation::zero_out_rewards_if_looped(obligation, &mut lending_market.reserves, clock);
    }

    /// Forgives a debt on an obligation, effectively reducing the borrow amount without requiring repayment.
    ///
    /// This is an admin-only function that can be used to handle bad debt or other special circumstances.
    /// It reduces the borrowed amount for a specific reserve within an obligation.
    ///
    /// # Arguments
    ///
    /// * `_` - The `LendingMarketOwnerCap` to authorize the operation.
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve for which to forgive the debt.
    /// * `obligation_id` - The ID of the obligation to forgive the debt for.
    /// * `clock` - A reference to the `Clock`.
    /// * `max_forgive_amount` - The maximum amount of debt to forgive.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * `obligation_id` is not a valid key in the `obligations` table.
    /// * The obligation has stale oracle prices.
    /// * The `coin_type` of the reserve does not match the type of the debt being forgiven (EWrongType).
    /// * `reserve_array_index` is out of bounds.
    public fun forgive<P, T>(
        _: &LendingMarketOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        obligation_id: ID,
        clock: &Clock,
        max_forgive_amount: u64,
    ) {
        let lending_market_id = object::id_address(lending_market);
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        let obligation = object_table::borrow_mut(
            &mut lending_market.obligations,
            obligation_id,
        );

        let exist_stale_oracles = obligation::refresh<P>(obligation, &mut lending_market.reserves, clock);
        obligation::assert_no_stale_oracles(exist_stale_oracles);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        assert!(reserve::coin_type(reserve) == type_name::with_defining_ids<T>(), EWrongType);

        let forgive_amount = obligation::forgive<P>(
            obligation,
            reserve,
            clock,
            decimal::from(max_forgive_amount),
        );

        reserve::forgive_debt<P>(reserve, forgive_amount);

        event::emit(ForgiveEvent {
            lending_market_id,
            coin_type: type_name::with_defining_ids<T>(),
            reserve_id: object::id_address(reserve),
            obligation_id: object::id_address(obligation),
            liquidity_amount: ceil(forgive_amount),
        });
    }

    /// Claims rewards earned by an obligation.
    ///
    /// This function allows an obligation owner to claim rewards that have accrued
    /// from either depositing or borrowing on a reserve.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `cap` - The `ObligationOwnerCap` to authorize the operation.
    /// * `clock` - A reference to the `Clock`.
    /// * `reserve_id` - The array index of the reserve that is giving out the rewards.
    /// * `reward_index` - The index of the reward pool to claim from.
    /// * `is_deposit_reward` - A boolean indicating whether to claim deposit rewards (true) or borrow rewards (false).
    ///
    /// # Returns
    ///
    /// * `Coin<RewardType>` - A `Coin` containing the claimed rewards.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * It will also panic if the underlying `claim_rewards_by_obligation_id` panics.
    public fun claim_rewards<P, RewardType>(
        lending_market: &mut LendingMarket<P>,
        cap: &ObligationOwnerCap<P>,
        clock: &Clock,
        reserve_id: u64,
        reward_index: u64,
        is_deposit_reward: bool,
        ctx: &mut TxContext,
    ): Coin<RewardType> {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        // Check for bad debt before allowing reward claim
        {
            let obligation = lending_market.obligations.borrow_mut(cap.obligation_id);

            // Exit if bad debt exists
            let borrowed_value = obligation.unweighted_borrowed_value_usd();
            let deposited_value = obligation.deposited_value_usd();
            assert!(deposited_value.ge(borrowed_value), EClaimRewardsWithBadDebt);
        };

        claim_rewards_by_obligation_id(
            lending_market,
            cap.obligation_id,
            clock,
            reserve_id,
            reward_index,
            is_deposit_reward,
            false,
            ctx,
        )
    }

    /// Claims rewards earned by an obligation and deposits them back into the obligation.
    ///
    /// This is a permissionless function that can be called by anyone to "crank" rewards for a given obligation.
    /// It first claims the rewards from the specified reward pool and then, if the obligation has a borrow of the
    /// same asset, it repays the borrow. Otherwise, it deposits the rewards into the specified reserve.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `obligation_id` - The ID of the obligation to claim rewards for and deposit into.
    /// * `clock` - A reference to the `Clock`.
    /// * `reward_reserve_id` - The array index of the reserve that is giving out the rewards.
    /// * `reward_index` - The index of the reward pool to claim from.
    /// * `is_deposit_reward` - A boolean indicating whether to claim deposit rewards (true) or borrow rewards (false).
    /// * `deposit_reserve_id` - The array index of the reserve to deposit the claimed rewards into.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The reward period is not over.
    /// * The `coin_type` of the deposit reserve does not match the type of the reward.
    /// * It will also panic if the underlying `claim_rewards_by_obligation_id` or `repay` or `deposit_liquidity_and_mint_ctokens` panics.
    public fun claim_rewards_and_deposit<P, RewardType>(
        lending_market: &mut LendingMarket<P>,
        obligation_id: ID,
        clock: &Clock,
        // array index of reserve that is giving out the rewards
        reward_reserve_id: u64,
        reward_index: u64,
        is_deposit_reward: bool,
        // array index of reserve with type RewardType
        deposit_reserve_id: u64,
        ctx: &mut TxContext,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        let mut rewards = claim_rewards_by_obligation_id<P, RewardType>(
            lending_market,
            obligation_id,
            clock,
            reward_reserve_id,
            reward_index,
            is_deposit_reward,
            true,
            ctx,
        );

        let obligation = object_table::borrow(&lending_market.obligations, obligation_id);
        if (gt(obligation::borrowed_amount<P, RewardType>(obligation), decimal::from(0))) {
            repay<P, RewardType>(
                lending_market,
                deposit_reserve_id,
                obligation_id,
                clock,
                &mut rewards,
                ctx,
            );
        };

        let deposit_reserve = vector::borrow_mut(&mut lending_market.reserves, deposit_reserve_id);
        let expected_ctokens = {
            assert!(
                reserve::coin_type(deposit_reserve) == type_name::with_defining_ids<RewardType>(),
                EWrongType,
            );

            floor(
                div(
                    decimal::from(coin::value(&rewards)),
                    reserve::ctoken_ratio(deposit_reserve),
                ),
            )
        };

        if (expected_ctokens == 0) {
            reserve::join_fees<P, RewardType>(deposit_reserve, coin::into_balance(rewards));
        } else {
            let ctokens = deposit_liquidity_and_mint_ctokens<P, RewardType>(
                lending_market,
                deposit_reserve_id,
                clock,
                rewards,
                ctx,
            );

            deposit_ctokens_into_obligation_by_id<P, RewardType>(
                lending_market,
                deposit_reserve_id,
                obligation_id,
                clock,
                ctokens,
                ctx,
            );
        }
    }

    /* Staker operations */

    /// Initializes a staker for a SUI reserve.
    ///
    /// This function is used to set up a staker for a SUI reserve, which allows the reserve
    /// to participate in staking and earn rewards. It can only be called by the owner of the
    /// lending market.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `_` - The `LendingMarketOwnerCap` to authorize the operation.
    /// * `sui_reserve_array_index` - The index of the SUI reserve to initialize the staker for.
    /// * `treasury_cap` - The `TreasuryCap` for the staker.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The reserve at `sui_reserve_array_index` is not a SUI reserve (EWrongType).
    /// * `sui_reserve_array_index` is out of bounds.
    public fun init_staker<P, S: drop>(
        lending_market: &mut LendingMarket<P>,
        _: &LendingMarketOwnerCap<P>,
        sui_reserve_array_index: u64,
        treasury_cap: TreasuryCap<S>,
        ctx: &mut TxContext,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, sui_reserve_array_index);
        assert!(reserve::coin_type(reserve) == type_name::with_defining_ids<SUI>(), EWrongType);

        reserve::init_staker<P, S>(reserve, treasury_cap, ctx);
    }

    /// Rebalances a staker by staking or unstaking SUI to match the target staking amount.
    ///
    /// This function is a wrapper around `reserve::rebalance_staker`. It ensures that the
    /// lending market is on the correct version and that the specified reserve is a SUI
    /// reserve before proceeding with the rebalancing.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `sui_reserve_array_index` - The index of the SUI reserve to rebalance.
    /// * `system_state` - A mutable reference to the `SuiSystemState`.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The reserve at `sui_reserve_array_index` is not a SUI reserve (EWrongType).
    /// * `sui_reserve_array_index` is out of bounds.
    public fun rebalance_staker<P>(
        lending_market: &mut LendingMarket<P>,
        sui_reserve_array_index: u64,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, sui_reserve_array_index);
        assert!(reserve::coin_type(reserve) == type_name::with_defining_ids<SUI>(), EWrongType);

        reserve::rebalance_staker<P>(reserve, system_state, ctx);
    }

    /// Unstakes SUI from a staker.
    ///
    /// This function is a wrapper around `reserve::unstake_sui_from_staker`. It ensures that the
    /// lending market is on the correct version and that the specified reserve is a SUI
    /// reserve before proceeding with the unstaking.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `sui_reserve_array_index` - The index of the SUI reserve to unstake from.
    /// * `liquidity_request` - A reference to the `LiquidityRequest` for the unstake.
    /// * `system_state` - A mutable reference to the `SuiSystemState`.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * `sui_reserve_array_index` is out of bounds.
    public fun unstake_sui_from_staker<P>(
        lending_market: &mut LendingMarket<P>,
        sui_reserve_array_index: u64,
        liquidity_request: &LiquidityRequest<P, SUI>,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, sui_reserve_array_index);
        if (reserve::coin_type(reserve) != type_name::with_defining_ids<SUI>()) {
            return
        };

        reserve::unstake_sui_from_staker<P, SUI>(reserve, liquidity_request, system_state, ctx);
    }

    // === Public-View Functions ===

    /// Get a reference to the lending market's reserves vector.
    public fun reserves<P>(lending_market: &LendingMarket<P>): &vector<Reserve<P>> {
        &lending_market.reserves
    }

    fun max_borrow_amount<P>(
        mut rate_limiter: RateLimiter,
        obligation: &Obligation<P>,
        reserve: &Reserve<P>,
        clock: &Clock,
    ): u64 {
        let remaining_outflow_usd = rate_limiter::remaining_outflow(
            &mut rate_limiter,
            clock::timestamp_ms(clock) / 1000,
        );

        let rate_limiter_max_borrow_amount = saturating_floor(
            reserve::usd_to_token_amount_lower_bound(
                reserve,
                min(remaining_outflow_usd, decimal::from(1_000_000_000)),
            ),
        );

        let max_borrow_amount_including_fees = std::u64::min(
            std::u64::min(
                obligation::max_borrow_amount(obligation, reserve),
                reserve::max_borrow_amount(reserve),
            ),
            rate_limiter_max_borrow_amount,
        );

        // account for fee
        let mut max_borrow_amount = floor(
            div(
                decimal::from(max_borrow_amount_including_fees),
                add(decimal::from(1), borrow_fee(reserve::config(reserve))),
            ),
        );

        let fee = ceil(
            mul(
                decimal::from(max_borrow_amount),
                borrow_fee(reserve::config(reserve)),
            ),
        );

        // since the fee is ceiling'd, we need to subtract 1 from the max_borrow_amount in certain
        // cases
        if (max_borrow_amount + fee > max_borrow_amount_including_fees && max_borrow_amount > 0) {
            max_borrow_amount = max_borrow_amount - 1;
        };

        max_borrow_amount
    }

    // maximum amount that can be withdrawn and redeemed
    fun max_withdraw_amount<P>(
        mut rate_limiter: RateLimiter,
        obligation: &Obligation<P>,
        reserve: &Reserve<P>,
        clock: &Clock,
    ): u64 {
        let remaining_outflow_usd = rate_limiter::remaining_outflow(
            &mut rate_limiter,
            clock::timestamp_ms(clock) / 1000,
        );

        let rate_limiter_max_withdraw_amount = reserve::usd_to_token_amount_lower_bound(
            reserve,
            min(remaining_outflow_usd, decimal::from(1_000_000_000)),
        );

        let rate_limiter_max_withdraw_ctoken_amount = floor(
            div(
                rate_limiter_max_withdraw_amount,
                reserve::ctoken_ratio(reserve),
            ),
        );

        std::u64::min(
            std::u64::min(
                obligation::max_withdraw_amount(obligation, reserve),
                rate_limiter_max_withdraw_ctoken_amount,
            ),
            reserve::max_redeem_amount(reserve),
        )
    }

    /// Get the obligation ID from an `ObligationOwnerCap`.
    public fun obligation_id<P>(cap: &ObligationOwnerCap<P>): ID {
        cap.obligation_id
    }

    /// Get the array index of a reserve by its coin type.
    /// slow function. use sparingly.
    public fun reserve_array_index<P, T>(lending_market: &LendingMarket<P>): u64 {
        let mut i = 0;
        while (i < vector::length(&lending_market.reserves)) {
            let reserve = vector::borrow(&lending_market.reserves, i);
            if (reserve::coin_type(reserve) == type_name::with_defining_ids<T>()) {
                return i
            };

            i = i + 1;
        };

        i
    }

    /// Get a reference to a reserve by its coin type.
    public fun reserve<P, T>(lending_market: &LendingMarket<P>): &Reserve<P> {
        let i = reserve_array_index<P, T>(lending_market);
        vector::borrow(&lending_market.reserves, i)
    }

    /// Get a reference to an obligation by its ID.
    public fun obligation<P>(lending_market: &LendingMarket<P>, obligation_id: ID): &Obligation<P> {
        object_table::borrow(&lending_market.obligations, obligation_id)
    }

    /// Get the fee receiver address.
    public fun fee_receiver<P>(lending_market: &LendingMarket<P>): address {
        lending_market.fee_receiver
    }

    public use fun rate_limiter_exemption_amount as RateLimiterExemption.amount;

    /// Get the amount of a rate limiter exemption.
    public fun rate_limiter_exemption_amount<P, T>(exemption: &RateLimiterExemption<P, T>): u64 {
        exemption.amount
    }

    // === Admin Functions ===

    /// Migrates the lending market to the current version.
    entry fun migrate<P>(_: &LendingMarketOwnerCap<P>, lending_market: &mut LendingMarket<P>) {
        assert!(lending_market.version <= CURRENT_VERSION - 1, EIncorrectVersion);
        lending_market.version = CURRENT_VERSION;
    }

    /// Adds a new reserve to the lending market.
    ///
    /// This function creates a new reserve and adds it to the lending market's reserves vector.
    /// It can only be called by the owner of the lending market.
    ///
    /// # Arguments
    ///
    /// * `_` - The `LendingMarketOwnerCap` to authorize the operation.
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `price_info` - The initial Pyth price feed for the new reserve.
    /// * `config` - The configuration for the new reserve.
    /// * `coin_metadata` - The metadata for the coin type of the new reserve.
    /// * `clock` - A reference to the `Clock`.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * A reserve for the same coin type already exists (EDuplicateReserve).
    public fun add_reserve<P, T>(
        _: &LendingMarketOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        price_info: &PriceInfoObject,
        config: ReserveConfig,
        coin_metadata: &CoinMetadata<T>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        add_reserve_internal<P, T>(
            lending_market,
            price_info,
            config,
            coin_metadata.get_decimals(),
            clock,
            ctx,
        );
    }

    /// Creates a new coin_registry::Currency reserve in a lending market
    public fun add_reserve_v2<P, T>(
        _lending_market_owner_cap: &LendingMarketOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        price_info: &PriceInfoObject,
        config: ReserveConfig,
        currency: &sui::coin_registry::Currency<T>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        add_reserve_internal<P, T>(
            lending_market,
            price_info,
            config,
            currency.decimals(),
            clock,
            ctx,
        );
    }

    /// Updates the configuration of a reserve.
    ///
    /// This function allows the owner of the lending market to update the configuration of a specific reserve.
    /// It can only be called by the owner of the lending market.
    ///
    /// # Arguments
    ///
    /// * `_` - The `LendingMarketOwnerCap` to authorize the operation.
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to update.
    /// * `config` - The new configuration for the reserve.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * `reserve_array_index` is out of bounds.
    /// * The `coin_type` of the reserve does not match the type `T` (EWrongType).
    public fun update_reserve_config<P, T>(
        _: &LendingMarketOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        config: ReserveConfig,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        assert!(reserve::coin_type(reserve) == type_name::with_defining_ids<T>(), EWrongType);

        reserve::update_reserve_config<P>(reserve, config);
    }

    /// Changes the price feed of a reserve.
    ///
    /// This function allows the owner of the lending market to update the Pyth price feed for a specific reserve.
    /// It can only be called by the owner of the lending market.
    ///
    /// # Arguments
    ///
    /// * `_` - The `LendingMarketOwnerCap` to authorize the operation.
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to update the price feed for.
    /// * `price_info_obj` - The new Pyth price feed object.
    /// * `clock` - A reference to the `Clock`.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * `reserve_array_index` is out of bounds.
    /// * The `coin_type` of the reserve does not match the type `T` (EWrongType).
    public fun change_reserve_price_feed<P, T>(
        _: &LendingMarketOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        price_info_obj: &PriceInfoObject,
        clock: &Clock,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        assert!(reserve::coin_type(reserve) == type_name::with_defining_ids<T>(), EWrongType);

        reserve::change_price_feed<P>(reserve, price_info_obj, clock);
    }

    /// Adds a new reward pool to a reserve for either deposits or borrows.
    ///
    /// This function allows the owner of the lending market to incentivize users by adding rewards
    /// to a specific reserve. The rewards are distributed over a specified time period.
    ///
    /// # Arguments
    ///
    /// * `_` - The `LendingMarketOwnerCap` to authorize the operation.
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to add the reward pool to.
    /// * `is_deposit_reward` - A boolean indicating whether the reward is for deposits (`true`) or borrows (`false`).
    /// * `rewards` - The `Coin` containing the total amount of rewards to be distributed.
    /// * `start_time_ms` - The timestamp in milliseconds when the reward distribution starts.
    /// * `end_time_ms` - The timestamp in milliseconds when the reward distribution ends.
    /// * `clock` - A reference to the `Clock`.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * `reserve_array_index` is out of bounds.
    /// * The underlying `liquidity_mining::add_pool_reward` function panics (e.g., if `start_time_ms` >= `end_time_ms` or reward amount is zero).
    public fun add_pool_reward<P, RewardType>(
        _: &LendingMarketOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        is_deposit_reward: bool,
        rewards: Coin<RewardType>,
        start_time_ms: u64,
        end_time_ms: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        let pool_reward_manager = if (is_deposit_reward) {
            reserve::deposits_pool_reward_manager_mut(reserve)
        } else {
            reserve::borrows_pool_reward_manager_mut(reserve)
        };

        liquidity_mining::add_pool_reward<RewardType>(
            pool_reward_manager,
            coin::into_balance(rewards),
            start_time_ms,
            end_time_ms,
            clock,
            ctx,
        );
    }

    /// Cancels a reward pool from a reserve.
    ///
    /// This is an admin-only function that allows the lending market owner to cancel a reward pool
    /// that is currently active. When a reward pool is cancelled, any unallocated rewards are
    /// returned to the owner.
    ///
    /// # Arguments
    ///
    /// * `_` - The `LendingMarketOwnerCap` to authorize the operation.
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to cancel the reward pool from.
    /// * `is_deposit_reward` - A boolean indicating whether the reward is for deposits (`true`) or borrows (`false`).
    /// * `reward_index` - The index of the reward pool to cancel.
    /// * `clock` - A reference to the `Clock`.
    ///
    /// # Returns
    ///
    /// * `Coin<RewardType>` - A `Coin` containing the unallocated rewards from the cancelled pool.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * `reserve_array_index` is out of bounds.
    /// * The underlying `liquidity_mining::cancel_pool_reward` function panics.
    public fun cancel_pool_reward<P, RewardType>(
        _: &LendingMarketOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        is_deposit_reward: bool,
        reward_index: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<RewardType> {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        let pool_reward_manager = if (is_deposit_reward) {
            reserve::deposits_pool_reward_manager_mut(reserve)
        } else {
            reserve::borrows_pool_reward_manager_mut(reserve)
        };

        let unallocated_rewards = liquidity_mining::cancel_pool_reward<RewardType>(
            pool_reward_manager,
            reward_index,
            clock,
        );

        coin::from_balance(unallocated_rewards, ctx)
    }

    /// Closes a reward pool from a reserve after its distribution period has ended.
    ///
    /// This is an admin-only function that allows the lending market owner to close a reward pool
    /// that has finished distributing rewards. When a reward pool is closed, any unallocated rewards
    /// due to rounding or other factors are returned to the owner. This function can only be called
    /// after the pool's `end_time_ms` has passed.
    ///
    /// # Arguments
    ///
    /// * `_` - The `LendingMarketOwnerCap` to authorize the operation.
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to close the reward pool from.
    /// * `is_deposit_reward` - A boolean indicating whether the reward is for deposits (`true`) or borrows (`false`).
    /// * `reward_index` - The index of the reward pool to close.
    /// * `clock` - A reference to the `Clock`.
    ///
    /// # Returns
    ///
    /// * `Coin<RewardType>` - A `Coin` containing the unallocated rewards from the closed pool.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * `reserve_array_index` is out of bounds.
    /// * The underlying `liquidity_mining::close_pool_reward` function panics (e.g., if the reward period is not over).
    public fun close_pool_reward<P, RewardType>(
        _: &LendingMarketOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        is_deposit_reward: bool,
        reward_index: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<RewardType> {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        let pool_reward_manager = if (is_deposit_reward) {
            reserve::deposits_pool_reward_manager_mut(reserve)
        } else {
            reserve::borrows_pool_reward_manager_mut(reserve)
        };

        let unallocated_rewards = liquidity_mining::close_pool_reward<RewardType>(
            pool_reward_manager,
            reward_index,
            clock,
        );

        coin::from_balance(unallocated_rewards, ctx)
    }

    /// Updates the rate limiter configuration.
    ///
    /// This is an admin-only function that allows the lending market owner to update the rate
    /// limiter configuration. The new configuration will replace the existing one.
    ///
    /// # Arguments
    ///
    /// * `_` - The `LendingMarketOwnerCap` to authorize the operation.
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `clock` - A reference to the `Clock` to get the current timestamp.
    /// * `config` - The new `RateLimiterConfig` to apply.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    public fun update_rate_limiter_config<P>(
        _: &LendingMarketOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        clock: &Clock,
        config: RateLimiterConfig,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        lending_market.rate_limiter = rate_limiter::new(config, clock::timestamp_ms(clock) / 1000);
    }

    /// Sets the fee receivers for the lending market.
    ///
    /// This is an admin-only function that allows the lending market owner to set the fee receivers
    /// and their respective weights for distributing protocol fees. The fees are distributed
    /// proportionally based on these weights.
    ///
    /// # Arguments
    ///
    /// * `_` - The `LendingMarketOwnerCap` to authorize the operation.
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `receivers` - A vector of addresses that will receive the fees.
    /// * `weights` - A vector of weights corresponding to each receiver.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The `receivers` and `weights` vectors do not have the same length (EInvalidFeeReceivers).
    /// * The `receivers` vector is empty (EInvalidFeeReceivers).
    /// * The sum of `weights` is zero (EInvalidFeeReceivers).
    public fun set_fee_receivers<P>(
        _: &LendingMarketOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        receivers: vector<address>,
        weights: vector<u64>,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        assert!(vector::length(&receivers) == vector::length(&weights), EInvalidFeeReceivers);
        assert!(vector::length(&receivers) > 0, EInvalidFeeReceivers);

        let total_weight = vector::fold!(weights, 0, |acc, weight| acc + weight);
        assert!(total_weight > 0, EInvalidFeeReceivers);

        if (dynamic_field::exists_(&lending_market.id, FeeReceiversKey {})) {
            let FeeReceivers { .. } = dynamic_field::remove<FeeReceiversKey, FeeReceivers>(
                &mut lending_market.id,
                FeeReceiversKey {},
            );
        };

        dynamic_field::add(
            &mut lending_market.id,
            FeeReceiversKey {},
            FeeReceivers { receivers, weights, total_weight },
        );
    }

    /// Claims the fees from a reserve and distributes them to the fee receivers.
    ///
    /// This is a permissionless entry function that can be called by anyone to trigger the
    /// distribution of accumulated protocol fees from a specific reserve. The fees, which
    /// can be in both the underlying asset and cTokens, are transferred to the fee receivers
    /// according to the weights configured via `set_fee_receivers`.
    ///
    /// # Arguments
    ///
    /// * `lending_market` - A mutable reference to the `LendingMarket`.
    /// * `reserve_array_index` - The index of the reserve to claim fees from.
    /// * `system_state` - A mutable reference to the `SuiSystemState`, required for claiming staking rewards.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The generic type `T` does not match the coin type of the reserve at `reserve_array_index` (EWrongType).
    /// * `reserve_array_index` is out of bounds.
    /// * The `FeeReceivers` dynamic field has not been set on the lending market.
    entry fun claim_fees<P, T>(
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        assert!(reserve::coin_type(reserve) == type_name::with_defining_ids<T>(), EWrongType);

        let (mut ctoken_fees, mut fees) = reserve::claim_fees<P, T>(reserve, system_state, ctx);
        let total_ctoken_fees = balance::value(&ctoken_fees);
        let total_fees = balance::value(&fees);

        let fee_receivers: &FeeReceivers = dynamic_field::borrow(
            &lending_market.id,
            FeeReceiversKey {},
        );
        let num_fee_receivers = vector::length(&fee_receivers.weights);

        num_fee_receivers.do!(|i| {
            let fee_amount =
                (total_fees as u128) * (fee_receivers.weights[i] as u128) / (fee_receivers.total_weight as u128);
            let fee = if (i == num_fee_receivers - 1) {
                balance::withdraw_all(&mut fees)
            } else {
                balance::split(&mut fees, fee_amount as u64)
            };

            if (balance::value(&fee) > 0) {
                transfer::public_transfer(coin::from_balance(fee, ctx), fee_receivers.receivers[i]);
            } else {
                balance::destroy_zero(fee);
            };

            let ctoken_fee_amount =
                (total_ctoken_fees as u128) * (fee_receivers.weights[i] as u128) / (fee_receivers.total_weight as u128);
            let ctoken_fee = if (i == num_fee_receivers - 1) {
                balance::withdraw_all(&mut ctoken_fees)
            } else {
                balance::split(&mut ctoken_fees, ctoken_fee_amount as u64)
            };

            if (balance::value(&ctoken_fee) > 0) {
                transfer::public_transfer(
                    coin::from_balance(ctoken_fee, ctx),
                    fee_receivers.receivers[i],
                );
            } else {
                balance::destroy_zero(ctoken_fee);
            };
        });

        balance::destroy_zero(fees);
        balance::destroy_zero(ctoken_fees);
    }

    /// Creates a new obligation owner cap for an existing obligation.
    ///
    /// This is an admin-only function that allows the lending market owner to create a new
    /// `ObligationOwnerCap` for an obligation that already exists. This can be useful for
    /// recovery purposes or administrative actions where a new capability object is needed.
    ///
    /// # Arguments
    ///
    /// * `_` - The `LendingMarketOwnerCap` to authorize the operation.
    /// * `lending_market` - A reference to the `LendingMarket`.
    /// * `obligation_id` - The ID of the obligation to create a new owner cap for.
    ///
    /// # Returns
    ///
    /// * `ObligationOwnerCap<P>` - The newly created ownership capability for the specified obligation.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    /// * The `lending_market` version is not `CURRENT_VERSION` (EIncorrectVersion).
    /// * The `obligation_id` is not found in the lending market's obligations (EInvalidObligationId).
    public fun new_obligation_owner_cap<P>(
        _: &LendingMarketOwnerCap<P>,
        lending_market: &LendingMarket<P>,
        obligation_id: ID,
        ctx: &mut TxContext,
    ): ObligationOwnerCap<P> {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(
            object_table::contains(&lending_market.obligations, obligation_id),
            EInvalidObligationId,
        );

        let cap = ObligationOwnerCap<P> {
            id: object::new(ctx),
            obligation_id: obligation_id,
        };

        cap
    }

    // === Private Functions ===
    fun deposit_ctokens_into_obligation_by_id<P, T>(
        lending_market: &mut LendingMarket<P>,
        reserve_array_index: u64,
        obligation_id: ID,
        clock: &Clock,
        deposit: Coin<CToken<P, T>>,
        _ctx: &mut TxContext,
    ) {
        let lending_market_id = object::id_address(lending_market);
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(coin::value(&deposit) > 0, ETooSmall);

        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
        assert!(reserve::coin_type(reserve) == type_name::with_defining_ids<T>(), EWrongType);

        let obligation = object_table::borrow_mut(
            &mut lending_market.obligations,
            obligation_id,
        );

        event::emit(DepositEvent {
            lending_market_id,
            coin_type: type_name::with_defining_ids<T>(),
            reserve_id: object::id_address(reserve),
            obligation_id: object::id_address(obligation),
            ctoken_amount: coin::value(&deposit),
        });

        obligation::deposit<P>(
            obligation,
            reserve,
            clock,
            coin::value(&deposit),
        );
        reserve::deposit_ctokens<P, T>(reserve, coin::into_balance(deposit));

        obligation::zero_out_rewards_if_looped(obligation, &mut lending_market.reserves, clock);
    }

    fun claim_rewards_by_obligation_id<P, RewardType>(
        lending_market: &mut LendingMarket<P>,
        obligation_id: ID,
        clock: &Clock,
        reserve_id: u64,
        reward_index: u64,
        is_deposit_reward: bool,
        fail_if_reward_period_not_over: bool,
        ctx: &mut TxContext,
    ): Coin<RewardType> {
        let lending_market_id = object::id_address(lending_market);
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);

        // assert!(
        //     type_name::borrow_string(&type_name::with_defining_ids<RewardType>()) != 
        //     &ascii::string(b"97d2a76efce8e7cdf55b781bd3d23382237fb1d095f9b9cad0bf1fd5f7176b62::suilend_point_2::SUILEND_POINT_2"),
        //     ECannotClaimReward,
        // );

        let obligation = object_table::borrow_mut(
            &mut lending_market.obligations,
            obligation_id,
        );

        let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_id);
        reserve::compound_interest(reserve, clock);

        let pool_reward_manager = if (is_deposit_reward) {
            reserve::deposits_pool_reward_manager_mut(reserve)
        } else {
            reserve::borrows_pool_reward_manager_mut(reserve)
        };

        if (fail_if_reward_period_not_over) {
            let pool_reward = option::borrow(
                liquidity_mining::pool_reward(pool_reward_manager, reward_index),
            );
            assert!(
                clock::timestamp_ms(clock) >= liquidity_mining::end_time_ms(pool_reward),
                ERewardPeriodNotOver,
            );
        };

        let rewards = coin::from_balance(
            obligation::claim_rewards<P, RewardType>(
                obligation,
                pool_reward_manager,
                clock,
                reward_index,
            ),
            ctx,
        );

        let pool_reward_id = liquidity_mining::pool_reward_id(pool_reward_manager, reward_index);

        event::emit(ClaimRewardEvent {
            lending_market_id,
            reserve_id: object::id_address(reserve),
            obligation_id: object::id_address(obligation),
            is_deposit_reward,
            pool_reward_id: object::id_to_address(&pool_reward_id),
            coin_type: type_name::with_defining_ids<RewardType>(),
            liquidity_amount: coin::value(&rewards),
        });

        rewards
    }

    fun add_reserve_internal<P, T>(
        lending_market: &mut LendingMarket<P>,
        price_info: &PriceInfoObject,
        config: ReserveConfig,
        decimals: u8,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        assert!(
            reserve_array_index<P, T>(lending_market) == vector::length(&lending_market.reserves),
            EDuplicateReserve,
        );

        let reserve = reserve::create_reserve<P, T>(
            object::id(lending_market),
            config,
            vector::length(&lending_market.reserves),
            decimals,
            price_info,
            clock,
            ctx,
        );

        vector::push_back(&mut lending_market.reserves, reserve);
    }

    // === Test Functions ===

    #[test_only]
    public fun new_lending_market_owner_cap_for_testing<P>(lending_market_id: ID, ctx: &mut TxContext): LendingMarketOwnerCap<P> {
        LendingMarketOwnerCap {
            id: object::new(ctx),
            lending_market_id,
        }
    }

    #[test_only]
    public fun destroy_for_testing<P>(obligation_owner_cap: ObligationOwnerCap<P>) {
        let ObligationOwnerCap { id, obligation_id: _ } = obligation_owner_cap;
        object::delete(id);
    }

    #[test_only]
    public fun destroy_lending_market_owner_cap_for_testing<P>(
        lending_market_owner_cap: LendingMarketOwnerCap<P>,
    ) {
        let LendingMarketOwnerCap { id, lending_market_id: _ } = lending_market_owner_cap;
        object::delete(id);
    }

    #[test_only]
    public fun reserves_mut_for_testing<P>(
        lending_market: &mut LendingMarket<P>,
    ): &mut vector<Reserve<P>> {
        &mut lending_market.reserves
    }

    #[test_only]
    public fun refresh_obligation_for_testing<P>(lending_market: &mut LendingMarket<P>, obligation_id: ID, clock: &Clock): Option<obligation::ExistStaleOracles> {
        let obligation = lending_market.obligations.borrow_mut(obligation_id);
        obligation.refresh(&mut lending_market.reserves, clock)
    }

    #[test_only]
    public fun add_reserve_for_testing<P, T>(
        _: &LendingMarketOwnerCap<P>,
        lending_market: &mut LendingMarket<P>,
        price_info: &PriceInfoObject,
        config: ReserveConfig,
        mint_decimals: u8,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(
            reserve_array_index<P, T>(lending_market) == vector::length(&lending_market.reserves),
            EDuplicateReserve,
        );

        let reserve = reserve::create_reserve<P, T>(
            object::id(lending_market),
            config,
            vector::length(&lending_market.reserves),
            mint_decimals,
            price_info,
            clock,
            ctx,
        );

        vector::push_back(&mut lending_market.reserves, reserve);
    }

    #[test_only]
    public fun new_obligation_owner_cap_for_testing<P>(
        lending_market: &LendingMarket<P>,
        obligation_id: ID,
        ctx: &mut TxContext,
    ): ObligationOwnerCap<P> {
        assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
        assert!(
            object_table::contains(&lending_market.obligations, obligation_id),
            EInvalidObligationId,
        );

        let cap = ObligationOwnerCap<P> {
            id: object::new(ctx),
            obligation_id: obligation_id,
        };

        cap
    }

    #[test_only]
    public fun mock_for_testing<P>(
        reserves: vector<Reserve<P>>,
        obligations: ObjectTable<ID, Obligation<P>>,
        fee_receiver: address,
        bad_debt_usd: Decimal,
        bad_debt_limit_usd: Decimal,
        ctx: &mut TxContext,
    ): LendingMarket<P> {
        let lending_market = LendingMarket<P> {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            reserves,
            obligations,
            rate_limiter: rate_limiter::new(
                rate_limiter::new_config(1, 18_446_744_073_709_551_615),
                0,
            ),
            fee_receiver,
            bad_debt_usd,
            bad_debt_limit_usd,
        };

        lending_market

    }
}
