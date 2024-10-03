import type { Account, Contract } from "starknet";
import { buildStarknetAccount, deployStarknetContract } from "../cairo";
import type { DeploymentConfig } from "../config";
import { type Deployer, type Chain, STARKNET_CHAINS } from "./interface";

export class OracleDeployer implements Deployer {
  readonly allowedChains: Chain[] = STARKNET_CHAINS;
  readonly defaultChain: Chain = "starknet";
  async deploy(config: DeploymentConfig, chain?: Chain): Promise<void> {
    if (!chain) chain = this.defaultChain;
    if (!this.allowedChains.includes(chain)) {
      throw new Error(`⛔ Deployment to ${chain} is not supported.`);
    }

    console.log(`🧩 Deploying Oracle to ${chain}...`);
    let deployer = await buildStarknetAccount(chain);
    let deploymentInfo: any = {};

    // 0. Deploy pragma publisher registry

    // 1. Deploy Pragma Oracle

    // 2. Add Pairs

    // 3. Register Publishers

    // 4. Deploy Summary stats

    // 5. Deploy randomness

    // 6. Save deployment addresses
  }

  private async deployPublisherRegistry(deployer: Account): Promise<Contract> {
    let publisherRegistry = await deployStarknetContract(
      deployer,
      "oracle",
      `pragma_publisher_registry_PublisherRegistry`,
      [
        deployer.address, // admin
      ],
    );
    console.log("✅ Deployed the Pragma Publisher Registry");
    return publisherRegistry;
  }
}
