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
