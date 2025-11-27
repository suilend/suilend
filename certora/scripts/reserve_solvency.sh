certoraSuiProver Spec.conf --rule \
    "spec::reserve_solvency::solvency_base" \
    "spec::reserve_solvency::solvency_step_deduct_liquidation_fee" \
    "spec::reserve_solvency::solvency_step_join_fees" \
    "spec::reserve_solvency::solvency_step_update_reserve_config" \
    "spec::reserve_solvency::solvency_step_update_price" \
    "spec::reserve_solvency::solvency_step_compound_interest" \
    "spec::reserve_solvency::solvency_step_claim_fees" \
    "spec::reserve_solvency::solvency_step_deposit_liquidity_and_mint_ctokens" \
    "spec::reserve_solvency::solvency_step_redeem_ctokens" \
    "spec::reserve_solvency::solvency_step_fulfill_liquidity_request" \
    "spec::reserve_solvency::solvency_step_init_staker" \
    "spec::reserve_solvency::solvency_step_rebalance_staker" \
    "spec::reserve_solvency::solvency_step_unstake_sui_from_staker" \
    "spec::reserve_solvency::solvency_step_borrow_liquidity" \
    "spec::reserve_solvency::solvency_step_repay_liquidity" \
    "spec::reserve_solvency::solvency_step_forgive_debt" \
    "spec::reserve_solvency::solvency_step_deposit_ctokens" \
    "spec::reserve_solvency::solvency_step_withdraw_ctokens" \
    "spec::reserve_solvency::solvency_step_change_price_feed" 
  