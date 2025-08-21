module TWENTY_PACKAGE::twenty_coin_tests {
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::tx_context::TxContext;
    use sui::object::UID;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::sui::SUI;
    use usdc::usdc::USDC;
    use TWENTY_PACKAGE::twenty::{Self, TWENTY, ISSUER_TWENTY, USDC_Vault, test_for_init, mint_twenty_token, burn_twenty_token, deposit_usdc_in_vault, swap_twenty_to_usdc};
    use sui::table;

    // 測試地址
    const ADMIN: address = @0xAD;
    const USER1: address = @0xA1;
    const USER2: address = @0xA2;

    #[test]
    public fun test_mint_twenty_token() {
        // 1. 初始化測試場景，設定 ADMIN 為創始使用者
        let mut scenario = ts::begin(ADMIN);

        // --- 交易 1: ADMIN 發布 `twenty` 模組並獲取 TreasuryCap ---
        // 這是「創世」或「設定」交易
        ts::next_tx(&mut scenario, ADMIN);
        {
            // 呼叫初始化函式，這會創建 TreasuryCap<TWENTY> 並發送給 ADMIN
            test_for_init(ts::ctx(&mut scenario));
        };

        // --- 交易 2: ADMIN 使用 TreasuryCap 鑄造代幣 ---
        // 這是「執行操作」的交易
        ts::next_tx(&mut scenario, ADMIN);
        {
            // a. 從場景中取出 TreasuryCap
            let mut treasury_cap = ts::take_from_sender<TreasuryCap<TWENTY>>(&scenario);
            
            // b. 呼叫鑄幣函式，為 ADMIN 自己鑄造 100 個代幣
            mint_twenty_token(&mut treasury_cap, 100, ADMIN, ts::ctx(&mut scenario));

            // c. 將 TreasuryCap 物件歸還給場景
            ts::return_to_sender(&scenario, treasury_cap);
        };

        // --- 交易 3: ADMIN 驗證自己是否收到了正確數量的代幣 ---
        // 這是「驗證結果」的交易
        ts::next_tx(&mut scenario, ADMIN);
        {
            // a. 從 ADMIN 的持有物中取出剛剛鑄造的 Coin<TWENTY>
            let coin = ts::take_from_sender<Coin<TWENTY>>(&scenario);
            
            // b. 斷言代幣的餘額是否為 100 (你原本寫的是 10)
            assert!(coin::value(&coin) == 100, 1);

            // c. 將 coin 物件歸還，保持場景狀態乾淨
            ts::return_to_sender(&scenario, coin);
        };
        
        // 結束場景
        ts::end(scenario);
    }

    #[test]
    public fun test_burn_twenty_token() {
        // 1. 初始化測試場景，設定 ADMIN 為創始使用者
        let mut scenario = ts::begin(ADMIN);

        // --- 交易 1: ADMIN 發布 `twenty` 模組並獲取 TreasuryCap ---
        // 這是「創世」或「設定」交易
        ts::next_tx(&mut scenario, ADMIN);
        {
            // 呼叫初始化函式，這會創建 TreasuryCap<TWENTY> 並發送給 ADMIN
            test_for_init(ts::ctx(&mut scenario));
        };

        // --- 交易 2: ADMIN 使用 TreasuryCap 鑄造代幣 ---
        // 這是「執行操作」的交易
        ts::next_tx(&mut scenario, ADMIN);
        {
            // a. 從場景中取出 TreasuryCap
            let mut treasury_cap = ts::take_from_sender<TreasuryCap<TWENTY>>(&scenario);
            
            // b. 呼叫鑄幣函式，為 ADMIN 自己鑄造 100 個代幣
            mint_twenty_token(&mut treasury_cap, 100, ADMIN, ts::ctx(&mut scenario));

            // c. 將 TreasuryCap 物件歸還給場景
            ts::return_to_sender(&scenario, treasury_cap);
        };

        ts::next_tx(&mut scenario, ADMIN);
        {
            // a. 從場景中取出 TreasuryCap
            let mut treasury_cap = ts::take_from_sender<TreasuryCap<TWENTY>>(&scenario);
            let mut coin = ts::take_from_sender<Coin<TWENTY>>(&scenario);

            let burn_part = coin::split(&mut coin, 60, ts::ctx(&mut scenario));

            // b. 呼叫鑄幣函式，為 ADMIN 自己鑄造 100 個代幣
            burn_twenty_token(&mut treasury_cap, burn_part, 60, ts::ctx(&mut scenario));

            // c. 將 TreasuryCap 物件歸還給場景
            ts::return_to_sender(&scenario, treasury_cap);
            ts::return_to_sender(&scenario, coin);
        };

        // --- 交易 3: ADMIN 驗證自己是否收到了正確數量的代幣 ---
        // 這是「驗證結果」的交易
        ts::next_tx(&mut scenario, ADMIN);
        {
            // a. 從 ADMIN 的持有物中取出剛剛鑄造的 Coin<TWENTY>
            let coin = ts::take_from_sender<Coin<TWENTY>>(&scenario);
            
            // b. 斷言代幣的餘額是否為 100 (你原本寫的是 10)
            assert!(coin::value(&coin) == 40, 1);

            // c. 將 coin 物件歸還，保持場景狀態乾淨
            ts::return_to_sender(&scenario, coin);
        };
        
        // 結束場景
        ts::end(scenario);
    }

    #[test]
    public fun test_deposit_usdc_in_vault() {
        // 1. 初始化測試場景，設定 ADMIN 為創始使用者
        let mut scenario = ts::begin(ADMIN);

        // --- 交易 1: ADMIN 發布 `twenty` 模組並獲取 TreasuryCap ---
        // 這是「創世」或「設定」交易
        ts::next_tx(&mut scenario, ADMIN);
        {
            // 呼叫初始化函式，這會創建 TreasuryCap<TWENTY> 並發送給 ADMIN
            test_for_init(ts::ctx(&mut scenario));
        };

        ts::next_tx(&mut scenario, ADMIN);
        {
            // a. 從場景中取出 TreasuryCap
            let mut vault = ts::take_from_sender<USDC_Vault>(&scenario);
            // let mut usdc = ts::take_from_sender<Coin<USDC>>(&scenario);

             // 直接創建測試用的 USDC 代幣
            let usdc_coin = coin::mint_for_testing<USDC>(500000, ts::ctx(&mut scenario));

            // b. 呼叫鑄幣函式，為 ADMIN 自己鑄造 100 個代幣
            deposit_usdc_in_vault(&mut vault, usdc_coin, ts::ctx(&mut scenario));

            // c. 將 TreasuryCap 物件歸還給場景
            ts::return_to_sender(&scenario, vault);
            // ts::return_to_sender(&scenario, usdc);
        };

        // 結束場景
        ts::end(scenario);
    }

    #[test]
    public fun test_swap_twenty_to_usdc() {
        // 1. 初始化測試場景，設定 ADMIN 為創始使用者
        let mut scenario = ts::begin(ADMIN);

        // --- 交易 1: ADMIN 發布 `twenty` 模組並獲取 TreasuryCap ---
        ts::next_tx(&mut scenario, ADMIN);
        {
            // 呼叫初始化函式，這會創建 TreasuryCap<TWENTY> 並發送給 ADMIN
            test_for_init(ts::ctx(&mut scenario));
        };

        // --- 交易 2: 創建 USDC Vault 並添加一些 USDC ---
        ts::next_tx(&mut scenario, ADMIN);
        {
            // 假設你有創建 USDC vault 的函數
            // create_usdc_vault_with_balance(1000000, ts::ctx(&mut scenario)); // 添加足夠的USDC

            // a. 從場景中取出 TreasuryCap
            let mut vault = ts::take_from_sender<USDC_Vault>(&scenario);
            // let mut usdc = ts::take_from_sender<Coin<USDC>>(&scenario);

             // 直接創建測試用的 USDC 代幣
            let usdc_coin = coin::mint_for_testing<USDC>(10000, ts::ctx(&mut scenario));

            // b. 呼叫鑄幣函式，為 ADMIN 自己鑄造 100 個代幣
            deposit_usdc_in_vault(&mut vault, usdc_coin, ts::ctx(&mut scenario));

            // c. 將 TreasuryCap 物件歸還給場景
            ts::return_to_sender(&scenario, vault);
        };

        // --- 交易 3: 為 USER1 鑄造 TWENTY 代幣 ---
        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut treasury_cap = ts::take_from_sender<TreasuryCap<TWENTY>>(&scenario);
            
            // 為 USER1 鑄造 10000 個 TWENTY 代幣
            mint_twenty_token(&mut treasury_cap, 10000 * 9000, USER1, ts::ctx(&mut scenario));

            ts::return_to_sender(&scenario, treasury_cap);
        };

        // --- 交易 4: USER1 執行兌換 ---
        ts::next_tx(&mut scenario, USER1);
        {
            let mut treasury_cap = ts::take_from_address<TreasuryCap<TWENTY>>(&scenario, ADMIN);
            let mut vault = ts::take_from_address<USDC_Vault>(&scenario, ADMIN);
            let twenty_coin = ts::take_from_sender<Coin<TWENTY>>(&scenario);

            // 兌換 1000 個 TWENTY (應該得到 0.1 個 USDC)
            swap_twenty_to_usdc(
                &mut treasury_cap, 
                &mut vault, 
                twenty_coin,           // 傳入整個 coin 對象（會被函數消耗）
                10000 * 8000,                  // 要兌換的數量
                USER1,                 // 接收者
                ts::ctx(&mut scenario)
            );

            // 歸還沒有被消耗的對象
            ts::return_to_address(ADMIN, treasury_cap);
            ts::return_to_address(ADMIN, vault);
        };

        // --- 交易 5: 驗證結果 ---
        ts::next_tx(&mut scenario, USER1);
        {
            // 檢查 USER1 是否收到了正確數量的 USDC
            let usdc_coin = ts::take_from_sender<Coin<USDC>>(&scenario);
            let usdc_balance = coin::value(&usdc_coin);

            // 1000 TWENTY = 0.1 USDC = 100 (假設 USDC 有 3 位小數)
            assert!(usdc_balance == 8000, 0); // 根據你的 USDC 小數位數調整
            
            ts::return_to_sender(&scenario, usdc_coin);
            
            // 檢查是否還有剩餘的 TWENTY
            if (ts::has_most_recent_for_sender<Coin<TWENTY>>(&scenario)) {
                let remaining_twenty = ts::take_from_sender<Coin<TWENTY>>(&scenario);
                let remaining_balance = coin::value(&remaining_twenty);
                
                std::debug::print(&remaining_balance);

                // 應該剩下 9000 個 TWENTY (10000 - 1000)
                assert!(remaining_balance == 10000000, 1);

                ts::return_to_sender(&scenario, remaining_twenty);
            };
        };
    
        ts::end(scenario);
    }
}