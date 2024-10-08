import { Account, RpcProvider } from "starknet";
import { Deployer, type StarknetChain } from "..";
import { STARKNET_RPC_URLS } from "./rpcs";

export async function buildAccount(chain: StarknetChain): Promise<Deployer> {
  const nodeUrl = STARKNET_RPC_URLS[chain];
  console.log("");
  console.log("⛓️‍💥 Chain:", chain);
  console.log("➰ Provider url:", nodeUrl);

  const provider = new RpcProvider({ nodeUrl });
  const deployer = loadAccount(provider);
  console.log("👤 Account:", deployer.address);
  console.log("");

  return new Deployer(provider, deployer);
}

function loadAccount(provider: RpcProvider): Account {
  if (
    !process.env.STARKNET_ACCOUNT_ADDRESS ||
    !process.env.STARKNET_PRIVATE_KEY
  ) {
    throw new Error(
      "Missing STARKNET_ACCOUNT_ADDRESS or STARKNET_PRIVATE_KEY env var",
    );
  }
  const deployer = new Account(
    provider,
    process.env.STARKNET_ACCOUNT_ADDRESS,
    process.env.STARKNET_PRIVATE_KEY,
  );
  return deployer;
}
