import dotenv from "dotenv";
import fs from "fs";

import { Account, Contract, json, RpcProvider } from "starknet";
import { STARKNET_CHAINS, type Chain } from "../types/chains";

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

/// Creates a Starknet account from the .env variables provided.
export async function buildStarknetAccount(chain: Chain): Promise<Account> {
  const nodeUrl = getStarknetRpcUrl(chain);
  const provider = new RpcProvider({ nodeUrl });

  if (!PRIVATE_KEY || !ACCOUNT_ADDRESS) {
    throw new Error("Private key or account address not set in .env file");
  }
  return new Account(provider, ACCOUNT_ADDRESS, PRIVATE_KEY);
}

function getProjectBuildFolder(project: projectName): string {
  if (project === "oracle") {
    return "../../cairo/oracle/target/dev";
  } else {
    return "../../cairo/dispatcher/target/dev";
  }
}

/// Reads from a pre-compiled contract file.
export function getCompiledContract(
  project: projectName,
  contractName: string,
): any {
  const fullContractPath = `${getProjectBuildFolder(project)}/${contractName}.contract_class.json`;
  return json.parse(fs.readFileSync(fullContractPath).toString("ascii"));
}

/// Reads from a pre-compiled casm file.
export function getCompiledContractCasm(
  project: projectName,
  contractName: string,
): any {
  const fullContractPath = `${getProjectBuildFolder(project)}/${contractName}.compiled_contract_class.json`;
  return JSON.parse(fs.readFileSync(fullContractPath, "utf-8"));
}

export function getContract(
  project: projectName,
  contractName: string,
  address: string,
  account: Account,
): Contract {
  const compiledContract = getCompiledContract(project, contractName);
  return new Contract(compiledContract.abi, address, account);
}
