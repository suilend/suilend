/// Stake unlent Sui.
module suilend::staker {
    use liquid_staking::fees;
    use liquid_staking::liquid_staking::{Self, LiquidStakingInfo, AdminCap};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, TreasuryCap};
    use sui::sui::SUI;
    use sui_system::sui_system::SuiSystemState;

    // errors
    const ETreasuryCapNonZeroSupply: u64 = 0;
    const EInvariantViolation: u64 = 1;

    // constants
    const U64_MAX: u64 = 18446744073709551615;
    const SUILEND_VALIDATOR: address =
        @0xce8e537664ba5d1d5a6a857b17bd142097138706281882be6805e17065ecde89;

    // This is mostly so i don't hit the "zero lst coin mint" error.
    const MIN_DEPLOY_AMOUNT: u64 = 1_000_000; // 1 SUI
    const MIST_PER_SUI: u64 = 1_000_000_000;

    public struct Staker<phantom P> has store {
        admin: AdminCap<P>,
        liquid_staking_info: LiquidStakingInfo<P>,
        lst_balance: Balance<P>,
        sui_balance: Balance<SUI>,
        liabilities: u64, // how much sui is owed to the reserve
    }

    /* Public-View Functions */

    /// Gets the total liabilities of the staker.
    ///
    /// # Arguments
    ///
    /// * `staker` - A reference to the `Staker` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The total amount of SUI owed to the reserve.
    public(package) fun liabilities<P>(staker: &Staker<P>): u64 {
        staker.liabilities
    }

    /// Gets the balance of liquid staking tokens (LST).
    ///
    /// # Arguments
    ///
    /// * `staker` - A reference to the `Staker` to query.
    ///
    /// # Returns
    ///
    /// * `&Balance<P>` - A reference to the LST balance.
    public(package) fun lst_balance<P>(staker: &Staker<P>): &Balance<P> {
        &staker.lst_balance
    }

    /// Gets the balance of SUI held by the staker.
    ///
    /// # Arguments
    ///
    /// * `staker` - A reference to the `Staker` to query.
    ///
    /// # Returns
    ///
    /// * `&Balance<SUI>` - A reference to the SUI balance.
    public(package) fun sui_balance<P>(staker: &Staker<P>): &Balance<SUI> {
        &staker.sui_balance
    }

    /// Gets the total SUI supply, including staked and unstaked amounts.
    ///
    /// Note: This value can be stale if the `liquid_staking_info` has not been refreshed.
    ///
    /// # Arguments
    ///
    /// * `staker` - A reference to the `Staker` to query.
    ///
    /// # Returns
    ///
    /// * `u64` - The total SUI supply, including both staked and unstaked SUI.
    public(package) fun total_sui_supply<P>(staker: &Staker<P>): u64 {
        staker.liquid_staking_info.total_sui_supply() + staker.sui_balance.value()
    }

    /// Gets the liquid staking information.
    ///
    /// # Arguments
    ///
    /// * `staker` - A reference to the `Staker` to query.
    ///
    /// # Returns
    ///
    /// * `&LiquidStakingInfo<P>` - A reference to the liquid staking information.
    public(package) fun liquid_staking_info<P>(staker: &Staker<P>): &LiquidStakingInfo<P> {
        &staker.liquid_staking_info
    }

    /* Public Mutative Functions */

    /// Creates a new staker with the provided treasury cap.
    ///
    /// Initializes a staker with a new liquid staking configuration and zero balances.
    ///
    /// # Arguments
    ///
    /// * `treasury_cap` - The treasury cap for the liquid staking token type.
    ///
    /// # Returns
    ///
    /// * `Staker<P>` - A new staker instance.
    ///
    /// # Panics
    ///
    /// * If the treasury cap has a non-zero supply (`ETreasuryCapNonZeroSupply`).
    public(package) fun create_staker<P: drop>(
        treasury_cap: TreasuryCap<P>,
        ctx: &mut TxContext,
    ): Staker<P> {
        assert!(coin::total_supply(&treasury_cap) == 0, ETreasuryCapNonZeroSupply);

        let (admin_cap, liquid_staking_info) = liquid_staking::create_lst(
            fees::new_builder(ctx).to_fee_config(),
            treasury_cap,
            ctx,
        );

        Staker {
            admin: admin_cap,
            liquid_staking_info,
            lst_balance: balance::zero(),
            sui_balance: balance::zero(),
            liabilities: 0,
        }
    }

    /// Deposits SUI into the staker.
    ///
    /// Increases the staker's SUI balance and liabilities.
    ///
    /// # Arguments
    ///
    /// * `staker` - A mutable reference to the `Staker` to modify.
    /// * `sui` - The SUI balance to deposit.
    public(package) fun deposit<P>(staker: &mut Staker<P>, sui: Balance<SUI>) {
        staker.liabilities = staker.liabilities + sui.value();
        staker.sui_balance.join(sui);
    }

    /// Withdraws SUI from the staker.
    ///
    /// Unstakes SUI if necessary to fulfill the withdrawal request and updates liabilities.
    ///
    /// # Arguments
    ///
    /// * `staker` - A mutable reference to the `Staker` to modify.
    /// * `withdraw_amount` - The amount of SUI to withdraw.
    /// * `system_state` - A mutable reference to the `SuiSystemState` for staking operations.
    ///
    /// # Returns
    ///
    /// * `Balance<SUI>` - The withdrawn SUI balance.
    public(package) fun withdraw<P: drop>(
        staker: &mut Staker<P>,
        withdraw_amount: u64,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext,
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

    /// Rebalances the staker by staking available SUI.
    ///
    /// Converts available SUI to liquid staking tokens (LST) and increases validator stake.
    ///
    /// # Arguments
    ///
    /// * `staker` - A mutable reference to the `Staker` to modify.
    /// * `system_state` - A mutable reference to the `SuiSystemState` for staking operations.
    public(package) fun rebalance<P: drop>(
        staker: &mut Staker<P>,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext,
    ) {
        staker.liquid_staking_info.refresh(system_state, ctx);

        if (staker.sui_balance.value() < MIN_DEPLOY_AMOUNT) {
            return
        };

        let sui = staker.sui_balance.withdraw_all();
        let lst = staker
            .liquid_staking_info
            .mint(
                system_state,
                coin::from_balance(sui, ctx),
                ctx,
            );
        staker.lst_balance.join(lst.into_balance());

        staker
            .liquid_staking_info
            .increase_validator_stake(
                &staker.admin,
                system_state,
                SUILEND_VALIDATOR,
                U64_MAX,
                ctx,
            );
    }

    /// Claims excess SUI as fees from the staker.
    ///
    /// Withdraws any SUI in excess of liabilities plus a buffer, unstaking if necessary.
    ///
    /// # Arguments
    ///
    /// * `staker` - A mutable reference to the `Staker` to modify.
    /// * `system_state` - A mutable reference to the `SuiSystemState` for staking operations.
    ///
    /// # Returns
    ///
    /// * `Balance<SUI>` - The claimed SUI fees.
    ///
    /// # Panics
    ///
    /// * If the total SUI supply is less than the liabilities after claiming (`EInvariantViolation`).
    public(package) fun claim_fees<P: drop>(
        staker: &mut Staker<P>,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext,
    ): Balance<SUI> {
        staker.liquid_staking_info.refresh(system_state, ctx);

        let total_sui_supply = staker.total_sui_supply();

        // leave 1 SUI extra, just in case
        let excess_sui = if (total_sui_supply > staker.liabilities + MIST_PER_SUI) {
            total_sui_supply - staker.liabilities - MIST_PER_SUI
        } else {
            0
        };

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
    fun unstake_n_sui<P: drop>(
        staker: &mut Staker<P>,
        system_state: &mut SuiSystemState,
        sui_amount_out: u64,
        ctx: &mut TxContext,
    ) {
        if (sui_amount_out == 0) {
            return
        };

        let total_sui_supply = (staker.liquid_staking_info.total_sui_supply() as u128);
        let total_lst_supply = (staker.liquid_staking_info.total_lst_supply() as u128);

        // ceil lst redemption amount
        let lst_to_redeem =
            ((sui_amount_out as u128) * total_lst_supply + total_sui_supply - 1) / total_sui_supply;
        let lst = balance::split(&mut staker.lst_balance, (lst_to_redeem as u64));

        let sui = liquid_staking::redeem(
            &mut staker.liquid_staking_info,
            coin::from_balance(lst, ctx),
            system_state,
            ctx,
        );

        staker.sui_balance.join(sui.into_balance());
    }

    /* Test Functions */

    #[test_only]
    public fun deposit_for_testing<P>(staker: &mut Staker<P>, sui: Balance<SUI>) {
        staker.liabilities = staker.liabilities + sui.value();
        staker.sui_balance.join(sui);
    }
    
    #[test_only]
    public fun rebalance_for_testing<P: drop>(
        staker: &mut Staker<P>,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext,
    ) {
        rebalance(
            staker,
            system_state,
            ctx,
        );
    }
}
