module commons::helper;

use cvlm::asserts::cvlm_assume_msg;
use dummy_pool::dummy_pool::DummyPool;
use suilend::decimal::{Self, Decimal};
use suilend::lending_market::LendingMarket;
use suilend::obligation::Obligation;
use suilend::reserve::{Reserve, config};
use suilend::reserve_config::{open_ltv, isolated};

/// Maximum number of deposits allowed in an obligation for verification purposes.
/// Limited to 1 to reduce verification complexity.
const MAX_DEPOSITS: u64 = 1;

/// Maximum number of borrows allowed in an obligation for verification purposes.
/// Limited to 1 to reduce verification complexity.
const MAX_BORROWS: u64 = 1;

/// Returns the maximum number of deposits allowed in an obligation for verification.
public fun max_deposits(): u64 {
    MAX_DEPOSITS
}

/// Returns the maximum number of borrows allowed in an obligation for verification.
public fun max_borrows(): u64 {
    MAX_BORROWS
}

/// Returns a Decimal representation of zero (0).
public fun zero(): Decimal {
    decimal::from_scaled_val(0)
}

/// Returns a Decimal representation of one (1.0).
/// Scaled value: 1 * 10^18
public fun one(): Decimal {
    decimal::from_scaled_val(1000000000000000000)
}

/// Returns a Decimal representation of one (1.0).
/// Scaled value: 1 * 10^18
public fun two(): Decimal {
    decimal::from_scaled_val(2000000000000000000)
}


/// Returns a Decimal representation of twenty percent (0.2).
/// Scaled value: 0.2 * 10^18
public fun twenty_percent(): Decimal {
    decimal::from_scaled_val(20000000000000000)
}

/// Helper function to setup assumptions and calculations for a single deposit.
///
/// Sets up verification assumptions for a deposit reserve and calculates the associated
/// collateral values.
///
/// # Assumptions
/// - 0 < open_ltv <= close_ltv < 1
/// - ctoken_ratio == 1
/// - deposit.market_value() == deposited_value_usd
///
/// # Returns
/// - deposited_value_usd: The USD value of the deposited ctokens
/// - allowed_borrow_value: The borrowing capacity from this deposit (deposited_value_usd_lb * open_ltv)
/// - unhealthy_borrow_value_usd: The liquidation threshold (deposited_value_usd_lb * close_ltv)
fun setup_deposit_assumptions(
    deposit_reserve: &suilend::reserve::Reserve<DummyPool>,
    deposit: &suilend::obligation::Deposit,
): (suilend::decimal::Decimal, suilend::decimal::Decimal, suilend::decimal::Decimal) {
    let zero = zero();
    let one = one();

    let open_ltv = deposit_reserve.config().open_ltv();
    let close_ltv = deposit_reserve.config().close_ltv();

    cvlm_assume_msg(zero.lt(open_ltv), b"0 < open_ltv");
    cvlm_assume_msg(open_ltv.le(close_ltv), b"open_ltv <= close_ltv");
    cvlm_assume_msg(close_ltv.lt(one), b"close_ltv < 1");
    cvlm_assume_msg(deposit_reserve.ctoken_ratio().eq(one), b"ctoken_ratio = 1");

    let fees = deposit_reserve
        .config()
        .protocol_liquidation_fee()
        .add(deposit_reserve.config().liquidation_bonus());
    cvlm_assume_msg(fees.le(twenty_percent()), b"Fees and bonus do not exceed 20 percent");

    let (deposited_value_usd, allowed_borrow_value, unhealthy_borrow_value_usd) = deposit_values(
        deposit_reserve,
        deposit,
        open_ltv,
        close_ltv,
    );

    cvlm_assume_msg(
        deposit.market_value() == deposited_value_usd,
        b"Deposit market value matches calculated deposited value in USD",
    );

    (deposited_value_usd, allowed_borrow_value, unhealthy_borrow_value_usd)
}

fun deposit_values<P>(
    deposit_reserve: &suilend::reserve::Reserve<P>,
    deposit: &suilend::obligation::Deposit,
    open_ltv: Decimal,
    close_ltv: Decimal,
): (Decimal, Decimal, Decimal) {
    let deposited_value_usd = deposit_reserve.ctoken_market_value(deposit.deposited_ctoken_amount());
    let deposited_value_usd_lb = deposit_reserve.ctoken_market_value_lower_bound(deposit.deposited_ctoken_amount());
    let allowed_borrow_value = deposited_value_usd_lb.mul(open_ltv);
    let unhealthy_borrow_value_usd = deposited_value_usd_lb.mul(close_ltv);

    (deposited_value_usd, allowed_borrow_value, unhealthy_borrow_value_usd)
}

/// Helper function to setup assumptions and calculations for a single borrow.
///
/// Sets up verification assumptions for a borrow reserve and calculates the associated
/// debt values.
///
/// # Assumptions
/// - borrow_weight >= 1
/// - ctoken_ratio == 1
/// - borrow.market_value() == unweighted_borrowed_value_usd
///
/// # Returns
/// - unweighted_borrowed_value_usd: The USD value of the borrowed amount
/// - weighted_borrowed_value_usd: The risk-adjusted borrowed value (unweighted * borrow_weight)
/// - weighted_borrowed_value_upper_bound_usd: Upper bound of risk-adjusted value (for conservative estimates)
fun setup_borrow_assumptions(
    borrow_reserve: &suilend::reserve::Reserve<DummyPool>,
    borrow: &suilend::obligation::Borrow,
): (suilend::decimal::Decimal, suilend::decimal::Decimal, suilend::decimal::Decimal) {
    let one = decimal::from(1);

    let borrow_weight = borrow_reserve.config().borrow_weight();
    cvlm_assume_msg(borrow_weight.ge(one), b"Borrow weight >= 1");
    cvlm_assume_msg(borrow_reserve.ctoken_ratio().eq(one), b"ctoken_ratio = 1");

    let (
        unweighted_borrowed_value_usd,
        weighted_borrowed_value_usd,
        weighted_borrowed_value_upper_bound_usd,
    ) = borrow_values(borrow_reserve, borrow, borrow_weight);

    cvlm_assume_msg(
        borrow.market_value() == unweighted_borrowed_value_usd,
        b"Borrow market value matches calculated unweighted borrowed value in USD",
    );

    (
        unweighted_borrowed_value_usd,
        weighted_borrowed_value_usd,
        weighted_borrowed_value_upper_bound_usd,
    )
}

fun borrow_values<P>(
    borrow_reserve: &suilend::reserve::Reserve<P>,
    borrow: &suilend::obligation::Borrow,
    borrow_weight: Decimal,
): (Decimal, Decimal, Decimal) {
    let unweighted_borrowed_value_usd = borrow_reserve.market_value(borrow.borrowed_amount());
    let unweighted_borrowed_value_usd_ub = borrow_reserve.market_value_upper_bound(borrow.borrowed_amount());
    let weighted_borrowed_value_usd = unweighted_borrowed_value_usd.mul(borrow_weight);
    let weighted_borrowed_value_upper_bound_usd = unweighted_borrowed_value_usd_ub.mul(
        borrow_weight,
    );
    (
        unweighted_borrowed_value_usd,
        weighted_borrowed_value_usd,
        weighted_borrowed_value_upper_bound_usd,
    )
}

/// Sets up an obligation for verification with support for multiple deposits and borrows.
///
/// Establishes verification assumptions for all deposits and borrows in the obligation,
/// and verifies that the obligation's aggregate values match the expected calculations.
///
/// # Constraints
/// - Number of deposits <= MAX_DEPOSITS
/// - Number of borrows <= MAX_BORROWS
///
/// # Assumptions (for each deposit/borrow)
/// - See `setup_deposit_assumptions` and `setup_borrow_assumptions` for individual assumptions
/// - Aggregate obligation values match the sum of individual deposit/borrow values
///
/// # Returns
/// A reference to the verified obligation
public fun setup_obligation(lm: &LendingMarket<DummyPool>, ob_id: ID): &Obligation<DummyPool> {
    let obligation = lm.obligation(ob_id);
    cvlm_assume_msg(obligation.deposits().length() <= MAX_DEPOSITS, b"Limit number of deposits");
    cvlm_assume_msg(obligation.borrows().length() <= MAX_BORROWS, b"Limit number of borrows");

    let deposits = obligation.deposits().length();
    let borrows = obligation.borrows().length();

    /* Freshness */
    let zero = zero();

    // Collateral
    let mut deposited_value_usd = zero;
    let mut allowed_borrow_value = zero;
    let mut unhealthy_borrow_value_usd = zero;

    let mut i = 0;
    while (i < deposits) {
        let deposit = &obligation.deposits()[i];
        let deposit_reserve = &lm.reserves()[deposit.reserve_array_index()];

        let (
            deposited_value_usd_i,
            allowed_borrow_value_i,
            unhealthy_borrow_value_usd_i,
        ) = setup_deposit_assumptions(deposit_reserve, deposit);

        deposited_value_usd = deposited_value_usd.add(deposited_value_usd_i);
        allowed_borrow_value = allowed_borrow_value.add(allowed_borrow_value_i);
        unhealthy_borrow_value_usd = unhealthy_borrow_value_usd.add(unhealthy_borrow_value_usd_i);

        i = i+1;
    };

    cvlm_assume_msg(
        obligation.deposited_value_usd() == deposited_value_usd,
        b"Obligation deposited value matches sum of all deposits",
    );
    cvlm_assume_msg(
        obligation.allowed_borrow_value_usd() == allowed_borrow_value,
        b"Obligation allowed borrow value matches calculated borrowing capacity",
    );
    cvlm_assume_msg(
        obligation.unhealthy_borrow_value_usd() == unhealthy_borrow_value_usd,
        b"Obligation unhealthy borrow value matches calculated liquidation threshold",
    );

    // Debt

    let mut unweighted_borrowed_value_usd = decimal::from(0);
    let mut weighted_borrowed_value_usd = decimal::from(0);
    let mut weighted_borrowed_value_upper_bound_usd = decimal::from(0);

    let mut i = 0;
    while (i < borrows) {
        let borrow = &obligation.borrows()[i];
        let borrow_reserve = &lm.reserves()[borrow.reserve_array_index()];

        let (
            unweighted_borrowed_value_usd_i,
            weighted_borrowed_value_usd_i,
            weighted_borrowed_value_upper_bound_usd_i,
        ) = setup_borrow_assumptions(borrow_reserve, borrow);

        unweighted_borrowed_value_usd =
            unweighted_borrowed_value_usd.add(unweighted_borrowed_value_usd_i);
        weighted_borrowed_value_usd =
            weighted_borrowed_value_usd.add(weighted_borrowed_value_usd_i);
        weighted_borrowed_value_upper_bound_usd =
            weighted_borrowed_value_upper_bound_usd.add(weighted_borrowed_value_upper_bound_usd_i);

        i = i+1;
    };

    cvlm_assume_msg(
        obligation.unweighted_borrowed_value_usd() == unweighted_borrowed_value_usd,
        b"Obligation unweighted borrowed value matches sum of all borrows",
    );
    cvlm_assume_msg(
        obligation.weighted_borrowed_value_usd() == weighted_borrowed_value_usd,
        b"Obligation weighted borrowed value matches sum of all risk-adjusted borrows",
    );
    cvlm_assume_msg(
        obligation.weighted_borrowed_value_upper_bound_usd() == weighted_borrowed_value_upper_bound_usd,
        b"Obligation weighted borrowed value upper bound matches sum of all upper bounds",
    );

    obligation
}

/// Sets up an obligation for liquidation verification with exactly one deposit and one borrow.
///
/// Similar to `setup_obligation` but specialized for liquidation scenarios where there is
/// exactly one collateral deposit and one debt position. Returns the reserve indices needed
/// for liquidation operations.
///
/// # Constraints
/// - Exactly 1 deposit required
/// - Exactly 1 borrow required
/// - Withdraw reserve index != repay reserve index (different assets)
///
/// # Assumptions
/// - See `setup_deposit_assumptions` for deposit-related assumptions
/// - See `setup_borrow_assumptions` for borrow-related assumptions
/// - Obligation aggregate values match the single deposit/borrow values
///
/// # Returns
/// - obligation: Reference to the verified obligation
/// - repay_reserve_index: Index of the reserve to repay (the borrowed asset)
/// - withdraw_reserve_index: Index of the reserve to withdraw (the collateral asset)
public fun setup_obligation_for_liquidation(
    lm: &LendingMarket<DummyPool>,
    ob_id: ID,
): (&Obligation<DummyPool>, u64, u64) {
    cvlm_assume_msg(lm.reserves().length() == 2, b"Exactly two reserves");

    let obligation = lm.obligation(ob_id);
    cvlm_assume_msg(obligation.deposits().length() == 1, b"Exactly one deposit required");
    cvlm_assume_msg(obligation.borrows().length() == 1, b"Exactly one borrow required");

    let borrow = &obligation.borrows()[0];
    let deposit = &obligation.deposits()[0];

    let repay_reserve_index = borrow.reserve_array_index();
    let withdraw_reserve_index = deposit.reserve_array_index();

    cvlm_assume_msg(
        withdraw_reserve_index != repay_reserve_index,
        b"Withdraw and repay reserves must differ",
    );

    let borrow_reserve = &lm.reserves()[repay_reserve_index];
    let deposit_reserve = &lm.reserves()[withdraw_reserve_index];
    cvlm_assume_msg(
        borrow_reserve != deposit_reserve,
        b"Borrow from different reserve than deposited to",
    );

    // Setup deposit assumptions and calculate collateral values
    let (
        deposited_value_usd,
        allowed_borrow_value,
        unhealthy_borrow_value_usd,
    ) = setup_deposit_assumptions(deposit_reserve, deposit);

    cvlm_assume_msg(
        obligation.deposited_value_usd() == deposited_value_usd,
        b"Obligation deposited value matches single deposit value",
    );
    cvlm_assume_msg(
        obligation.allowed_borrow_value_usd() == allowed_borrow_value,
        b"Obligation allowed borrow value matches single deposit borrowing capacity",
    );
    cvlm_assume_msg(
        obligation.unhealthy_borrow_value_usd() == unhealthy_borrow_value_usd,
        b"Obligation unhealthy borrow value matches single deposit liquidation threshold",
    );

    // Setup borrow assumptions and calculate debt values
    let (
        unweighted_borrowed_value_usd,
        weighted_borrowed_value_usd,
        weighted_borrowed_value_upper_bound_usd,
    ) = setup_borrow_assumptions(borrow_reserve, borrow);

    cvlm_assume_msg(
        obligation.unweighted_borrowed_value_usd() == unweighted_borrowed_value_usd,
        b"Obligation unweighted borrowed value matches single borrow value",
    );
    cvlm_assume_msg(
        obligation.weighted_borrowed_value_usd() == weighted_borrowed_value_usd,
        b"Obligation weighted borrowed value matches single borrow risk-adjusted value",
    );
    cvlm_assume_msg(
        obligation.weighted_borrowed_value_upper_bound_usd() == weighted_borrowed_value_upper_bound_usd,
        b"Obligation weighted borrowed value upper bound matches single borrow upper bound",
    );

    (obligation, repay_reserve_index, withdraw_reserve_index)
}

/// Refreshes the health metrics of an obligation by recalculating all deposit and borrow values.
///
/// This function iterates through all deposits and borrows in the obligation, recalculates
/// their current market values based on the latest reserve data, and updates the obligation's
/// aggregate health metrics.
///
/// # Important
/// **This function ignores all debt and interest accrual.** It does not update borrowed amounts
/// or accumulate interest over time. It only recalculates the USD values based on current prices
/// and the existing deposited/borrowed token amounts.
///
/// # Updates
/// For each deposit:
/// - Recalculates deposited value, allowed borrow value, and unhealthy borrow value
/// - Updates the deposit's market value
///
/// For each borrow:
/// - Recalculates unweighted, weighted, and upper bound borrowed values
/// - Updates the borrow's market value
///
/// Obligation-level values updated:
/// - deposited_value_usd
/// - allowed_borrow_value_usd
/// - unhealthy_borrow_value_usd
/// - unweighted_borrowed_value_usd
/// - weighted_borrowed_value_usd
/// - weighted_borrowed_value_upper_bound_usd
public fun refresh_health<P>(obligation: &mut Obligation<P>, reserves: &vector<Reserve<P>>) {
   refresh_health_deposit(obligation, reserves); 
   refresh_health_borrow(obligation, reserves);  
}

public fun refresh_health_borrow<P>(obligation: &mut Obligation<P>, reserves: &vector<Reserve<P>>){
    let borrows = obligation.borrows().length();

    /* Freshness */
    let zero = zero();

    let mut unweighted_borrowed_value_usd = zero;
    let mut weighted_borrowed_value_usd = zero;
    let mut weighted_borrowed_value_upper_bound_usd = zero;
    let mut i = 0;
    while (i < borrows) {
        let borrow = &mut obligation.borrows_mut()[i];
        let borrow_reserve = &reserves[borrow.reserve_array_index()];
        let borrow_weight = borrow_reserve.config().borrow_weight();

        // Sound state
        cvlm_assume_msg(borrow_weight.ge(one()), b"Borrow weight >= 1");

        let (
            unweighted_borrowed_value_usd_i,
            weighted_borrowed_value_usd_i,
            weighted_borrowed_value_upper_bound_usd_i,
        ) = borrow_values(borrow_reserve, borrow, borrow_weight);

        unweighted_borrowed_value_usd =
            unweighted_borrowed_value_usd.add(unweighted_borrowed_value_usd_i);
        weighted_borrowed_value_usd =
            weighted_borrowed_value_usd.add(weighted_borrowed_value_usd_i);
        weighted_borrowed_value_upper_bound_usd =
            weighted_borrowed_value_upper_bound_usd.add(weighted_borrowed_value_upper_bound_usd_i);

        *borrow.market_value_mut() = unweighted_borrowed_value_usd_i;
        i = i+1;
    };
    *obligation.unweighted_borrowed_value_usd_mut() = unweighted_borrowed_value_usd;
    *obligation.weighted_borrowed_value_usd_mut() = weighted_borrowed_value_usd;
    *obligation.weighted_borrowed_value_upper_bound_usd_mut() =
        weighted_borrowed_value_upper_bound_usd;
}

public fun refresh_health_deposit<P>(obligation: &mut Obligation<P>, reserves: &vector<Reserve<P>>){
    let deposits = obligation.deposits().length();

    /* Freshness */
    let zero = zero();

    let mut deposited_value_usd = zero;
    let mut allowed_borrow_value = zero;
    let mut unhealthy_borrow_value_usd = zero;
    let mut i = 0;
    while (i < deposits) {
        let deposit = &mut obligation.deposits_mut()[i];
        let deposit_reserve = &reserves[deposit.reserve_array_index()];
        let open_ltv = deposit_reserve.config().open_ltv();
        let close_ltv = deposit_reserve.config().close_ltv();

        // Sound state
        cvlm_assume_msg(zero.lt(open_ltv), b"0 < open_ltv");
        cvlm_assume_msg(open_ltv.le(close_ltv), b"open_ltv <= close_ltv");
        cvlm_assume_msg(close_ltv.lt(one()), b"close_ltv < 1");
        cvlm_assume_msg(deposit_reserve.ctoken_ratio().eq(one()), b"ctoken_ratio = 1");

        let (
            deposited_value_usd_i,
            allowed_borrow_value_i,
            unhealthy_borrow_value_usd_i,
        ) = deposit_values(deposit_reserve, deposit, open_ltv, close_ltv);

        deposited_value_usd = deposited_value_usd.add(deposited_value_usd_i);
        allowed_borrow_value = allowed_borrow_value.add(allowed_borrow_value_i);
        unhealthy_borrow_value_usd = unhealthy_borrow_value_usd.add(unhealthy_borrow_value_usd_i);

        *deposit.market_value_mut() = deposited_value_usd_i;
        i = i+1;
    };
}

public fun weighted_borrowed_value_usd<P>(obligation: &mut Obligation<P>, reserves: &vector<Reserve<P>>): Decimal {
    let borrows = obligation.borrows().length();
    let mut weighted_borrowed_value_usd = zero();

    let mut i = 0;
    while (i < borrows) {
         let borrow = &mut obligation.borrows_mut()[i];
        let borrow_reserve = &reserves[borrow.reserve_array_index()];
        let borrow_weight = borrow_reserve.config().borrow_weight();

        // Sound state
        cvlm_assume_msg(borrow_weight.ge(one()), b"Borrow weight >= 1");
        let unweighted_borrowed_value_usd = borrow_reserve.market_value(borrow.borrowed_amount());
        let weighted_borrowed_value_usd_i = unweighted_borrowed_value_usd.mul(borrow_weight);
        weighted_borrowed_value_usd =
            weighted_borrowed_value_usd.add(weighted_borrowed_value_usd_i);
        i = i+1;
    };
    weighted_borrowed_value_usd
}


/// Refreshes the isolated asset borrowing status of an obligation.
///
/// Iterates through all borrows to determine if any borrow involves an isolated asset.
/// If any borrow is of an isolated asset, the obligation is marked as borrowing an isolated asset.
///
/// # Updates
/// - borrowing_isolated_asset: Set to true if any borrow involves an isolated reserve
public fun refresh_isolation<P>(obligation: &mut Obligation<P>, reserves: &vector<Reserve<P>>) {
    let borrows = obligation.borrows().length();

    let mut i = 0;
    let mut borrowing_isolated_asset = false;
    // Loop through borrows until we find an isolated asset or exhaust all borrows
    while (i < borrows && !borrowing_isolated_asset) {
        let borrow = &obligation.borrows()[i];
        let borrow_reserve = &reserves[borrow.reserve_array_index()];

        // Check if this borrow's reserve is isolated
        borrowing_isolated_asset = isolated(config(borrow_reserve));
        i = i+1;
    };

    *obligation.borrowing_isolated_asset_mut() = borrowing_isolated_asset;

}
