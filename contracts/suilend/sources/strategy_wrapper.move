module suilend::strategy_wrapper {
    use std::ascii::{Self, String};
    use std::option::{Self, Option};
    use sui::clock::Clock;
    use sui::coin::Coin;
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use suilend::lending_market::{Self, LendingMarket, ObligationOwnerCap};
    use suilend::reserve::CToken;

    // Phantom type for the lending market
    public struct LENDING_MARKET has drop {}

    // Errors
    const ENotOwner: u64 = 0;
    const ECapAlreadyEjected: u64 = 1;

    // Structs
    public struct StrategyObligation has key {
        id: UID,
        obligation_id: ID,
        cap: Option<ObligationOwnerCap<LENDING_MARKET>>,
        tag: String,
        owner: address,
    }

    // Events
    public struct CreatedStrategyObligation has copy, drop {
        strategy_id: ID,
        obligation_id: ID,
        tag: String,
        owner: address,
    }

    public struct EjectedCap has copy, drop {
        strategy_id: ID,
        obligation_id: ID,
        recipient: address,
    }

    // Public functions
    public entry fun create_strategy_obligation(
        lending_market: &mut LendingMarket<LENDING_MARKET>,
        tag: vector<u8>,
        ctx: &mut TxContext
    ) {
        let cap = lending_market::create_obligation(lending_market, ctx);
        let obligation_id = lending_market::obligation_id(&cap);

        let strategy = StrategyObligation {
            id: object::new(ctx),
            obligation_id,
            cap: option::some(cap),
            tag: ascii::string(tag),
            owner: tx_context::sender(ctx),
        };

        event::emit(CreatedStrategyObligation {
            strategy_id: object::id(&strategy),
            obligation_id,
            tag: strategy.tag,
            owner: strategy.owner,
        });

        transfer::share_object(strategy);
    }

    public entry fun eject(
        strategy: &mut StrategyObligation,
        recipient: address,
        ctx: &TxContext
    ) {
        assert!(tx_context::sender(ctx) == strategy.owner, ENotOwner);
        assert!(option::is_some(&strategy.cap), ECapAlreadyEjected);

        let cap = option::extract(&mut strategy.cap);
        transfer::public_transfer(cap, recipient);

        event::emit(EjectedCap {
            strategy_id: object::id(strategy),
            obligation_id: strategy.obligation_id,
            recipient,
        });
    }

    // Example wrapper function for depositing ctokens
    public entry fun deposit_ctokens_into_strategy<T>(
        strategy: &StrategyObligation,
        lending_market: &mut LendingMarket<LENDING_MARKET>,
        reserve_array_index: u64,
        clock: &Clock,
        deposit: Coin<CToken<LENDING_MARKET, T>>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == strategy.owner, ENotOwner);
        assert!(option::is_some(&strategy.cap), ECapAlreadyEjected);

        lending_market::deposit_ctokens_into_obligation<LENDING_MARKET, T>(
            lending_market,
            reserve_array_index,
            option::borrow(&strategy.cap),
            clock,
            deposit,
            ctx
        );
    }

    // TODO: Add more wrapper functions for borrow, withdraw, repay, etc., following the same pattern
    // TODO: Automated reward compounding (to be implemented later)
    // TODO: public entry fun compound_rewards(strategy: &StrategyObligation, ...) { ... }
} 