import fs from "fs";
import path from "path";
import axios from "axios";
import qs from "qs";
import hre, { ethers, upgrades } from "hardhat";
import { AbiCoder, Contract, parseEther, zeroPadValue } from "ethers";
import { EVM_CHAINS, type Chain, type EvmChain } from "pragma-utils";
import { type ContractDeployer } from "./interface";
import type { DeploymentConfig } from "../config";

/*
 * NOTE: We use the v2 API of Etherscan.
 * It is fairly new so it's possible that one recent chain is not supported by it.
 */
const ETHERSCAN_VERIFIER_URL = "https://api.etherscan.io/v2/api";

export class PragmaDeployer implements ContractDeployer {
  readonly allowedChains: Chain[] = EVM_CHAINS;
  readonly defaultChain: EvmChain = "mainnet";

  async deploy(
    config: DeploymentConfig,
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

      // Verify contracts
      await this.verifyContracts(config, hyperlane, pragma);
    } catch (error) {
      console.error("Deployment failed:", error);
      throw error;
    }
  }

  /// Deploys Hyperlane.sol
  private async deployHyperlane(config: DeploymentConfig): Promise<Contract> {
    const hyperlaneArtifact = await hre.artifacts.readArtifact(
      "src/Hyperlane.sol:Hyperlane",
    );
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
    const pragmaArtifact = await hre.artifacts.readArtifact(
      "src/Pragma.sol:Pragma",
    );
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

  /// Verifies deployed contracts using Etherscan API
  private async verifyContracts(
    config: DeploymentConfig,
    hyperlane: Contract,
    pragmaProxy: Contract,
  ): Promise<void> {
    const apiKey = process.env.ETHERSCAN_API_KEY;
    if (!apiKey) {
      console.warn(
        "ETHERSCAN_API_KEY is not set. Skipping contract verification.",
      );
      return;
    }

    const chainId = hre.network.config.chainId;

    if (!chainId) {
      console.error("Chain ID not found in network config.");
      return;
    }

    try {
      console.log("⏳ Verifying contracts on Etherscan...");

      // Verify Hyperlane
      await this.verifyContract(
        hyperlane,
        "src/Hyperlane.sol:Hyperlane",
        apiKey,
        chainId,
        [config.pragma.hyperlane.validators], // Constructor arguments for Hyperlane
      );

      // Get the implementation address of Pragma
      const pragmaProxyAddress = await pragmaProxy.getAddress();
      const pragmaImplAddress =
        await upgrades.erc1967.getImplementationAddress(pragmaProxyAddress);

      // Create a Contract instance for the implementation
      const pragmaImpl = await ethers.getContractAt(
        "src/Pragma.sol:Pragma",
        pragmaImplAddress,
      );

      // Verify Pragma implementation
      await this.verifyContract(
        pragmaImpl,
        "src/Pragma.sol:Pragma",
        apiKey,
        chainId,
        [], // No constructor arguments for implementation contract
      );

      console.log("✅ Contracts verified successfully.");
    } catch (error) {
      console.error("Contract verification failed:", error);
    }
  }

  /// Verifies a single contract using Etherscan API
  private async verifyContract(
    contract: Contract,
    contractFullyQualifiedName: string,
    apiKey: string,
    chainId: number,
    constructorArguments: any[] = [],
  ): Promise<void> {
    const contractAddress = await contract.getAddress();

    const artifact = await hre.artifacts.readArtifact(
      contractFullyQualifiedName,
    );

    const buildInfo = await hre.artifacts.getBuildInfo(
      `${artifact.sourceName}:${artifact.contractName}`,
    );
    if (!buildInfo) {
      console.error(
        `Build info not found for contract ${artifact.contractName}`,
      );
      return;
    }

    const compilerVersion = `v${buildInfo.solcLongVersion}`;
    const inputJSON = buildInfo.input;
    // Encode constructor arguments if any
    let constructorArgumentsEncoded = "";
    if (constructorArguments.length > 0) {
      const constructorAbi = artifact.abi.find(
        (item) => item.type === "constructor",
      );
      if (constructorAbi) {
        const abiCoder = new AbiCoder();
        constructorArgumentsEncoded = abiCoder
          .encode(constructorAbi.inputs || [], constructorArguments)
          .replace(/^0x/, "");
      }
    }

    const queryParams = {
      apikey: apiKey,
      chainid: chainId.toString(),
      module: "contract",
      action: "verifysourcecode",
    };

    const bodyData = {
      codeformat: "solidity-standard-json-input",
      sourceCode: JSON.stringify(inputJSON),
      contractaddress: contractAddress,
      contractname: `${artifact.sourceName}:${artifact.contractName}`,
      compilerversion: compilerVersion,
      // NOTE: There's a mistake in the etherscan api... "Arguements". To fix, one day.
      constructorArguements: constructorArgumentsEncoded,
    };
    const url = `${ETHERSCAN_VERIFIER_URL}?${qs.stringify(queryParams)}`;
    try {
      const response = await axios.post(url, qs.stringify(bodyData), {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      });

      if (response.data.status === "1") {
        console.log(
          `✅ Contract ${artifact.contractName} verified successfully.`,
        );
      } else {
        console.error(
          `❌ Verification failed for contract ${artifact.contractName}: ${response.data.result}`,
        );
      }
    } catch (error: any) {
      console.error(
        `❌ Verification failed for contract ${artifact.contractName}:`,
        error.response?.data || error.message,
      );
    }
  }
}
