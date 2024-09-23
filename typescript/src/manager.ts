import type { Deployer } from './deployers/interface';

import { OracleDeployer } from './deployers/oracle';
import { DispatcherDeployer } from './deployers/dispatcher';
import { PragmaDeployer } from './deployers/pragma';

class DeploymentManager {
  private deployers: Map<string, Deployer> = new Map();

  registerDeployer(name: string, deployer: Deployer): void {
    this.deployers.set(name, deployer);
  }

  supportedDeployments(): string[] {
    return Array.from(this.deployers.keys());
  }

  async deploy(contract: string, chain?: string): Promise<void> {
    const deployer = this.deployers.get(contract);
    if (!deployer) {
      throw new Error(`Unknown contract: ${contract}`);
    }

    await deployer.deploy(chain);
  }
}

const deploymentManager = new DeploymentManager();
deploymentManager.registerDeployer('oracle', new OracleDeployer());
deploymentManager.registerDeployer('dispatcher', new DispatcherDeployer());
deploymentManager.registerDeployer('pragma', new PragmaDeployer());

export default deploymentManager;
