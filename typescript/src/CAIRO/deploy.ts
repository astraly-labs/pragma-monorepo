import {
    Account,
    CallData,
    ContractFactory,
} from "starknet";
import type { ContractFactoryParams } from "starknet";

import { getCompiledContract, getCompiledContractCasm } from "./utils";

export async function deployContract(
    account: Account,
    contractName: string,
): Promise<string> {
    console.log(`Deploying contract ${contractName}...`);

    const compiledContract = getCompiledContract(contractName);
    const casm = getCompiledContractCasm(contractName);
    const constructorCalldata = CallData.compile([]);
    const params: ContractFactoryParams = {
        compiledContract,
        account,
        casm
    };

    const contractFactory = new ContractFactory(params);
    const contract = await contractFactory.deploy(constructorCalldata);

    console.log(`Contract ${contractName} deployed at address:`, contract.address);

    return contract.address;
}
