module spec::liquid_staking_summaries;

use cvlm::manifest::{ summary, ghost };
use sui_system::staking_pool::PoolTokenExchangeRate;

public fun cvlm_manifest() {
    summary(b"get_sui_amount", @liquid_staking, b"storage", b"get_sui_amount");
    ghost(b"get_sui_amount");
}

public native fun get_sui_amount(exchange_rate: &PoolTokenExchangeRate, token_amount: u64): u64;
