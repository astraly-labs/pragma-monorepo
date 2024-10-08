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
    .name("add-source-for-publisher")
    .description("CLI to add a source for a publisher in PublisherRegistry")
    .requiredOption(
      "--publisher <name>",
      "Name of the publisher to add the source for",
    )
    .requiredOption("--source <name>", "Name of the source to add")
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

async function addSourceForPublisher(
  publisherRegistry: Contract,
  account: Deployer,
  publisherName: string,
  sourceName: string,
) {
  try {
    console.log(
      `⏳ Adding source ${sourceName} for publisher ${publisherName}...`,
    );
    const publisherNameFelt = shortString.encodeShortString(publisherName);
    const sourceNameFelt = shortString.encodeShortString(sourceName);
    const invoke = await publisherRegistry.invoke("add_source_for_publisher", [
      publisherNameFelt,
      sourceNameFelt,
    ]);
    await account.waitForTransaction(invoke.transaction_hash);

    const receipt = await account.getTransactionReceipt(
      invoke.transaction_hash,
    );
    await ensureSuccess(receipt, account.provider);
    console.log(
      `🧩 Successfully added source ${sourceName} for publisher ${publisherName}`,
    );

    // Check for any relevant event (if applicable)
    if ("events" in receipt) {
      // Adjust the event name if there's a specific event for adding a source
      const event = receipt.events?.find(
        (e) => e.keys[0] === num.toHex(hash.starknetKeccak("SourceAdded")),
      );
      if (event) {
        console.log("Event emitted:", event);
      }
    }
  } catch (error) {
    console.error(
      `⛔ Error adding source ${sourceName} for publisher ${publisherName}:`,
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
    `👉 Adding source for publisher in contract ${publisherRegistryAddress} on chain ${options.chain}`,
  );

  const publisherRegistry = await account.loadContract(
    publisherRegistryAddress,
  );

  await addSourceForPublisher(
    publisherRegistry,
    account,
    options.publisher,
    options.source,
  );

  console.log("✅ Source addition process completed!");
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exit(1);
});
