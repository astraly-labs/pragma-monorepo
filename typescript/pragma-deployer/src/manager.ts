import type { DeploymentConfig } from "./config";
import type { Deployer } from "./deployers";
import {
  OracleDeployer,
  DispatcherDeployer,
  PragmaDeployer,
} from "./deployers";

class DeploymentManager {
  private deployers: Map<string, Deployer> = new Map();

  registerDeployer(name: string, deployer: Deployer): void {
    this.deployers.set(name, deployer);
  }

  supportedDeployments(): string[] {
    return Array.from(this.deployers.keys());
  }

  async deploy(
    contract: string,
    config: DeploymentConfig,
    chain?: string,
  ): Promise<void> {
    const deployer = this.deployers.get(contract);
    if (!deployer) {
      throw new Error(`Unknown contract: ${contract}`);
    }

    await deployer.deploy(config, chain);
  }
}

const deploymentManager = new DeploymentManager();
deploymentManager.registerDeployer("oracle", new OracleDeployer());
deploymentManager.registerDeployer("dispatcher", new DispatcherDeployer());
deploymentManager.registerDeployer("pragma", new PragmaDeployer());

export default deploymentManager;
