import dotenv from "dotenv";
import path from "path";

dotenv.config();
const ACCOUNT_ADDRESS = process.env.ACCOUNT_ADDRESS;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const NETWORK = process.env.NETWORK

const BUILD_FOLDER = "../cairo/target/dev/";
const DEPLOYED_CONTRACTS_FILE = path.join('deployments', `${NETWORK}_deployed_contracts.json`);

export {
    ACCOUNT_ADDRESS,
    PRIVATE_KEY,
    NETWORK,
    BUILD_FOLDER,
    DEPLOYED_CONTRACTS_FILE
}
