# Theoros SDK

The official TypeScript SDK for interacting with the Pragma Theoros API. The Theoros SDK simplifies the process of fetching calldata for a given Feed ID, which can be used to update data on EVM chains.

## Install

```bash
npm install @pragma/theoros-sdk
```

## Usage

### Initializing the SDK

To start using the Theoros SDK, import it and create an instance:

```typescript
import { TheorosSDK } from "@pragma/theoros-sdk";

const sdk = new TheorosSDK({
  baseUrl: "https://api.pragma.build/v1", // Optional, defaults to this value
  timeout: 10000, // Optional, in milliseconds
});
```

- `baseUrl`: The base URL of the Pragma Theoros API. Defaults to `https://api.pragma.build/v1`.
- `timeout`: The request timeout in milliseconds. Defaults to `10000`.

### Fetching Available Feed IDs

Retrieve the list of available Feed IDs using the `getAvailableFeedIds` method:

```typescript
const feedIds = await sdk.getAvailableFeedIds();
console.log("Available Feed IDs:", feedIds);
```

This method returns a promise that resolves to an array of string containing the Feed IDs.

### Fetching Calldata for a Feed ID

Once you have a Feed ID, you can fetch its calldata using the `getCalldata` method:

```typescript
const feedId = feedIds[0]; // For example, use the first Feed ID
const calldataResponse = await sdk.getCalldata(feedId);
console.log("Calldata:", calldataResponse.calldata);
```

- `feedId`: The Feed ID for which you want to fetch the calldata.
  The getCalldata method returns a promise that resolves to a `CalldataResponse` object containing:
- `calldata`: An array of numbers representing the calldata.

#### Example

Here is a complete example demonstrating how to use the Theoros SDK:

```typescript
import { TheorosSDK } from "@pragma/theoros-sdk";

(async () => {
  const sdk = new TheorosSDK({
    baseUrl: "https://api.pragma.build/v1",
  });

  try {
    // Fetch available feed IDs
    const feeds = await sdk.getAvailableFeedIds();
    console.log("Available Feed IDs:", feeds);

    if (feeds.length === 0) {
      console.log("No feeds available.");
      return;
    }

    // Fetch calldata for the first available Feed ID
    const calldataResponse = await sdk.getCalldata(feeds[0]);
    console.log("Calldata:", calldataResponse.calldata);
  } catch (error) {
    console.error("An error occurred:", error);
  }
})();
```

This script:

1. Initializes the SDK.
2. Retrieves the available Feed IDs.
3. Fetches the calldata for the first Feed ID.
4. Logs the calldata to the console.

## License

This project is licensed under the [MIT License](../../LICENSE.md).
