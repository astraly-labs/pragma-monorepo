import dotenv from "dotenv";
import fs from "fs";

import type { ContractFactoryParams, RawArgs } from "starknet";
import {
  Account,
  json,
  RpcProvider,
  CallData,
  Contract,
  ContractFactory,
} from "starknet";

dotenv.config();
const ACCOUNT_ADDRESS = process.env.STARKNET_ACCOUNT_ADDRESS;
const PRIVATE_KEY = process.env.STARKNET_PRIVATE_KEY;
const CAIRO_BUILD_FOLDER = "../cairo/target/dev";

/// Creates a Starknet account from the .env variables provided.
export async function buildAccount(): Promise<Account> {
  const provider = new RpcProvider({ nodeUrl: process.env.STARKNET_RPC_URL });

  if (!PRIVATE_KEY || !ACCOUNT_ADDRESS) {
    throw new Error("Private key or account address not set in .env file");
  }
  return new Account(provider, ACCOUNT_ADDRESS, PRIVATE_KEY);
}

/// Reads from a pre-compiled contract file.
function getCompiledContract(name: string): any {
  const prefix = name.includes("FeedsRegistry")
    ? "pragma_feeds_registry_"
    : "pragma_dispatcher_";
  const contractPath = `${CAIRO_BUILD_FOLDER}/${prefix}${name}.contract_class.json`;
  return json.parse(fs.readFileSync(contractPath).toString("ascii"));
}

/// Reads from a pre-compiled casm file.
function getCompiledContractCasm(name: string): any {
  const prefix = name.includes("FeedsRegistry")
    ? "pragma_feeds_registry_"
    : "pragma_dispatcher_";
  const contractPath = `${CAIRO_BUILD_FOLDER}/${prefix}${name}.compiled_contract_class.json`;
  return JSON.parse(fs.readFileSync(contractPath, "utf-8"));
}

/// Deploys a contract using the account provided.
export async function deployContract(
  deployer: Account,
  contractName: string,
  calldata: RawArgs,
): Promise<Contract> {
  console.log(`Deploying contract ${contractName}...`);

  const compiledContract = getCompiledContract(contractName);
  const casm = getCompiledContractCasm(contractName);
  const constructorCalldata = CallData.compile(calldata);
  const params: ContractFactoryParams = {
    compiledContract,
    account: deployer,
    casm,
  };

  const contractFactory = new ContractFactory(params);
  const contract = await contractFactory.deploy(constructorCalldata);

  console.log(
    `Contract ${contractName} deployed at address:`,
    contract.address,
  );

  return contract;
}
