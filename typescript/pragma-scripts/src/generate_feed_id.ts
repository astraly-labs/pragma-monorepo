import { Command } from "commander";
import {
  AssetClass,
  UniqueVariant,
  TwapVariant,
  RealizedVolatilityVariant,
  type FeedType,
  generateFeedId,
} from "pragma-utils";

function parseCommandLineArguments() {
  const program = new Command();
  program
    .name("generate-feed-id")
    .description(
      "CLI to generate a feed ID based on asset class, feed type, and pair ID",
    )
    .requiredOption("--asset-class <class>", "Asset class (e.g., Crypto)")
    .requiredOption("--feed-type <type>", "Feed type (e.g., Unique)")
    .requiredOption(
      "--feed-variant <variant>",
      "Feed variant (e.g., SpotMedian)",
    )
    .requiredOption("--pair-id <id>", "Pair ID (e.g., ETH/USD)")
    .parse(process.argv);

  const options = program.opts();
  return options;
}

function parseFeedType(type: string, variant: string): FeedType {
  switch (type) {
    case "Unique":
      return {
        type: "Unique",
        variant: UniqueVariant[variant as keyof typeof UniqueVariant],
      };
    case "Twap":
      return {
        type: "Twap",
        variant: TwapVariant[variant as keyof typeof TwapVariant],
      };
    case "RealizedVolatility":
      return {
        type: "RealizedVolatility",
        variant:
          RealizedVolatilityVariant[
            variant as keyof typeof RealizedVolatilityVariant
          ],
      };
    default:
      throw new Error(`Invalid feed type: ${type}`);
  }
}

function main() {
  const options = parseCommandLineArguments();

  const assetClass = AssetClass[options.assetClass as keyof typeof AssetClass];
  if (assetClass === undefined) {
    throw new Error(`Invalid asset class: ${options.assetClass}`);
  }

  const feedType = parseFeedType(options.feedType, options.feedVariant);

  const feedId = generateFeedId(assetClass, feedType, options.pairId);
  console.log(`Generated Feed ID: ${feedId}`);
}

main();
