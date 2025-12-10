module spec::rate_limiter_sanity;

use cvlm::manifest::{ target, target_sanity };

public fun cvlm_manifest() {
    target(@suilend, b"rate_limiter", b"process_qty");
    target(@suilend, b"rate_limiter", b"remaining_outflow");
    target_sanity();
}