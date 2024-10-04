import type { HardhatUserConfig } from "hardhat/config";
import type { NetworkUserConfig } from "hardhat/types";
import "@nomicfoundation/hardhat-ethers";

import * as dotenv from "dotenv";
dotenv.config();

// Load environment variables
const INFURA_PROJECT_ID = process.env.INFURA_PROJECT_ID;
const PRIVATE_KEY: string = process.env.ETH_PRIVATE_KEY || "";

if (!PRIVATE_KEY || PRIVATE_KEY.length === 0) {
  throw new Error("Please set your PRIVATE_KEY in a .env file");
}
if (!INFURA_PROJECT_ID) {
  throw new Error("Please set your INFURA_PROJECT_ID in a .env file");
}

const chainIds = {
  goerli: 5,
  hardhat: 31337,
  kovan: 42,
  mainnet: 1,
  rinkeby: 4,
  ropsten: 3,
  avalanche: 43114,
  bsc: 56,
  bsctestnet: 97,
  polygon: 137,
  polygonZkEvm: 1101,
  mumbai: 80001,
  fantom: 250,
  arbitrum: 42161,
  optimism: 10,
  base: 8453,
};

function getChainConfig(
  network: keyof typeof chainIds,
  url: string,
  gasPrice: number | "auto" = "auto",
): NetworkUserConfig {
  return {
    accounts: [PRIVATE_KEY],
    chainId: chainIds[network],
    url,
    gasPrice,
  };
}

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.27",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  // Supported EVM networks
  networks: {
    hardhat: {
      forking: {
        url: `https://mainnet.infura.io/v3/${INFURA_PROJECT_ID}`,
        blockNumber: 16519700,
      },
      loggingEnabled: true,
      chainId: chainIds.hardhat,
    },
    ethereum: getChainConfig(
      "mainnet",
      `https://mainnet.infura.io/v3/${INFURA_PROJECT_ID}`,
    ),
    ropsten: getChainConfig(
      "ropsten",
      `https://ropsten.infura.io/v3/${INFURA_PROJECT_ID}`,
    ),
    rinkeby: getChainConfig(
      "rinkeby",
      `https://rinkeby.infura.io/v3/${INFURA_PROJECT_ID}`,
    ),
    bsc: getChainConfig("bsc", "https://bsc-dataseed1.defibit.io/"),
    bscTestnet: getChainConfig(
      "bsctestnet",
      "https://data-seed-prebsc-1-s1.binance.org:8545",
    ),
    polygon: getChainConfig("polygon", "https://polygon-rpc.com/"),
    polygonTestnet: getChainConfig(
      "mumbai",
      "https://rpc-mumbai.maticvigil.com",
    ),
    polygonZkEvm: getChainConfig("polygonZkEvm", "https://zkevm-rpc.com"),
    avalanche: getChainConfig(
      "avalanche",
      "https://api.avax.network/ext/bc/C/rpc",
    ),
    fantom: getChainConfig("fantom", "https://rpc.ftm.tools/"),
    arbitrum: getChainConfig("arbitrum", "https://arb1.arbitrum.io/rpc"),
    optimism: getChainConfig("optimism", "https://rpc.ankr.com/optimism"),
    base: getChainConfig("base", "https://mainnet.base.org"),
  },
  paths: {
    sources: "./src/SOLIDITY",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 40000,
  },
};

export default config;
