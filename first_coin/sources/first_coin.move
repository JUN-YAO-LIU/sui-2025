module first_coin_PACKAGE::f1_coin;

use sui::common::{Self, UID};
use sui::tx_context::{Self, TxContext};
use sui::coin::{Self, Coin};
use sui::transfer;
use sui::balance::{Self, Balance};

use USDC_PACKAGE::usdc::USDC;

struct F1_Coin has key, store {
    id: UID,
    value: u64,
    name: vector<u8>
};

// 儲存 USDC 幣的物件
struct USDC_Vault has key, store {
    id: UID,
    balance: Coin<USDC> // 這裡從 SUI 換成 USDC
}

public entry fun mint(
    usdc_to_deposit: Coin<USDC>,
    ctx: &mut TxContext) {

}


fun create_coin(ctx: &mut TxContext): F1_Coin {
    let coin = F1_Coin {
        id: object::new(ctx),
        value: 1000, // Example value, can be adjusted
        name: b"F1 Coin".to_vec(),
    };
    coin
}