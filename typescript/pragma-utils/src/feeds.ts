import { shortString } from "starknet";

export enum AssetClass {
  Crypto = 0,
}

export enum UniqueVariant {
  SpotMedian = 0,
  PerpMedian = 1,
  SpotMean = 2,
}

export enum TwapVariant {
  SpotMedianOneDay = 0,
}

export enum RealizedVolatilityVariant {
  OneWeek = 0,
}

export type FeedType =
  | { type: "Unique"; variant: UniqueVariant }
  | { type: "Twap"; variant: TwapVariant }
  | { type: "RealizedVolatility"; variant: RealizedVolatilityVariant };

export type Feed = {
  assetClass: AssetClass;
  feedType: FeedType;
  pairId: bigint;
};

// Helper type for a complete Feed with its ID
export type FeedWithId = Feed & { feedId: bigint };

// Utility function to convert FeedId (bigint) to Feed
export function feedFromId(id: bigint): Feed {
  const ASSET_CLASS_SHIFT = BigInt(
    "0x10000000000000000000000000000000000000000000000000000000000",
  );
  const FEED_TYPE_SHIFT = BigInt(
    "0x1000000000000000000000000000000000000000000000000000000",
  );
  const FEED_TYPE_MASK = BigInt("0xFFFF");

  const assetClassFelt = id / ASSET_CLASS_SHIFT;
  const feedTypeFelt = (id / FEED_TYPE_SHIFT) & FEED_TYPE_MASK;
  const pairId =
    id - assetClassFelt * ASSET_CLASS_SHIFT - feedTypeFelt * FEED_TYPE_SHIFT;

  const assetClass = AssetClass[AssetClass[assetClassFelt as AssetClass]];
  const feedType = decodeFeedType(Number(feedTypeFelt));

  return { assetClass, feedType, pairId };
}

// toString method for FeedType
export function feedTypeToString(feedType: FeedType): string {
  switch (feedType.type) {
    case "Unique":
      return `Unique(${UniqueVariant[feedType.variant]})`;
    case "Twap":
      return `Twap(${TwapVariant[feedType.variant]})`;
    case "RealizedVolatility":
      return `RealizedVolatility(${RealizedVolatilityVariant[feedType.variant]})`;
  }
}

// toString method for Feed
export function feedToString(feed: Feed): string {
  return `Feed {
      assetClass: ${AssetClass[feed.assetClass]},
      feedType: ${feedTypeToString(feed.feedType)},
      pairId: ${shortString.decodeShortString(feed.pairId.toString())}
    }`;
}

// toString method for FeedWithId
export function feedWithIdToString(feedWithId: FeedWithId): string {
  return `FeedWithId {
    feedId: ${feedWithId.feedId},
    assetClass: ${AssetClass[feedWithId.assetClass]},
    feedType: ${feedTypeToString(feedWithId.feedType)},
    pairId: ${shortString.decodeShortString(feedWithId.pairId.toString())}
  }`;
}

// Utility function to decode FeedType
export function decodeFeedType(id: number): FeedType {
  const mainType = (id & 0xff00) >> 8;
  const variant = id & 0x00ff;

  switch (mainType) {
    case 0:
      return { type: "Unique", variant: variant as UniqueVariant };
    case 1:
      return { type: "Twap", variant: variant as TwapVariant };
    case 2:
      return {
        type: "RealizedVolatility",
        variant: variant as RealizedVolatilityVariant,
      };
    default:
      throw new Error("Unknown feed type");
  }
}

export function decodeFeeds(feedIds: bigint[]): FeedWithId[] {
  return feedIds.map((id) => ({ feedId: id, ...feedFromId(id) }));
}
