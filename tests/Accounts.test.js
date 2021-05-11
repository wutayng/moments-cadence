//accounts.test.js
//setup accounts on a local emulator

const config = require("../config.js");
const fjs = require("flow-js-testing/dist");
const path = require("path");

const setupAccount = require("../transactions/accounts/setupAccount.js");

// init
fjs.init(path.resolve(__dirname, "../"));

// array of test accounts
const names = [
    config["0xAdmin"],
    "Ben",
    "Colin",
    "Sarah"
  ];

// setup accounts with name aliases
test('Set up Sample Accounts', async () => {
  for (let name of names) {
    await setupAccount(name)
  }
});