// Supported chains
export type Chain =
  | "starknet"
  | "madara_devnet"
  | "starknet_sepolia"
  | "mainnet" // ethereum mainnet
  | "ropsten"
  | "rinkeby"
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

// Utilities for different type of chains
export const STARKNET_CHAINS: Chain[] = [
  "starknet",
  "starknet_sepolia",
  "madara_devnet",
];
export const EVM_CHAINS: Chain[] = [
  "mainnet",
  "ropsten",
  "rinkeby",
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
];
