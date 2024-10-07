import dotenv from "dotenv";
import fs from "fs";

import type { ContractFactoryParams, ContractOptions, RawArgs } from "starknet";
import {
  Account,
  json,
  RpcProvider,
  CallData,
  Contract,
  ContractFactory,
  hash,
} from "starknet";
import { STARKNET_CHAINS, type Chain } from "../chains";
import { CONSTANT_SALT } from "../constants";

dotenv.config();
const ACCOUNT_ADDRESS = process.env.STARKNET_ACCOUNT_ADDRESS;
const PRIVATE_KEY = process.env.STARKNET_PRIVATE_KEY;

type projectName = "oracle" | "dispatcher";

/// Get an RPC for a starknet chain.
export function getStarknetRpcUrl(chain: Chain): string {
  if (!STARKNET_CHAINS.includes(chain)) {
    throw new Error("Must be a starknet chain.");
  }
  if (chain === "starknet") {
    return "https://free-rpc.nethermind.io/mainnet-juno";
  } else if (chain === "pragmaDevnet") {
    return "https://madara-pragma-prod.karnot.xyz/";
  } else {
    return "https://free-rpc.nethermind.io/sepolia-juno"; // sepolia
  }
}

function getProjectBuildFolder(project: projectName): string {
  if (project === "oracle") {
    return "../../cairo/oracle/target/dev";
  } else {
    return "../../cairo/dispatcher/target/dev";
  }
}

/// Creates a Starknet account from the .env variables provided.
export async function buildStarknetAccount(chain: Chain): Promise<Account> {
  const nodeUrl = getStarknetRpcUrl(chain);
  const provider = new RpcProvider({ nodeUrl });

  if (!PRIVATE_KEY || !ACCOUNT_ADDRESS) {
    throw new Error("Private key or account address not set in .env file");
  }
  return new Account(provider, ACCOUNT_ADDRESS, PRIVATE_KEY);
}

/// Reads from a pre-compiled contract file.
function getCompiledContract(project: projectName, contractName: string): any {
  const fullContractPath = `${getProjectBuildFolder(project)}/${contractName}.contract_class.json`;
  return json.parse(fs.readFileSync(fullContractPath).toString("ascii"));
}

/// Reads from a pre-compiled casm file.
function getCompiledContractCasm(
  project: projectName,
  contractName: string,
): any {
  const fullContractPath = `${getProjectBuildFolder(project)}/${contractName}.compiled_contract_class.json`;
  return JSON.parse(fs.readFileSync(fullContractPath, "utf-8"));
}

/// Deploys a contract using the account provided.
export async function deployStarknetContract(
  deployer: Account,
  projectName: projectName,
  contractName: string,
  calldata: RawArgs,
  deterministic: boolean,
): Promise<Contract> {
  console.log(`Deploying contract ${contractName}...`);

  const compiledContract = getCompiledContract(projectName, contractName);
  const casm = getCompiledContractCasm(projectName, contractName);
  const constructorCalldata = CallData.compile(calldata);
  const params: ContractFactoryParams = {
    account: deployer,
    compiledContract,
    casm,
  };
  const contractFactory = new ContractFactory(params);

  const deployOptions: ContractOptions = {};
  if (deterministic) {
    deployOptions.addressSalt = CONSTANT_SALT;
  }
  // TODO: Update this whole logic so we handle correctly errors when contract is already deployed.
  const contract = await contractFactory.deploy(
    constructorCalldata,
    deployOptions,
  );

  return contract;
}
