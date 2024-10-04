import dotenv from "dotenv";
import fs from "fs";
import path from "path";

import { ethers } from "hardhat";
import { parseEther, zeroPadValue } from "ethers";

import { type Deployer } from "./interface";
import type { DeploymentConfig } from "../config";
import { EVM_CHAINS, type Chain } from "../chains";

const HYPERLANE_CONTRACT_NAME: string = "Hyperlane";
const PRAGMA_CONTRACT_NAME: string = "Pragma";

dotenv.config();
const NETWORK = process.env.NETWORK;

export class PragmaDeployer implements Deployer {
  readonly allowedChains: Chain[] = EVM_CHAINS;
  readonly defaultChain: Chain = "mainnet";

  async deploy(config: DeploymentConfig, chain?: Chain): Promise<void> {
    if (!chain) chain = this.defaultChain;
    if (!this.allowedChains.includes(chain)) {
      throw new Error(`⛔ Deployment to ${chain} is not supported.`);
    }

    if (NETWORK === undefined) {
      throw new Error("⛔ NETWORK in .env must be defined");
    }

    console.log(`🧩 Deploying Pragma.sol to ${chain}:${NETWORK}...`);

    const [deployer] = await ethers.getSigners();

    console.log("Deployer account:", deployer.address);

    // Deploy Hyperlane contract
    const Hyperlane = await ethers.getContractFactory(HYPERLANE_CONTRACT_NAME);
    const hyperlane = await Hyperlane.deploy(
      config.pragma.hyperlane.validators,
    );
    await hyperlane.deployed();
    console.log("✅ Hyperlane deployed to:", hyperlane.address);

    // Prepare Pragma contract arguments
    const pragmaConfig = {
      dataSourceEmitterChainIds: config.pragma.data_source_emitters.map(
        (emitter) => emitter.chain_id,
      ),
      dataSourceEmitterAddresses: config.pragma.data_source_emitters.map(
        (emitter) => zeroPadValue(emitter.address, 32),
      ),
      validTimePeriodSeconds: config.pragma.valid_time_period_in_seconds,
      singleUpdateFeeInWei: parseEther(config.pragma.single_update_fee_in_wei),
    };

    // Deploy Pragma contract
    const Pragma = await ethers.getContractFactory(PRAGMA_CONTRACT_NAME);
    const pragma = await Pragma.deploy(
      hyperlane.address,
      pragmaConfig.dataSourceEmitterChainIds,
      pragmaConfig.dataSourceEmitterAddresses,
      pragmaConfig.validTimePeriodSeconds,
      pragmaConfig.singleUpdateFeeInWei,
    );
    await pragma.deployed();
    console.log(`✅ Pragma.sol deployed at ${pragma.address}`);

    // Save deployment info
    const deploymentInfo = {
      Hyperlane: hyperlane.address,
      Pragma: pragma.address,
    };

    const jsonContent = JSON.stringify(deploymentInfo, null, 2);
    const filePath = path.join("deployments", NETWORK, "pragma.json");
    fs.writeFileSync(filePath, jsonContent);
    console.log(`Deployment info saved to ${filePath}`);
  }
}
