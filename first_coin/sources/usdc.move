module TWENTY_PACKAGE::usdc;

use sui::coin;
use sui::tx_context::{Self, TxContext};
use sui::transfer;
use sui::url;
use std::option;

/// The One-Time Witness struct for the USDC coin.
public struct USDC has drop {}

#[allow(lint(share_owned))]
fun init(witness: USDC, ctx: &mut TxContext) {
    let (treasury_cap, coin_metadata) = coin::create_currency(
        witness,
        6, // decimals
        b"USDC", // symbol
        b"USD Coin", // name
        b"USDC is a US dollar-backed stablecoin", // description
        option::none(), // icon URL
        ctx,
    );

    // Transfer treasury cap to sender
    transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    
    // Share the metadata object
    transfer::public_share_object(coin_metadata);
}

#[test_only]
public fun test_init_usdc(ctx: &mut TxContext) {
    init(USDC {}, ctx);
}