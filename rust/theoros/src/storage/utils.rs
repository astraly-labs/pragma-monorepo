use alloy::primitives::keccak256;
use alloy_primitives::FixedBytes;
use bigdecimal::{BigDecimal, ToPrimitive};

use crate::{
    types::hyperlane::{DispatchMessage, DispatchUpdate},
    AppState,
};

pub fn format_message(message: DispatchMessage) -> FixedBytes<32> {
    let mut input = Vec::new();
    input.push(message.header.version);
    input.extend_from_slice(&message.header.nonce.to_be_bytes());
    input.extend_from_slice(&message.header.origin.to_be_bytes());
    input.extend_from_slice(&message.header.sender.low().to_be_bytes());
    input.extend_from_slice(&message.header.sender.high().to_be_bytes());
    input.extend_from_slice(&message.header.destination.to_be_bytes());
    input.extend_from_slice(&message.header.recipient.low().to_be_bytes());
    input.extend_from_slice(&message.header.recipient.high().to_be_bytes());

    input.extend_from_slice(&message.body.nb_updated.to_be_bytes());

    for update in message.body.updates {
        match update {
            DispatchUpdate::SpotMedian(spot_update) => {
                input.extend_from_slice(&spot_update.pair_id.low().to_be_bytes());
                input.extend_from_slice(&spot_update.pair_id.high().to_be_bytes());
                let scaled_price = (spot_update.price * BigDecimal::from(10u32.pow(spot_update.metadata.decimals)))
                    .to_u128()
                    .unwrap_or(0);
                input.extend_from_slice(&scaled_price.to_be_bytes());

                input.extend_from_slice(&spot_update.volume.to_be_bytes());
                input.extend_from_slice(&spot_update.metadata.decimals.to_be_bytes());
                input.extend_from_slice(&spot_update.metadata.timestamp.to_be_bytes());
                input.extend_from_slice(&spot_update.metadata.num_sources_aggregated.to_be_bytes());
            }
        }
    }

    keccak256(&input)
}

#[cfg(test)]
mod tests {
    use crate::types::hyperlane::{DispatchMessageBody, DispatchMessageHeader, MetadataUpdate, SpotMedianUpdate};

    use super::*;
    use bigdecimal::BigDecimal;
    use starknet::core::types::U256;

    #[test]
    fn test_format_message() {
        // Create a test message
        let message = DispatchMessage {
            header: DispatchMessageHeader {
                version: 1,
                nonce: 123,
                origin: 1,
                sender: U256::from_words(123, 0),
                destination: 2,
                recipient: U256::from_words(789, 0),
            },
            body: DispatchMessageBody {
                nb_updated: 1,
                updates: vec![DispatchUpdate::SpotMedian(SpotMedianUpdate {
                    pair_id: U256::from_words(1, 0),
                    metadata: MetadataUpdate { timestamp: 1634567890, num_sources_aggregated: 5, decimals: 8 },
                    price: BigDecimal::from(1000),
                    volume: 50000,
                })],
            },
        };

        let hash = format_message(message);

        // TODO: add the assertion for the expected hash (from hyperlane_starknet repository)
    }
}
