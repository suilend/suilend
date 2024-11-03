/// Stake unlent Sui.
module suilend::staker {
    use liquid_staking::liquid_staking::{LiquidStakingInfo, AdminCap, Self, total_sui_supply, total_lst_supply};
    use liquid_staking::fees::{Self};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{TxContext};
    use sui::coin::{Self, TreasuryCap};
    use sui_system::sui_system::{SuiSystemState};
    use sui::sui::SUI;

    // errors
    const ETreasuryCapNonZeroSupply: u64 = 0;
    const EInvariantViolation: u64 = 1;

    // constants
    const U64_MAX: u64 = 18446744073709551615;
    const SUILEND_VALIDATOR: address = @0xce8e537664ba5d1d5a6a857b17bd142097138706281882be6805e17065ecde89;

    // how much of the sui should be staked. Eventually this number will trend to 100%, 
    // but we start at 50% for safety reasons.
    const TARGET_UTIL_BPS: u64 = 5000; // 50%

    public struct Staker<phantom P> has store {
        admin: AdminCap<P>,
        liquid_staking_info: LiquidStakingInfo<P>,
        lst_balance: Balance<P>,
        sui_balance: Balance<SUI>,
        liabilities: u64, // how much sui is owed to the reserve
    }

    /* Public-View Functions */
    public(package) fun liabilities<P>(staker: &Staker<P>): u64 {
        staker.liabilities
    }

    public(package) fun lst_balance<P>(staker: &Staker<P>): &Balance<P> {
        &staker.lst_balance
    }

    /* Public Mutative Functions */
    public(package) fun create_staker<P: drop>(
        treasury_cap: TreasuryCap<P>, 
        ctx: &mut TxContext
    ): Staker<P> {
        assert!(coin::total_supply(&treasury_cap) == 0, ETreasuryCapNonZeroSupply);

        let (admin_cap, liquid_staking_info) = liquid_staking::create_lst(
            fees::new_builder(ctx).to_fee_config(),
            treasury_cap, 
            ctx
        );

        Staker {
            admin: admin_cap,
            liquid_staking_info,
            lst_balance: balance::zero(),
            sui_balance: balance::zero(),
            liabilities: 0,
        }
    }

    public(package) fun deposit<P: drop>(
        staker: &mut Staker<P>,
        sui: Balance<SUI>,
    ) {
        staker.liabilities = staker.liabilities + sui.value();
        staker.sui_balance.join(sui);
    }

    public(package) fun stake<P: drop>(
        staker: &mut Staker<P>, 
        system_state: &mut SuiSystemState,
        sui: Balance<SUI>, 
        ctx: &mut TxContext
    ) {
        staker.liabilities = staker.liabilities + balance::value(&sui);

        let lst = staker.liquid_staking_info.mint(
            system_state,
            coin::from_balance(sui, ctx),
            ctx
        );

        staker.liquid_staking_info.increase_validator_stake(
            &staker.admin,
            system_state,
            SUILEND_VALIDATOR,
            U64_MAX,
            ctx
        );

        staker.lst_balance.join(lst.into_balance());
        assert!(staker.liquid_staking_info.total_sui_supply() >= staker.liabilities, EInvariantViolation);
    }

    // unstake sui. this function can return less than the requested amount due to rounding
    public(package) fun unstake<P: drop>(
        staker: &mut Staker<P>, 
        system_state: &mut SuiSystemState,
        unstake_amount: u64,
        ctx: &mut TxContext
    ): Balance<SUI> {
        staker.liquid_staking_info.refresh(system_state, ctx);

        let sui = staker.withdraw_n_sui(system_state, unstake_amount, ctx);

        staker.liabilities = staker.liabilities - unstake_amount;

        assert!(staker.liquid_staking_info.total_sui_supply() >= staker.liabilities, EInvariantViolation);

        sui
    }

    public(package) fun claim_fees<P: drop>(
        staker: &mut Staker<P>,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext
    ): Balance<SUI> {
        liquid_staking::refresh(&mut staker.liquid_staking_info, system_state, ctx);
        let total_sui_supply = total_sui_supply(&staker.liquid_staking_info);
        let excess_sui = total_sui_supply - staker.liabilities;

        let sui = withdraw_n_sui(staker, system_state, excess_sui, ctx);

        assert!(total_sui_supply(&staker.liquid_staking_info) >= staker.liabilities, EInvariantViolation);

        sui
    }

    /* Private Functions */

    // liquid_staking_info must be refreshed before calling this
    fun withdraw_n_sui<P: drop>(
        staker: &mut Staker<P>,
        system_state: &mut SuiSystemState,
        sui_amount_out: u64,
        ctx: &mut TxContext
    ): Balance<SUI> {
        let total_sui_supply = (total_sui_supply(&staker.liquid_staking_info) as u128);
        let total_lst_supply = (total_lst_supply(&staker.liquid_staking_info) as u128);

        let lst_to_redeem = (sui_amount_out as u128) * total_lst_supply / total_sui_supply;
        let lst = balance::split(&mut staker.lst_balance, (lst_to_redeem as u64));

        let sui = liquid_staking::redeem(
            &mut staker.liquid_staking_info,
            coin::from_balance(lst, ctx),
            system_state,
            ctx
        );

        assert!(coin::value(&sui) <= sui_amount_out, EInvariantViolation);

        coin::into_balance(sui)
    }
}
