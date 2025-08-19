module TWENTY_PACKAGE::twenty;

use sui::object::{Self, UID};
use sui::tx_context::{Self, TxContext};
use sui::coin::{Self, Coin, TreasuryCap};
use sui::transfer;

use usdc::usdc::USDC;

// 證人物件，用於 init 函式
public struct TWENTY has drop {}

public struct ISSUER_TWENTY has key, store {
    id: UID
}

public struct USDC_Vault has key, store {
    id: UID,
    balance: u64  // Simplified to use u64 instead of Coin<USDC>
}

public struct GameParticipant has key, store {
    id: UID,
    player_address: address
}

// internal
fun init(otw: TWENTY, ctx: &mut TxContext){
    let (treasury_cap, coin_metadata) = coin::create_currency(
        otw,
        0, // no decimals
        b"TWENTY", // symbol
        b"20 Game Token", // name
        b"Token for 20 game", // description
        option::none(), // url
        ctx,
    );

    // 鑄幣權限給部署者
    transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    
    // 元數據設為共享對象
    transfer::public_share_object(coin_metadata);

    let usdc_vault = USDC_Vault {
        id: object::new(ctx),
        balance: 0
    };
    
    transfer::transfer(usdc_vault, tx_context::sender(ctx));

    let issuer_twenty = ISSUER_TWENTY {
        id: object::new(ctx)
    };

    transfer::transfer(issuer_twenty, tx_context::sender(ctx));
}

public entry fun join_game(issuer: &mut ISSUER_TWENTY, ctx: &mut TxContext) {
    let participant = GameParticipant {
        id: object::new(ctx),
        player_address: tx_context::sender(ctx)
    };
    transfer::transfer(participant, tx_context::sender(ctx));
}


// ctx reference isn't first place.
public entry fun mint_twenty_token(
    cap: &mut TreasuryCap<TWENTY>,
    amount: u64,
    recipient: address,
    ctx: &mut TxContext) {

    coin::mint_and_transfer(cap, amount, recipient, ctx);
}

public fun burn_twenty_token(
    treasury_cap: &mut TreasuryCap<TWENTY>, 
    coin: Coin<TWENTY>,
    amount: u64,
    ctx: &mut TxContext) {

   coin::burn(treasury_cap, coin);
}

public entry fun deposit_usdc_in_vault(
    vault: &mut USDC_Vault, 
    usdc_to_deposit: Coin<USDC>, 
    ctx: &mut TxContext) {
        
    let balance = vault.balance;
    vault.balance = balance + usdc_to_deposit.value();

    let new_vault = USDC_Vault {
        id: object::new(ctx),
        balance: vault.balance
    };

    transfer::transfer(new_vault, tx_context::sender(ctx));
}

public entry fun swap_twenty_to_usdc(
    twenty: Coin<TWENTY>,
    ctx: &mut TxContext) {
    // let usdc = coin::swap(twenty, ctx);
    // coin::transfer(usdc, tx_context::sender(ctx), ctx);
}