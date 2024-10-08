import { shortString, uint256 } from "starknet";

export interface Pair {
  id: string;
  quote_currency_id: string;
  base_currency_id: string;
}

export function decodePair(pairId: bigint): Pair {
  const pairString = shortString.decodeShortString(pairId.toString());
  const [base, quote] = pairString.split("/");
  return {
    id: uint256.bnToUint256(pairId).toString(),
    base_currency_id: uint256
      .bnToUint256(shortString.encodeShortString(base))
      .toString(),
    quote_currency_id: uint256
      .bnToUint256(shortString.encodeShortString(quote))
      .toString(),
  };
}
