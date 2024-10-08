import type { Chain } from "pragma-utils";
import type { DeploymentConfig } from "../config";

/// Main interface called when deploying a contract
export interface ContractDeployer {
  readonly allowedChains: Chain[];
  readonly defaultChain: Chain;
  deploy(
    config: DeploymentConfig,
    deterministic: boolean,
    chain?: string,
  ): Promise<void>;
}
