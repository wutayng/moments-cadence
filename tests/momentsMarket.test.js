//momentsMarket.test.js
//test moments Market contract on local flow emulator

const config = require("../config.js");
const fjs = require("flow-js-testing/dist");
const path = require("path");

const sellMarketMoment = require('../transactions/MomentsMarket/sellMarketMoment.js');
const getForSaleMoments = require('../scripts/MomentsMarket/getForSaleMoments.js');
const removeMarketMoment = require('../transactions/MomentsMarket/removeMarketMoment.js');
const buyMarketMoment = require('../transactions/MomentsMarket/buyMarketMoment.js');
const getMoments = require('../scripts/Moments/getMoments.js');
const getFUSDBalance = require('../scripts/FUSD/getFUSDBalance.js');

//init flow-js-testing path
fjs.init(path.resolve(__dirname, "../"));

// sell Moments
test('List Moments for Sale', async () => {
    await sellMarketMoment("Sarah",5,"225.0000","0.0500",config["0xAdmin"]);
    await sellMarketMoment("Sarah",6,"95.7500","0.0500",config["0xAdmin"]);
    await sellMarketMoment("Colin",2,"30.5000","0.0500",config["0xAdmin"]);
});

// get Sale Offers
test('Get For Sale Moments', async () => {
    const saleMoments = await getForSaleMoments("Sarah");
    expect(saleMoments.length).toBe(2)
    expect(saleMoments[0]["itemID"]).toBe(5);
    expect(saleMoments[1]["price"]).toBe("95.75000000");
  });

// remove Sale Offer
test('Remove a Market Moment', async () => {
  await removeMarketMoment("Sarah",5);
  const saleMoments = await getForSaleMoments("Sarah");
  expect(saleMoments.length).toBe(1)
  expect(saleMoments[0]["itemID"]).toBe(6);
});

// buy Sale Offer
test('Purchase a Market Moment', async () => {
  await buyMarketMoment("Colin", "Sarah",6);
  const moments = await getMoments("Colin");
  expect(moments.length).toBe(2)
  expect(moments[0]["id"]).toBe(2);
  expect(moments[1]["id"]).toBe(6);
  // get resulting FUSD balances
  await expect(getFUSDBalance(config["0xAdmin"])).resolves.toBe("854.78750000");
  await expect(getFUSDBalance("Sarah")).resolves.toBe("90.96250000");
  await expect(getFUSDBalance("Colin")).resolves.toBe("54.25000000");
});