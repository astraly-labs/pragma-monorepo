import { Command, type OptionValues } from "commander";
import { type Contract } from "starknet";
import {
  buildAccount,
  decodeFeeds,
  feedWithIdToString,
  getDeployedAddress,
  STARKNET_CHAINS,
  type FeedWithId,
} from "pragma-utils";

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

async function main() {
  const options = parseCommandLineArguments();

  const publisherRegistryAddress = getDeployedAddress(
    options.chain,
    "dispatcher",
    "FeedsRegistry",
  );
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
