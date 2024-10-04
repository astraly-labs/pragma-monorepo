// Supported chains
export type Chain =
  | "starknet" // starknet
  | "starknetSepolia"
  | "madaraDevnet"
  | "mainnet" // ethereum mainnet
  | "hardhat"
  | "sepolia"
  | "holesky"
  | "bsc"
  | "bscTestnet"
  | "polygon"
  | "polygonTestnet"
  | "polygonZkEvm"
  | "avalanche"
  | "fantom"
  | "arbitrum"
  | "optimism"
  | "base";

export const STARKNET_CHAINS: Chain[] = [
  "starknet",
  "starknetSepolia",
  "madaraDevnet",
];
export const EVM_CHAINS: Chain[] = [
  "mainnet",
  "sepolia",
  "holesky",
  "bsc",
  "bscTestnet",
  "polygon",
  "polygonTestnet",
  "polygonZkEvm",
  "avalanche",
  "fantom",
  "arbitrum",
  "optimism",
  "base",
  "hardhat",
];
