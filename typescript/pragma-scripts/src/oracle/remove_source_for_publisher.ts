import { Command, type OptionValues } from "commander";
import type { Contract } from "starknet";
import {
  buildAccount,
  Deployer,
  ensureSuccess,
  getDeployedAddress,
  STARKNET_CHAINS,
} from "pragma-utils";
import { shortString, num, hash } from "starknet";

function parseCommandLineArguments(): OptionValues {
  const program = new Command();
  program
    .name("remove-source-for-publisher")
    .description("CLI to remove a source for a publisher in PublisherRegistry")
    .requiredOption(
      "--publisher <name>",
      "Name of the publisher to remove the source from",
    )
    .requiredOption("--source <name>", "Name of the source to remove")
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

async function removeSourceForPublisher(
  publisherRegistry: Contract,
  account: Deployer,
  publisherName: string,
  sourceName: string,
) {
  try {
    console.log(
      `⏳ Removing source ${sourceName} for publisher ${publisherName}...`,
    );
    const publisherNameFelt = shortString.encodeShortString(publisherName);
    const sourceNameFelt = shortString.encodeShortString(sourceName);
    const invoke = await publisherRegistry.invoke(
      "remove_source_for_publisher",
      [publisherNameFelt, sourceNameFelt],
    );
    await account.waitForTransaction(invoke.transaction_hash);

    const receipt = await account.getTransactionReceipt(
      invoke.transaction_hash,
    );
    await ensureSuccess(receipt, account.provider);
    console.log(
      `🧩 Successfully removed source ${sourceName} for publisher ${publisherName}`,
    );

    // Check for the DeletedSource event
    if ("events" in receipt) {
      const event = receipt.events?.find(
        (e) => e.keys[0] === num.toHex(hash.starknetKeccak("DeletedSource")),
      );
      if (event) {
        console.log("Event emitted:", event);
      }
    }
  } catch (error) {
    console.error(
      `⛔ Error removing source ${sourceName} for publisher ${publisherName}:`,
      error,
    );
  }
}

async function main() {
  const options = parseCommandLineArguments();

  const publisherRegistryAddress = getDeployedAddress(
    options.chain,
    "oracle",
    "PublisherRegistry",
  );

  const account = await buildAccount(options.chain);
  console.log(
    `👉 Removing source for publisher in contract ${publisherRegistryAddress} on chain ${options.chain}`,
  );

  const publisherRegistry = await account.loadContract(
    publisherRegistryAddress,
  );

  await removeSourceForPublisher(
    publisherRegistry,
    account,
    options.publisher,
    options.source,
  );

  console.log("✅ Source removal process completed!");
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exit(1);
});
