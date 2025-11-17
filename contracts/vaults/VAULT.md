# Suilend Vault

A multi-market lending vault that allows users to deposit a single asset type and earn yield from automated lending strategies across multiple Suilend markets. The vault manager deploys funds to various obligations and periodically compounds rewards while charging fees.

## Overview

Users deposit base tokens (e.g., SUI, USDC) and receive fungible vault shares representing proportional ownership. Share value is determined by Net Asset Value (NAV) which includes both liquid vault assets and deployed lending positions across multiple markets. The vault manager actively allocates capital across obligations to generate yield, while users remain passive participants.

## User Operations

**Deposits**: Users deposit the base token and receive vault shares based on current NAV per share. A minimum deposit value of 0.1 USD is enforced. Optional deposit fees (0-5%) are deducted from minted shares.

**Withdrawals**: Users redeem shares for proportional base token amounts based on NAV. When vault liquidity is insufficient, the protocol supports unwinding lending positions using a FIFO strategy. Optional withdrawal fees (0-5%) are deducted from shares before redemption.

**Yield**: Returns accrue passively as the vault's lending positions generate interest and as rewards are compounded. Users can track performance via NAV per share appreciation.

## Manager Operations

**Vault Management**: The manager holds a VaultManagerCap proving authority over the vault. They can deploy liquid funds to lending obligations, withdraw deployed funds back to vault liquidity, and create new obligations across multiple lending markets.

**Rewards Compounding**: Rewards can be compounded through two mechanisms:
- **Base token rewards**: Claimed and deposited directly back into the lending obligation (permissionless)
- **Non-base token rewards**: Withdrawn, swapped externally for base token, then deposited to vault. Oracle-based slippage protection is enforced when both tokens have reserves in MAIN_POOL. Manager permission required for tokens without oracle coverage

**Vault Crank**: A periodic operation that verifies all rewards with MAIN_POOL reserves/oracles have been compounded across all vault obligations, and accrues management and performance fees. The crank can only be called once per minute (minimum interval) and must be called at least once per hour. This freshness requirement is enforced on user/manager operations.

**Fee Redemption**: The manager can redeem their accumulated fee shares (deposit, withdrawal, management, and performance fees) at any time.

## Fee Structure

**Deposit Fee** (0-5% max): Charged as a percentage of minted shares. Fee shares are credited to manager before user receives remaining shares.

**Withdrawal Fee** (0-5% max): Charged as a percentage of shares being redeemed. Fee shares are credited to manager before calculating withdrawal amount.

**Management Fee** (0-5% max annual): Time-based fee on assets under management, accrued during vault crank operations. Calculated as an annualized rate based on time elapsed since last crank. Implemented by minting new shares that dilute existing holders proportionally.

**Performance Fee** (0-50% max): Fee on NAV gains above the high water mark. Only charged when NAV per share exceeds its previous peak. Calculated after accounting for management fee dilution.

## Technical Architecture

### Type System

- `P` is the share token type (unique per vault)
- `T` is the base asset type (e.g., SUI, USDC)
- `L` represents unique lending market types (varies per operation)

### Core Components

**Vault Object**: Shared object containing the treasury cap for share tokens, liquid balance of base token, accumulated manager fees in shares, and a map of lending market obligations. Tracks fee parameters, NAV high water mark, and crank timestamp.

**Obligations**: The vault can hold multiple obligations per lending market type. Each obligation is wrapped in a struct containing the ownership capability and ID.

**Manager Capability**: A transferable `VaultManagerCap` proves authority over the vault and gates privileged operations like fund deployment and fee collection.

### Accumulator Pattern

The vault manages positions across multiple lending markets, each with a different type parameter `L`. Move's type system prevents a single function from accepting arbitrary amounts of `LendingMarket<L>` instances with different `L` values.

To circumvent this a [Hot Potato](https://move-book.com/programmability/hot-potato-pattern/) pattern is utilised, to ensure all lending markets (and obligations) are processed in the PTB. There are 3 instances where this is utilised:

- `VaultValueAccumulator` - for gathering USD values of all obligations for NAV calculation
- `VaultCrankAccumulator` - for verifying all rewards with MAIN_POOL reserves/oracles have been compounded + gathering obligation values for management and performance fee accrual
- `VaultUnwindAccumulator` - for building and executing an unwind plan when insufficient liquidity exists to redeem a users shares

### NAV and Share Pricing

NAV per share is calculated as:
```
NAV = (total_value_usd * NAV_PRECISION * 10^SHARE_DECIMALS) / total_shares
```

Where `total_value_usd` is the sum of liquid assets and all obligation net values (deposits minus borrows) across all markets. All values are normalized to USD using Suilend reserve prices.

Share conversions use this NAV to convert between shares and USD value, then between USD and base token amounts.

### Price Oracle Integration

All valuations use prices from Suilend `lending_market.reserve`, which are Pyth-based. Price freshness is validated on every operation.

## Constraints

**Freshness Requirement**: All operations require that the vault was cranked within the last hour. This ensures NAV calculations include recent yield accrual.

**Accumulator Atomicity**: All accumulator patterns must be fully processed within a single PTB. Partial processing will fail.

**Order Enforcement**: Lending markets and obligations must be processed in FIFO order during accumulator operations. This ensures deterministic behavior and prevents manipulation via processing order.

**Minimum Deposits**: There is a 0.1 USD value minimum.

**Unwind Strategy**: Obligation unwinds are prioritised on a FIFO basis.

**Reward Compounding**: Base token rewards are compounded permissionlessly via direct deposit. Non-base token rewards are withdrawn, swapped externally, then deposited with slippage validation when oracles are available.

**Slippage**: The vault stores a `slippage_bps` parameter for reward swaps. When both reward and base tokens have MAIN_POOL reserves, slippage protection is enforced using oracle prices.

## Planned Features

**Cross-Asset Borrowing**: Allow the vault to borrow against deposited collateral across lending markets.

**More Integrations**: Support protocols other than core Suilend as deployment targets, such as [Suilend Strategies](https://suilend.fi/strategies).
