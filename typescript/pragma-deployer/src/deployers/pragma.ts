import fs from "fs";
import path from "path";

import hre, { ethers, upgrades } from "hardhat";
import { Contract, parseEther, zeroPadValue } from "ethers";
import { EVM_CHAINS, type Chain, type EvmChain } from "pragma-utils";

import { type ContractDeployer } from "./interface";
import type { DeploymentConfig } from "../config";

export class PragmaDeployer implements ContractDeployer {
  readonly allowedChains: Chain[] = EVM_CHAINS;
  readonly defaultChain: EvmChain = "mainnet";

  async deploy(
    config: DeploymentConfig,
    // TODO: Handle deterministic deployments, not mandatory yet.
    _deterministic: boolean,
    chain?: EvmChain,
  ): Promise<void> {
    if (!chain) chain = this.defaultChain;
    if (!this.allowedChains.includes(chain)) {
      throw new Error(`⛔ Deployment to ${chain} is not supported.`);
    }
    await hre.switchNetwork(chain);

    try {
      console.log(`🧩 Deploying Pragma to ${chain}...\n`);

      const [deployer] = await ethers.getSigners();
      console.log("Deployer account:", deployer.address);

      // Deploy Hyperlane contract
      console.log("⏳ Deploying Hyperlane...");
      const hyperlane = await this.deployHyperlane(config);
      const hyperlaneAddress = await hyperlane.getAddress();
      console.log("✅ Hyperlane deployed to:", hyperlaneAddress);

      // Deploy Pragma contract
      console.log("⏳ Deploying Pragma...");
      const pragma = await this.deployPragma(
        config,
        deployer.address,
        hyperlaneAddress,
      );
      const pragmaAddress = await pragma.getAddress();
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

  /// Deploys Hyperlane.sol
  private async deployHyperlane(config: DeploymentConfig): Promise<Contract> {
    const hyperlaneArtifact = await hre.artifacts.readArtifact("Hyperlane");
    const Hyperlane = await ethers.getContractFactory(
      hyperlaneArtifact.abi,
      hyperlaneArtifact.bytecode,
    );
    const hyperlane = await Hyperlane.deploy(
      config.pragma.hyperlane.validators,
    );
    await hyperlane.waitForDeployment();
    return hyperlane;
  }

  /// Deploys Pragma.sol
  private async deployPragma(
    config: DeploymentConfig,
    deployerAddress: string,
    hyperlaneAddress: string,
  ): Promise<Contract> {
    const pragmaArtifact = await hre.artifacts.readArtifact("Pragma");
    const Pragma = await ethers.getContractFactory(
      pragmaArtifact.abi,
      pragmaArtifact.bytecode,
    );
    const dataSourceEmitterChainIds = config.pragma.data_source_emitters.map(
      (emitter) => emitter.chain_id,
    );
    const dataSourceEmitterAddresses = config.pragma.data_source_emitters.map(
      (emitter) => zeroPadValue(emitter.address, 32),
    );
    const pragma = await upgrades.deployProxy(
      Pragma,
      [
        hyperlaneAddress,
        deployerAddress,
        dataSourceEmitterChainIds,
        dataSourceEmitterAddresses,
        config.pragma.valid_time_period_in_seconds,
        parseEther(config.pragma.single_update_fee_in_wei),
      ],
      {
        initializer: "initialize",
        kind: "uups",
        unsafeAllow: ["constructor"],
      },
    );
    await pragma.waitForDeployment();
    return pragma;
  }
}
