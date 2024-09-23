import type { Deployer, Chain } from "./interface";
import fs from "fs";
import path from "path";

import { deployContract, buildAccount } from "../cairo";

const ASSET_CLASS_CRYPTO_ID = 0;

// TODO: This should probably be its own configuration *somewhere*. TBD
const PRAGMA_FEEDS = [
  18669995996566340, // BTC/USD: SpotMedian
  19514442401534788, // ETH/USD: SpotMedian
];

// TODO: Shall this be configured at a config file level? Or CLI? Both? TBD
const PRAGMA_ORACLE_ADDRESS = "0x1";
const HYPERLANE_MAILBOX_ADDRESS = "0x1";

export class DispatcherDeployer implements Deployer {
  readonly allowedChains: Chain[] = ["starknet"];
  readonly defaultChain: Chain = "starknet";
  async deploy(chain?: Chain): Promise<void> {
    if (!chain) chain = this.defaultChain;
    console.log(`🧩 Deploying Dispatcher to ${chain}...`);

    let deploymentInfo: any = {};
    let deployer = await buildAccount();

    // 0. Deploy the Feeds Registry
    let feedsRegistry = await deployContract(deployer, "PragmaFeedsRegistry", [
      deployer.address,
    ]);
    deploymentInfo.PragmaFeedsRegistry = feedsRegistry.address;
    for (const feed_id of PRAGMA_FEEDS) {
      let tx = await feedsRegistry.invoke("add_feed", [feed_id]);
      await deployer.waitForTransaction(tx.transaction_hash);
    }
    console.log("✅ Deployed the Pragma Feeds Registry");

    // 1. Deploy Dispatcher
    const dispatcher = await deployContract(deployer, "PragmaDispatcher", [
      deployer.address,
      feedsRegistry.address,
      HYPERLANE_MAILBOX_ADDRESS,
    ]);
    deploymentInfo.PragmaDispatcher = dispatcher.address;
    console.log("✅ Deployed the Pragma Dispatcher");

    // 2. Deploy Asset class router for Crypto
    console.log(
      `⏳ Deploying & registering asset class router ${ASSET_CLASS_CRYPTO_ID}...`,
    );
    let cryptoRouter = await deployContract(deployer, "AssetClassRouter", [
      deployer.address,
      ASSET_CLASS_CRYPTO_ID,
    ]);
    console.log("✅ Deployed!");
    let tx = await dispatcher.invoke("register_asset_class_router", [
      ASSET_CLASS_CRYPTO_ID,
      cryptoRouter.address,
    ]);
    await deployer.waitForTransaction(tx.transaction_hash);
    console.log("✅ Registered with the Pragma Dispatcher!\n");

    deploymentInfo.CryptoRouter = {
      address: cryptoRouter.address,
      feeds: {},
    };

    // 3. Deploy all unique feeds
    for (const feed_id of PRAGMA_FEEDS) {
      console.log(`⏳ Deploying & registering feed type router ${feed_id}...`);
      const feedRouter = await deployContract(
        deployer,
        "FeedTypeUniqueRouter",
        [PRAGMA_ORACLE_ADDRESS, feed_id],
      );
      console.log("✅ Deployed!");
      await cryptoRouter.invoke("register_feed_type_router", [
        feed_id,
        feedRouter.address,
      ]);
      console.log("✅ Registered with the Crypto Router!\n", feed_id);
      deploymentInfo.CryptoRouter.feeds[feed_id] = feedRouter.address;
    }

    // Save deployment info to JSON file
    const jsonContent = JSON.stringify(deploymentInfo, null, 2);
    const filePath = path.join("deployments", "dispatcher.json");
    fs.writeFileSync(filePath, jsonContent);
    console.log(`Deployment info saved to ${filePath}`);

    console.log("Deployment complete!");
  }
}
