import { Command, type OptionValues } from "commander";
import type { Contract } from "starknet";
import {
  buildAccount,
  decodePair,
  Deployer,
  ensureSuccess,
  getDeployedAddress,
  STARKNET_CHAINS,
  type Pair,
} from "pragma-utils";
import { shortString } from "starknet";

function parseCommandLineArguments(): OptionValues {
  const program = new Command();
  program
    .name("add-pairs")
    .description("CLI to add multiple pairs to PragmaOracle")
    .requiredOption("--pair-ids <pair_ids...>", "IDs of the pairs to add")
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

async function addPair(
  pragmaOracle: Contract,
  account: Deployer,
  pairId: bigint,
) {
  try {
    const pair: Pair = decodePair(pairId);
    console.log(
      `\t ⏳ Adding pair ${shortString.decodeShortString(pair.id)}...`,
    );
    const invoke = await pragmaOracle.invoke("add_pair", [pair]);
    await account.waitForTransaction(invoke.transaction_hash);

    const receipt = await account.getTransactionReceipt(
      invoke.transaction_hash,
    );
    await ensureSuccess(receipt, account.provider);
    console.log(
      `\t 🧩 Successfully added pair ${shortString.decodeShortString(pair.id)}`,
    );
  } catch (error) {
    console.error(
      `\t⛔ Error adding pair ${shortString.decodeShortString(pairId.toString())}:`,
      error,
    );
  }
}

async function main() {
  const options = parseCommandLineArguments();

  const pragmaOracleAddress = getDeployedAddress(
    options.chain,
    "oracle",
    "PragmaOracle",
  );
  const pairIds = options.pair_ids.map((id: any) => BigInt(id));
  const account = await buildAccount(options.chain);
  console.log(
    `👉 Adding pairs for contract ${pragmaOracleAddress} on chain ${options.chain}`,
  );

  const pragmaOracle = await account.loadContract(pragmaOracleAddress);
  for (const pairId of pairIds) {
    await addPair(pragmaOracle, account, pairId);
  }
  console.log("✅ All pairs added!");
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exit(1);
});
