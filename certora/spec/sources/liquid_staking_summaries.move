module spec::liquid_staking_summaries;

use cvlm::manifest::{ summary, ghost };
use sui_system::staking_pool::PoolTokenExchangeRate;

public fun cvlm_manifest() {
    summary(b"get_sui_amount", @liquid_staking, b"storage", b"get_sui_amount");
}

// We assume that liquid_staking::storage::get_sui_amount is equivalent to sui_system::staking_pool::get_sui_amount
// This is validated in the "assumptions" spec
public native fun get_sui_amount(exchange_rate: &PoolTokenExchangeRate, token_amount: u64): u64 {
    spec::sui_system_summaries::get_sui_amount(exchange_rate, token_amount)
}
