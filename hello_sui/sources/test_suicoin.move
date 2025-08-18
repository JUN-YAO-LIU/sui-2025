module test_coin::mytoken {
    use sui::coin::{Self, Coin, TreasuryCap};

    /// 代幣類型見證者
    public struct MYTOKEN has drop {}
    
    /// 初始化函數（一次性執行）
    fun init(witness: MYTOKEN, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<MYTOKEN>(
            witness,
            9,                    // 小數位數
            b"MTK",              // 符號
            b"My Token",         // 名稱
            b"Description",      // 描述
            option::none(),      // 現在可以使用了
            ctx
        );
        
        // 鑄幣權限給部署者
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        
        // 元數據設為共享對象
        transfer::public_share_object(metadata);
    }

    /// 添加一些實用函數
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<MYTOKEN>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx);
    }

    public entry fun burn(
        treasury_cap: &mut TreasuryCap<MYTOKEN>, 
        coin: Coin<MYTOKEN>
    ) {
        coin::burn(treasury_cap, coin);
    }
}