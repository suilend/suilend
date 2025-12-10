module spec::lending_market_registry_sanity;

use cvlm::manifest::{ target, target_sanity };

public fun cvlm_manifest() {
    target(@suilend, b"lending_market_registry", b"create_lending_market");
    target_sanity();
}