import { ethers } from "ethers";

export const hyperlaneConfig = {
  validators: [
    "0x1234567890123456789012345678901234567890",
    "0x2345678901234567890123456789012345678901",
    "0x3456789012345678901234567890123456789012"
  ],
};

export const pragmaConfig = {
  dataSourceEmitterChainIds: [1, 2, 3],
  dataSourceEmitterAddresses: [
    "0x1111111111111111111111111111111111111111",
    "0x2222222222222222222222222222222222222222",
    "0x3333333333333333333333333333333333333333"
  ],
  validTimePeriodSeconds: 3600, // 1 hour
  singleUpdateFeeInWei: ethers.utils.parseEther("0.01"), // 0.01 ETH
};