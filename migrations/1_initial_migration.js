const Migrations = artifacts.require("Migrations");
const { constants } = require("@openzeppelin/test-helpers");

module.exports = function (deployer, network, accounts) {
  deployer.deploy(Migrations);
};
