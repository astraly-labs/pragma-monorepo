import fs from "fs";
import { Command, type OptionValues } from "commander";
import type { Account, Contract } from "starknet";
import {
  buildAccount,
  Deployer,
  ensureSuccess,
  STARKNET_CHAINS,
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
    .name("remove-feeds")
    .description("CLI to remove multiple Pragma data feeds")
    .requiredOption(
      "--feed-ids <feed_ids...>",
      "IDs of the data feeds to remove",
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

async function removeFeed(
  pragmaDispatcher: Contract,
  account: Deployer,
  feedId: string,
) {
  try {
    console.log(`Removing feed ${feedId}`);
    const invoke = await pragmaDispatcher.invoke("remove_feed", [feedId]);
    await account.waitForTransaction(invoke.transaction_hash);

    const receipt = await account.getTransactionReceipt(
      invoke.transaction_hash,
    );
    await ensureSuccess(receipt, account.provider);
    console.log(`Successfully removed feed ${feedId}`);
  } catch (error) {
    console.error(`Error removing feed ${feedId}:`, error);
  }
}

async function main() {
  const options = parseCommandLineArguments();

  const publisherRegistryAddress = getDeployedAddress(options.chain);
  const feedIds = options.feedIds;
  const account = await buildAccount(options.chain);
  console.log(
    `👉 Removing feeds for contract ${publisherRegistryAddress} on chain ${options.chain}`,
  );

  const pragmaDispatcher = await account.loadContract(publisherRegistryAddress);
  for (const feedId of feedIds) {
    await removeFeed(pragmaDispatcher, account, feedId);
  }
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exit(1);
});