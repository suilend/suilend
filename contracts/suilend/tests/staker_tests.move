module suilend::staker_tests {

    public struct STAKER_TESTS has drop {}

    use sui::test_scenario::{Self, Scenario};
    use sui_system::governance_test_utils::{
        advance_epoch_with_reward_amounts,
        create_validator_for_testing,
        create_sui_system_state_for_testing,
    };
    use sui::balance::{Self};
    use sui::coin::{Self};
    use suilend::staker::{create_staker};
    use sui_system::sui_system::{SuiSystemState};
    use sui::sui::{SUI};

    /* Constants */
    const MIST_PER_SUI: u64 = 1_000_000_000;
    const SUILEND_VALIDATOR: address = @0xce8e537664ba5d1d5a6a857b17bd142097138706281882be6805e17065ecde89;

    public struct STAKER has drop {}

    fun setup_sui_system(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUILEND_VALIDATOR);
        let validator = create_validator_for_testing(SUILEND_VALIDATOR, 100, test_scenario::ctx(scenario));
        create_sui_system_state_for_testing(vector[validator], 0, 0, test_scenario::ctx(scenario));

        advance_epoch_with_reward_amounts(0, 0, scenario);
    }

    #[test]
    public fun test_end_to_end_happy() {
        let owner = @0x26;
        let mut scenario = test_scenario::begin(owner);
        setup_sui_system(&mut scenario);

        let treasury_cap = coin::create_treasury_cap_for_testing<STAKER>(test_scenario::ctx(&mut scenario));

        let mut staker = create_staker(treasury_cap, test_scenario::ctx(&mut scenario));
        assert!(staker.sui_balance().value() == 0, 0);
        assert!(staker.lst_balance().value() == 0, 0);
        assert!(staker.liabilities() == 0, 0);

        let mut system_state = test_scenario::take_shared<SuiSystemState>(&scenario);
        staker.rebalance(&mut system_state, scenario.ctx());

        let sui = balance::create_for_testing<SUI>(100 * MIST_PER_SUI);
        staker.deposit(sui);

        assert!(staker.liabilities() == 100 * MIST_PER_SUI, 0);
        assert!(staker.sui_balance().value() == 100 * MIST_PER_SUI, 0);
        assert!(staker.lst_balance().value() == 0, 0);

        let sui = staker.withdraw(100 * MIST_PER_SUI, &mut system_state, scenario.ctx());
        assert!(sui.value() == 100 * MIST_PER_SUI, 0);
        assert!(staker.liabilities() == 0, 0);
        assert!(staker.sui_balance().value() == 0, 0);
        assert!(staker.lst_balance().value() == 0, 0);

        staker.deposit(sui);
        staker.rebalance(&mut system_state, scenario.ctx());

        assert!(staker.liabilities() == 100 * MIST_PER_SUI, 0);
        assert!(staker.sui_balance().value() == 0, 0);
        assert!(staker.lst_balance().value() == 100 * MIST_PER_SUI, 0);
        assert!(staker.total_sui_supply() == 100 * MIST_PER_SUI, 0);
        assert!(staker.liquid_staking_info().total_sui_supply() == 100 * MIST_PER_SUI, 0);

        test_scenario::return_shared(system_state);

        advance_epoch_with_reward_amounts(0, 0, &mut scenario);
        // 1 lst is worth 2 sui now
        advance_epoch_with_reward_amounts(0, 200, &mut scenario); // 100 SUI

        let mut system_state = test_scenario::take_shared<SuiSystemState>(&scenario);

        staker.rebalance(&mut system_state, scenario.ctx());
        assert!(staker.liabilities() == 100 * MIST_PER_SUI, 0);
        assert!(staker.sui_balance().value() == 0, 0);
        assert!(staker.liquid_staking_info().total_sui_supply() == 200 * MIST_PER_SUI, 0);
        assert!(staker.lst_balance().value() == 100 * MIST_PER_SUI, 0);
        assert!(staker.total_sui_supply() == 200 * MIST_PER_SUI, 0);

        let sui = staker.claim_fees(&mut system_state, scenario.ctx());
        assert!(sui.value() == 99 * MIST_PER_SUI, 0);
        assert!(staker.liabilities() == 100 * MIST_PER_SUI, 0);
        assert!(staker.sui_balance().value() == 0, 0);
        assert!(staker.liquid_staking_info().total_sui_supply() == 101 * MIST_PER_SUI, 0);
        assert!(staker.lst_balance().value() == 50 * MIST_PER_SUI + 500_000_000, 0);
        assert!(staker.total_sui_supply() == 101 * MIST_PER_SUI, 0);
        sui::test_utils::destroy(sui);

        // should be no fees to claim
        let sui = staker.claim_fees(&mut system_state, scenario.ctx());
        assert!(sui.value() == 0, 0);
        assert!(staker.liabilities() == 100 * MIST_PER_SUI, 0);
        assert!(staker.sui_balance().value() == 0, 0);
        assert!(staker.liquid_staking_info().total_sui_supply() == 101 * MIST_PER_SUI, 0);
        assert!(staker.lst_balance().value() == 50 * MIST_PER_SUI + 500_000_000, 0);
        assert!(staker.total_sui_supply() == 101 * MIST_PER_SUI, 0);
        sui::test_utils::destroy(sui);

        let sui = staker.withdraw(MIST_PER_SUI + 1, &mut system_state, scenario.ctx());
        assert!(sui.value() == MIST_PER_SUI + 1, 0);
        assert!(staker.liabilities() == 99 * MIST_PER_SUI - 1, 0);
        assert!(staker.sui_balance().value() == 1, 0);
        assert!(staker.liquid_staking_info().total_sui_supply() == 100 * MIST_PER_SUI - 2, 0);
        assert!(staker.lst_balance().value() == 50 * MIST_PER_SUI - 1, 0);
        assert!(staker.total_sui_supply() == 100 * MIST_PER_SUI - 1, 0);
        sui::test_utils::destroy(sui);

        let sui = staker.claim_fees(&mut system_state, scenario.ctx());
        assert!(sui.value() == 0);
        sui::test_utils::destroy(sui);

        let sui = staker.withdraw(0, &mut system_state, scenario.ctx());
        assert!(sui.value() == 0);
        sui::test_utils::destroy(sui);

        test_scenario::return_shared(system_state);
        sui::test_utils::destroy(staker);
        test_scenario::end(scenario);
    }

}
