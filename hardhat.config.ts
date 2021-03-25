import 'dotenv/config'
import "@nomiclabs/hardhat-waffle";
import '@nomiclabs/hardhat-solhint'
import "hardhat-gas-reporter";
import "hardhat-spdx-license-identifier";
import 'hardhat-deploy'
import "hardhat-deploy-ethers";
import { HardhatUserConfig } from "hardhat/types";

const accounts = [
  process.env.PRIVATEKEY
]
const config: HardhatUserConfig = {
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
      accounts,
      gasPrice: 1.3 * 1000000000,
      chainId: 128,
    },
    testnet: {
      url: `https://http-testnet.hecochain.com`,
      accounts,
      gasPrice: 1 * 1000000000,
      chainId: 256,
    },
    localhost: {
      live: false,
      saveDeployments: true,
      tags: ["local"],
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
    artifacts: "artifacts",
    cache: "cache",
    deploy: "deploy",
    deployments: "deployments",
    imports: "imports",
    sources: "contracts",
    tests: "test",
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
    overwrite: false,
    runOnCompile: true,
  },
};
export default config;
