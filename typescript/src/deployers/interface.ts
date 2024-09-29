import type { DeploymentConfig } from "../config";

// Supported chains
export type Chain = "starknet" | "ethereum";

/// Main interface called when deploying a contract
export interface Deployer {
  readonly allowedChains: Chain[];
  readonly defaultChain: Chain;
  deploy(config: DeploymentConfig, chain?: string): Promise<void>;
}
