import dotenv from "dotenv";
import fs from "fs";
import path from "path";

import type { Deployer, Chain } from "./interface";
import { deployContract, buildAccount } from "../cairo";
import {
  loadConfig,
  type AssetClassRouter,
  type DeploymentConfig,
  type FeedsConfig,
  type FeedTypeRouter,
} from "../config";
import { FEEDS_CONFIG_FILE } from "../constants";
import type { Account, Contract } from "starknet";

dotenv.config();
const NETWORK = process.env.NETWORK;

const REGISTRY_PREFIX = "pragma_feeds_registry";
const DISPATCHER_PREFIX = "pragma_dispatcher";

export class DispatcherDeployer implements Deployer {
  readonly allowedChains: Chain[] = ["starknet"];
  readonly defaultChain: Chain = "starknet";

  async deploy(config: DeploymentConfig, chain?: Chain): Promise<void> {
    if (!chain) chain = this.defaultChain;
    if (!this.allowedChains.includes(chain)) {
      throw new Error(`⛔ Deployment to ${chain} is not supported.`);
    }

    if (NETWORK === undefined) {
      throw new Error("⛔ NETWORK in .env must be defined");
    }

    console.log(`🧩 Deploying Dispatcher to ${chain}...`);
    let supported_feeds = loadConfig<FeedsConfig>(FEEDS_CONFIG_FILE);
    let deployer = await buildAccount();
    let deploymentInfo: any = {};

    const feedsRegistry = await this.deployFeedsRegistry(
      deployer,
      supported_feeds,
    );
    deploymentInfo.FeedsRegistry = feedsRegistry.address;

    const dispatcher = await this.deployDispatcher(
      deployer,
      feedsRegistry.address,
      config,
    );
    deploymentInfo.PragmaDispatcher = dispatcher.address;

    deploymentInfo.AssetClassRouters = await this.deployAllRouters(
      deployer,
      config,
      supported_feeds,
      dispatcher,
    );

    const jsonContent = JSON.stringify(deploymentInfo, null, 2);
    const filePath = path.join("deployments", NETWORK, "dispatcher.json");
    fs.writeFileSync(filePath, jsonContent);
    console.log(`Deployment info saved to ${filePath}`);

    console.log("Deployment complete!");
  }

  /// Deploys the Pragma Feeds Registry and register all supported feeds.
  private async deployFeedsRegistry(
    deployer: Account,
    supported_feeds: FeedsConfig,
  ): Promise<Contract> {
    let feedsRegistry = await deployContract(
      deployer,
      `${REGISTRY_PREFIX}_PragmaFeedsRegistry`,
      [deployer.address],
    );
    for (const feed of supported_feeds.feeds) {
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
  ): Promise<Contract> {
    const dispatcher = await deployContract(
      deployer,
      `${DISPATCHER_PREFIX}_PragmaDispatcher`,
      [
        deployer.address,
        feedsRegistryAddress,
        config.pragma_dispatcher.hyperlane_mailbox_address,
      ],
    );
    return dispatcher;
  }

  /// Deploys all supported routers.
  private async deployAllRouters(
    deployer: Account,
    config: DeploymentConfig,
    supported_feeds: FeedsConfig,
    pragmaDispatcher: Contract,
  ): Promise<any> {
    let assetClassRouters: any = {};
    for (const asset_class of supported_feeds.asset_classes_routers) {
      assetClassRouters[asset_class.name] = await this.deployNewAssetClass(
        deployer,
        config,
        asset_class,
        pragmaDispatcher,
      );
    }
    return assetClassRouters;
  }

  private async deployNewAssetClass(
    deployer: Account,
    config: DeploymentConfig,
    asset_class: AssetClassRouter,
    pragmaDispatcher: Contract,
  ): Promise<any> {
    let assetRouter = await deployContract(
      deployer,
      `${DISPATCHER_PREFIX}_${asset_class.contract}`,
      [deployer.address, asset_class.id],
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
  ): Promise<string> {
    const feedRouter = await deployContract(
      deployer,
      `${DISPATCHER_PREFIX}_${feed_type.contract}`,
      [config.pragma_dispatcher.pragma_oracle_address, feed_type.id],
    );
    await asset_class.invoke("register_feed_type_router", [
      feed_type.id,
      feedRouter.address,
    ]);
    return feedRouter.address;
  }
}
