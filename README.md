# 基礎概念和環境搭建

## 理解 Sui 的核心概念

### Object-oriented programming model

在 Sui 中，所有的數據都是 Objects（物件），這與傳統區塊鏈（如 Ethereum）的賬戶模型完全不同。

- **QA :**
    - 有沒有例外?

### Move 語言基礎

- 每個 Object 都有：
    - Unique ID：全球唯一識別符
    - Owner：物件的擁有者
    - Version：版本號（用於防止雙花）
    - Data：實際的數據內容
- 可以不要有嗎?

```javascript
module hello_sui::coin {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// 定義一個簡單的代幣 Object
    struct Coin has key, store {
        id: UID,           // 物件的唯一 ID
        value: u64,        // 代幣的數值
        name: vector<u8>,  // 代幣名稱
    }

    /// 創建新代幣的函數
    public fun mint(value: u64, name: vector<u8>, ctx: &mut TxContext): Coin {
        Coin {
            id: object::new(ctx),
            value,
            name,
        }
    }

    /// 轉移代幣給指定地址
    public entry fun transfer_coin(coin: Coin, recipient: address) {
        transfer::transfer(coin, recipient);
    }

    /// 獲取代幣數值
    public fun value(coin: &Coin): u64 {
        coin.value
    }
}
```


一定會有包名 + 模組名稱。
都可以自訂像是hello_sui::coin。
包名 : move.toml定義。
每個.move檔案，至少一個module。用來組織功能。
也可以使用官方的package。

你的專案 = 一本書
├── 包名 = 書的標題（你決定）
└── 模組名 = 各章節標題（你決定）
    ├── 第一章：角色系統 (module my_game::character)
    ├── 第二章：戰鬥系統 (module my_game::battle)  
    └── 第三章：道具系統 (module my_game::item)

**注意:** move 語言命名規範?


1. struct Coin - 定義一個名為 Coin 的結構體（就是 Object）
1. has key, store - 這是 abilities（能力），非常重要：
    - key - 表示這個 Object 可以被儲存在全局存儲中，有唯一 ID
    - store - 表示這個 Object 可以被儲存在其他 Object 內部
1. 欄位說明：
    - id: UID - 每個 Object 都必須有的唯一識別符
    - value: u64 - 代幣數量（64位無符號整數）
    - name: vector<u8> - 代幣名稱（字節向量，類似字串）


public entry fun transfer_coin()  // 可以從交易直接調用
public fun mint()                 // 只能被其他函數調用

// 所有權轉移 - Object 被"消耗"了
transfer_coin(my_coin, @recipient)  // my_coin 不再屬於我

// 借用 - 只是讀取，Object 還是我的
let val = value(&my_coin);  // my_coin 還是我的

在專案根目錄（有 Move.toml 的地方）執行
> sui move build

**&mut TxContext**
use sui::object::{Self, UID};
//  ↑     ↑       ↑      ↑
//  │     │       │      └── 引入 UID 類型
//  │     │       └───────── 引入 object 模組本身
//  │     └───────────────── object 模組名稱
//  └─────────────────────── sui 是官方提供的包名

use sui::object::{UID, ID};
//                ↑    ↑
//                │    └── 物件 ID 類型
//                └─────── 唯一識別符類型

// 然後可以使用這些函數：
object::new(ctx)           // 創建新的 UID
object::uid_to_inner(uid)  // 取得 UID 的內部 ID
object::uid_to_address(uid) // 轉換為地址

```javascript
module hello_sui::example {
    use sui::object::{Self, UID, ID};  // 引入模組 + 兩個類型
    use sui::tx_context::TxContext;

    struct MyObject has key {
        id: UID,        // ← 使用 UID 類型
    }

    public fun create_object(ctx: &mut TxContext): MyObject {
        MyObject {
            id: object::new(ctx),  // ← 使用 object 模組的 new 函數
        }
    }

    public fun get_id(obj: &MyObject): ID {
        object::uid_to_inner(&obj.id)  // ← 使用 object 模組的函數
    }
}


// 物件系統
use sui::object::{Self, UID, ID};

// 轉移功能
use sui::transfer::{Self};

// 交易上下文
use sui::tx_context::{Self, TxContext};

// 代幣標準
use sui::coin::{Self, Coin, TreasuryCap};

// 事件系統
use sui::event::{Self};

// 字串處理
use sui::string::{Self, String};

// 向量操作
use sui::vec_map::{Self, VecMap};

// 時鐘功能
use sui::clock::{Self, Clock};
```

### test

```bash
# 在 hello_sui 目錄下執行

# 1. 重新編譯（修正錯誤後）
sui move build

# 2. 運行所有測試
sui move test

# 3. 運行特定測試
sui move test test_create_coin

# 4. 顯示詳細輸出
sui move test --verbose

# 5. 運行測試並顯示 gas 使用
sui move test --gas-report

# 運行包含失敗的測試
sui move test --include-test-failures

# 運行測試並顯示覆蓋率
sui move test --coverage

# 只運行特定模組的測試
sui move test test_coin::coin_tests

# 運行測試並保存結果
sui move test --save-results test_results.json
```

### Gas 機制和交易模型


## 創建第一個 Sui 項目

### 初始化項目結構

### 了解 Move.toml 配置

### 基本的項目組織