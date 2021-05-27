//moments.test.js
//test moments contract on local flow emulator

const config = require("../config.js");
const fjs = require("flow-js-testing/dist");
const path = require("path");

const mintMoments = require('../transactions/Moments/mintMoments.js');
const getMoments = require('../scripts/Moments/getMoments.js');
const sendMoments = require('../transactions/Moments/sendMoment.js');

//init flow-js-testing path
fjs.init(path.resolve(__dirname, "../"));

// mint Moments
test('Mint Moments to Sample Account 1', async () => {
    const metadata_1 = [
        { key: "name", value: "NFT 1 Qty 5"},
        { key: "description", value: "Description of NFT"},
        { key: "Author", value: "FirstName LastName"},
        { key: "ipfs", value: "uri_string_identifier0124093485823213"}
    ]
    await mintMoments(config["0xAdmin"], "Ben", 5, metadata_1);

    const metadata_2 = [
        { key: "name", value: "NFT 2 Qty 3"},
        { key: "description", value: "Description of NFT"},
        { key: "Author", value: "FirstName LastName"},
        { key: "ipfs", value: "uri_string_identifier0124002982344329"}
    ]
    await mintMoments(config["0xAdmin"], "Sarah", 3, metadata_1);
});

// get Moments
test('Get Moments from Sample Accounts', async () => {
    const moments = await getMoments("Ben");
    expect(moments.length).toBe(5)
    expect(moments[0]["metadata"]["name"]).toBe("NFT 1 Qty 5");
    expect(moments[3]["serial"]).toBe(4);
    expect(moments[3]["serialCount"]).toBe(5);
  });

// send Moments
test('Send Moments to/from Sample Accounts', async () => {
    await sendMoments("Ben", "Colin", 2);
    const moments = await getMoments("Colin");
    expect(moments.length).toBe(1)
    //id indexing starts at 0, serial indexing starts at 1
    expect(moments[0]["serial"]).toBe(3);
  });