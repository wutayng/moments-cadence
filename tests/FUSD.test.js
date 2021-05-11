//FUSD.test.js
//test FUSD contract on local flow emulator

const config = require("../config.js");
const fjs = require("flow-js-testing/dist");
const path = require("path");

const mintFUSD = require('../transactions/FUSD/mintFUSD.js');
const getFUSDBalance = require('../scripts/FUSD/getFUSDBalance.js');
const sendFUSD = require('../transactions/FUSD/sendFUSD.js');

//init flow-js-testing path
fjs.init(path.resolve(__dirname, "../"));

// mint
test('Mint FUSD to Sample Accounts', async () => {
  await mintFUSD(config["0xAdmin"], config["0xAdmin"], "1000.0000");
});

// get balance
test('Get FUSD Balance of Sample Accounts', async () => {
    await expect(getFUSDBalance(config["0xAdmin"])).resolves.toBe("1000.00000000");
    await expect(getFUSDBalance("Sarah")).resolves.toBe("0.00000000");
  });

// send FUSD
test('Send FUSD to/from Sample Accounts', async () => {
  await sendFUSD(config["0xAdmin"], "Colin", "150.0000");
  await expect(getFUSDBalance("Colin")).resolves.toBe("150.00000000");
});