import type { Chain } from "../chains";
import type { DeploymentConfig } from "../config";

/// Main interface called when deploying a contract
export interface Deployer {
  readonly allowedChains: Chain[];
  readonly defaultChain: Chain;
  deploy(
    config: DeploymentConfig,
    deterministic: boolean,
    chain?: string,
  ): Promise<void>;
}
