import { Account, RpcProvider } from "starknet";
import { Deployer, logAddresses, type StarknetChain } from "..";
import { STARKNET_RPC_URLS } from "./rpcs";

export async function buildDeployer(chain: StarknetChain): Promise<Deployer> {
  const nodeUrl = STARKNET_RPC_URLS[chain];
  console.log("");
  console.log("⛓️‍💥 Chain:", chain);
  console.log("➰ Provider url:", nodeUrl);

  const provider = new RpcProvider({ nodeUrl });
  const deployer = loadAccount(provider);
  logAddresses("Accounts:", { deployer: deployer });
  return new Deployer(provider, deployer);
}

function loadAccount(provider: RpcProvider): Account {
  if (!process.env.ADDRESS || !process.env.PRIVATE_KEY) {
    throw new Error("Missing ADDRESS or ACCOUNT_PRIVATE_KEY env var");
  }
  const deployer = new Account(
    provider,
    process.env.ADDRESS,
    process.env.PRIVATE_KEY,
  );
  return deployer;
}
