import * as yaml from "js-yaml";
import * as fs from "fs";
import { STARKNET_CHAINS, type Chain } from "./deployers/interface";

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

// =========================

/// DEPLOYMENT CONFIGURATION.
export interface DeploymentConfig {
  pragma_oracle: {
    publishers: Array<{
      name: string;
      address: string;
      sources: string[];
    }>;
  };
  pragma_dispatcher: {
    owner?: string;
    pragma_oracle_address: string;
    hyperlane_mailbox_address: string;
  };
  pragma: {
    data_source_emitters: Array<{
      chain_id: number;
      address: string;
    }>;
    valid_time_period_in_seconds: number;
    single_update_fee_in_wei: string;
    hyperlane: {
      validators: string[];
    };
  };
}

// =========================

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

/// SUPPORTED FEEDS CONFIGURATION.
export interface FeedsConfig {
  feeds: Feed[];
  asset_classes_routers: AssetClassRouter[];
}

// =========================

/// Get an RPC for a starknet chain.
export function getStarknetRpcUrl(chain: Chain): string {
  if (!STARKNET_CHAINS.includes(chain)) {
    throw new Error("Must be a starknet chain.");
  }
  if (chain === "starknet") {
    return "https://free-rpc.nethermind.io/mainnet-juno";
  } else if (chain === "starknet_devnet") {
    return "http://127.0.0.1:9615";
  } else {
    // sepolia
    return "https://free-rpc.nethermind.io/sepolia-juno";
  }
}

// =========================

/// CURRENCIES CONFIGURATION.
export interface CurrencyConfig {
  name: string;
  decimals: number;
  ticker: string;
  coingecko_id?: string;
  starknet_address?: string;
  ethereum_address?: string;
  abstract?: boolean;
}

export type CurrenciesConfig = CurrencyConfig[];

// Class representing a Currency
export class Currency {
  id: string;
  decimals: number;
  isAbstractCurrency: boolean;
  starknetAddress: bigint;
  ethereumAddress: bigint;

  constructor(
    currencyId: string,
    decimals: number,
    isAbstractCurrency: boolean,
    starknetAddress?: string | bigint,
    ethereumAddress?: string | bigint,
  ) {
    this.id = currencyId;
    this.decimals = decimals;
    this.isAbstractCurrency = isAbstractCurrency;
    this.starknetAddress = this.validateAddress(starknetAddress);
    this.ethereumAddress = this.validateAddress(ethereumAddress);
  }

  private validateAddress(address?: string | bigint): bigint {
    if (address === undefined) {
      return BigInt(0);
    }
    if (typeof address === "string") {
      return BigInt(`0x${address}`);
    }
    return address;
  }

  static fromCurrencyConfig(config: CurrencyConfig): Currency {
    return new Currency(
      config.ticker,
      config.decimals,
      config.abstract || false,
      config.starknet_address,
      config.ethereum_address,
    );
  }

  serialize(): [string, number, boolean, bigint, bigint] {
    return [
      this.id,
      this.decimals,
      this.isAbstractCurrency,
      this.starknetAddress,
      this.ethereumAddress,
    ];
  }

  toObject(): {
    id: string;
    decimals: number;
    isAbstractCurrency: boolean;
    starknetAddress: string;
    ethereumAddress: string;
  } {
    return {
      id: this.id,
      decimals: this.decimals,
      isAbstractCurrency: this.isAbstractCurrency,
      starknetAddress: `0x${this.starknetAddress.toString(16)}`,
      ethereumAddress: `0x${this.ethereumAddress.toString(16)}`,
    };
  }

  toString(): string {
    return `Currency(${this.id}, ${this.decimals}, ${this.isAbstractCurrency}, ${this.starknetAddress}, ${this.ethereumAddress})`;
  }
}
