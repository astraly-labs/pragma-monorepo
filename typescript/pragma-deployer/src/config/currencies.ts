import { shortString } from "starknet";

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

  static fromCurrencyConfig(config: CurrencyConfig): Currency {
    return new Currency(
      config.ticker,
      config.decimals,
      config.abstract || false,
      config.starknet_address,
      config.ethereum_address,
    );
  }

  private validateAddress(address?: string | bigint): bigint {
    if (address === undefined) {
      return BigInt(0);
    }
    if (typeof address === "string") {
      if (address.startsWith("0x")) {
        return BigInt(`${address}`);
      } else {
        return BigInt(`0x${address}`);
      }
    }
    return address;
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
}
