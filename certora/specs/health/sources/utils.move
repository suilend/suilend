module health::utils;

use cvlm::asserts::{cvlm_assume_msg};
use dummy_pool::dummy_pool::DummyPool;
use suilend::decimal;
use suilend::lending_market::LendingMarket;
use suilend::obligation::Obligation;

public fun setup_obligation(lm: &LendingMarket<DummyPool>, ob_id: ID): &Obligation<DummyPool> {
    let obligation = lm.obligation(ob_id);
    cvlm_assume_msg(obligation.deposits().length() <= 1, b"");
    cvlm_assume_msg(obligation.borrows().length() <= 1, b"");
    require_freshness(lm, ob_id);
    obligation
}

fun require_freshness(lm: &LendingMarket<DummyPool>, ob_id: ID) {
    let obligation = lm.obligation(ob_id);

    let deposits = obligation.deposits().length();
    let borrows = obligation.borrows().length();

    /* Freshness */
    let zero = decimal::from(0);
    let one = decimal::from(1);

    // Collateral
    let mut deposited_value_usd = zero;
    let mut allowed_borrow_value = zero;
    let mut unhealthy_borrow_value_usd = zero;

    let mut i = 0;
    while (i < deposits) {
        let deposit = &obligation.deposits()[i];
        let deposit_reserve = &lm.reserves()[deposit.reserve_array_index()];
        let open_ltv = deposit_reserve.config().open_ltv();
        let close_ltv = deposit_reserve.config().close_ltv();

        cvlm_assume_msg(zero.lt(open_ltv), b"");
        cvlm_assume_msg(open_ltv.le(close_ltv), b"");
        cvlm_assume_msg(close_ltv.lt(one), b"");

        let deposited_value_usd_i = deposit_reserve.ctoken_market_value(deposit.deposited_ctoken_amount());

        let deposited_value_usd_lb_i = deposit_reserve.ctoken_market_value_lower_bound(deposit.deposited_ctoken_amount());
        let allowed_borrow_value_i = deposited_value_usd_lb_i.mul(open_ltv);

        let unhealthy_borrow_value_usd_i = deposited_value_usd_lb_i.mul(close_ltv);

        deposited_value_usd = deposited_value_usd.add(deposited_value_usd_i);
        allowed_borrow_value = allowed_borrow_value.add(allowed_borrow_value_i);
        unhealthy_borrow_value_usd = unhealthy_borrow_value_usd.add(unhealthy_borrow_value_usd_i);

        cvlm_assume_msg(deposit.market_value() == deposited_value_usd_i, b"");

        i = i+1;
    };

    cvlm_assume_msg(obligation.deposited_value_usd() == deposited_value_usd, b"");
    cvlm_assume_msg(obligation.allowed_borrow_value_usd() == allowed_borrow_value, b"");
    cvlm_assume_msg(obligation.unhealthy_borrow_value_usd() == unhealthy_borrow_value_usd, b"");

    // Debt

    let mut unweighted_borrowed_value_usd = decimal::from(0);
    let mut weighted_borrowed_value_usd = decimal::from(0);
    let mut weighted_borrowed_value_upper_bound_usd = decimal::from(0);

    let mut i = 0;
    while (i < borrows) {
        let borrow = &obligation.borrows()[i];
        let borrow_reserve = &lm.reserves()[borrow.reserve_array_index()];

        let borrow_weight = borrow_reserve.config().borrow_weight();
        cvlm_assume_msg(borrow_weight.le(one), b"");

        let unweighted_borrowed_value_usd_i = borrow_reserve.market_value(borrow.borrowed_amount());
        let weighted_borrowed_value_usd_i = unweighted_borrowed_value_usd_i.mul(borrow_weight);

        let unweighted_borrowed_value_usd_ub_i = borrow_reserve.market_value_upper_bound(borrow.borrowed_amount());
        let weighted_borrowed_value_upper_bound_usd_i = unweighted_borrowed_value_usd_ub_i.mul(
            borrow_weight,
        );

        unweighted_borrowed_value_usd =
            unweighted_borrowed_value_usd.add(unweighted_borrowed_value_usd_i);
        weighted_borrowed_value_usd =
            weighted_borrowed_value_usd.add(weighted_borrowed_value_usd_i);
        weighted_borrowed_value_upper_bound_usd =
            weighted_borrowed_value_upper_bound_usd.add(weighted_borrowed_value_upper_bound_usd_i);

        cvlm_assume_msg(borrow.market_value() == unweighted_borrowed_value_usd_i, b"");

        i = i+1;
    };

    cvlm_assume_msg(
        obligation.unweighted_borrowed_value_usd() == unweighted_borrowed_value_usd,
        b"",
    );
    cvlm_assume_msg(obligation.weighted_borrowed_value_usd() == weighted_borrowed_value_usd, b"");
    cvlm_assume_msg(
        obligation.weighted_borrowed_value_upper_bound_usd() == weighted_borrowed_value_upper_bound_usd,
        b"",
    );
}
