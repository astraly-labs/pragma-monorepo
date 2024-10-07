import fs from "fs";
import path from "path";

import { type Deployer } from "./interface";
import { deployStarknetContract, buildStarknetAccount } from "../starknet";
import {
  loadConfig,
  type AssetClassRouter,
  type DeploymentConfig,
  type FeedsConfig,
  type FeedTypeRouter,
} from "../config";
import { FEEDS_CONFIG_FILE } from "../constants";
import type { Account, Contract } from "starknet";
import { STARKNET_CHAINS, type Chain } from "../chains";

export class DispatcherDeployer implements Deployer {
  readonly allowedChains: Chain[] = STARKNET_CHAINS;
  readonly defaultChain: Chain = "starknet";

  async deploy(
    config: DeploymentConfig,
    deterministic: boolean,
    chain?: Chain,
  ): Promise<void> {
    if (!chain) chain = this.defaultChain;
    if (!this.allowedChains.includes(chain)) {
      throw new Error(`⛔ Deployment to ${chain} is not supported.`);
    }

    console.log(`🧩 Deploying Dispatcher to ${chain}...`);
    let feeds = loadConfig<FeedsConfig>(FEEDS_CONFIG_FILE);
    let deployer = await buildStarknetAccount(chain);
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
    deployer: Account,
    feeds: FeedsConfig,
    deterministic: boolean,
  ): Promise<Contract> {
    let feedsRegistry = await deployStarknetContract(
      deployer,
      "dispatcher",
      `pragma_feeds_registry_PragmaFeedsRegistry`,
      [deployer.address],
      deterministic,
    );
    for (const feed of feeds.feeds) {
      let tx = await feedsRegistry.invoke("add_feed", [feed.id]);
      await deployer.waitForTransaction(tx.transaction_hash);
      console.log("Registered", feed.name);
    }
    console.log("✅ Deployed the Pragma Feeds Registry");
    return feedsRegistry;
  }

  /// Deploys the Pragma Dispatcher contract.
  private async deployDispatcher(
    deployer: Account,
    feedsRegistryAddress: string,
    config: DeploymentConfig,
    deterministic: boolean,
  ): Promise<Contract> {
    const dispatcher = await deployStarknetContract(
      deployer,
      "dispatcher",
      `pragma_dispatcher_PragmaDispatcher`,
      [
        deployer.address,
        feedsRegistryAddress,
        config.pragma_dispatcher.hyperlane_mailbox_address,
      ],
      deterministic,
    );
    return dispatcher;
  }

  /// Deploys all supported routers.
  private async deployAllRouters(
    deployer: Account,
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
    deployer: Account,
    config: DeploymentConfig,
    asset_class: AssetClassRouter,
    pragmaDispatcher: Contract,
    deterministic: boolean,
  ): Promise<any> {
    let assetRouter = await deployStarknetContract(
      deployer,
      "dispatcher",
      `pragma_dispatcher_${asset_class.contract}`,
      [deployer.address, asset_class.id],
      deterministic,
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
    }

    return {
      address: assetRouter.address,
      feed_type_routers: feedTypeRouters,
    };
  }

  private async deployNewFeedType(
    deployer: Account,
    config: DeploymentConfig,
    asset_class: Contract,
    feed_type: FeedTypeRouter,
    deterministic: boolean,
  ): Promise<string> {
    const feedRouter = await deployStarknetContract(
      deployer,
      "dispatcher",
      `pragma_dispatcher_${feed_type.contract}`,
      [config.pragma_dispatcher.pragma_oracle_address, feed_type.id],
      deterministic,
    );
    let tx = await asset_class.invoke("register_feed_type_router", [
      feed_type.id,
      feedRouter.address,
    ]);
    await deployer.waitForTransaction(tx.transaction_hash);
    return feedRouter.address;
  }
}
