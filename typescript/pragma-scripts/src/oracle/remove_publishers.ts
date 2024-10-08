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
    .name("remove-publishers")
    .description("CLI to remove multiple publishers from PublisherRegistry")
    .requiredOption(
      "--publishers <names...>",
      "Names of the publishers to remove",
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

async function removePublisher(
  publisherRegistry: Contract,
  account: Deployer,
  publisherName: string,
) {
  try {
    console.log(`⏳ Removing publisher ${publisherName}...`);
    const publisherNameFelt = shortString.encodeShortString(publisherName);
    const invoke = await publisherRegistry.invoke("remove_publisher", [
      publisherNameFelt,
    ]);
    await account.waitForTransaction(invoke.transaction_hash);

    const receipt = await account.getTransactionReceipt(
      invoke.transaction_hash,
    );
    await ensureSuccess(receipt, account.provider);
    console.log(`🧩 Successfully removed publisher ${publisherName}`);

    // Check for the RemovedPublisher event
    if ("events" in receipt) {
      const event = receipt.events?.find(
        (e) => e.keys[0] === num.toHex(hash.starknetKeccak("RemovedPublisher")),
      );
      if (event) {
        console.log("Event emitted:", event);
      }
    }
  } catch (error) {
    console.error(`⛔ Error removing publisher ${publisherName}:`, error);
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
    `👉 Removing publishers from contract ${publisherRegistryAddress} on chain ${options.chain}`,
  );

  const publisherRegistry = await account.loadContract(
    publisherRegistryAddress,
  );

  for (const publisherName of options.publishers) {
    await removePublisher(publisherRegistry, account, publisherName);
  }

  console.log("✅ Publisher removal process completed!");
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exit(1);
});
