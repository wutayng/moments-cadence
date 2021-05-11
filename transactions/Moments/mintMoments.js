//mintMoments.js
//args:
//  auth, String alias name of account e.g. "Ben", or account address e.g. config["0xAdmin"] or Oxf8d6e0586b0a20c7
//  recipient, ""
//  quantity, Quantity minted, total number of serial numbers for this specific moment, Int
//  metadata, formatted specifically for flow-js-testing transaction arg
    //  key fields:
        // name, moment name
        // key1, sample key/value pair
        // key2, sample key/value pair
        // ipfs, file name for ipfs link
        /* format 
              const metadata_1 = [
                { key: "name", value: "Sample Name"},
                { key: "key1", value: "value1"}
                { key: "ipfs", value: "uri_string_identifierXXXXXXX"}
              ] 
         */
//outputs:
//  none

const config = require("../../config.js");
const fjs = require("flow-js-testing/dist");
const t = require("@onflow/types");
const path = require("path");

// init
fjs.init(path.resolve(__dirname, "../../"));

async function main(auth, recipient, quantity, metadata) {
  // Get adresses
  let authName = {};
  if (auth == config["0xAdmin"]) {
    authName = auth
  } else {
    authName = await fjs.getAccountAddress(auth);
  }
  let recipientName = {};
  if (recipient == config["0xAdmin"]) {
    recipientName = recipient
  } else {
    recipientName = await fjs.getAccountAddress(recipient);
  }

  // Read or create transaction code
  const addressMap = {NonFungibleToken: config["0xAdmin"],Moments: config["0xAdmin"]}
  const transactionTemplate = await fjs.getTransactionCode({
    name: "Moments/mintMoments",
    addressMap
  });

  const args = [
      [recipientName, t.Address],
      [quantity, t.Int],
      [metadata,
        // Since our script expects {String: String} we need to define types for key and value
        t.Dictionary({ key: t.String, value: t.String }),
      ]
  ];

  const signers = [authName];

  try {
    const txResult = await fjs.sendTransaction({ code: transactionTemplate, args, signers });
    console.log({ txResult });
  } catch (e) {
    console.log(e);
  }
};
module.exports = main;