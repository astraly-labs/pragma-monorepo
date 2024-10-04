import path from "path";
import fs from "fs";
import type { Account, Contract } from "starknet";
import { buildStarknetAccount, deployStarknetContract } from "../starknet";
import {
  type CurrenciesConfig,
  loadConfig,
  type DeploymentConfig,
  parsePairsFromConfig,
} from "../config";
import { type Deployer } from "./interface";
import { CURRENCIES_CONFIG_FILE } from "../constants";
import { Currency } from "../config/currencies";
import { STARKNET_CHAINS, type Chain } from "../chains";

export class OracleDeployer implements Deployer {
  readonly allowedChains: Chain[] = STARKNET_CHAINS;
  readonly defaultChain: Chain = "starknet";
  async deploy(config: DeploymentConfig, chain?: Chain): Promise<void> {
    if (!chain) chain = this.defaultChain;
    if (!this.allowedChains.includes(chain)) {
      throw new Error(`⛔ Deployment to ${chain} is not supported.`);
    }

    console.log(`🧩 Deploying Oracle to ${chain}...`);
    let currencies = loadConfig<CurrenciesConfig>(CURRENCIES_CONFIG_FILE);
    let deployer = await buildStarknetAccount(chain);
    let deploymentInfo: any = {};

    // 0. Deploy pragma publisher registry
    const publisherRegistry = await this.deployPublisherRegistry(
      deployer,
      config,
    );
    deploymentInfo.PublisherRegistry = publisherRegistry.address;

    // 1. Deploy Pragma Oracle
    const pragmaOracle = await this.deployPragmaOracle(
      deployer,
      config,
      currencies,
      publisherRegistry.address,
    );
    deploymentInfo.PragmaOracle = pragmaOracle.address;

    // 3. Deploy Summary stats
    const summaryStats = await this.deploySummaryStats(
      deployer,
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
    deployer: Account,
    config: DeploymentConfig,
  ): Promise<Contract> {
    let publisherRegistry = await deployStarknetContract(
      deployer,
      "oracle",
      `pragma_publisher_registry_PublisherRegistry`,
      [deployer.address],
    );
    console.log("⏳ Registering every publishers and their sources...");
    for (const publisher of config.pragma_oracle.publishers) {
      // Register the publisher
      let tx = await publisherRegistry.invoke("add_publisher", [
        publisher.name,
        publisher.address,
      ]);
      await deployer.waitForTransaction(tx.transaction_hash);
      // Register sources for the publisher
      tx = await publisherRegistry.invoke("add_sources_for_publisher", [
        publisher.name,
        publisher.sources,
      ]);
      await deployer.waitForTransaction(tx.transaction_hash);
    }
    console.log("✅ Done!");
    return publisherRegistry;
  }

  /// Deploys the Pragma Oracle with the currencies & pairs from the config.
  private async deployPragmaOracle(
    deployer: Account,
    config: DeploymentConfig,
    currenciesConfig: CurrenciesConfig,
    publisherRegistryAddress: string,
  ): Promise<Contract> {
    const currencies = currenciesConfig.map(Currency.fromCurrencyConfig);
    const serializedCurrencies = currencies.map((currency) => currency.toObject());

    const pairs = parsePairsFromConfig(config);
    const serializedPairs = pairs.map((pair) => pair.toObject());

    const pragmaOracle = await deployStarknetContract(
      deployer,
      "oracle",
      `pragma_oracle_Oracle`,
      [
        deployer.address, // admin
        publisherRegistryAddress,
        serializedCurrencies,
        serializedPairs,
      ],
    );

    return pragmaOracle;
  }

  /// Deploys the Summary Stats contract.
  private async deploySummaryStats(
    deployer: Account,
    pragmaOracleAddress: string,
  ): Promise<Contract> {
    const summaryStats = await deployStarknetContract(
      deployer,
      "oracle",
      "pragma_summary_stats_SummaryStats",
      [pragmaOracleAddress],
    );
    return summaryStats;
  }
}
