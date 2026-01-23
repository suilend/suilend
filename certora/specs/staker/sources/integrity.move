module staker::integrity;

use cvlm::asserts::{cvlm_assert};

use cvlm::ghost::ghost_destroy;
use cvlm::manifest::{target, invoker, rule};
use dummy_pool::dummy_pool::DummyPool;

use suilend::staker::{Staker};
use sui::sui::SUI;
use sui::balance::Balance;
use sui_system::sui_system::SuiSystemState;
use cvlm::function::Function;

public fun cvlm_manifest() {
    // Public mut functions
    target(@dummy_pool, b"staker", b"deposit");
    target(@dummy_pool, b"staker", b"withdraw");
    target(@dummy_pool, b"staker", b"rebalance");
    target(@dummy_pool, b"staker", b"claim_fees");

    invoker(b"invoke");

    rule(b"deposit_increases_liability");
    rule(b"withdraw_decreases_liability");
    
}

native fun invoke(target: Function, staker: &mut Staker<DummyPool>);

public fun deposit_increases_liability(staker: &mut Staker<DummyPool>, sui: Balance<SUI>) {
    let liabilities_pre = staker.liabilities();
    let sui_val = sui.value();
    staker.deposit(sui);

    let liabilities_post = staker.liabilities();

    cvlm_assert(liabilities_post >= liabilities_pre);
    cvlm_assert(liabilities_post - liabilities_pre == sui_val);
}

public fun withdraw_decreases_liability(staker: &mut Staker<DummyPool>, withdraw_amount: u64, system_state: &mut SuiSystemState, ctx: &mut TxContext) {
    let liabilities_pre = staker.liabilities();
    let sui = staker.withdraw(withdraw_amount, system_state, ctx);

    let liabilities_post = staker.liabilities();

    cvlm_assert(liabilities_post <= liabilities_pre);
    cvlm_assert(liabilities_pre - liabilities_post  == sui.value());
    cvlm_assert(withdraw_amount  == sui.value());

    ghost_destroy(sui);
}