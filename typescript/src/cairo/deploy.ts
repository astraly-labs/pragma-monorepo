import {
    Account,
    CallData,
    ContractFactory,
} from "starknet";
import type { ContractFactoryParams, RawArgs } from "starknet";

import { getCompiledContract, getCompiledContractCasm } from ".";

export async function deployContract(
    deployer: Account,
    contractName: string,
    calldata: RawArgs,
): Promise<string> {
    console.log(`Deploying contract ${contractName}...`);

    const compiledContract = getCompiledContract(contractName);
    const casm = getCompiledContractCasm(contractName);
    const constructorCalldata = CallData.compile(calldata);
    const params: ContractFactoryParams = {
        compiledContract,
        account: deployer,
        casm
    };

    const contractFactory = new ContractFactory(params);
    const contract = await contractFactory.deploy(constructorCalldata);

    console.log(`Contract ${contractName} deployed at address:`, contract.address);

    return contract.address;
}
