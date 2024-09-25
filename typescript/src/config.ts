import * as yaml from "js-yaml";
import * as fs from "fs";

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

export interface DeploymentConfig {
  pragma_oracle: any; // TODO: Define specific fields
  pragma_dispatcher: {
    owner?: string;
    pragma_oracle_address: string;
    hyperlane_mailbox_address: string;
  };
  pragma: any; // TODO: Define specific fields
}

export interface Feed {
  name: string;
  id: string;
}

export interface FeedTypeRouter {
  name: string;
  contract: string;
  id: string;
}

export interface AssetClassRouter {
  name: string;
  contract: string;
  id: string;
  feed_types_routers: FeedTypeRouter[];
}

export interface FeedsConfig {
  feeds: Feed[];
  asset_classes_routers: AssetClassRouter[];
}
