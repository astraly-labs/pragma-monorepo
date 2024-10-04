import fs from "fs";
import path from "path";
import hre, { ethers, network } from "hardhat";
import { parseEther, zeroPadBytes, zeroPadValue } from "ethers";

import { type Deployer } from "./interface";
import { EVM_CHAINS, type Chain } from "../chains";
import type { DeploymentConfig } from "../config";

export class PragmaDeployer implements Deployer {
  readonly allowedChains: Chain[] = EVM_CHAINS;
  readonly defaultChain: Chain = "mainnet";

  async deploy(config: DeploymentConfig, chain?: Chain): Promise<void> {
    if (!chain) chain = this.defaultChain;
    if (!this.allowedChains.includes(chain)) {
      throw new Error(`⛔ Deployment to ${chain} is not supported.`);
    }
    await hre.switchNetwork(chain);

    try {
      console.log(`🧩 Deploying Pragma.sol to ${chain}...`);

      const [deployer] = await ethers.getSigners();
      console.log("Deployer account:", deployer.address);

      // Load contract artifacts
      const hyperlaneArtifactPath = path.join(
        hre.config.paths.artifacts,
        "Hyperlane.sol/Hyperlane.json",
      );
      const pragmaArtifactPath = path.join(
        hre.config.paths.artifacts,
        "Pragma.sol/Pragma.json",
      );

      if (
        !fs.existsSync(hyperlaneArtifactPath) ||
        !fs.existsSync(pragmaArtifactPath)
      ) {
        throw new Error(
          "Contract artifacts not found. Ensure contracts are in the correct location and have been compiled.",
        );
      }

      const hyperlaneArtifact = JSON.parse(
        fs.readFileSync(hyperlaneArtifactPath, "utf8"),
      );
      const pragmaArtifact = JSON.parse(
        fs.readFileSync(pragmaArtifactPath, "utf8"),
      );

      // Deploy Hyperlane contract
      const Hyperlane = await ethers.getContractFactory(
        hyperlaneArtifact.abi,
        hyperlaneArtifact.bytecode,
      );
      console.log("Deploying Hyperlane...");
      const hyperlane = await Hyperlane.deploy(
        config.pragma.hyperlane.validators,
      );
      await hyperlane.waitForDeployment();
      const hyperlaneAddress = await hyperlane.getAddress();
      console.log("✅ Hyperlane deployed to:", hyperlaneAddress);

      // Deploy Pragma contract
      const Pragma = await ethers.getContractFactory(
        pragmaArtifact.abi,
        pragmaArtifact.bytecode,
      );
      console.log("Deploying Pragma...");
      const pragma = await Pragma.deploy();
      await pragma.waitForDeployment();
      const pragmaAddress = await pragma.getAddress();

      // Initialize Pragma contract
      console.log("Initializing Pragma contract...");
      const dataSourceEmitterChainIds = config.pragma.data_source_emitters.map(
        (emitter) => emitter.chain_id,
      );
      const dataSourceEmitterAddresses = config.pragma.data_source_emitters.map(
        (emitter) => zeroPadValue(emitter.address, 32),
      );
      const initTx = await pragma.initialize(
        hyperlaneAddress,
        deployer.address,
        dataSourceEmitterChainIds,
        dataSourceEmitterAddresses,
        config.pragma.valid_time_period_in_seconds,
        parseEther(config.pragma.single_update_fee_in_wei),
      );
      await initTx.wait();
      console.log(`✅ Pragma.sol deployed and initialized at ${pragmaAddress}`);

      // Save deployment info
      const deploymentInfo = {
        Hyperlane: hyperlaneAddress,
        Pragma: pragmaAddress,
      };
      const jsonContent = JSON.stringify(deploymentInfo, null, 2);
      const deploymentPath = path.join("..", "..", "deployments", chain);
      fs.mkdirSync(deploymentPath, { recursive: true });
      const filePath = path.join(deploymentPath, "pragma.json");
      fs.writeFileSync(filePath, jsonContent);
      console.log(`Deployment info saved to ${filePath}`);
      console.log("Deployment complete!");
    } catch (error) {
      console.error("Deployment failed:", error);
      throw error;
    }
  }
}
