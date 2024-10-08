import { num } from "starknet";

export interface Currency {
  id: string;
  decimals: number;
  is_abstract_currency: boolean;
  starknet_address: string;
  ethereum_address: string;
}

export function parseCurrency(currencyString: string): Currency {
  const [id, decimals, is_abstract, starknet_address, ethereum_address] =
    currencyString.split(",");
  return {
    id: num.toHex(BigInt(id)),
    decimals: parseInt(decimals),
    is_abstract_currency: is_abstract === "true",
    starknet_address,
    ethereum_address,
  };
}
