import fs from "fs";

import { buildAccount } from "./utils";
import { deployContract } from "./deploy";
import { DEPLOYED_CONTRACTS_FILE } from "./constants";

interface DeployedContracts {
    [key: string]: string;
}

interface ContractConfig {
    name: string;
    constructor: Record<string, { type: string; value: string | string[] }>;
}

interface Config {
    contracts: Record<string, ContractConfig>;
    deploymentOrder: string[];
}

async function deployContracts(): Promise<DeployedContracts> {
    try {
        const account = await buildAccount();
        const config: Config = JSON.parse(fs.readFileSync("TODO.json", 'utf-8'));
        const deployedContracts: DeployedContracts = {};

        for (const contractName of config.deploymentOrder) {
            const address = await deployContract(
                account,
                contractName,
            );
            deployedContracts[contractName] = address;
        }

        console.log("All contracts deployed successfully:");
        console.log(deployedContracts);

        fs.writeFileSync(DEPLOYED_CONTRACTS_FILE, JSON.stringify(deployedContracts, null, 2));
        console.log(`Deployed contracts saved to ${DEPLOYED_CONTRACTS_FILE}`);

        return deployedContracts;
    } catch (error) {
        console.error("Deployment failed:", error);
        throw error;
    }
}

deployContracts()
    .then((addresses) => {
        console.log("Deployment successful. Contract addresses:", addresses);
    })
    .catch((error) => {
        console.error("Deployment failed:", error);
    });
