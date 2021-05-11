//removeMarketMoment.js
//args:
//  account, String alias name of account e.g. "Ben", or account address e.g. config["0xAdmin"] or Oxf8d6e0586b0a20c7
//  id, id of Moment to remove from market, UInt64
//outputs:
//  none

const config = require("../../config.js");
const fjs = require("flow-js-testing/dist");
const t = require("@onflow/types");
const path = require("path");

// init
fjs.init(path.resolve(__dirname, "../../"));

async function main(account, itemID) {
  // Get address
  let authAccount  = {};
  if (account == config["0xAdmin"]) {
    authAccount = account
  } else {
    authAccount = await fjs.getAccountAddress(account);
  }

  // Read or create transaction code
  const addressMap = {MomentsMarket: config["0xAdmin"]}
  const transactionTemplate = await fjs.getTransactionCode({
    name: "MomentsMarket/removeMarketMoment",
    addressMap
  });

  const args = [
    [itemID, t.UInt64]
  ];
  const signers = [authAccount];

  try {
    const txResult = await fjs.sendTransaction({ code: transactionTemplate, args, signers });
    console.log({ txResult });
  } catch (e) {
    console.log(e);
  }
};
module.exports = main;