## Pragma Solidity SDK

This package provides the interfaces and structs that can be used in your
solidity contracts to interact with Pragma core contract.

## Installation

### Foundry

```bash
# Install Foundry (Forge)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install the Solidity SDK for Forge
forge install @pragmaoracle/solidity-sdk
```

### Hardhat

```bash
# Install Hardhat globally
npm install --save-dev hardhat

# Install the Solidity SDK for Hardhat
npm install @pragmaoracle/solidity-sdk
```

## Example Usage

```solidity
pragma solidity ^0.8.0;

import "@pragmaoracle/solidity-sdk/IPragma.sol";
import "@pragmaoracle/solidity-sdk/PragmaStructs.sol";

contract YourContract {
  IPragma oracle;

  /**
   * @param pragmaContract The address of the Pragma contract
   */
  constructor(address pragmaContract) {
    // The IPragam interface from the sdk provides the methods to interact with the Pragma contract.
    oracle = IPragma(pragmaContract);
  }

  /**
   * This method is an example of how to interact with the Pragma contract to fetch Spot Median updates. You can check the documentation to
   * find the available feeds.
   * @param priceUpdate The encoded data to update the contract with the latest price
   */
  function yourFunction(bytes[] calldata priceUpdate) public payable {
    // Submit a priceUpdate to the Pragma contract to update the on-chain price.
    // Updating the price requires paying the fee returned by getUpdateFee.
    uint fee = oracle.getUpdateFee(priceUpdate);
    oracle.updatePriceFeeds{ value: fee }(priceUpdate);

    // Read the current price from a price feed if it is less than 60 seconds old.
    // Each price feed (e.g., Spot Median ETH/USD) is identified by a unique identifier id.
    bytes32 id = 0x4554482f555344; // ETH/USD
    PragmaStructs.DataFeed memory data_feed = oracle.getSpotMedianNoOlderThan(
      id,
      60
    );
  }
}
```

Let's detail the operations done by the snippet above.
Firstly we instantiate a `IPragma` interface from the solidity SDK, linked to a Pragma contract, passed in the constructor.  
Then we call `IPragma.getUpdateFee` to determine the fee charged to update the price.  
After calling `IPragma.updatePriceFeeds` to update the price, paying the previous fee, we call `IPragma.getSpotMedianNoOlderThan` to read the current spot median price for the given feed id providing an acceptable staleness for the data to be fetched.
You can find [here](https://docs.pragma.build/v2/Price%20Feeds/supported-assets-chains) the list of available feeds.

#### Integration by copying the Pragma interface

Alternatively, you can copy the `IPragma.sol` interface and `PragmaStructs.sol` inside your repository, and generate an instance using a deployed Pragma contract.

```solidity
import { IPragma } from "./interfaces/IPragma.sol";
import "./interfaces/PragmaStructs.sol" as PragmaStructs;
```

The rest remains the same as described above.

### Available feeds

You can now use various methods to fetch data from the Pragma oracle. Here are the main functions:

- **getSpotMedianNoOlderThan**(bytes32 id, uint256 age)
- **getTwapNoOlderThan**(bytes32 id, uint256 age)
- **getRealizedVolatilityNoOlderThan**(bytes32 id, uint256 age)
- **getOptionsNoOlderThan**(bytes32 id, uint256 age)
- **getPerpNoOlderThan**(bytes32 id, uint256 age)
