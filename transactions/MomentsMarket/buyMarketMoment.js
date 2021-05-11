//buyMarketMoment.js
//args:
//  buyer, String alias name of account e.g. "Ben", or account address e.g. config["0xAdmin"] or Oxf8d6e0586b0a20c7
//  seller, String alias name of account e.g. "Ben", or account address e.g. config["0xAdmin"] or Oxf8d6e0586b0a20c7
//  id, id of Moment to buy, UInt64
//outputs:
//  none

const config = require("../../config.js");
const fjs = require("flow-js-testing/dist");
const t = require("@onflow/types");
const path = require("path");

// init
fjs.init(path.resolve(__dirname, "../../"));

async function main(buyer, seller, itemID) {
  // Get addresses
  let buyerAccount  = {};
  if (buyer == config["0xAdmin"]) {
    buyerAccount  = buyer
  } else {
    buyerAccount  = await fjs.getAccountAddress(buyer);
  }
  let sellerAccount  = {};
  if (seller == config["0xAdmin"]) {
    sellerAccount  = seller
  } else {
    sellerAccount  = await fjs.getAccountAddress(seller);
  }

  // Read or create transaction code
  const addressMap = {FungibleToken: config["0xAdmin"], FUSD: config["0xAdmin"], NonFungibleToken: config["0xAdmin"], Moments: config["0xAdmin"], MomentsMarket: config["0xAdmin"]}
  const transactionTemplate = await fjs.getTransactionCode({
    name: "MomentsMarket/buyMarketMoment",
    addressMap
  });

  const args = [
    [itemID, t.UInt64],
    [sellerAccount, t.Address]
  ];
  const signers = [buyerAccount];

  try {
    const txResult = await fjs.sendTransaction({ code: transactionTemplate, args, signers });
    console.log({ txResult });
  } catch (e) {
    console.log(e);
  }
};
module.exports = main;