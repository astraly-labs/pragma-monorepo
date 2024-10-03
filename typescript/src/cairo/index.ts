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

import { STARKNET_CHAINS, type Chain } from "../deployers/interface";

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
  } else if (chain === "starknet_devnet") {
    return "http://127.0.0.1:9615";
  } else {
    // sepolia
    return "https://free-rpc.nethermind.io/sepolia-juno";
  }
}

function getProjectBuildFolder(project: projectName): string {
  if (project === "oracle") {
    return "../cairo/oracle/target/dev";
  } else {
    return "../cairo/dispatcher/target/dev";
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
): Promise<Contract> {
  console.log(`Deploying contract ${contractName}...`);

  const compiledContract = getCompiledContract(projectName, contractName);
  const casm = getCompiledContractCasm(projectName, contractName);
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
