//sellMarketMoment.js
//args:
//  sender, String alias name of account e.g. "Ben", or account address e.g. config["0xAdmin"] or Oxf8d6e0586b0a20c7
//  id, id of Moment to sell, UInt64
//  price, price of Moment to sell, UFix64 (4 decimals) as a string, e.g. "500.0000"
//  rake, rake of sale, UFix64 (4 decimals) as a string, e.g. "500.0000"
//  rakeAddress, String alias name of account e.g. "Ben", or account address e.g. config["0xAdmin"] or Oxf8d6e0586b0a20c7
//outputs:
//  none

const config = require("../../config.js");
const fjs = require("flow-js-testing/dist");
const t = require("@onflow/types");
const path = require("path");

// init
fjs.init(path.resolve(__dirname, "../../"));

async function main(sender, itemID, price, rake, rakeAddress) {
  // Get address
  let senderAccount  = {};
  if (sender == config["0xAdmin"]) {
    senderAccount  = sender
  } else {
    senderAccount  = await fjs.getAccountAddress(sender);
  }
  let rakeAccount  = {};
  if (rakeAddress == config["0xAdmin"]) {
    rakeAccount  = rakeAddress
  } else {
    rakeAccount  = await fjs.getAccountAddress(rakeAddress);
  }

  // Read or create transaction code
  const addressMap = {FungibleToken: config["0xAdmin"], FUSD: config["0xAdmin"], NonFungibleToken: config["0xAdmin"], Moments: config["0xAdmin"], MomentsMarket: config["0xAdmin"]}
  const transactionTemplate = await fjs.getTransactionCode({
    name: "MomentsMarket/sellMarketMoment",
    addressMap
  });

  const args = [
    [itemID, t.UInt64],
    [price, t.UFix64],
    [rakeAccount, t.Address],
    [rake, t.UFix64]
  ];
  const signers = [senderAccount];

  try {
    const txResult = await fjs.sendTransaction({ code: transactionTemplate, args, signers });
    console.log({ txResult });
  } catch (e) {
    console.log(e);
  }
};
module.exports = main;