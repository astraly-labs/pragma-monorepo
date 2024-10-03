import type { DeploymentConfig } from "./deployment";

export function parsePairsFromConfig(config: DeploymentConfig): Pair[] {
  return config.pragma_oracle.pairs.map(Pair.fromStr);
}

export class Pair {
  id: string;
  baseCurrency: string;
  quoteCurrency: string;

  constructor(baseCurrency: string, quoteCurrency: string) {
    this.id = `${baseCurrency}/${quoteCurrency}`.toUpperCase();
    this.baseCurrency = baseCurrency.toUpperCase();
    this.quoteCurrency = quoteCurrency.toUpperCase();
  }

  serialize(): [string, string, string] {
    return [this.id, this.baseCurrency, this.quoteCurrency];
  }

  toObject(): {
    id: string;
    baseCurrency: string;
    quoteCurrency: string;
  } {
    return {
      id: this.id,
      baseCurrency: this.baseCurrency,
      quoteCurrency: this.quoteCurrency,
    };
  }

  static fromStr(pairStr: string): Pair {
    const [base, quote] = pairStr.split("/");
    if (!base || !quote) {
      throw new Error(`Invalid pair string: ${pairStr}`);
    }
    return new Pair(base, quote);
  }
}
