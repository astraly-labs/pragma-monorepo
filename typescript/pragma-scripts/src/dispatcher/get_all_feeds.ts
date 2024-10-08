import fs from "fs";
import { Command, type OptionValues } from "commander";
import { shortString, type Contract } from "starknet";
import {
  buildAccount,
  decodeFeeds,
  Deployer,
  feedWithIdToString,
  STARKNET_CHAINS,
  type Feed,
  type FeedWithId,
} from "pragma-utils";

function getDeployedAddress(chainName: string): string {
  try {
    const filePath = `../../deployments/${chainName}/dispatcher.json`;
    const fileContents = fs.readFileSync(filePath, "utf8");
    const config = JSON.parse(fileContents);
    if (!config.FeedsRegistry) {
      throw new Error(
        `Invalid or missing Pragma Dispatcher contract address for chain ${chainName}`,
      );
    }
    return config.FeedsRegistry;
  } catch (error) {
    console.error(
      `Error reading configuration file for chain ${chainName}:`,
      error,
    );
    throw error;
  }
}

function parseCommandLineArguments(): OptionValues {
  const program = new Command();
  program
    .name("get-all-feeds")
    .description("CLI to get all Pragma data feeds")
    .requiredOption(
      "--chain <chain_name>",
      "Name of the target chain (e.g., pragmaDevnet)",
    )
    .parse(process.argv);

  const options = program.opts();
  if (!STARKNET_CHAINS.includes(options.chain)) {
    console.error(
      `Error: Invalid starknet chain, must be in ${STARKNET_CHAINS.toString()}.`,
    );
    process.exit(1);
  }
  return options;
}

async function getAllFeeds(pragmaDispatcher: Contract): Promise<FeedWithId[]> {
  try {
    console.log("⏳ Getting all feeds...");
    const rawFeeds = await pragmaDispatcher.call("get_all_feeds");
    const feeds = decodeFeeds(rawFeeds as bigint[]);
    console.log("\n📜 All feeds:");
    feeds.forEach((feed) => {
      console.log(feedWithIdToString(feed));
    });
    return feeds;
  } catch (error) {
    console.error("Error getting all feeds:", error);
    throw error;
  }
}

shortString.decodeShortString;

async function main() {
  const options = parseCommandLineArguments();

  const publisherRegistryAddress = getDeployedAddress(options.chain);
  const account = await buildAccount(options.chain);
  console.log(
    `👉 Getting all feeds for contract ${publisherRegistryAddress} on chain ${options.chain}`,
  );

  const pragmaDispatcher = await account.loadContract(publisherRegistryAddress);
  await getAllFeeds(pragmaDispatcher);
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exit(1);
});
