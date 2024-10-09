export type Chain =
  | "starknet"
  | "starknetSepolia"
  | "pragmaDevnet"
  | "mainnet"
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

export type StarknetChain = Extract<
  Chain,
  "starknet" | "starknetSepolia" | "pragmaDevnet"
>;

export const STARKNET_CHAINS: Chain[] = [
  "starknet",
  "starknetSepolia",
  "pragmaDevnet",
];

export type EvmChain = Exclude<Chain, StarknetChain>;

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

export interface CalldataResponse {
  calldata: number[];
}
