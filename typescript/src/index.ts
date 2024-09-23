import { Command } from "commander";
import deploymentManager from "./manager";

const program = new Command();

program
  .description("CLI to deploy Pragma contracts")
  .arguments("<contract>")
  .option("-c, --chain <chain>", "Chain where the contract will be deployed")
  .action(async (contract: string, options) => {
    contract = contract.toLocaleLowerCase();
    const supportedDeployments = deploymentManager.supportedDeployments();
    if (!supportedDeployments.includes(contract)) {
      throw new Error(
        `"${contract}" is not supported for deployments. Supported names: ${supportedDeployments}`,
      );
    }
    try {
      await deploymentManager.deploy(contract, options.chain);
    } catch (error) {
      console.error("Deployment failed:", (error as Error).message);
      process.exit(1);
    }
  });

program.parse(process.argv);
