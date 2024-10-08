import type { DeploymentConfig } from "./config";
import {
  type ContractDeployer,
  OracleDeployer,
  DispatcherDeployer,
  PragmaDeployer,
} from "./deployers";

class DeploymentManager {
  private deployers: Map<string, ContractDeployer> = new Map();

  registerDeployer(name: string, deployer: ContractDeployer): void {
    this.deployers.set(name, deployer);
  }

  supportedDeployments(): string[] {
    return Array.from(this.deployers.keys());
  }

  async deploy(
    contract: string,
    config: DeploymentConfig,
    chain?: string,
    deterministic: boolean = false,
  ): Promise<void> {
    const deployer = this.deployers.get(contract);
    if (!deployer) {
      throw new Error(`Unknown contract: ${contract}`);
    }

    await deployer.deploy(config, deterministic, chain);
  }
}

const deploymentManager = new DeploymentManager();
deploymentManager.registerDeployer("oracle", new OracleDeployer());
deploymentManager.registerDeployer("dispatcher", new DispatcherDeployer());
deploymentManager.registerDeployer("pragma", new PragmaDeployer());

export default deploymentManager;
