import {
    Account,
    json,
    RpcProvider,
} from "starknet";
import fs from "fs";

import {
    ACCOUNT_ADDRESS,
    PRIVATE_KEY,
    NETWORK,
    BUILD_FOLDER
} from "./constants";

export async function buildAccount(): Promise<Account> {
    const provider = new RpcProvider({ nodeUrl: process.env.RPC_URL });

    if (!PRIVATE_KEY || !ACCOUNT_ADDRESS) {
        throw new Error("Private key or account address not set in .env file");
    }
    if (!NETWORK) {
        throw new Error('NETWORK environment variable is not set');
    }

    return new Account(provider, ACCOUNT_ADDRESS, PRIVATE_KEY);
}

export function getCompiledContract(name: string): any {
    const contractPath = `${BUILD_FOLDER}_${name}.contract_class.json`;
    return json.parse(fs.readFileSync(contractPath).toString("ascii"));
}

export function getCompiledContractCasm(name: string): any {
    const contractPath = `${BUILD_FOLDER}_${name}.compiled_contract_class.json`;
    return json.parse(fs.readFileSync(contractPath).toString("ascii"));
}

