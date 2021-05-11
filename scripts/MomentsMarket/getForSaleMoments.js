//getForSaleMoments.js
//args:
//  name, String alias name of account e.g. "Ben", or account address e.g. config["0xAdmin"] or Oxf8d6e0586b0a20c7
//outputs:
//  dict of moments for sale (moment id: key UInt64) paired with prices (sale price: value UFix64)
    // json 
        // id, flow universe Moment unique identifier, UInt64
        // price, sale offer price, UFix64

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
    const addressMap = {NonFungibleToken: config["0xAdmin"], Moments: config["0xAdmin"], MomentsMarket: config["0xAdmin"]}
    const scriptTemplate = await fjs.getScriptCode({
        name: "MomentsMarket/getForSaleMoments",
        addressMap
    });
  
    // Create list of arguments
    // You can group items with the same time under single array
    // Last item in the list should always be the type of passed values
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

