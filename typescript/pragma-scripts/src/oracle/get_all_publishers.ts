import { Command, type OptionValues } from "commander";
import type { Contract } from "starknet";
import {
  buildAccount,
  Deployer,
  getDeployedAddress,
  STARKNET_CHAINS,
} from "pragma-utils";
import { shortString, num } from "starknet";

function parseCommandLineArguments(): OptionValues {
  const program = new Command();
  program
    .name("get-all-publishers-and-sources")
    .description(
      "CLI to get all publishers and their sources from PublisherRegistry",
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

async function getAllPublishersAndSources(publisherRegistry: Contract) {
  try {
    console.log("⏳ Fetching all publishers...");
    const publishersFelt = (await publisherRegistry.call(
      "get_all_publishers",
    )) as string[];
    const publishers = publishersFelt.map((felt: string) =>
      shortString.decodeShortString(felt),
    );

    console.log("👥 Registered Publishers:");
    for (const publisher of publishers) {
      console.log(`  - ${publisher}`);

      console.log("    📚 Sources:");
      const sourcesFelt = (await publisherRegistry.call(
        "get_publisher_sources",
        [shortString.encodeShortString(publisher)],
      )) as string[];
      const sources = sourcesFelt.map((felt: string) =>
        shortString.decodeShortString(felt),
      );

      if (sources.length === 0) {
        console.log("      No sources registered for this publisher.");
      } else {
        for (const source of sources) {
          console.log(`      - ${source}`);
        }
      }
      console.log(); // Empty line for readability
    }
  } catch (error) {
    console.error("⛔ Error fetching publishers and sources:", error);
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
    `👉 Fetching publishers and sources from contract ${publisherRegistryAddress} on chain ${options.chain}`,
  );

  const publisherRegistry = await account.loadContract(
    publisherRegistryAddress,
  );

  await getAllPublishersAndSources(publisherRegistry);

  console.log("✅ Fetching process completed!");
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exit(1);
});
