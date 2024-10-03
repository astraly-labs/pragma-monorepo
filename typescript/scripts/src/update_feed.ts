// ## Cli
// - chain
// - target-chain (de Pragma.sol - donc ça doit être déployé)
// - feed_id
// - private_key
// - (keystore)

// ## Steps
// 1. Theoros ? (choix de l'endpoint)
// 2. Get calldata from Theoros
// 3. Call `updateDataFeeds` avec la calldata
// 4. Assertions - check that on the destination chain everything is correctly updated
//    Show gas consumption


import { Command } from "commander";
import { ethers } from "ethers";
import dotenv from "dotenv";

dotenv.config();

interface ChainConfig {
  contractId: string;
}

function getChainConfig(chainId: string): ChainConfig {
  const chainConfigs: { [key: string]: ChainConfig } = {
    "0x1": { contractId: "0x1111111111111111111111111111111111111111" }, // Ethereum Mainnet
    "0xaa36a7": { contractId: "0x2222222222222222222222222222222222222222" }, // Ethereum Sepolia
    "0x534e5f4d41494e": {
      contractId: "0x3333333333333333333333333333333333333333",
    }, // StarkNet Mainnet
    "0x534e5f474f45524c49": {
      contractId: "0x4444444444444444444444444444444444444444",
    }, // StarkNet Sepolia (Goerli)
    "0xa4b1": { contractId: "0x5555555555555555555555555555555555555555" }, // Arbitrum
    "0xa": { contractId: "0x6666666666666666666666666666666666666666" }, // Optimism
  };

  const config = chainConfigs[chainId];
  if (!config) {
    throw new Error(`Configuration non trouvée pour le chainId ${chainId}`);
  }

  return config;
}

function parseCommandLineArguments() {
  const program = new Command();

  program
    .name("update-data-feed")
    .description("CLI to update a Pragma data feed")
    .requiredOption("--target-chain <chain_id>", "Chain ID of the target chain")
    .requiredOption("--feed-id <feed_id>", "ID of the data feed to update")
    .requiredOption(
      "--private-key <private_key>",
      "Private key to sign the transaction",
    )
    .option(
      "--theoros-endpoint <url>",
      "Theoros endpoint URL",
      "https://theoros.pragma.build/",
    )
    .parse(process.argv);

  const options = program.opts();

  if (!ethers.isHexString(options.targetChain)) {
    console.error("Error: Target chain ID must be a valid hexadecimal string");
    process.exit(1);
  }

  if (!Number.isInteger(Number(options.feedId))) {
    console.error("Error: Feed ID must be an integer");
    process.exit(1);
  }

  if (!ethers.isHexString(options.privateKey)) {
    console.error("Error: Private key must be a valid hexadecimal string");
    process.exit(1);
  }

  if (options.theorosEndpoint) {
    try {
      new URL(options.theorosEndpoint);
    } catch (error) {
      console.error("Error: The Theoros endpoint URL is not valid");
      process.exit(1);
    }
  }

  return options;
}

async function getCalldataFromTheoros(
  theorosEndpoint: string,
  feedId: string,
): Promise<Uint8Array> {
  try {
    const url = `${theorosEndpoint}/v1/calldata/${feedId}`;
    console.log(`Fetching calldata from: ${url}`);

    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`HTTP error: ${response.status}`);
    }

    const data = await response.json();

    // Assuming that we retrieve calldata as hex string from theoros
    // TODO: change this part with real calldata from theoros
    if (!data.calldata || typeof data.calldata !== "string") {
      throw new Error("Invalid response format: calldata missing or invalid");
    }
    const calldataHex = data.calldata.startsWith("0x")
      ? data.calldata.slice(2)
      : data.calldata;
    return new Uint8Array(Buffer.from(calldataHex, "hex"));
  } catch (error) {
    console.error("Error fetching data from Theoros:", error);
    throw error;
  }
}

async function main() {
  const options = parseCommandLineArguments();

  const chainConfig = getChainConfig(options.targetChain);
  const feedId = options.feedId;
  const privateKey = options.privateKey;
  const theorosEndpoint = options.theorosEndpoint;

  console.log(
    `Updating data feed ${feedId} for contract ${chainConfig.contractId} on chain ${options.targetChain}`,
  );
  console.log(`Using Theoros endpoint: ${theorosEndpoint}`);

  // 2. Get calldata from Theoros
  let calldata: Uint8Array;
  try {
    calldata = await getCalldataFromTheoros(theorosEndpoint, feedId);
    console.log("Calldata retrieved from Theoros:", calldata);
  } catch (error) {
    console.error("Failed to retrieve calldata from Theoros:", error);
    process.exit(1);
  }
  
  // 3. Call `updateDataFeeds` with the calldata
  let abi;
  try {
    abi = await import("../../../solidity/out/Pragma.sol/Pragma.json");
  } catch (error) {
    console.error("Failed to import ABI:", error);
    throw new Error("ABI file not found or invalid");
  }
  const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
  const wallet = new ethers.Wallet(privateKey, provider);
  const contract = new ethers.Contract(chainConfig.contractId, abi.abi, wallet);

  try {
    const tx = await contract.updateDataFeeds(calldata);
    console.log("Transaction sent. Transaction hash:", tx.hash);

    // 4. Assertions - check that everything is correctly updated on the destination chain
    const receipt = await tx.wait();
    console.log("Transaction confirmed in block:", receipt.blockNumber);
    console.log("Gas used:", receipt.gasUsed.toString());
  } catch (error) {
    console.error("Error updating data feed:", error);
    process.exit(1);
  }
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exit(1);
});
