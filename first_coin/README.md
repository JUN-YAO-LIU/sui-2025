address = 0x361ff5d1ee306da3692f0a55c57ff27cff73d1d39ff7b783f2146400a822ee0e

PackageID = 0xed0ece3cae9266c11090a5e6e4dac9efd5bdedeebc65245e5844919743f81598

USDC_Vault = 0x27b285a6ab60a34f28f12f6ab091a1181c22970d371b3ed0eb654e971c3a4fd5

UpgradeCap = 0x82cc6d4235f3417bd3479b4604bffbc1e529218ac6f9c8bdbf73e4babad35766

TreasuryCap<TWENTY> = 0xe12abdc9883e290a47d2e61b1477c532117fa5a453e9ddc8bcb2c9c8c989b10f

CoinMetadata = 0xe6cb6013aea9e08fe9b5f847f1acb0a2e8124a3b3e1fb74a5b02309be218e568

ISSUER_TWENTY = 0xe6ccd7a3757ec4149a420249d915be8f87bf72ad0a9cd0350e7f36dbb0a3de66

SUI = 0x38d9ea911f59067f77ebf9b25214e0752053083825305fb170a416d948c2a6b6

不是packageID。是你錢包獲得的objectID。
USDC = 0x637643192ee7f74640702b4deaf5c18ede94ad7157ea5e0414544a8505ee3c3d

ObjectType 要先存。

**Successfully**
sui client call --package 0xf001416442c35c99ce1665ad2b5141ccd4eaaea191ff522932bba578e44dce8c --module twenty --function mint_usdc_in_vault --args 0xdb6c6f4741ec17a8318574d93dd5ca9aa1a0f135f6c25c9d11418544536b5cd9 0xbf1ecffe4d404a53eebdc396ae48f7361b7e362d6f42ddf04eb0c4fa370c7038 --gas-budget 10000000


## CURL

curl --location --request POST 'https://fullnode.mainnet.sui.io:443' \
--header 'Content-Type: application/json' \
--data-raw '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "sui_executeTransactionBlock",
    "params": [
        "您的交易位元組",
        ["您的簽名"],
        {
            "showEffects": true
        }
    ]
}'
AAiMM8YC+zWDasWTGPk8JQCFNz4vVoSrp1tJjYhso3t0


## MAC-dev

address = 0x3f58a419f88a0b054daebff43c2a759a7a390a6f749cfc991793134cf6a89e21

PackageID = 0xf001416442c35c99ce1665ad2b5141ccd4eaaea191ff522932bba578e44dce8c

USDC_Vault = 0xbf1ecffe4d404a53eebdc396ae48f7361b7e362d6f42ddf04eb0c4fa370c7038

UpgradeCap = 0x2641d8dcf60e1245d6012eefd0b1d75d3c3c69207d7a82bb5e899704e4691890

TreasuryCap<TWENTY> = 0x6123b7110b0c33e23e7dca7089abb9f740fe4224f9db7d94e8c108833c793a11

TreasuryCap<USDC> = 0xdb6c6f4741ec17a8318574d93dd5ca9aa1a0f135f6c25c9d11418544536b5cd9

CoinMetadata = 0x39e3921ee35d39c9c69a5587a8f8b32cb6ff8430e01f4f14f83429ab780d2828

CoinMetadata_usdc = 0x5cdfeaa11027e5a314dfa048a305b6f52528b636df7322dbff0918cd09c761e3

ISSUER_TWENTY = 0x927f1d5175baff5475e448d09ebf811b839e8d8686426a0d2ff0f86c8e2314fc

SUI = 0x6a1d55476153e08f43e062778e7ef1302924d4fa4a244975d7f86e7ca17d31d6

不是packageID。是你錢包獲得的objectID。
USDC = 0x637643192ee7f74640702b4deaf5c18ede94ad7157ea5e0414544a8505ee3c3d

user
0x1ab7fe6300145028517e65794d33783710b75885940ad2a9f33b177e0ba290bf
TWENTY
0xff41f22c069ced7fb7a097eee212f91105caea5c559d66348ffd951cbe8efe70


sui keytool export --key-identity 0x3f58a419f88a0b054daebff43c2a759a7a390a6f749cfc991793134cf6a89e21 > my_sui_private_key.txt

zkUser private key = OIg8Z+KcwNAhr38EljriQeXsD5qpgWfIkDKdScQzTFs=

QA:

但是如果要做跟valut swap這件事情vault一定是 sponsor的吧
所以你的意思是 在跟smart contract執行交易時，傳入的參數的擁有者都必須是sender的？
那為什麼我單元測試會過？

10,000 * 10 ^ 6 = 10,000,000,000 TWENTY = 1 USDC
2048000

sui move test test_new_game_creation
sui move test test_add_new_tile
sui move test test_right_move
sui move test test_bomb_explosion_on_merge

before
[2,2,4,0,0]
[8,0,0,0,0]
[0,0,0,0,0]
[0,0,0,0,0]
[0,16,0,0,0]

after
[0,0,0,0,0]
[0,0,0,0,0]
[0,0,0,0,0]
[0,0,0,0,0]
[16,0,0,0,0]

bomb
[1,0,0,0,0]
[0,0,0,0,0]
[0,0,0,0,0]
[0,0,0,0,0]
[0,0,0,0,0]