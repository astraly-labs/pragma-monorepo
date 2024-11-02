import {
  TheorosSDK,
  type Feed,
  type RpcDataFeed,
  type TheorosSDKError,
} from "@pragma/theoros-sdk";

(async () => {
  const sdk = new TheorosSDK();

  try {
    // Fetch available feeds
    const feeds = await sdk.getAvailableFeeds();
    console.log("Available Feeds:", feeds);

    // Fetch supported chains
    const chains = await sdk.getSupportedChains();
    console.log("Supported Chains:", chains);

    // Choose a chain and feed IDs
    const chain = chains[0];
    const feedIds = feeds.slice(0, 2).map((feed: Feed) => feed.feed_id);

    // Fetch calldata
    const calldataResponses = await sdk.getCalldata(chain, feedIds);
    console.log("Calldata Responses:", calldataResponses);

    // Subscribe to data feed updates
    const subscription = sdk.subscribe(chain, feedIds);

    subscription.on("update", (dataFeeds: RpcDataFeed[]) => {
      console.log("Data Feed Update:", dataFeeds);
    });

    subscription.on("error", (error: TheorosSDKError) => {
      console.error("Subscription Error:", error);
    });

    // Add a new feed ID after some time
    setTimeout(() => {
      subscription.addFeedIds(["0x1234567890abcdef"]);
    }, 5000);

    // Unsubscribe after some time
    setTimeout(() => {
      subscription.unsubscribe();
    }, 15000);
  } catch (error) {
    console.error("An error occurred:", error);
  }
})();
