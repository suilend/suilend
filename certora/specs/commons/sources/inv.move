/// Common invariants used across multiple Certora specifications.
module commons::inv;

use cvlm::asserts::cvlm_assume_msg;
use suilend::obligation::Obligation;


/// Invariant: If an obligation is liquidatable, then it must be unhealthy.
/// In other words, only unhealthy obligations may be liquidated.
///
/// Proved in: spec/obligation/
public fun liquidatable_implies_unhealthy<P>(obligation: &Obligation<P>): bool {
    let healthy = obligation.is_healthy();
    let liquidatable = obligation.is_liquidatable();
    // liquidatable -> unhealthy  <==> !liquidatable || unhealthy
    return !liquidatable || !healthy
}

/// Invariant: If an obligation is forgivable, then it must be either unhealthy or debt-free.
/// This ensures that only obligations in distress or with no debt can be forgiven.
///
/// Proved in: spec/obligation/
public fun forgivable_only_if_unhealthy_or_debt_free<P>(obligation: &Obligation<P>): bool {
    let healthy = obligation.is_healthy();
    let forgivable = obligation.is_forgivable();
    let no_debt = obligation.borrows().length() == 0;
    // forgivable => unhealthy | no borrows
    return !forgivable || !healthy || no_debt
}


/// Requires that the obligation satisfies the sound state invariants.
/// This is used to assume invariants in specifications that depend on them.
public fun require_sound_obligation_state<P>(obligation: &Obligation<P>) {
   cvlm_assume_msg(liquidatable_implies_unhealthy(obligation), b"");
   cvlm_assume_msg(forgivable_only_if_unhealthy_or_debt_free(obligation), b"")
}


