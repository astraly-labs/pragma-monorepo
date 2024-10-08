# Pragma Scripts

This package contains scripts used to interact with Pragma contracts.

## Dependencies

### Requirements

You'll need either [NPM](https://www.npmjs.com/) or [Bun](https://bun.sh/).

### Installation

Install dependencies:

```bash
bun install
# or
npm install
```

Copy the `env.example` as `.env` and fill the variables.

## Available Scripts

#### generate_feed_id.ts

Allows you to generate a Feed ID from feed values:

```bash
bun run generate_feed_id --asset-class Crypto --feed-type Unique --feed-variant SpotMedian --pair-id EKUBO/USD
```

### Dispatcher Scripts

Located in the `dispatcher/` directory.

#### add_feeds.ts

Adds multiple data feeds to the Pragma Dispatcher contract.

```bash
bun run dispatcher:add_feeds --chain <chain_name> --feed-ids <feed_id1> <feed_id2> ...
```

#### dispatch.ts

Dispatches multiple data feeds.

```bash
bun run dispatcher:dispatch --chain <chain_name> --feed-ids <feed_id1> <feed_id2> ...
```

#### get_all_feeds.ts

Retrieves all registered feeds from the Pragma Dispatcher contract.

```bash
bun run dispatcher:get_all_feeds --chain <chain_name>
```

#### remove_feeds.ts

Removes multiple data feeds from the Pragma Dispatcher contract.

```bash
bun run dispatcher:remove_feeds --chain <chain_name> --feed-ids <feed_id1> <feed_id2> ...
```

### Oracle Scripts

Located in the `oracle/` directory.

#### add_currency.ts

Adds a new currency to the Pragma Oracle contract.

```bash
bun run oracle:add_currency --chain <chain_name> --id <currency_id> --decimals <decimals> --is_abstract --starknet_address <address> --ethereum_address <address>
```

#### add_pairs.ts

Adds multiple trading pairs to the Pragma Oracle contract.

```bash
bun run oracle:add_pairs --chain <chain_name> --pair-ids <pair_id1> <pair_id2> ...
```

#### add_publisher.ts

Adds a new publisher to the PublisherRegistry contract.

```bash
bun run oracle:add_publisher --chain <chain_name> --publisher <name> --address <address>
```

#### add_sources_for_publisher.ts

Adds multiple sources for a specific publisher in the PublisherRegistry contract.

```bash
bun run oracle:add_sources_for_publisher --chain <chain_name> --publisher <name> --sources <source1> <source2> ...
```

#### get_all_publishers.ts

Retrieves all registered publishers and their sources from the PublisherRegistry contract.

```bash
bun run oracle:get_all_publishers --chain <chain_name>
```

#### remove_publishers.ts

Removes multiple publishers from the PublisherRegistry contract.

```bash
bun run oracle:remove_publishers --chain <chain_name> --publishers <name1> <name2> ...
```

#### remove_sources_for_publisher.ts

Removes multiple sources for a specific publisher in the PublisherRegistry contract.

```bash
bun run oracle:remove_sources_for_publisher --chain <chain_name> --publisher <name> --sources <source1> <source2> ...
```

### Pragma Scripts

Located in the `pragma/` directory.

#### update_feed.ts

Updates a data feed on a specific chain.

```bash
bun run pragma:update_feed --chain <chain_name> --feed-id <feed_id>
```

## Note

For all scripts, replace `<chain_name>` with the target chain (e.g., pragmaDevnet) and provide the required parameters as shown in the usage examples.

Make sure you have the necessary permissions and access to interact with the contracts on the specified chain.
