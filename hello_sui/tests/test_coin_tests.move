#[test_only]
module test_coin::coin_tests {
    use test_coin::coin::{Self, JimCoin};
    use sui::test_scenario::{Self, Scenario};
    use sui::transfer;

    // 測試地址
    const ADMIN: address = @0xAD;
    const USER1: address = @0xA1;
    const USER2: address = @0xA2;

    #[test]
    fun test_create_coin() {
        let mut scenario = test_scenario::begin(ADMIN);
        
        // 測試創建代幣
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let coin = coin::create_coin(test_scenario::ctx(&mut scenario));
            
            // 驗證代幣價值
            assert!(coin::get_value(&coin) == 100, 0);
            
            // 轉移給 ADMIN
            transfer::public_transfer(coin, ADMIN);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_mint_and_transfer() {
        let mut scenario = test_scenario::begin(ADMIN);
        
        // ADMIN 創建並轉移代幣給 USER1
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            coin::mint_and_transfer(50, USER1, test_scenario::ctx(&mut scenario));
        };
        
        // 檢查 USER1 是否收到代幣
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let coin = test_scenario::take_from_sender<JimCoin>(&scenario);
            assert!(coin::get_value(&coin) == 50, 1);
            test_scenario::return_to_sender(&scenario, coin);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_transfer_coin() {
        let mut scenario = test_scenario::begin(ADMIN);
        
        // ADMIN 創建代幣
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            coin::mint_and_transfer(75, ADMIN, test_scenario::ctx(&mut scenario));
        };
        
        // ADMIN 轉移代幣給 USER2
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let coin = test_scenario::take_from_sender<JimCoin>(&scenario);
            coin::transfer_coin(coin, USER2);
        };
        
        // 檢查 USER2 是否收到代幣
        test_scenario::next_tx(&mut scenario, USER2);
        {
            let coin = test_scenario::take_from_sender<JimCoin>(&scenario);
            assert!(coin::get_value(&coin) == 75, 2);
            test_scenario::return_to_sender(&scenario, coin);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_burn_coin() {
        let mut scenario = test_scenario::begin(ADMIN);
        
        // 創建代幣
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            coin::mint_and_transfer(25, ADMIN, test_scenario::ctx(&mut scenario));
        };
        
        // 銷毀代幣
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let coin = test_scenario::take_from_sender<JimCoin>(&scenario);
            coin::burn_coin(coin);
        };
        
        // 驗證代幣已被銷毀（不應該存在）
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            assert!(!test_scenario::has_most_recent_for_sender<JimCoin>(&scenario), 3);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_failure_example() {
        // 這是一個失敗測試的例子
        assert!(false, 0);
    }
}