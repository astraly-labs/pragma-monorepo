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

export class Pair {
  id: string;
  baseCurrencyId: string;
  quoteCurrencyId: string;

  constructor(baseCurrency: string, quoteCurrency: string) {
    this.id = shortString.encodeShortString(
      `${baseCurrency}/${quoteCurrency}`.toUpperCase(),
    );
    this.baseCurrencyId = shortString.encodeShortString(baseCurrency);
    this.quoteCurrencyId = shortString.encodeShortString(quoteCurrency);
  }

  toString(): string {
    return `Pair(${shortString.decodeShortString(this.id)}, ${shortString.decodeShortString(this.baseCurrencyId)}, ${shortString.decodeShortString(this.quoteCurrencyId)})`;
  }

  serialize(): [string, string, string] {
    return [this.id, this.quoteCurrencyId, this.baseCurrencyId];
  }
}

/// From a Currency config, generate all possible pairs.
export function generateAllPairs(currencies: CurrencyConfig[]): Pair[] {
  const pairs: Pair[] = [];
  const nonAbstractCurrencies = currencies.filter((c) => !c.abstract);
  const abstractCurrencies = currencies.filter((c) => c.abstract);

  // Generate pairs between non-abstract currencies
  for (let i = 0; i < nonAbstractCurrencies.length; i++) {
    for (let j = i + 1; j < nonAbstractCurrencies.length; j++) {
      const base = nonAbstractCurrencies[i];
      const quote = nonAbstractCurrencies[j];
      pairs.push(new Pair(base.ticker, quote.ticker));
      pairs.push(new Pair(quote.ticker, base.ticker));
    }
  }

  // Generate pairs between non-abstract and abstract currencies
  for (const nonAbstract of nonAbstractCurrencies) {
    for (const abstract of abstractCurrencies) {
      pairs.push(new Pair(nonAbstract.ticker, abstract.ticker));
    }
  }

  return pairs;
}
