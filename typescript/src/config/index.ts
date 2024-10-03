import * as yaml from "js-yaml";
import * as fs from "fs";

export {
  type CurrencyConfig,
  type CurrenciesConfig,
  Currency,
} from "./currencies";

export type { DeploymentConfig } from "./deployment";

export type {
  Feed,
  FeedTypeRouter,
  AssetClassRouter,
  FeedsConfig,
} from "./feeds";

export { Pair, parsePairsFromConfig } from "./pairs";

export function loadConfig<T>(filePath: string): T {
  try {
    const fileContents = fs.readFileSync(filePath, "utf8");
    return yaml.load(fileContents) as T;
  } catch (error) {
    console.error(
      `Error loading config file ${filePath}:`,
      (error as Error).message,
    );
    process.exit(1);
  }
}
