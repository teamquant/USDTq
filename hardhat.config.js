require("hardhat-deploy");
require("@nomicfoundation/hardhat-toolbox");
require("hardhat-contract-sizer");
require("dotenv").config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

// Use a dummy private key for CI/local development when PRIVATE_KEY is not set
const PRIVATE_KEY = process.env.PRIVATE_KEY || "0000000000000000000000000000000000000000000000000000000000000001";
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY || "";

const forkEnabled = process.env.FORK_ENABLED === "true";

module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10000000,
      },
      viaIR: true,
    },
  },
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0,
      forking: {
        url: "https://bsc-dataseed.binance.org/",
        enabled: forkEnabled,
      },
    },
    localhost: {
      url: "http://127.0.0.1:8545/",
      chainId: 31337,
    },
    bsc_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [PRIVATE_KEY.startsWith("0x") ? PRIVATE_KEY : `0x${PRIVATE_KEY}`],
    },
    bsc_mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [PRIVATE_KEY.startsWith("0x") ? PRIVATE_KEY : `0x${PRIVATE_KEY}`],
    },
  },
  etherscan: {
    apiKey: {
      bscTestnet: BSCSCAN_API_KEY,
      bsc: BSCSCAN_API_KEY,
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY || "",
    gasPrice: 20,
    outputFile: process.env.REPORT_GAS === "true" ? "gas-report.txt" : undefined,
    noColors: process.env.REPORT_GAS === "true",
  },
  mocha: {
    timeout: 40000,
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
    },
    minter: {
      default: 1,
    },
    blacklister: {
      default: 2,
    },
    pauser: {
      default: 3,
    },
    reserveManager: {
      default: 4,
    },
  },
};
