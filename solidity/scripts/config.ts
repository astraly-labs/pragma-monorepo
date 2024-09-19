import { ethers } from "ethers";


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
    ethers.utils.hexZeroPad("0x51298007E4e8A48d11B64D9361d6ED64f2B4309D", 32),
    ethers.utils.hexZeroPad("0x51298007E4e8A48d11B64D9361d6ED64f2B4309D", 32),
    ethers.utils.hexZeroPad("0x51298007E4e8A48d11B64D9361d6ED64f2B4309D", 32),
  ],
  validTimePeriodSeconds: 3600, // 1 hour
  singleUpdateFeeInWei: ethers.utils.parseEther("0.01"), // 0.01 ETH
};