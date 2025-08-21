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
sui client call --package 0xed0ece3cae9266c11090a5e6e4dac9efd5bdedeebc65245e5844919743f81598 --module twenty --function deposit_usdc_in_vault --args 0x27b285a6ab60a34f28f12f6ab091a1181c22970d371b3ed0eb654e971c3a4fd5 0x637643192ee7f74640702b4deaf5c18ede94ad7157ea5e0414544a8505ee3c3d --gas-budget 10000000


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