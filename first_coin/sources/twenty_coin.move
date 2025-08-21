module TWENTY_PACKAGE::twenty;

use sui::object::{Self, UID};
use sui::tx_context::{Self, TxContext};
use sui::coin::{Self, Coin, TreasuryCap};
use sui::transfer;
use sui::sui::SUI;

use usdc::usdc::USDC;

// 證人物件，用於 init 函式
public struct TWENTY has drop {}

public struct ISSUER_TWENTY has key, store {
    id: UID
}

public struct USDC_Vault has key {
    id: UID,
    balance: Coin<USDC>
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
        balance: coin::zero<USDC>(ctx)
    };

    transfer::transfer(usdc_vault, tx_context::sender(ctx));

    let issuer_twenty = ISSUER_TWENTY {
        id: object::new(ctx)
    };

    transfer::transfer(issuer_twenty, tx_context::sender(ctx));
}

// ctx reference isn't first place.
public entry fun mint_twenty_token(
    cap: &mut TreasuryCap<TWENTY>,
    amount: u64,
    recipient: address,
    ctx: &mut TxContext) {

    coin::mint_and_transfer(cap, amount, recipient, ctx);
}

public entry fun burn_twenty_token(
    treasury_cap: &mut TreasuryCap<TWENTY>, 
    coin: Coin<TWENTY>,
    amount: u64,
    ctx: &mut TxContext) {

    coin::burn(treasury_cap, coin);
}

public entry fun deposit_usdc_in_vault(
    vault: &mut USDC_Vault,
    amount: Coin<USDC>,
    ctx: &mut TxContext) {
    coin::join(&mut vault.balance,  amount);
}


public entry fun swap_twenty_to_usdc(
    cap: &mut TreasuryCap<TWENTY>, 
    vault: &mut USDC_Vault, 
    mut payment: Coin<TWENTY>,  // 用戶傳入的 TWENTY 代幣
    twenty_amount: u64,         // 要兌換的數量
    recipient: address,
    ctx: &mut TxContext) {
    
    // 從用戶的代幣中分離出指定數量
    let twenty_to_burn = coin::split(&mut payment, twenty_amount, ctx);
    
    // 把剩餘的代幣還給用戶
    if (coin::value(&payment) > 0) {
        transfer::public_transfer(payment, tx_context::sender(ctx));
    } else {
        coin::destroy_zero(payment);
    };
    
    // 計算可換取的 USDC 數量
    let usdc_value = twenty_amount / 10000;
    
    // 銷毀指定數量的 TWENTY
    coin::burn(cap, twenty_to_burn);
    
    // 從 vault 中取出 USDC
    let usdc_coin = coin::split(&mut vault.balance, usdc_value, ctx);
    
    // 轉給接收者
    transfer::public_transfer(usdc_coin, recipient);
}

#[test_only]
public fun test_for_init(ctx: &mut TxContext) {
    init(TWENTY {}, ctx);
}