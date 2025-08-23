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
sui client call --package 0x459e01a382c9b0a2508c8ad30b0916102912332e120ba5dfc38f3991a612b429 --module twenty --function deposit_usdc_in_vault --args 0x6a55e6ba15c0d1f99aa82ecd05cc2fd285a14cacc16fe1fc281f9e631227ebec 0x78d1ce0f2fde9eaf1fc5cb8744a9c7bc6fe5e7c46a94f95b9ed57cb968b29f96 --gas-budget 10000000


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


## MAC

address = 0x3f58a419f88a0b054daebff43c2a759a7a390a6f749cfc991793134cf6a89e21

PackageID = 0x23fd50c3c3bb7963558f84bbaf8fcb71c0d82b4cb718584bf2e3ab4da40fe18c

USDC_Vault = 0x32a0fdef603123cff085823500e62c1968dff383ec558120496e27d1eed6bbe4

UpgradeCap = 0x884dde3af0c31bfb72095d3d1abd8a6c465c827c5d929856f5716a40bf977165

TreasuryCap<TWENTY> = 0x3d5c9b85c390744ebac963955f4f954fc5766bddab3991d0a12cacf3486555ed

CoinMetadata = 0x8ac55e9b92fb7b3b3f65201185e143a9a60e0fcfd7f2246afd5c794de2dcb861

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