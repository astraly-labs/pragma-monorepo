import { TheorosSDK, AssetClass, UniqueVariant } from "@pragma/theoros-sdk";

(async () => {
  const sdk = new TheorosSDK({
    baseUrl: "https://api.pragma.build/v1",
  });

  try {
    const feeds = await sdk.getAvailableFeedIds();
    console.log("Data Feeds:", feeds);

    // Fetch calldata for the generated Feed ID
    const calldata = await sdk.getCalldata(feeds[0]);
    console.log("Calldata:", calldata.calldata);
  } catch (error) {
    console.error(error);
  }
})();
