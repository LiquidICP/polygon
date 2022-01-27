/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * trufflesuite.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */
require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');
const fs = require('fs');

const ganacheConfig = {
  host: "127.0.0.1",     // Localhost (default: none)
  port: 8545,            // Standard Ethereum port (default: none)
  network_id: "*",       // Any network (default: none)
};

module.exports = {

  networks: {
    development: ganacheConfig,
    polygon_testnet_fork: ganacheConfig,

//polygon Infura mainnet
    polygon_mainnet: {
      provider: () => new HDWalletProvider({
        mnemonic: {
          phrase: process.env.MNEMONIC
        },
        providerOrUrl:
            "wss://polygon-mumbai.g.alchemy.com/v2/" + polygonscan
      }),
      network_id: 137,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      chainId: 137
    },
    //polygon Infura testnet
    polygon_testnet: {
      provider: () => new HDWalletProvider({
        mnemonic: {
          phrase: process.env.MNEMONIC_POLYGON
        },
        providerOrUrl:
            "wss://polygon-mumbai.g.alchemy.com/v2/" + process.env.ALCHEMY_MUMBAI_KEY
      }),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      chainId: 80001
    }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    timeout: 120000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.11",
      settings: {
        optimizer: {
          enabled: false,
          runs: 200
        }
      }
    }
  },
  plugins: [
    'truffle-plugin-verify',
    'solidity-coverage'
  ],
  api_keys: {
    polygonscan: process.env.POLYGONSCAN_API_KEY
  }
};
