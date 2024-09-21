import { ethers } from "hardhat";
import "@nomicfoundation/hardhat-ethers";
import { parseEther, zeroPadValue } from "ethers";

import type { Deployer, Chain } from './interface';

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
  async deploy(chain?: Chain): Promise<void> {
    if (!chain || !this.allowedChains.includes(chain)) {
      throw new Error(`Deployment to ${chain || 'unknown chain'} is not supported.`);
    }
    console.log(`Deploying pragma to ${chain}...`);

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

    console.log('Pragma deployed successfully to ETH.');
  }
}
