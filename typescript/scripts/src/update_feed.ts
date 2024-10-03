// ## CLI
// - chain
// - target-chain (from Pragma.sol - must be deployed)
// - feed_id
// - private_key

// ## Steps
// 1. Theoros ? (endpoint selection)
// 2. Get calldata from Theoros
// 3. Call `updateDataFeeds` with the calldata
// 4. Assertions - check that on the destination chain everything is correctly updated
//    Show gas consumption


import { Command, type OptionValues } from "commander";
import { ethers } from "ethers";
import dotenv from "dotenv";
import yaml from 'js-yaml';
import fs from 'fs';

dotenv.config();

interface ChainConfig {
  contract_address: string;
}

function getChainConfig(chainName: string): ChainConfig {
  try {
    const fileContents = fs.readFileSync('configs/contracts.yaml', 'utf8');
    const chainConfigs = yaml.load(fileContents) as { [key: string]: ChainConfig };

    const chainConfig = chainConfigs[chainName];
    if (!chainConfig) {
      throw new Error(`Configuration not found for chain ${chainName}`);
    }

    return chainConfig;
  } catch (error) {
    console.error("Error reading configuration file:", error);
    throw error;
  }
}

function parseCommandLineArguments(): OptionValues {
  const program = new Command();

  program
    .name("update-data-feed")
    .description("CLI to update a Pragma data feed")
    .requiredOption("--target-chain <chain_name>", "Name of the target chain (e.g., ethereum_mainnet)")
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

  if (!options.targetChain || typeof options.targetChain !== 'string') {
    console.error("Error: Target chain name must be a valid string");
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
    `Updating data feed ${feedId} for contract ${chainConfig.contract_address} on chain ${options.targetChain}`,
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
  const contract = new ethers.Contract(chainConfig.contract_address, abi.abi, wallet);

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
