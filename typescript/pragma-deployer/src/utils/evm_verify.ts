import axios from "axios";
import qs from "qs";
import hre from "hardhat";
import { AbiCoder, Contract } from "ethers";

/*
 * NOTE: We use the v2 API of Etherscan.
 * It is fairly new so it's possible that one recent chain is not supported by it.
 */
export const ETHERSCAN_VERIFIER_URL = "https://api.etherscan.io/v2/api";

/// Verifies a single contract using Etherscan API
export async function verifyContract(
  contract: Contract,
  contractFullyQualifiedName: string,
  apiKey: string,
  chainId: number,
  constructorArguments: any[] = [],
): Promise<void> {
  const contractAddress = await contract.getAddress();

  const artifact = await hre.artifacts.readArtifact(contractFullyQualifiedName);

  const buildInfo = await hre.artifacts.getBuildInfo(
    `${artifact.sourceName}:${artifact.contractName}`,
  );
  if (!buildInfo) {
    console.error(`Build info not found for contract ${artifact.contractName}`);
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
