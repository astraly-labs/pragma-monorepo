# Theoros SDK

The official TypeScript SDK for interacting with the Pragma Theoros API. The Theoros SDK simplifies the process of:

- Fetching calldata for given feed IDs.
- Subscribing to real-time data feed updates via WebSocket.
- Retrieving available feeds and supported chains.

## Installation

```bash
npm install @pragma/theoros-sdk
```

## Introduction

The Theoros SDK provides a convenient way to interact with the Pragma Theoros API. It allows developers to:

- Fetch available data feeds and their details.
- Retrieve the list of supported chains.
- Fetch calldata for specific feeds on a given chain.
- Subscribe to real-time updates for data feeds over WebSockets.

## Getting Started

### Initializing the SDK

Import the SDK and create an instance:

```typescript
import { TheorosSDK } from "@pragma/theoros-sdk";

const sdk = new TheorosSDK({
  baseUrl: "https://api.pragma.build/v1", // Optional, defaults to this value
  timeout: 10000, // Optional, in milliseconds
});
```

- `baseUrl` (optional): The base URL of the Pragma Theoros API. Defaults to `'https://api.pragma.build/v1'`.
- `timeout` (optional): The request timeout in milliseconds. Defaults to `10000`.

### Usage

#### Fetching Available Feeds

Retrieve the list of available feeds:

```typescript
const feeds = await sdk.getAvailableFeeds();
console.log("Available Feeds:", feeds);
```

This method returns a promise that resolves to an array of Feed objects, each containing:

- `feed_id`: The unique identifier for the feed.
- `asset_class`: The asset class of the feed.
- `feed_type`: The type of the feed.
- `pair_id`: The pair identifier associated with the feed.

#### Fetching Supported Chains

Retrieve the list of supported chains:

```typescript
const chains = await sdk.getSupportedChains();
console.log("Supported Chains:", chains);
```

This method returns a promise that resolves to an array of strings representing the chain names.

#### Fetching Calldata

Fetch calldata for specific feed IDs on a given chain:

```typescript
const chain = "zircuit_testnet";
const feedIds = ["0x4e5354522f555344", "0x4c5553442f555344"];

try {
  const calldataResponses = await sdk.getCalldata(chain, feedIds);
  console.log("Calldata Responses:", calldataResponses);
} catch (error) {
  console.error("Error fetching calldata:", error);
}
```

- `chain`: The name of the chain.
- `feedIds`: An array of feed IDs.

The method returns a promise that resolves to an array of `CalldataResponse` objects, each containing:

- `feed_id`: The feed ID.
- `encoded_calldata`: The calldata encoded as a hex string.

### Subscribing to Data Feeds

Subscribe to data feed updates over WebSocket:

```typescript
const chain = "zircuit_testnet";
const feedIds = ["0x4e5354522f555344", "0x4c5553442f555344"];

const subscription = sdk.subscribe(chain, feedIds);
```

#### Handling Updates

Listen for updates and other events:

```typescript
subscription.on("update", (dataFeeds) => {
  console.log("Data Feed Update:", dataFeeds);
});

subscription.on("error", (error) => {
  console.error("Subscription Error:", error);
});

subscription.on("close", () => {
  console.log("Subscription Closed");
});
```

- `'update'`: Emitted when new data feed updates are received. The callback receives an array of RpcDataFeed objects.
- `'error'`: Emitted when an error occurs. The callback receives an error object.
- `'close'`: Emitted when the subscription is closed.

#### Adding and Removing Feed IDs

You can dynamically add or remove feed IDs from the subscription:

```typescript
// Add new feed IDs
subscription.addFeedIds(["0x1234567890abcdef"]);

// Remove feed IDs
subscription.removeFeedIds(["0x4e5354522f555344"]);
```

#### Unsubscribing

To unsubscribe from all feeds and close the connection:

```typescript
subscription.unsubscribe();
```

#### Example

Here's a complete example demonstrating how to use the SDK:

```typescript
import { TheorosSDK } from "@pragma/theoros-sdk";

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
    const feedIds = feeds.slice(0, 2).map((feed) => feed.feed_id);

    // Fetch calldata
    const calldataResponses = await sdk.getCalldata(chain, feedIds);
    console.log("Calldata Responses:", calldataResponses);

    // Subscribe to data feed updates
    const subscription = sdk.subscribe(chain, feedIds);

    subscription.on("update", (dataFeeds) => {
      console.log("Data Feed Update:", dataFeeds);
    });

    subscription.on("error", (error) => {
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
```

### Error Handling

The SDK uses a custom `TheorosSDKError` class for error handling. You can catch errors using `try...catc`h blocks:

```typescript
try {
  const calldataResponses = await sdk.getCalldata(chain, feedIds);
} catch (error) {
  if (error instanceof TheorosSDKError) {
    console.error("Theoros SDK Error:", error.message);
  } else {
    console.error("Unexpected Error:", error);
  }
}
```

For subscriptions, listen to the 'error' event:

```typescript
subscription.on("error", (error) => {
  console.error("Subscription Error:", error);
});
```

## License

This project is licensed under the [MIT](../../LICENSE) License.
