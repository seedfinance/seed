//import 'dotenv/config'
//import "@nomiclabs/hardhat-waffle";
//import '@nomiclabs/hardhat-solhint'
//import "hardhat-gas-reporter";
require("hardhat-spdx-license-identifier");
//import 'hardhat-deploy'
//import "hardhat-deploy-ethers";
//import { HardhatUserConfig } from "hardhat/types";
/*
const accounts = [
  process.env.PRIVATEKEY
]
*/

module.exports = {
  defaultNetwork: "hardhat",
  namedAccounts: {
    deployer: {
      default: 0
    },
    dev: {
      default: 1
    },
  },
  networks: {
    mainnet: {
      url: `https://http-mainnet-node.huobichain.com`,
      //accounts: accounts,
      gasPrice: 1.3 * 1000000000,
      chainId: 128,
    },
    testnet: {
      url: `https://http-testnet.hecochain.com`,
      //accounts: accounts,
      gasPrice: 1 * 1000000000,
      chainId: 256,
    },
    hardhat: {
      forking: {
        enabled: process.env.FORKING === "true",
        url: `https://http-mainnet-node.huobichain.com`,
      },
      live: true,
      saveDeployments: true,
      tags: ["test", "local"],
    },
  },
  paths: {
  },
  solidity: {
    compilers: [
      {
        version: "0.7.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  spdxLicenseIdentifier: {
    overwrite: true,
    runOnCompile: true,
  },
};
//export default config;
