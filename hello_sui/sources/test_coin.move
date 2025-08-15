module test_coin::coin{

// 引用沒有用，會出現錯誤
use sui::transfer;
use sui::tx_context::{Self, TxContext};
use sui::object::{Self, UID};

public struct JimCoin has key, store {
    id: UID,
    value: u64
}
    
public fun create_coin(ctx: &mut TxContext): JimCoin {
    JimCoin {
        id: object::new(ctx),
        value: 100,
    }
}

/// 轉移 JimCoin
public entry fun transfer_coin(coin: JimCoin, recipient: address) {
    transfer::public_transfer(coin, recipient);
}

/// 創建並轉移 JimCoin
public entry fun mint_and_transfer(
    value: u64,
    recipient: address,
    ctx: &mut TxContext
) {
    let coin = create_coin(ctx);
    transfer::public_transfer(coin, recipient);
}

/// 獲取代幣價值
public fun get_value(coin: &JimCoin): u64 {
    coin.value
}

/// 銷毀代幣
public entry fun burn_coin(coin: JimCoin) {
    let JimCoin { id, value: _ } = coin;
    object::delete(id);
}
}