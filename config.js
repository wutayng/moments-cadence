require('dotenv').config()
const fclconfig = require("@onflow/fcl");
const config = fclconfig.config()

module.exports = {
    "accessNode.api":  process.env.ACCESS_NODE,
    "0xAdmin": process.env.ADMIN_ACCOUNT,
  };