import { Command } from "commander";
import deploymentManager from "./manager";
import { loadConfig, type DeploymentConfig } from "./config/index";

const program = new Command();

program
  .name("pragma-cli")
  .description("CLI to deploy and verify Pragma contracts")
  .version("1.0.0");

program
  .command("deploy <contract>")
  .description("Deploy a contract")
  .requiredOption("--config <config>", "Path to the YAML config file")
  .option("--chain <chain>", "Chain where the contract will be deployed")
  .option("--deterministic", "Deterministic deployment addresses")
  .action(async (contract: string, options) => {
    contract = contract.toLowerCase();

    const supportedDeployments = deploymentManager.supportedDeployments();
    if (!supportedDeployments.includes(contract)) {
      throw new Error(
        `"${contract}" is not supported for deployment. Supported contracts: ${supportedDeployments.join(
          ", ",
        )}`,
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

program
  .command("verify <contract>")
  .description("Verify a deployed contract")
  .requiredOption("--config <config>", "Path to the YAML config file")
  .option("--chain <chain>", "Chain where the contract is deployed")
  .action(async (contract: string, options) => {
    contract = contract.toLowerCase();

    const supportedDeployments = deploymentManager.supportedDeployments();
    if (!supportedDeployments.includes(contract)) {
      throw new Error(
        `"${contract}" is not supported for verification. Supported contracts: ${supportedDeployments.join(
          ", ",
        )}`,
      );
    }

    const config = loadConfig<DeploymentConfig>(options.config);
    try {
      await deploymentManager.verify(contract, config, options.chain);
    } catch (error) {
      console.error("Verification failed:", (error as Error).message);
      process.exit(1);
    }
  });

program.parse(process.argv);
