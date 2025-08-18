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

public fun create_coin_with_value(value: u64, ctx: &mut TxContext): JimCoin {
    JimCoin {
        id: object::new(ctx),
        value: value,  // 使用傳入的值
    }
}

/// 轉移 JimCoin
public entry fun transfer_coin(coin: JimCoin, recipient: address) {
    transfer::public_transfer(coin, recipient);
}

public entry fun mint_coin(recipient: address, ctx: &mut TxContext) {
    let coin = create_coin(ctx);
    transfer::public_transfer(coin, recipient);
}

/// 創建並轉移 JimCoin
public entry fun mint_and_transfer(
    value: u64,
    recipient: address,
    ctx: &mut TxContext
) {
    let coin = create_coin(ctx);
    split_and_transfer(coin, value, recipient, ctx);
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

public entry fun split_and_transfer(
    mut coin: JimCoin,
    split_amount: u64,
    recipient: address,
    ctx: &mut TxContext
) {
    // 檢查餘額是否足夠
    assert!(coin.value >= split_amount, 0);
    
    if (coin.value == split_amount) {
        // 如果要轉移的金額等於總額，直接轉移整個代幣
        transfer::public_transfer(coin, recipient);
    } else {
        // 減少原代幣的價值
        coin.value = coin.value - split_amount;
        
        // 創建新代幣給接收者
        let new_coin = JimCoin {
            id: object::new(ctx),
            value: split_amount,
        };
        
        // 轉移新代幣給接收者
        transfer::public_transfer(new_coin, recipient);
        
        // 剩餘代幣回到發送者
        transfer::public_transfer(coin, tx_context::sender(ctx));
    }
}
}