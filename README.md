## Setup
1. Configure a ./flow.json to deploy the 5 contracts to the Emulator Account
		
		https://docs.onflow.org/flow-cli/configuration/

	```
	"contracts": {
      "Moments": "./contracts/Moments.cdc",
      "MomentsMarket": "./contracts/MomentsMarket.cdc",
      "FungibleToken": "./contracts/FungibleToken.cdc",
      "FUSD": "./contracts/FUSD.cdc",
      "NonFungibleToken": "./contracts/NonFungibleToken.cdc"
    },
	```
	```
	"accounts": {
      "emulator-account": {
        "address": "f8d6e0586b0a20c7",
        "keys": "xxxxx",
        "chain": "flow-emulator"
      }
	},
	```
	```
	"deployments": {
      "emulator": {
        "emulator-account": [
          "Moments",
          "MomentsMarket",
          "NonFungibleToken",
          "FungibleToken",
          "FUSD"
        ]
      }
    },
	```

2. Configure .env with the Emulator HTTP server port and Emulator account address

## Test
Run Jest testing suites to test contracts with Scripts and Transactions
1. Start the flow emulator in the same repo directory

	```flow emulator```
    
2. Deploy Contracts to the Emulator Account

	```flow project deploy --network=emulator```

3. ```npm test```
 
	This runs all tests sequentially, so there are no overlapping transaction errors in the emulator - which look like this:
    ```
	invalid proposal key: public key 0 on account f8d6e0586b0a20c7 has sequence number 19, but given 18
	```
	Once the test suites are run, 4 accounts will be set up, FUSD and Moments minted, sent, put up for sale, removed from the market, and bought/sold.

## Use Cadence Scripts & Transactions

#### Examples:

- Simple Transaction

	```
	flow transactions send ./transactions/setup_account.cdc --signer emulator-account
	```
- Transactions with Args

	```
	flow transactions send ./transactions/mint_FUSD.cdc --arg Address:0xf8d6e0586b0a20c7 --arg UFix64:1000.0000 --signer emulator-account
    flow transactions send ./transactions/send_FUSD.cdc --arg UFix64:1200.0000 --arg Address:0x01cf0e2f2f715450 --signer emulator-account
	```
- Scripts

	```
	flow scripts execute ./scripts/getFUSDbalance.cdc --arg Address:0xf8d6e0586b0a20c7
	```
- Using node scripts

	###### ```main({args});``` Must be added to the bottom of the .js file to run the function **

	```
	node transactions/FUSD/mintFUSD.js
	```
    
## Attribution

Most of the cadence smart contracts are templated off of the kitty-items example application.

    https://github.com/onflow/kitty-items