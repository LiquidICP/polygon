const Bridge = artifacts.require("Bridge");
const WrapperBridgedStandardERC20 = artifacts.require("WrapperBridgedStandardERC20");

const fs = require('fs');
const { constants } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;

module.exports = async function (deployer, network, accounts) {

  const owner = accounts[0];
  const feeWallet = accounts[1];

  const deployBridgeAtEnd = async () => {
    console.log("Deployer address: " + deployer);
    await deployer.deploy(WrapperBridgedStandardERC20);
    await deployer.deploy(
        Bridge,
        WrapperBridgedStandardERC20.address,
        feeWallet,
        5,
        owner,
        "WrapperICP",
        "WICP",
        8
    );
    const bridge = await Bridge.deployed();
    console.log(`BridgedToken deployed: ${bridge}`);
    return [Bridge.address];
  }

  const readTokenAddress = () => {
    return require('./polygon_token_address.json')['polygonTokenAddress'];
  }

  if (network === "polygon_testnet_fork" || network === "polygon_testnet") {
    const addresses = await deployBridgeAtEnd();
    console.log(`Using polygon bridged version on polygon testnet: ${addresses}`);
    console.log(`Deployed bridge on polygon testnet: ${addresses}`);
  }
};
