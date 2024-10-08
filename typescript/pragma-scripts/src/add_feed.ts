import fs from "fs";
import { Command, type OptionValues } from "commander";
import { ethers } from "ethers";
import { buildStarknetAccount } from "./utils";
import { STARKNET_CHAINS } from "./types/chains";
import { getContract } from "./utils/starknet";
import type { Account, Contract } from "starknet";

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
    .name("add-feeds")
    .description("CLI to update multiple Pragma data feeds")
    .requiredOption(
      "--feed-ids <feed_ids...>",
      "IDs of the data feeds to update",
    )
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

async function addFeed(
  pragmaDispatcher: Contract,
  account: Account,
  feedId: string,
) {
  try {
    console.log(`Adding feed ${feedId}`);
    const invoke = await pragmaDispatcher.invoke("add_feed", [feedId]);
    await account.waitForTransaction(invoke.transaction_hash);

    const receipt = await account.getTransactionReceipt(
      invoke.transaction_hash,
    );
    if (receipt.isError() || receipt.isRejected() || receipt.isReverted()) {
      console.error(`Error adding feed ${feedId}:`, receipt.value);
    }
    console.log(`Successfully added feed ${feedId}`);
  } catch (error) {
    console.error(`Error adding feed ${feedId}:`, error);
  }
}

async function main() {
  const options = parseCommandLineArguments();

  const publisherRegistryAddress = getDeployedAddress(options.chain);
  const feedIds = options.feedIds;
  const account = await buildStarknetAccount(options.chain);
  console.log(
    `Adding feeds for contract ${publisherRegistryAddress} on chain ${options.chain}`,
  );

  const pragmaDispatcher = getContract(
    "dispatcher",
    "pragma_feeds_registry_PragmaFeedsRegistry",
    publisherRegistryAddress,
    account,
  );

  for (const feedId of feedIds) {
    await addFeed(pragmaDispatcher, account, feedId);
  }
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exit(1);
});
