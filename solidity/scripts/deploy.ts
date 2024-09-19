import { ethers } from "hardhat";
import { hyperlaneConfig, pragmaConfig } from "./config";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Hyperlane contract
  const Hyperlane = await ethers.getContractFactory("Hyperlane");
  const hyperlane = await Hyperlane.deploy(hyperlaneConfig.validators);
  await hyperlane.deployed();
  console.log("Hyperlane deployed to:", hyperlane.address);

  // Deploy Pragma contract
  const Pragma = await ethers.getContractFactory("Pragma");
  const pragma = await Pragma.deploy(
    hyperlane.address,
    pragmaConfig.dataSourceEmitterChainIds,
    pragmaConfig.dataSourceEmitterAddresses,
    pragmaConfig.validTimePeriodSeconds,
    pragmaConfig.singleUpdateFeeInWei
  );
  await pragma.deployed();
  console.log("Pragma deployed to:", pragma.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });