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

        let treasury_cap = coin::create_treasury_cap_for_testing<STAKER_TESTS>(test_scenario::ctx(&mut scenario));

        let mut staker = create_staker(treasury_cap, test_scenario::ctx(&mut scenario));
        // TODO: check more stuff
        assert!(staker.liabilities() == 0, 0);

        let mut system_state = test_scenario::take_shared<SuiSystemState>(&scenario);

        let sui = balance::create_for_testing<SUI>(100 * MIST_PER_SUI);
        staker.stake(&mut system_state, sui, test_scenario::ctx(&mut scenario));

        assert!(staker.liabilities() == 100 * MIST_PER_SUI, 0);
        assert!(staker.lst_balance().value() == 100 * MIST_PER_SUI, 0);

        test_scenario::return_shared(system_state);
        advance_epoch_with_reward_amounts(0, 0, &mut scenario);
        // 1 lst is worth 2 sui now
        advance_epoch_with_reward_amounts(0, 200, &mut scenario); // 100 SUI

        let mut system_state = test_scenario::take_shared<SuiSystemState>(&scenario);
        let sui = staker.unstake(&mut system_state, 100 * MIST_PER_SUI, test_scenario::ctx(&mut scenario));

        std::debug::print(&staker);

        assert!(staker.liabilities() == 0, 0);
        assert!(staker.lst_balance().value() == 50 * MIST_PER_SUI, 0);
        assert!(sui.value() == 100 * MIST_PER_SUI, 0);

        let fees = staker.claim_fees(&mut system_state, test_scenario::ctx(&mut scenario));
        assert!(fees.value() == 100 * MIST_PER_SUI, 0);

        std::debug::print(&staker);

        sui::test_utils::destroy(sui);
        sui::test_utils::destroy(fees);
        sui::test_utils::destroy(staker);
        test_scenario::return_shared(system_state);
        test_scenario::end(scenario);
    }

}