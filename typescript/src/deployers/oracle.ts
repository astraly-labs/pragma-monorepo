import type { Deployer, Chain } from "./interface";

export class OracleDeployer implements Deployer {
  readonly allowedChains: Chain[] = ["starknet"];
  readonly defaultChain: Chain = "starknet";
  async deploy(chain?: Chain): Promise<void> {
    if (!chain) chain = this.defaultChain;
    // TODO: Implement the Oracle deployer once we have the files in the monorepo
    // See: https://github.com/astraly-labs/pragma-oracle
    console.log("Oracle deployment is not yet implemented. Exiting.");
    process.exit(0);
  }
}
