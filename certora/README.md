# Certora Formal Verification: Suilend

This directory contains Certora's formal verification of the Suilend lending protocol, written in Move on Sui.

## Directory Structure

### `specs/`

The primary verification packages. Each subdirectory is an independent Move package containing specification files (written in Move using the `cvlm` framework), per-rule configuration files, and package metadata.

- `specs/commons/`: Shared helpers, invariants, and utilities used across all specification packages.
  - `sources/helper.move`: Setup helpers for constructing obligation and reserve state in pre-conditions.
  - `sources/inv.move`: Common invariants (e.g. `liquidatable_implies_unhealthy`, `forgivable_only_if_unhealthy_or_debt_free`) that are proved in individual spec packages and assumed as preconditions in others.
  - `sources/utils.move`: Miscellaneous utilities.
- `specs/dummy_pool/`: A synthetic `DummyPool` type used as the lending market type parameter throughout all specs, along with wrapper modules that expose internal contract functions to the Prover.
- `specs/setup/`: Sanity checks and summary validation for oracles, rate limiters, decimal arithmetic, and the SUI system staking interface.
- `specs/health/`: Obligation health and LTV properties.
- `specs/solvency/`: Reserve solvency and ctoken ratio properties.
- `specs/liquidation/`: Liquidation correctness properties.
- `specs/obligation/`: Obligation-level invariants (health consistency, isolation mode, reserve separation).
- `specs/staker/`: Staker solvency and fee accounting properties.

Each spec package follows the same layout:

- `sources/`: Specification modules. Each `.move` file encodes one or more verifiable properties as rules.
- `confs/`: Per-rule Certora Prover configuration files (`.conf`), one per property group.
- `Move.toml`: Package manifest referencing the `suilend` contract, `commons`, `dummy_pool`, the `cvlm` (Certora Verification Language for Move) library, and Certora Sui framework summaries.

### `munges/`

Code modification scripts and patch files. These make internal functions accessible to the Prover by widening their visibility.

- `munge.sh`: Applies all patches before running verification.
- `unmunge.sh`: Reverts all patches.
- `record_patches.sh`: Regenerates patch files from current working-directory diffs against HEAD.
- `*.patch`: Widens visibility of view functions and internal helpers and exposes internal states to the rules.

> [!NOTE]
> The patches are applied as git patches and must be kept in sync with the source code. If the patched files change, `munge.sh` will fail to apply and verification will not run. Use `record_patches.sh` to regenerate the patches after updating the source.

## Certora Prover

The Certora Prover is a formal verification tool for smart contracts. It statically proves or disproves properties expressed as rules in the Certora Verification Language for Move.

## Running Instructions

0. Install the latest certora prover by following the [installation guide](https://docs.certora.com/en/latest/docs/user-guide/install.html).

1. From the repository root, apply the munges:

    ```sh
    sh certora/munges/munge.sh
    ```

    This only needs to be done once per working copy. **Do not commit the munged files.**

2. Change into the desired spec package directory and run the desired verification job (see table below for all properties). Example:

    ```sh
    cd certora/specs/health
    certoraRun confs/health.conf
    ```

    Note that the spec package directory must be the working directory for `certoraRun`, otherwise it will fail to compile.

3. To revert munges:

    ```sh
    sh certora/munges/unmunge.sh
    ```

## High-Level Properties

See the doc-comments in each spec file for detailed descriptions of individual rules.

### Health (`specs/health/`)

- **Obligation Health Preservation** (`health.move`, `health.conf`): healthy obligations remain healthy after all lending operations, assuming no debt accumulation or price/config changes; newly created obligations are healthy.
- **Obligation Solvency Integrity** (`integrity.move`, `integrity.conf`): zero-debt obligations are always healthy; increasing collateral preserves health.
- **LTV Monotonicity** (`ltv_monotonicity.move`, `ltv_monotonicity_decrease.conf`, `ltv_monotonicity_increase_part1/2.conf`): LTV increases when debt increases and decreases when collateral increases.
- **Collateral Non-Decrease** (`no_col_decrease.move`, `no_col_decrease.conf`): total deposited ctokens never decrease except through explicit withdrawal.
- **No Deposit No Debt** (`no_deposit_no_debt.move`, `no_dep_no_borrow.conf`): obligations without deposits cannot have borrows; newly created obligations satisfy this invariant.
- **Unhealthy Obligation Condition** (`unhealthy_condition.move`, `unhealthy_condition.conf`): an obligation only becomes unhealthy when borrow value increases (excluding price/config changes).

### Solvency (`specs/solvency/`)

- **Reserve Solvency** (`solvency.move`, `solvency.conf`): ctoken ratio (assets/ctokens) is ≥ 1 for newly created reserves and is preserved by all lending operations.
- **CToken Ratio Monotonicity** (`ratios.move`, `ratios.conf`): the ctoken ratio (assets/shares) never decreases through user operations, ensuring ctokens maintain or increase in value.
- **Reserve Available Balance Accounting** (`accounting.move`, `accounting.conf`): the internal available balance never exceeds the sum of on-chain balance and staked SUI.

### Liquidation (`specs/liquidation/`)

- **Liquidation Only on Unhealthy Obligations** (`integrity.move`, `integrity.conf`): liquidation only succeeds on unhealthy obligations.
- **Liquidation Reduces Collateral and Debt** (`integrity.move`, `integrity.conf`): liquidation strictly reduces both collateral and borrowed amounts.
- **Liquidation Improves Health** (`integrity.move`, `integrity.conf`): liquidation does not worsen the LTV ratio (debt/collateral).
- **Liquidation Profitability** (`profit.move`, `profit.conf`): a liquidator does not incur a loss; the market value of seized ctokens equals or exceeds the market value of repaid debt, up to a bounded rounding error of 1 ctoken base unit.

### Obligation (`specs/obligation/`)

- **Obligation Health Consistency** (`health_consistency.move`, `health_consistency_p1/2.conf`): liquidatable obligations are unhealthy; forgivable obligations are either unhealthy or debt-free. Proved by induction over obligation-level operations.
- **Isolation Mode** (`isolation.move`, `isolation.conf`): obligations borrowing an isolated asset have exactly one borrow; depositing isolated assets provides zero borrowing power (open and close LTV = 0).
- **Reserve Separation** (`reserve_separation.move`, `reserve_separation.conf`): an obligation cannot simultaneously hold a borrow and a deposit from the same reserve.

### Staker (`specs/staker/`)

- **Staker Supply Covers Liabilities** (`liabilities_covered.move`, `liabilities_covered.conf`): `total_sui_supply >= liabilities` always holds; a minimum buffer of 1 SUI (`total_sui_supply - liabilities >= 1e9`) is maintained.
- **Staker Liability Integrity** (`integrity.move`, `integrity.conf`): deposit increases liabilities by exactly the deposited amount; withdrawal decreases liabilities by exactly the withdrawn amount.
- **Staker Fee Management** (`fees.move`, `fees.conf`): fee rates (redeem, mint, spread) remain at zero throughout all operations; accrued internal fees remain zero when fee rates are zero; fees accumulate monotonically except during explicit `claim_fees`.

## General Assumptions

- **Loop unrolling.** All specs use `optimistic_loop: true`. `loop_iter` is typically set to 1 or 2, with at most 2 reserves and 1–2 deposits/borrows per obligation modeled to keep verification tractable.
- **`claim_rewards_and_deposit` exclusion.** For tractability, this function is excluded from direct verification in several specs (health, solvency, ratio monotonicity) because it is a sequential composition of individually verified operations. Each sub-operation preserves the relevant invariant, so the composed function maintains the property inductively.
- **Simplified liquidation model.** Liquidation profitability and health improvement rules assume 1:1 prices, 1:1 ctoken ratios, and zero mint decimals for performance.
