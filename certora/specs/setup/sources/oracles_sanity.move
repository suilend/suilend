module spec::oracles_sanity;

use cvlm::manifest::{ target, target_sanity };

public fun cvlm_manifest() {
    target(@suilend, b"oracles", b"get_pyth_price_and_identifier");
    target_sanity();
}