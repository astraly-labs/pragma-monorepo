import { Command, type OptionValues } from "commander";
import type { Contract } from "starknet";
import {
  buildAccount,
  Deployer,
  ensureSuccess,
  getDeployedAddress,
  STARKNET_CHAINS,
  type Currency,
} from "pragma-utils";
import { shortString, num } from "starknet";

function parseCommandLineArguments(): OptionValues {
  const program = new Command();
  program
    .name("add-currency")
    .description("CLI to add a single currency to PragmaOracle")
    .requiredOption("--id <id>", "ID of the currency to add")
    .requiredOption(
      "--decimals <decimals>",
      "Number of decimals for the currency",
    )
    .option("--is_abstract", "Flag to indicate if the currency is abstract")
    .requiredOption(
      "--starknet_address <address>",
      "Starknet address of the currency",
    )
    .requiredOption(
      "--ethereum_address <address>",
      "Ethereum address of the currency",
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

async function addCurrency(
  pragmaOracle: Contract,
  account: Deployer,
  currency: Currency,
) {
  try {
    console.log(
      `⏳ Adding currency ${shortString.decodeShortString(currency.id)}...`,
    );
    const invoke = await pragmaOracle.invoke("add_currency", [currency]);
    await account.waitForTransaction(invoke.transaction_hash);

    const receipt = await account.getTransactionReceipt(
      invoke.transaction_hash,
    );
    await ensureSuccess(receipt, account.provider);
    console.log(
      `🧩 Successfully added currency ${shortString.decodeShortString(currency.id)}`,
    );
  } catch (error) {
    console.error(
      `⛔ Error adding currency ${shortString.decodeShortString(currency.id)}:`,
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

  const currency: Currency = {
    id: num.toHex(BigInt(options.id)),
    decimals: parseInt(options.decimals),
    is_abstract_currency: options.is_abstract ? true : false,
    starknet_address: options.starknet_address,
    ethereum_address: options.ethereum_address,
  };

  const account = await buildAccount(options.chain);
  console.log(
    `👉 Adding currency to contract ${pragmaOracleAddress} on chain ${options.chain}`,
  );

  const pragmaOracle = await account.loadContract(pragmaOracleAddress);
  await addCurrency(pragmaOracle, account, currency);

  console.log("✅ Currency addition process completed!");
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exit(1);
});
