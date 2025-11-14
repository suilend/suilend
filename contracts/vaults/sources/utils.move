module vaults::utils;

use sui::clock::Clock;
use suilend::{decimal::{Self, Decimal}, lending_market::LendingMarket};

/// T amount -> USD amount
public(package) fun token_amount_to_usd<L, T>(
    amount: u64,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
): Decimal {
    let reserve = lending_market.reserve<_, T>();
    reserve.assert_price_is_fresh(clock);
    reserve.market_value(decimal::from(amount))
}

/// USD amount -> T amount
public(package) fun usd_to_token_amount<L, T>(
    amount: Decimal,
    lending_market: &LendingMarket<L>, // Must contain reserve for T (price source)
    clock: &Clock,
): Decimal {
    let reserve = lending_market.reserve<_, T>();
    reserve.assert_price_is_fresh(clock);
    reserve.usd_to_token_amount(amount)
}
