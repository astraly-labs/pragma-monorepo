import type { HardhatUserConfig } from "hardhat/config";
import type { NetworkUserConfig } from "hardhat/types";
import "hardhat-switch-network";
import "@nomicfoundation/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import * as dotenv from "dotenv";

// Load environment variables
dotenv.config();
const INFURA_PROJECT_ID = process.env.INFURA_PROJECT_ID;
const PRIVATE_KEY: string = process.env.ETH_PRIVATE_KEY || "";

if (!PRIVATE_KEY || PRIVATE_KEY.length === 0) {
  throw new Error("Please set your PRIVATE_KEY in a .env file");
}
if (!INFURA_PROJECT_ID) {
  throw new Error("Please set your INFURA_PROJECT_ID in a .env file");
}

const chainIds = {
  hardhat: 31337,
  sepolia: 11155111,
  mainnet: 1,
  holesky: 17000,
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
  scroll: 534352,
  scrollTestnet: 11155111,
  scrollSepoliaTestnet: 534351,
  zircuitTestnet: 48899,
  plumeTestnet: 161221135,
  worldchain: 480,
  worldchainTestnet: 4801,
  zksync: 324,
  zksyncTestnet: 300,
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
  networks: {
    hardhat: {
      forking: {
        url: `https://mainnet.infura.io/v3/${INFURA_PROJECT_ID}`,
        blockNumber: 16519700,
      },
      loggingEnabled: true,
      chainId: chainIds.hardhat,
    },
    mainnet: getChainConfig(
      "mainnet",
      `https://mainnet.infura.io/v3/${INFURA_PROJECT_ID}`,
    ),
    sepolia: getChainConfig(
      "sepolia",
      `https://sepolia.infura.io/v3/${INFURA_PROJECT_ID}`,
    ),
    holesky: getChainConfig(
      "holesky",
      `https://holesky.infura.io/v3/${INFURA_PROJECT_ID}`,
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
    avalanche: getChainConfig(
      "avalanche",
      "https://api.avax.network/ext/bc/C/rpc",
    ),
    fantom: getChainConfig("fantom", "https://rpc.ftm.tools/"),
    arbitrum: getChainConfig("arbitrum", "https://arb1.arbitrum.io/rpc"),
    optimism: getChainConfig("optimism", "https://rpc.ankr.com/optimism"),
    base: getChainConfig("base", "https://mainnet.base.org"),
    scroll: getChainConfig("scroll", "https://rpc.scroll.io/"),
    scrollTestnet: getChainConfig(
      "scrollTestnet",
      "https://eth-sepolia-public.unifra.io",
    ),
    scrollSepoliaTestnet: getChainConfig(
      "scrollSepoliaTestnet",
      "https://sepolia-rpc.scroll.io/",
    ),
    zircuitTestnet: getChainConfig(
      "zircuitTestnet",
      "https://zircuit1-testnet.p2pify.com",
    ),
    plumeTestnet: getChainConfig(
      "plumeTestnet",
      "https://testnet-rpc.plumenetwork.xyz/http",
    ),
    worldchain: getChainConfig(
      "worldchain",
      "https://worldchain-mainnet.g.alchemy.com/public",
    ),
    worldchainTestnet: getChainConfig(
      "worldchainTestnet",
      "https://worldchain-sepolia.g.alchemy.com/public",
    ),
    zksync: getChainConfig("zksync", "https://mainnet.era.zksync.io"),
    zksyncTestnet: getChainConfig(
      "zksyncTestnet",
      "https://sepolia.era.zksync.dev",
    ),
  },
  paths: {
    root: "../../solidity",
    sources: "src",
    tests: "test",
    cache: "cache",
    artifacts: "out",
  },
  mocha: {
    timeout: 40000,
  },
};

export default config;
