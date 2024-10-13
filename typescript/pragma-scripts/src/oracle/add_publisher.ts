import { Command, type OptionValues } from "commander";
import type { Contract } from "starknet";
import {
  buildAccount,
  Deployer,
  ensureSuccess,
  getDeployedAddress,
  STARKNET_CHAINS,
} from "pragma-utils";
import { num, hash } from "starknet";

function parseCommandLineArguments(): OptionValues {
  const program = new Command();
  program
    .name("add-publisher")
    .description("CLI to add a single publisher to PublisherRegistry")
    .requiredOption("--publisher <name>", "Name of the publisher to add")
    .requiredOption("--address <address>", "Address of the publisher")
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

async function addPublisher(
  publisherRegistry: Contract,
  account: Deployer,
  publisherName: string,
  publisherAddress: string,
) {
  try {
    console.log(`⏳ Adding publisher ${publisherName}...`);
    const publisherNameFelt = num.toHex(hash.starknetKeccak(publisherName));
    const invoke = await publisherRegistry.invoke("add_publisher", [
      publisherNameFelt,
      publisherAddress,
    ]);
    await account.waitForTransaction(invoke.transaction_hash);

    const receipt = await account.getTransactionReceipt(
      invoke.transaction_hash,
    );
    await ensureSuccess(receipt, account.provider);
    console.log(`🧩 Successfully added publisher ${publisherName}`);

    // Check for the RegisteredPublisher event
    if ("events" in receipt) {
      const event = receipt.events?.find(
        (e) =>
          e.keys[0] === num.toHex(hash.starknetKeccak("RegisteredPublisher")),
      );
      if (event) {
        console.log("Event emitted:", event);
      }
    }
  } catch (error) {
    console.error(`⛔ Error adding publisher ${publisherName}:`, error);
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
    `👉 Adding publisher to contract ${publisherRegistryAddress} on chain ${options.chain}`,
  );

  const publisherRegistry = await account.loadContract(
    publisherRegistryAddress,
  );
  await addPublisher(
    publisherRegistry,
    account,
    options.publisher,
    options.address,
  );

  console.log("✅ Publisher addition process completed!");
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exit(1);
});
