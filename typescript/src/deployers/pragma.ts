import { ethers } from "hardhat";
import "@nomicfoundation/hardhat-ethers";
import { parseEther, zeroPadValue } from "ethers";

import type { Deployer, Chain } from './interface';

const HYPERLANE_CONTRACT_NAME: string = "Hyperlane";
const PRAGMA_CONTRACT_NAME: string = "Pragma";

// Configuration arguments for Hyperlane.sol contract
export const hyperlaneConfig = {
  validators: [
    "0x1234567890123456789012345678901234567890",
    "0x2345678901234567890123456789012345678901",
    "0x3456789012345678901234567890123456789012"
  ],
};

// Configuration arguments for Pragma.sol contract
export const pragmaConfig = {
  dataSourceEmitterChainIds: [1, 2, 3],
  dataSourceEmitterAddresses: [
    zeroPadValue("0x51298007E4e8A48d11B64D9361d6ED64f2B4309D", 32),
    zeroPadValue("0x51298007E4e8A48d11B64D9361d6ED64f2B4309D", 32),
    zeroPadValue("0x51298007E4e8A48d11B64D9361d6ED64f2B4309D", 32),
  ],
  validTimePeriodSeconds: 3600, // 1 hour
  singleUpdateFeeInWei: parseEther("0.01"), // 0.01 ETH
};

export class PragmaDeployer implements Deployer {
  readonly allowedChains: Chain[] = ['ethereum'];
  readonly defaultChain: Chain = 'ethereum';
  async deploy(chain?: Chain): Promise<void> {
    if (!chain) chain = this.defaultChain;
    if (!this.allowedChains.includes(chain)) {
      throw new Error(`⛔ Deployment to ${chain} is not supported.`);
    }
    console.log(`Deploying Pragma.sol to ${chain}...`);

    const [deployer] = await ethers.getSigners();

    console.log("Deployer account:", deployer.address);

    // TODO: Should be a deployer itself?
    // Deploy Hyperlane contract
    const Hyperlane = await ethers.getContractFactory(HYPERLANE_CONTRACT_NAME);
    const hyperlane = await Hyperlane.deploy(hyperlaneConfig.validators);
    await hyperlane.deployed();
    console.log("✅ Hyperlane deployed to:", hyperlane.address);

    // Deploy Pragma contract
    const Pragma = await ethers.getContractFactory(PRAGMA_CONTRACT_NAME);
    const pragma = await Pragma.deploy(
      hyperlane.address,
      pragmaConfig.dataSourceEmitterChainIds,
      pragmaConfig.dataSourceEmitterAddresses,
      pragmaConfig.validTimePeriodSeconds,
      pragmaConfig.singleUpdateFeeInWei
    );
    await pragma.deployed();
    console.log(`✅ Pragma.sol deployed at ${pragma.address}`);
  }
}
