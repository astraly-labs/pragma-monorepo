import { Command, type OptionValues } from "commander";
import { encodeBytes32String, ethers, getBytes, solidityPacked } from "ethers";
import dotenv from "dotenv";
import { getDeployedAddress } from "pragma-utils";
import fetch from "node-fetch";

const PRAGMA_SOL_ABI_PATH = "../../../../solidity/out/Pragma.sol/Pragma.json";

dotenv.config();
const RPC_URL = process.env.RPC_URL;
if (!RPC_URL) {
  throw new Error("RPC URL not set in .env file");
}

function snakeToCamel(s: string): string {
  return s.replace(/_([a-z])/g, (g) => g[1].toUpperCase());
}

function parseCommandLineArguments(): OptionValues {
  const program = new Command();

  program
    .name("update-feed")
    .description("CLI to update a Pragma feed")
    .requiredOption(
      "--chain <chain_name>",
      "Name of the target chain (e.g., ethereum_mainnet)",
    )
    .requiredOption("--feed-id <feed_id>", "ID of the feed to update")
    .option(
      "--theoros-url <url>",
      "Theoros URL",
      "https://theoros.pragma.build",
    )
    .parse(process.argv);

  const options = program.opts();

  if (!options.chain || typeof options.chain !== "string") {
    console.error("Error: Chain name must be a valid string");
    process.exit(1);
  }

  if (!options.feedId || typeof options.feedId !== "string") {
    console.error("Error: Feed ID must be a valid string");
    process.exit(1);
  }

  if (options.theorosUrl) {
    try {
      new URL(options.theorosUrl);
    } catch (error) {
      console.error("Error: The Theoros endpoint URL is not valid");
      process.exit(1);
    }
  }

  return options;
}

async function getCalldataFromTheoros(
  theorosUrl: string,
  chain: string,
  feedIds: string[],
): Promise<string> {
  try {
    const feedIdsParam = feedIds.join(",");
    const url = `${theorosUrl}/v1/calldata?chain=${chain}&feed_ids=${feedIdsParam}`;
    console.log(`Fetching calldata from: ${url}`);

    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`HTTP error: ${response.status}`);
    }

    const data = await response.json();

    if (!Array.isArray(data) || data.length === 0) {
      throw new Error("Invalid response format: data is not a non-empty array");
    }

    // Find the object with the matching feed_id
    const calldataObj = data.find((item) => item.feed_id === feedIds[0]);
    if (!calldataObj) {
      throw new Error(`Feed ID ${feedIds[0]} not found in response`);
    }
    if (
      !calldataObj.encoded_calldata ||
      typeof calldataObj.encoded_calldata !== "string"
    ) {
      throw new Error(
        "Invalid response format: encoded_calldata missing or invalid",
      );
    }
    return `0x${calldataObj.encoded_calldata}`;
  } catch (error) {
    console.error("Error fetching data from Theoros:", error);
    throw error;
  }
}

async function main() {
  const options = parseCommandLineArguments();

  const chain = options.chain;
  const feedId = options.feedId;
  const theorosUrl = options.theorosUrl;

  const pragmaAddress = getDeployedAddress(
    snakeToCamel(chain),
    "pragma",
    "Pragma",
  );

  const privateKey = process.env.ETH_PRIVATE_KEY;
  if (!privateKey) {
    throw new Error("Missing ETH_PRIVATE_KEY env var");
  }

  console.log(
    `Updating feed ${feedId} for contract ${pragmaAddress} on chain ${chain}`,
  );
  console.log(`Using Theoros endpoint: ${theorosUrl}`);

  // 2. Get calldata from Theoros
  let calldata: string;
  try {
    calldata = await getCalldataFromTheoros(theorosUrl, chain, [feedId]);
    console.log("Calldata retrieved from Theoros:", calldata);
  } catch (error) {
    console.error("Failed to retrieve calldata from Theoros:", error);
    process.exit(1);
  }

  // 3. Call updateDataFeeds with the calldata
  let abi;
  try {
    abi = await import(PRAGMA_SOL_ABI_PATH);
  } catch (error) {
    console.error("Failed to import ABI:", error);
    throw new Error("ABI file not found or invalid");
  }
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const wallet = new ethers.Wallet(privateKey, provider);
  const contract = new ethers.Contract(pragmaAddress, abi.abi, wallet);

  try {
    const tx = await contract.updateDataFeeds([calldata]);
    console.log("Transaction sent. Transaction hash:", tx.hash);

    // 4. Assertions - check that everything is correctly updated on the destination chain
    const receipt = await tx.wait();
    console.log("Transaction confirmed in block:", receipt.blockNumber);
    console.log("Gas used:", receipt.gasUsed.toString());
  } catch (error) {
    console.error("Error updating feed:", error);
    process.exit(1);
  }
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exit(1);
});
