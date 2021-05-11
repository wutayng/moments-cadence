//setupAccount.js
//args:
//  name, String alias name of account e.g. "Ben", or account address e.g. config["0xAdmin"] or Oxf8d6e0586b0a20c7
//outputs:
//  none

const config = require("../../config.js");
const fjs = require("flow-js-testing/dist");
const t = require("@onflow/types");
const path = require("path");

// init
fjs.init(path.resolve(__dirname, "../../"));

async function main(name) {
  // Get signers adresses
  let accountName = {};
  if (name == config["0xAdmin"]) {
    accountName = name
  } else {
    accountName = await fjs.getAccountAddress(name);
  }

  // Read or create transaction code
  const addressMap = {FungibleToken: config["0xAdmin"], FUSD: config["0xAdmin"], NonFungibleToken: config["0xAdmin"], Moments: config["0xAdmin"], MomentsMarket: config["0xAdmin"]}
  const transactionTemplate = await fjs.getTransactionCode({
    name: "accounts/setupAccount",
    addressMap
  });

  // Create list of arguments
  const args = [
  ];
  // Create list of signers
  const signers = [accountName];

  try {
    const txResult = await fjs.sendTransaction({ code: transactionTemplate, args, signers });
    console.log({ txResult });
  } catch (e) {
    console.log(e);
  }
};
module.exports = main;