/// Stake unlent Sui.
module suilend::staker {
    use liquid_staking::liquid_staking::{LiquidStakingInfo, AdminCap, Self};
    use liquid_staking::fees::{Self};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{TxContext};
    use sui::coin::{Self, TreasuryCap};
    use sui_system::sui_system::{SuiSystemState};
    use sui::sui::SUI;
    use std::option::{Self, Option};
    use sui::transfer::Self;

    // errors
    const ETreasuryCapNonZeroSupply: u64 = 0;
    const EInvariantViolation: u64 = 1;

    // constants
    const U64_MAX: u64 = 18446744073709551615;
    const SUILEND_VALIDATOR: address = @0xce8e537664ba5d1d5a6a857b17bd142097138706281882be6805e17065ecde89;

    // This is mostly so i don't hit the "zero lst coin mint" error.
    const MIN_DEPLOY_AMOUNT: u64 = 1_000_000; // 1 SUI

    public struct STAKER has drop {}

    fun init(otw: STAKER, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            otw,
            9,
            b"SprungSui",
            b"",
            b"",
            option::none(),
            ctx
        );

        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, ctx.sender())
    }

    public struct Staker has store {
        admin: AdminCap<STAKER>,
        liquid_staking_info: LiquidStakingInfo<STAKER>,
        lst_balance: Balance<STAKER>,
        sui_balance: Balance<SUI>,
        liabilities: u64, // how much sui is owed to the reserve
    }

    /* Public-View Functions */
    public(package) fun liabilities(staker: &Staker): u64 {
        staker.liabilities
    }

    public(package) fun lst_balance(staker: &Staker): &Balance<STAKER> {
        &staker.lst_balance
    }

    public(package) fun sui_balance(staker: &Staker): &Balance<SUI> {
        &staker.sui_balance
    }

    // this value can be stale if the staker hasn't refreshed the liquid_staking_info
    public(package) fun total_sui_supply(staker: &Staker): u64 {
        staker.liquid_staking_info.total_sui_supply() + staker.sui_balance.value()
    }

    public(package) fun liquid_staking_info(staker: &Staker): &LiquidStakingInfo<STAKER> {
        &staker.liquid_staking_info
    }

    /* Public Mutative Functions */
    public(package) fun create_staker(
        treasury_cap: TreasuryCap<STAKER>, 
        ctx: &mut TxContext
    ): Staker {
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

    public(package) fun deposit(
        staker: &mut Staker,
        sui: Balance<SUI>,
    ) {
        staker.liabilities = staker.liabilities + sui.value();
        staker.sui_balance.join(sui);
    }

    public(package) fun withdraw(
        staker: &mut Staker,
        withdraw_amount: u64,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext
    ): Balance<SUI> {
        staker.liquid_staking_info.refresh(system_state, ctx);

        if (withdraw_amount > staker.sui_balance.value()) {
            let unstake_amount = withdraw_amount - staker.sui_balance.value();
            staker.unstake_n_sui(system_state, unstake_amount, ctx);
        };

        let sui = staker.sui_balance.split(withdraw_amount);
        staker.liabilities = staker.liabilities - sui.value();

        sui
    }

    public(package) fun rebalance(
        staker: &mut Staker,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext
    ) {
        staker.liquid_staking_info.refresh(system_state, ctx);

        if (staker.sui_balance.value() < MIN_DEPLOY_AMOUNT) {
            return
        };

        let sui = staker.sui_balance.withdraw_all();
        let lst = staker.liquid_staking_info.mint(
            system_state,
            coin::from_balance(sui, ctx),
            ctx
        );
        staker.lst_balance.join(lst.into_balance());

        staker.liquid_staking_info.increase_validator_stake(
            &staker.admin,
            system_state,
            SUILEND_VALIDATOR,
            U64_MAX,
            ctx
        );
    }

    public(package) fun claim_fees(
        staker: &mut Staker,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext
    ): Balance<SUI> {
        staker.liquid_staking_info.refresh(system_state, ctx);

        let total_sui_supply = staker.total_sui_supply();
        let excess_sui = total_sui_supply - staker.liabilities;

        if (excess_sui > staker.sui_balance.value()) {
            let unstake_amount = excess_sui - staker.sui_balance.value();
            staker.unstake_n_sui(system_state, unstake_amount, ctx);
        };

        let sui = staker.sui_balance.split(excess_sui);

        assert!(staker.total_sui_supply() >= staker.liabilities, EInvariantViolation);

        sui
    }

    /* Private Functions */

    // liquid_staking_info must be refreshed before calling this
    // this function can unstake slightly more sui than requested due to rounding.
    fun unstake_n_sui(
        staker: &mut Staker,
        system_state: &mut SuiSystemState,
        sui_amount_out: u64,
        ctx: &mut TxContext
    ) {
        if (sui_amount_out == 0) {
            return;
        };

        let total_sui_supply = (staker.liquid_staking_info.total_sui_supply() as u128);
        let total_lst_supply = (staker.liquid_staking_info.total_lst_supply() as u128);

        // ceil lst redemption amount
        let lst_to_redeem = ((sui_amount_out as u128) * total_lst_supply + total_sui_supply - 1) / total_sui_supply;
        let lst = balance::split(&mut staker.lst_balance, (lst_to_redeem as u64));

        let sui = liquid_staking::redeem(
            &mut staker.liquid_staking_info,
            coin::from_balance(lst, ctx),
            system_state,
            ctx
        );

        staker.sui_balance.join(sui.into_balance());
    }
}
