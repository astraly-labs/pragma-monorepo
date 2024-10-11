import { Command, type OptionValues } from "commander";
import type { Contract } from "starknet";
import {
  buildAccount,
  Deployer,
  ensureSuccess,
  getDeployedAddress,
  STARKNET_CHAINS,
} from "pragma-utils";

function parseCommandLineArguments(): OptionValues {
  const program = new Command();
  program
    .name("dispatch-feeds")
    .description("CLI to dispatch multiple Pragma data feeds")
    .requiredOption(
      "--feed-ids <feed_ids...>",
      "IDs of the data feeds to dispatch",
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

async function dispatchFeeds(
  pragmaDispatcher: Contract,
  account: Deployer,
  feedIds: string[],
) {
  try {
    console.log(`⏳ Dispatching feeds: ${feedIds.join(", ")}...`);
    const invoke = await pragmaDispatcher.invoke("dispatch", [feedIds]);
    await account.waitForTransaction(invoke.transaction_hash);

    const receipt = await account.getTransactionReceipt(
      invoke.transaction_hash,
    );
    await ensureSuccess(receipt, account.provider);
    console.log("\n🧩 Successfully called dispatch method!");
  } catch (error) {
    console.error(`Error calling dispatch method:`, error);
    throw error;
  }
}

async function main() {
  const options = parseCommandLineArguments();

  const pragmaDispatcherAddress = getDeployedAddress(
    options.chain,
    "dispatcher",
    "PragmaDispatcher",
  );
  const feedIds = options.feedIds;
  const account = await buildAccount(options.chain);
  console.log(
    `👉 Calling dispatch for feeds on contract ${pragmaDispatcherAddress} on chain ${options.chain}`,
  );

  const pragmaDispatcher = await account.loadContract(pragmaDispatcherAddress);
  await dispatchFeeds(pragmaDispatcher, account, feedIds);
  console.log("\n✅ Dispatch call completed!");
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exit(1);
});
