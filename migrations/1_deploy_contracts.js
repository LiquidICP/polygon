const Bridge = artifacts.require("Bridge");
const WrapperBridgedStandardERC20 = artifacts.require("WrapperBridgedStandardERC20");

const fs = require('fs');
const { constants } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;

module.exports = async function (deployer, network, accounts) {

    const owner = accounts[0];
    const feeWallet = accounts[1];

    const deployBridgeAtEnd = async () => {

        return [Bridge.address];
    }

    const readTokenAddress = () => {
        return require('../polygon_token_address.json')['polygonTokenAddress'];
    }

    if (network === "polygon_testnet_fork" || network === "polygon_testnet") {
        console.log("Deployer address: " + deployer);
        await deployer.deploy(WrapperBridgedStandardERC20);
        await deployer.deploy(
            Bridge,
            WrapperBridgedStandardERC20.address,
            feeWallet,
            owner,
            5,
            8,
            "WrapperICP",
            "WICP"
        );
        const bridge = await Bridge.deployed();
        console.log(`BridgedToken deployed: ${bridge}`);

    }
};
