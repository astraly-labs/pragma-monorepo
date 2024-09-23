import dotenv from "dotenv";

dotenv.config();
const ACCOUNT_ADDRESS = process.env.ACCOUNT_ADDRESS;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const NETWORK = process.env.NETWORK

const CAIRO_BUILD_FOLDER = "../cairo/target/dev/";

export {
    ACCOUNT_ADDRESS,
    PRIVATE_KEY,
    NETWORK,
    CAIRO_BUILD_FOLDER,
}
