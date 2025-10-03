# Isolated Vault

### User Features
- **Deposit Assets**: Deposit supported tokens (e.g., SUI, USDC) to receive vault shares representing ownership
- **Withdraw Assets**: Redeem shares for proportional assets plus accrued yield
- **Yield Earning**: Earn returns from lending activities without managing positions directly

### Manager Actions
- **Fund Deployment**: Deploy vault assets to multiple lending markets (Suilend) for yield generation
- **Position Management**: Create and manage multiple obligations across multiple markets
- **Risk Controls**: Utilization rate limits are applied to vault assets
- **Fee Collection**: Vault manager can claim accrued fees

### Fee Structure
- **Deposit Fee**: Charged on deposits
- **Withdrawal Fee**: Charged on withdrawals
- **Management Fee**: Annual fee on assets under management
- **Performance Fee**: Fee on realized gains

### Technical Features
- **NAV-Based Valuation**: Share value tracks Net Asset Value (NAV) including liquid assets and lending positions
- **Atomic Operations**: Fee accrual and transactions happen atomically
- **Event Logging**: Event emission for offchain monitoring
- **Oracle Integration**: Uses Pyth price feeds for USD valuations
