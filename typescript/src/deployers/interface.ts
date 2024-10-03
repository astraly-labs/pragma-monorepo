import type { DeploymentConfig } from "../config";

// Supported chains
export type Chain =
  | "starknet"
  | "starknet_devnet"
  | "sepolia" // starknet testnet
  | "ethereum"
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
  "starknet_devnet",
  "sepolia",
];
export const EVM_CHAINS: Chain[] = [
  "ethereum",
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

/// Main interface called when deploying a contract
export interface Deployer {
  readonly allowedChains: Chain[];
  readonly defaultChain: Chain;
  deploy(config: DeploymentConfig, chain?: string): Promise<void>;
}
