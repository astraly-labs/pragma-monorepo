import type { StarknetChain } from "../chains";

export const STARKNET_RPC_URLS: { [key in StarknetChain]: string } = {
  starknet: "https://free-rpc.nethermind.io/mainnet-juno",
  starknetSepolia: "https://free-rpc.nethermind.io/sepolia-juno",
  pragmaDevnet: "https://madara-pragma-prod.karnot.xyz/",
};
