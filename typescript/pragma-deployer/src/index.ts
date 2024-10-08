import { Command } from "commander";
import deploymentManager from "./manager.ts";
import { loadConfig, type DeploymentConfig } from "./config/index.ts";

const program = new Command();

program
  .description("CLI to deploy Pragma contracts")
  .arguments("<contract>")
  .requiredOption("--config <config>", "Path to the YAML config file")
  .option("--chain <chain>", "Chain where the contract will be deployed")
  .option("--deterministic", "Deterministic deployments addresses")
  .action(async (contract: string, options) => {
    contract = contract.toLocaleLowerCase();

    const supportedDeployments = deploymentManager.supportedDeployments();
    if (!supportedDeployments.includes(contract)) {
      throw new Error(
        `"${contract}" is not supported for deployments. Supported names: ${supportedDeployments}`,
      );
    }

    const config = loadConfig<DeploymentConfig>(options.config);
    try {
      await deploymentManager.deploy(
        contract,
        config,
        options.chain,
        options.deterministic,
      );
    } catch (error) {
      console.error("Deployment failed:", (error as Error).message);
      process.exit(1);
    }
  });

program.parse(process.argv);
