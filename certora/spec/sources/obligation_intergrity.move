module spec::obligation_integrity;



use suilend::obligation::Obligation;
use spec::dummy_pool_lending_market::DummyPool;
use cvlm::manifest::rule;
use cvlm::function::Function;
use suilend::obligation::create_obligation;
use suilend::lending_market::LendingMarket;
use cvlm::asserts::cvlm_assert;
use suilend::obligation;
use cvlm::ghost::ghost_destroy;


public fun cvlm_manifest() {
    rule(b"liquidatable_implies_unhealthy_base");
    rule(b"liquidatable_implies_unhealthy_step");
}

/**
open_ltv <= close_ltv
market_value_lower_bound <= market_value <= market_value_upper_bound

allowed_borrow_value_usd = market_value_lower_bound * open_ltv
unhealthy_borrow_value_usd = market_value * close_ltv

==> allowed_borrow_value_usd <= unhealthy_borrow_value_usd

weighted_borrowed_value_upper_bound_usd = market_value_upper_bound * borrow_weight
weighted_borrowed_value_usd = market_value * borrow_weight

==> weighted_borrowed_value_usd <= weighted_borrowed_value_upper_bound_usd


Unhealthy:    market_value_upper_bound * borrow_weight >   market_value_lower_bound * open_ltv
                            >=                                            <=
Liquidatable:     market_value * borrow_weight         >         market_value * close_ltv

market_value_upper_bound * borrow_weight >= market_value * borrow_weight > market_value * close_ltv >= market_value_lower_bound * open_ltv
|                                           |                                                      |                                       |             
|                                           |------------------------- LIQUIDATABLE ---------------|                                       |
|---------------------------------------------------------------------- UNHEALTHY ---------------------------------------------------------|

Thus: LIQUIDATABLE => UNHEALTHY
But not UNHEALTHY => LIQUIDATABLE
*/
public fun liquidatable_implies_unhealthy(obligation: &Obligation<DummyPool>): bool {
    let healthy = obligation.is_healthy();
    let liquidatable = obligation.is_liquidatable();
    return !liquidatable || !healthy
}


public fun liquidatable_implies_unhealthy_base(lending_market_id: ID, ctx: &mut TxContext) {
    let obligation = create_obligation(lending_market_id, ctx);

    cvlm_assert(liquidatable_implies_unhealthy(&obligation));

    ghost_destroy(obligation);
}

public fun liquidatable_implies_unhealthy_step(obligation: &mut Obligation<DummyPool>, target: Function) {
    // TODO: Needs a Obligation<DummyPool> implementation
    cvlm_assert(false);
}