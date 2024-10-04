# Pragma Scripts

This package contains scripts used to interact with Pragma contracts.

# Dependencies

## Requirements

You'll need either [NPM](https://www.npmjs.com/) or [Bun](https://bun.sh/).

## Run

Install dependencies:

```bash
bun install
# or
npm install
```

# Available scripts

## update_feed

This script allows to update a data feed on a specific chain.

### Usage

```bash
bun run update_feed --target-chain <chain_name> --feed-id <feed_id> --private-key <private_key>
```
