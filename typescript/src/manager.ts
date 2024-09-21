import type { Deployer } from './deployers/interface';

import { OracleDeployer } from './deployers/oracle';
import { DispatcherDeployer } from './deployers/dispatcher';
import { PragmaDeployer } from './deployers/pragma';

/// Manager handling all the possible contracts to deploy.
class DeploymentManager {
  private deployers: Map<string, Deployer> = new Map();

  registerDeployer(name: string, deployer: Deployer): void {
    this.deployers.set(name, deployer);
  }

  async deploy(contract: string, chain?: string): Promise<void> {
    const [contractName, specifiedChain] = contract.split(':');
    const actualChain = chain || specifiedChain;

    const deployer = this.deployers.get(contractName);
    if (!deployer) {
      throw new Error(`Unknown contract: ${contractName}`);
    }

    await deployer.deploy(actualChain);
  }
}

const deploymentManager = new DeploymentManager();
deploymentManager.registerDeployer('oracle', new OracleDeployer());
deploymentManager.registerDeployer('dispatcher', new DispatcherDeployer());
deploymentManager.registerDeployer('pragma', new PragmaDeployer());

export default deploymentManager;
