import path from "path";
import fs from "fs";

import { CallData, type Account, type Contract } from "starknet";
import {
  buildDeployer,
  Deployer,
  STARKNET_CHAINS,
  type Chain,
  type StarknetChain,
} from "pragma-utils";

import {
  type CurrenciesConfig,
  loadConfig,
  type DeploymentConfig,
  parsePairsFromConfig,
} from "../config";
import { type ContractDeployer } from "./interface";
import { CURRENCIES_CONFIG_FILE } from "../constants";
import { Currency } from "../config/currencies";

export class OracleDeployer implements ContractDeployer {
  readonly allowedChains: Chain[] = STARKNET_CHAINS;
  readonly defaultChain: StarknetChain = "starknet";
  async deploy(
    config: DeploymentConfig,
    deterministic: boolean,
    chain?: StarknetChain,
  ): Promise<void> {
    if (!chain) chain = this.defaultChain;
    if (!this.allowedChains.includes(chain)) {
      throw new Error(`⛔ Deployment to ${chain} is not supported.`);
    }

    let currencies = loadConfig<CurrenciesConfig>(CURRENCIES_CONFIG_FILE);
    let deployer = await buildDeployer(chain);
    let deploymentInfo: any = {};

    // 0. Deploy pragma publisher registry
    const publisherRegistry = await this.deployPublisherRegistry(
      deployer,
      config,
      deterministic,
    );
    deploymentInfo.PublisherRegistry = publisherRegistry.address;

    // 1. Deploy Pragma Oracle
    const pragmaOracle = await this.deployPragmaOracle(
      deployer,
      config,
      deterministic,
      currencies,
      publisherRegistry.address,
    );
    deploymentInfo.PragmaOracle = pragmaOracle.address;

    // 3. Deploy Summary stats
    const summaryStats = await this.deploySummaryStats(
      deployer,
      deterministic,
      pragmaOracle.address,
    );
    deploymentInfo.SummaryStats = summaryStats.address;

    // 4. Save deployment addresses
    const jsonContent = JSON.stringify(deploymentInfo, null, 4);
    const directoryPath = path.join("..", "..", "deployments", chain);
    const filePath = path.join(directoryPath, "oracle.json");
    // Create the directory if it doesn't exist
    fs.mkdirSync(directoryPath, { recursive: true });
    fs.writeFileSync(filePath, jsonContent);
    console.log(`Deployment info saved to ${filePath}`);
    console.log("Deployment complete!");
  }

  /// Deploys the Pragma Publisher Registry & register all publishers with their sources.
  private async deployPublisherRegistry(
    deployer: Deployer,
    config: DeploymentConfig,
    deterministic: boolean,
  ): Promise<Contract> {
    console.log(`⏳ Deploying Pragma Publisher Registry...`);
    const [publisherRegistry, calls] = await deployer.deferContract(
      "oracle",
      "pragma_publisher_registry_PublisherRegistry",
      CallData.compile({ deployer: deployer.address }),
      deterministic,
    );
    let response = await deployer.execute([...calls]);
    await deployer.waitForTransaction(response.transaction_hash);
    console.log(
      `🧩 Publisher Registry deployed at ${publisherRegistry.address}`,
    );

    console.log("⏳ Registering every publishers and their sources...");
    for (const publisher of config.pragma_oracle.publishers) {
      // Register the publisher
      console.log("\t ⏳ Registering", publisher.name, "...");
      let tx = await publisherRegistry.invoke("add_publisher", [
        publisher.name,
        publisher.address,
      ]);
      await deployer.waitForTransaction(tx.transaction_hash);
      // Register sources for the publisher
      for (const source of publisher.sources) {
        tx = await publisherRegistry.invoke("add_source_for_publisher", [
          publisher.name,
          source,
        ]);
        await deployer.waitForTransaction(tx.transaction_hash);
        console.log("\t\t Added source", source);
      }
      console.log("\t ⌛ Registered", publisher.name);
    }
    console.log("🧩 All publishers registered!");
    console.log("✅ Pragma Publisher Registry deployment complete!\n");
    return publisherRegistry;
  }

  /// Deploys the Pragma Oracle with the currencies & pairs from the config.
  private async deployPragmaOracle(
    deployer: Deployer,
    config: DeploymentConfig,
    deterministic: boolean,
    currenciesConfig: CurrenciesConfig,
    publisherRegistryAddress: string,
  ): Promise<Contract> {
    console.log(`⏳ Deploying Pragma Oracle...`);
    const currencies = currenciesConfig.map(Currency.fromCurrencyConfig);
    const serializedCurrencies = currencies.map((currency) =>
      currency.toObject(),
    );

    const pairs = parsePairsFromConfig(config);
    const serializedPairs = pairs.map((pair) => pair.toObject());

    const [pragmaOracle, calls] = await deployer.deferContract(
      "oracle",
      "pragma_oracle_Oracle",
      CallData.compile({
        deployer: deployer.address,
        publisherRegistryAddress,
        currencies: serializedCurrencies,
        pairs: serializedPairs,
      }),
      deterministic,
    );
    let response = await deployer.execute([...calls]);
    await deployer.waitForTransaction(response.transaction_hash);
    console.log(`🧩 Pragma Oracle deployed at ${pragmaOracle.address}`);
    console.log("✅ Pragma Oracle deployment complete!\n");
    return pragmaOracle;
  }

  /// Deploys the Summary Stats contract.
  private async deploySummaryStats(
    deployer: Deployer,
    deterministic: boolean,
    pragmaOracleAddress: string,
  ): Promise<Contract> {
    console.log(`⏳ Deploying Pragma Summary Stats...`);
    const [summaryStats, calls] = await deployer.deferContract(
      "oracle",
      "pragma_summary_stats_SummaryStats",
      CallData.compile({ pragmaOracleAddress }),
      deterministic,
    );
    let response = await deployer.execute([...calls]);
    await deployer.waitForTransaction(response.transaction_hash);
    console.log(`🧩 Pragma Summary Stats deployed at ${summaryStats.address}`);
    console.log("✅ Pragma Summary Stats deployment complete!\n");
    return summaryStats;
  }
}
