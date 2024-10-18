import fs from "fs";
import path from "path";

import { CallData, type Contract } from "starknet";
import {
  buildAccount,
  Deployer,
  STARKNET_CHAINS,
  type Chain,
  type StarknetChain,
} from "pragma-utils";

import { type ContractDeployer } from "./interface";
import {
  loadConfig,
  type AssetClassRouter,
  type DeploymentConfig,
  type FeedsConfig,
  type FeedTypeRouter,
} from "../config";
import { FEEDS_CONFIG_FILE } from "../constants";

export class DispatcherDeployer implements ContractDeployer {
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

    let feeds = loadConfig<FeedsConfig>(FEEDS_CONFIG_FILE);
    let deployer = await buildAccount(chain);
    let deploymentInfo: any = {};

    // 0. Deploy feeds registry
    const feedsRegistry = await this.deployFeedsRegistry(
      deployer,
      feeds,
      deterministic,
    );
    deploymentInfo.FeedsRegistry = feedsRegistry.address;

    // 1. Deploy pragma dispatcher
    const dispatcher = await this.deployDispatcher(
      deployer,
      feedsRegistry.address,
      config,
      deterministic,
    );
    deploymentInfo.PragmaDispatcher = dispatcher.address;

    // 2. Deploy & register all routers
    deploymentInfo.AssetClassRouters = await this.deployAllRouters(
      deployer,
      config,
      feeds,
      dispatcher,
      deterministic,
    );

    // 3. Save deployment addresses
    const jsonContent = JSON.stringify(deploymentInfo, null, 4);
    const directoryPath = path.join("..", "..", "deployments", chain);
    const filePath = path.join(directoryPath, "dispatcher.json");
    // Create the directory if it doesn't exist
    fs.mkdirSync(directoryPath, { recursive: true });
    fs.writeFileSync(filePath, jsonContent);
    console.log(`Deployment info saved to ${filePath}`);
    console.log("Deployment complete!");
  }

  /// Deploys the Pragma Feeds Registry and register all supported feeds.
  private async deployFeedsRegistry(
    deployer: Deployer,
    feeds: FeedsConfig,
    deterministic: boolean,
  ): Promise<Contract> {
    console.log(`⏳ Deploying Pragma Feeds Registry...`);
    const [feedsRegistry, calls] = await deployer.deferContract(
      "dispatcher",
      "pragma_feeds_registry_PragmaFeedsRegistry",
      CallData.compile({ deployer: deployer.address }),
      deterministic,
    );
    let response = await deployer.execute([...calls]);
    await deployer.waitForTransaction(response.transaction_hash);
    console.log(
      `🧩 Pragma Feeds Registry deployed at ${feedsRegistry.address}`,
    );

    console.log("⏳ Registering all feed ids in the config...");
    let tx = await feedsRegistry.invoke("add_feeds", [feeds.feeds.map((feed) => feed.id)]);
    await deployer.waitForTransaction(tx.transaction_hash);
    console.log("\tRegistered", feeds.feeds.map((feed) => feed.name).join(", "));
    console.log("🧩 All feeds registered!");
    console.log("✅ Pragma Feeds Registry deployment complete!\n");
    return feedsRegistry;
  }

  /// Deploys the Pragma Dispatcher contract.
  private async deployDispatcher(
    deployer: Deployer,
    feedsRegistryAddress: string,
    config: DeploymentConfig,
    deterministic: boolean,
  ): Promise<Contract> {
    console.log(`⏳ Deploying Pragma Dispatcher...`);
    const [dispatcher, calls] = await deployer.deferContract(
      "dispatcher",
      "pragma_dispatcher_PragmaDispatcher",
      CallData.compile({
        deployer: deployer.address,
        feedsRegistryAddress,
        hyperlaneMailboxAddress:
          config.pragma_dispatcher.hyperlane_mailbox_address,
      }),
      deterministic,
    );
    let response = await deployer.execute([...calls]);
    await deployer.waitForTransaction(response.transaction_hash);
    console.log(`🧩 Pragma Dispatcher deployed at ${dispatcher.address}`);
    console.log("✅ Pragma Dispatcher deployment complete!\n");
    return dispatcher;
  }

  /// Deploys all supported routers.
  private async deployAllRouters(
    deployer: Deployer,
    config: DeploymentConfig,
    feeds: FeedsConfig,
    pragmaDispatcher: Contract,
    deterministic: boolean,
  ): Promise<any> {
    let assetClassRouters: any = {};
    for (const asset_class of feeds.asset_classes_routers) {
      assetClassRouters[asset_class.name] = await this.deployNewAssetClass(
        deployer,
        config,
        asset_class,
        pragmaDispatcher,
        deterministic,
      );
    }
    return assetClassRouters;
  }

  private async deployNewAssetClass(
    deployer: Deployer,
    config: DeploymentConfig,
    asset_class: AssetClassRouter,
    pragmaDispatcher: Contract,
    deterministic: boolean,
  ): Promise<any> {
    console.log(`⏳ Deploying & registering ${asset_class.contract} router...`);
    const [assetRouter, calls] = await deployer.deferContract(
      "dispatcher",
      `pragma_dispatcher_${asset_class.contract}`,
      CallData.compile({
        deployer: deployer.address,
        assetClassId: asset_class.id,
      }),
      deterministic,
    );
    let response = await deployer.execute([...calls]);
    await deployer.waitForTransaction(response.transaction_hash);
    console.log(
      `🧩 ${asset_class.contract} router deployed at ${assetRouter.address}`,
    );

    console.log(
      `⏳ Registering all feed types router of ${asset_class.contract}...`,
    );
    let tx = await pragmaDispatcher.invoke("register_asset_class_router", [
      asset_class.id,
      assetRouter.address,
    ]);
    await deployer.waitForTransaction(tx.transaction_hash);

    let feedTypeRouters: any = {};
    for (const feed_type of asset_class.feed_types_routers) {
      feedTypeRouters[feed_type.name] = await this.deployNewFeedType(
        deployer,
        config,
        assetRouter,
        feed_type,
        deterministic,
      );
      console.log("\tRegistered", feed_type.name);
    }

    console.log(`✅ ${asset_class.contract} router deployment complete!`);
    return {
      address: assetRouter.address,
      feed_type_routers: feedTypeRouters,
    };
  }

  private async deployNewFeedType(
    deployer: Deployer,
    config: DeploymentConfig,
    asset_class: Contract,
    feed_type: FeedTypeRouter,
    deterministic: boolean,
  ): Promise<string> {
    const [feedRouter, calls] = await deployer.deferContract(
      "dispatcher",
      `pragma_dispatcher_${feed_type.contract}`,
      CallData.compile({
        pragmaOracleAddress: config.pragma_dispatcher.pragma_oracle_address,
        feedTypeId: feed_type.id,
      }),
      deterministic,
    );
    let response = await deployer.execute([...calls]);
    await deployer.waitForTransaction(response.transaction_hash);

    let tx = await asset_class.invoke("register_feed_type_router", [
      feed_type.id,
      feedRouter.address,
    ]);
    await deployer.waitForTransaction(tx.transaction_hash);
    return feedRouter.address;
  }
}
