#!/bin/bash

# Array of tickers (excluding USD and EUR)
tickers=(
    "BTC" "ETH" "SOL" "USDT" "DAI" "USDC" "STRK" "LUSD" "WBTC" "WSTETH" "STETH" "NSTR" "LORDS" "ZEND" "EKUBO"
)

# Function to generate feed ID
generate_feed_id() {
    local base_asset=$1
    bun run generate_feed_id --asset-class Crypto --feed-type Unique --feed-variant SpotMedian --pair-id "${base_asset}/USD"
}

# Initialize JSON object
json="{"

# Generate feed IDs and build JSON
for ticker in "${tickers[@]}"; do
    feed_id=$(generate_feed_id "$ticker")
    json+="\"$ticker\": \"$feed_id\","
done

# Remove trailing comma and close JSON object
json="${json%,}"
json+="}"

# Write JSON to file
echo "$json" > feed_id_mapping.json

echo "Feed ID mapping has been written to feed_id_mapping.json"