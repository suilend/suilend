module health::utils;

use cvlm::asserts::cvlm_assume_msg;
use suilend::obligation::Obligation;



public fun require_liquidatable_only_if_unhealthy<P>(obligation: &Obligation<P>) {
    // Liquidatable => Unhealthy
    cvlm_assume_msg(
        !obligation.is_liquidatable() || !obligation.is_healthy(),
        b"Require invariant: Obligation is only liquidatable if it is unhealthy",
    );
}

public fun forgivable_only_if<P>(obligation: &Obligation<P>) {
    let forgivable = obligation.is_forgivable();
    let healthy = obligation.is_healthy();
    let no_debt = obligation.borrows().length() == 0;
    // forgivable => unhealthy | no borrows
    cvlm_assume_msg(
        !forgivable || (!healthy || no_debt),
        b"Require invariant: Obligation is only forgivable if it is unhealthy or has no debt",
    );
}
