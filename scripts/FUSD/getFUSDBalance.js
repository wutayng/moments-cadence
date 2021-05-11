//getFUSDBalance.js
//args:
//  name, String alias name of account e.g. "Ben", or account address e.g. config["0xAdmin"] or Oxf8d6e0586b0a20c7
//outputs:
//  String FUSD balance for the account

const config = require("../../config.js")
const fjs = require("flow-js-testing/dist");
const t = require("@onflow/types");
const path = require("path");

// init
fjs.init(path.resolve(__dirname, "../../"));

async function main(name) {
  // get account
  let accountName = {};
  if (name == config["0xAdmin"]) {
    accountName = name
  } else {
    accountName = await fjs.getAccountAddress(name);
  }

  // Read or create script code
  const addressMap = {FUSD: config["0xAdmin"],FungibleToken: config["0xAdmin"]}
  const scriptTemplate = await fjs.getScriptCode({
    name: "FUSD/getFUSDBalance",
    addressMap
  });

  // Create list of arguments
  const args = [
    [accountName, t.Address],
  ];

  try {
    const result = await fjs.executeScript({ code: scriptTemplate, args });
    console.log(name, result)
    return result
  } catch (e) {
    console.log(e);
    return e
  }
};
module.exports = main;