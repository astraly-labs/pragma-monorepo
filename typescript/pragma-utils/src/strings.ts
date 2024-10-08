// Shorten a hexadecimal string.
// Example: 0x18d070bcad4b53eb0c716c13d36e5f0d798e52bd87a2a25f0de477b5902c9ff => 0x18d07...c9ff
export function shortenHex(hex: string) {
  return `${hex.slice(0, 6)}...${hex.slice(-4)}`;
}
