use anyhow::{Context, Result};
use apibara_core::starknet::v1alpha2::FieldElement;
use bigdecimal::{BigDecimal,ToPrimitive};
use pragma_feeds::{AssetClass, FeedType};
use starknet::core::types::U256;
use alloy_primitives::{hex,FixedBytes, U256 as alloy_U256};
use alloy::{primitives::keccak256};

use pragma_utils::conversions::apibara::FromFieldBytes;

use super::FromStarknetEventData;

#[derive(Debug, Clone)]
#[allow(unused)]
pub struct DispatchEvent {
    pub sender: U256,
    pub destination_domain: u32,
    pub recipient_address: U256,
    pub message: DispatchMessage,
}

// Creates a Dispatch from a Dispatch starknet event data, which is:
// 0. (felt) sender address
// 1. (felt) destination chain id
// 2. (felt:low; felt:high) recipient address
// 3. message
//    a. header =>
//        - felt => version,
//        - felt => nonce,
//        - felt => origin,
//        - felt => sender_low,
//        - felt => sender_high,
//        - felt => destination,
//        - felt => recipient_low,
//        - felt => recipient_high,
//    b. body:
//        - felt => nbr data_feeds updated
//        - update (per data_feed) =>
//            - felt => asset_class
//            - felt => data_type (given it, we know update_size)
//            [depending on the asset_class <=> data_type tuple, update below...]
//            [for example for SpotMedian below]
//            - felt => pair_id
//            - felt => price
//            - felt => volume
//            - felt => decimals
//            - felt => timestamp
//            - felt => sources_aggregated
impl FromStarknetEventData for DispatchEvent {
    fn from_starknet_event_data(data: impl Iterator<Item = FieldElement>) -> Result<Self> {
        let mut data = data.into_iter();

        let sender = U256::from_words(
            u128::from_field_bytes(data.next().context("Missing sender part 1")?.to_bytes()),
            u128::from_field_bytes(data.next().context("Missing sender part 2")?.to_bytes()),
        );

        let destination_domain = u32::from_field_bytes(data.next().context("Missing destination")?.to_bytes());

        let recipient_address = U256::from_words(
            u128::from_field_bytes(data.next().context("Missing recipient part 1")?.to_bytes()),
            u128::from_field_bytes(data.next().context("Missing recipient part 2")?.to_bytes()),
        );

        let header = DispatchMessageHeader::from_starknet_event_data(&mut data.by_ref().take(HEADER_SIZE))?;
        let body = DispatchMessageBody::from_starknet_event_data(&mut data)?;
        let message = DispatchMessage { header, body };

        let dispatch = Self { sender, destination_domain, recipient_address, message };
        Ok(dispatch)
    }
}

impl DispatchEvent {
    pub fn format_message(&self) -> alloy_U256 {
        let mut input = Vec::new();
        
        // Formatting header part
        input.push(self.message.header.version);
        input.extend_from_slice(&self.message.header.nonce.to_be_bytes());
        input.extend_from_slice(&self.message.header.origin.to_be_bytes());
        input.extend_from_slice(&self.message.header.sender.low().to_be_bytes());
        input.extend_from_slice(&self.message.header.sender.high().to_be_bytes());
        input.extend_from_slice(&self.message.header.destination.to_be_bytes());
        input.extend_from_slice(&self.message.header.recipient.low().to_be_bytes());
        input.extend_from_slice(&self.message.header.recipient.high().to_be_bytes());

        // Formatting body part
        input.extend_from_slice(&self.message.body.nb_updated.to_be_bytes());

        for update in &self.message.body.updates {
            match update {
                DispatchUpdate::SpotMedian{feed_id:_, update:spot_update} => {
                    // Append pair_id (U256 split into high and low parts)
                    input.extend_from_slice(&spot_update.pair_id.low().to_be_bytes());
                    input.extend_from_slice(&spot_update.pair_id.high().to_be_bytes());

                    // Scale price by 10^decimals and convert to u128
                    let scaled_price = (spot_update.price.clone() * BigDecimal::from(10u32.pow(spot_update.metadata.decimals)))
                        .to_u128()
                        .unwrap_or(0);

                    // Append scaled price, volume, decimals, timestamp, and num_sources_aggregated
                    input.extend_from_slice(&scaled_price.to_be_bytes());
                    input.extend_from_slice(&spot_update.volume.to_be_bytes());
                    input.extend_from_slice(&spot_update.metadata.decimals.to_be_bytes());
                    input.extend_from_slice(&spot_update.metadata.timestamp.to_be_bytes());
                    input.extend_from_slice(&spot_update.metadata.num_sources_aggregated.to_be_bytes());
                }
            }
        }

        let hash = keccak256(&input);
        alloy_U256::from_be_bytes(<[u8; 32]>::try_from(hash.as_slice()).expect("Hash should be 32 bytes"))

    }
}

#[derive(Debug, Clone)]
#[allow(unused)]
pub struct DispatchMessage {
    pub header: DispatchMessageHeader,
    pub body: DispatchMessageBody,
}

const HEADER_SIZE: usize = 8;

#[derive(Debug, Clone)]
#[allow(unused)]
pub struct DispatchMessageHeader {
    pub version: u8,
    pub nonce: u32,
    pub origin: u32,
    pub sender: U256,
    pub destination: u32,
    pub recipient: U256,
}

impl FromStarknetEventData for DispatchMessageHeader {
    fn from_starknet_event_data(mut data: impl Iterator<Item = FieldElement>) -> Result<Self> {
        Ok(Self {
            version: u8::from_field_bytes(data.next().context("Missing version")?.to_bytes()),
            nonce: u32::from_field_bytes(data.next().context("Missing nonce")?.to_bytes()),
            origin: u32::from_field_bytes(data.next().context("Missing origin")?.to_bytes()),
            sender: U256::from_words(
                u128::from_field_bytes(data.next().context("Missing sender part 1")?.to_bytes()),
                u128::from_field_bytes(data.next().context("Missing sender part 2")?.to_bytes()),
            ),
            destination: u32::from_field_bytes(data.next().context("Missing destination")?.to_bytes()),
            recipient: U256::from_words(
                u128::from_field_bytes(data.next().context("Missing recipient part 1")?.to_bytes()),
                u128::from_field_bytes(data.next().context("Missing recipient part 2")?.to_bytes()),
            ),
        })
    }
}

#[derive(Debug, Clone)]
#[allow(unused)]
pub struct DispatchMessageBody {
    pub nb_updated: u32,
    pub updates: Vec<DispatchUpdate>,
}

impl FromStarknetEventData for DispatchMessageBody {
    fn from_starknet_event_data(mut data: impl Iterator<Item = FieldElement>) -> Result<Self> {
        let nb_updated = u32::from_field_bytes(data.next().context("Missing number of updates")?.to_bytes());

        let mut updates = Vec::with_capacity(nb_updated as usize);

        for _ in 0..nb_updated {
            let update = DispatchUpdate::from_starknet_event_data(&mut data).context("Failed to parse update")?;
            updates.push(update);
        }

        if updates.len() != nb_updated as usize {
            anyhow::bail!(
                "Mismatch between declared number of updates ({}) and actual updates parsed ({})",
                nb_updated,
                updates.len()
            );
        }

        Ok(Self { nb_updated, updates })
    }
}

#[derive(Debug, Clone)]
#[allow(unused)]
pub enum DispatchUpdate {
    SpotMedian {
        update: SpotMedianUpdate,
        feed_id: String,
    },
}

impl FromStarknetEventData for DispatchUpdate {
    fn from_starknet_event_data(mut data: impl Iterator<Item = FieldElement>) -> Result<Self> {
        // Asset class is always Crypto for now.
        let raw_asset_class = u8::from_field_bytes(data.next().context("Missing asset class")?.to_bytes());
        let asset_class = AssetClass::try_from(raw_asset_class)?;

        let raw_feed_type = u16::from_field_bytes(data.next().context("Missing data type")?.to_bytes());
        let feed_type = FeedType::try_from(raw_feed_type)?;

        let pair_id_low = u128::from_field_bytes(data.next().context("Missing pair ID part 1")?.to_bytes());
        let pair_id_high = u128::from_field_bytes(data.next().context("Missing pair ID part 2")?.to_bytes());

        // Create the feed ID string
        let mut bytes: Vec<u8> = Vec::with_capacity(35);
        bytes.push(raw_asset_class);
        bytes.extend_from_slice(&raw_feed_type.to_be_bytes());
        bytes.extend_from_slice(&pair_id_high.to_be_bytes());
        bytes.extend_from_slice(&pair_id_low.to_be_bytes());
        let feed_id = format!("0x{}", hex::encode(&bytes));

        let pair_id = U256::from_words(
            u128::from_field_bytes(data.next().context("Missing pair ID part 1")?.to_bytes()),
            u128::from_field_bytes(data.next().context("Missing pair ID part 2")?.to_bytes()),
        );

        let update = match feed_type {
            FeedType::SpotMedian => {
                let mut res = SpotMedianUpdate::from_starknet_event_data(&mut data)?;
                res.pair_id = pair_id;
                DispatchUpdate::SpotMedian{update: res, feed_id}
            }
            _ => unimplemented!("TODO: Implement the other updates"),
        };

        Ok(update)
    }
}



#[derive(Debug, Clone)]
pub struct MetadataUpdate {
    pub timestamp: u64,
    pub num_sources_aggregated: u32,
    pub decimals: u32,
}

#[derive(Debug, Clone)]
#[allow(unused)]
pub struct SpotMedianUpdate {
    pub pair_id: U256,
    pub metadata: MetadataUpdate,
    pub price: BigDecimal,
    pub volume: u128,
}

impl FromStarknetEventData for SpotMedianUpdate {
    fn from_starknet_event_data(mut data: impl Iterator<Item = FieldElement>) -> Result<Self> {

        let price_felt = data.next().context("Missing price")?;
        let volume = u128::from_field_bytes(data.next().context("Missing volume")?.to_bytes());
        let decimals = u32::from_field_bytes(data.next().context("Missing decimals")?.to_bytes());

        let price =
            BigDecimal::from(u128::from_field_bytes(price_felt.to_bytes())) / BigDecimal::from(10u32.pow(decimals));

        let timestamp = u64::from_field_bytes(data.next().context("Missing timestamp")?.to_bytes());
        let num_sources_aggregated =
            u32::from_field_bytes(data.next().context("Missing sources aggregated")?.to_bytes());

        // We set 0 for the pair_id, will be filled at the upper level
        Ok(Self { pair_id:  U256::from(0_u8), metadata: MetadataUpdate { decimals, timestamp, num_sources_aggregated }, price, volume })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use apibara_core::starknet::v1alpha2::FieldElement;

    fn create_field_element(value: u64) -> FieldElement {
        FieldElement::from_u64(value)
    }

    #[test]
    fn test_dispatch_event_from_event_data() {
        let event_data = vec![
            create_field_element(1),          // sender part 1
            create_field_element(0),          // sender part 2
            create_field_element(2),          // destination_domain
            create_field_element(3),          // recipient part 1
            create_field_element(0),          // recipient part 2
            create_field_element(1),          // version
            create_field_element(4),          // nonce
            create_field_element(5),          // origin
            create_field_element(6),          // sender part 1
            create_field_element(0),          // sender part 2
            create_field_element(7),          // destination
            create_field_element(8),          // recipient part 1
            create_field_element(0),          // recipient part 2
            create_field_element(1),          // nb_updated
            create_field_element(1),          // asset class (Crypto)
            create_field_element(21325),      // update type (SpotMedian)
            create_field_element(9),          // pair_id part 1
            create_field_element(0),          // pair_id part 2
            create_field_element(1000),       // price
            create_field_element(0),          // volume
            create_field_element(2),          // decimals
            create_field_element(1234567890), // timestamp
            create_field_element(5),          // num_sources_aggregated
        ];

        let dispatch_event = DispatchEvent::from_starknet_event_data(event_data.into_iter()).unwrap();

        assert_eq!(dispatch_event.sender, U256::from(1_u32));
        assert_eq!(dispatch_event.destination_domain, 2);
        assert_eq!(dispatch_event.recipient_address, U256::from(3_u32));

        let header = &dispatch_event.message.header;
        assert_eq!(header.version, 1);
        assert_eq!(header.nonce, 4);
        assert_eq!(header.origin, 5);
        assert_eq!(header.sender, U256::from(6_u32));
        assert_eq!(header.destination, 7);
        assert_eq!(header.recipient, U256::from(8_u32));

        let body = &dispatch_event.message.body;
        assert_eq!(body.nb_updated, 1);
        assert_eq!(body.updates.len(), 1);

        match &body.updates[0] {
            DispatchUpdate::SpotMedian{feed_id: _,update} => {
                assert_eq!(update.pair_id, U256::from(9_u32));
                assert_eq!(update.price, BigDecimal::from(10)); // 1000 / 10^2
                assert_eq!(update.volume, 0_u128);
                assert_eq!(update.metadata.decimals, 2);
                assert_eq!(update.metadata.timestamp, 1234567890);
                assert_eq!(update.metadata.num_sources_aggregated, 5);
            }
        }
    }

    #[test]
    fn test_dispatch_event_from_event_data_no_updates() {
        let event_data = vec![
            create_field_element(1), // sender part 1
            create_field_element(0), // sender part 2
            create_field_element(2), // destination_domain
            create_field_element(3), // recipient part 1
            create_field_element(0), // recipient part 2
            create_field_element(1), // version
            create_field_element(4), // nonce
            create_field_element(5), // origin
            create_field_element(6), // sender part 1
            create_field_element(0), // sender part 2
            create_field_element(7), // destination
            create_field_element(8), // recipient part 1
            create_field_element(0), // recipient part 2
            create_field_element(0), // nb_updated
        ];

        let dispatch_event = DispatchEvent::from_starknet_event_data(event_data.into_iter()).unwrap();

        assert_eq!(dispatch_event.sender, U256::from(1_u32));
        assert_eq!(dispatch_event.destination_domain, 2);
        assert_eq!(dispatch_event.recipient_address, U256::from(3_u32));

        let header = &dispatch_event.message.header;
        assert_eq!(header.version, 1);
        assert_eq!(header.nonce, 4);
        assert_eq!(header.origin, 5);
        assert_eq!(header.sender, U256::from(6_u32));
        assert_eq!(header.destination, 7);
        assert_eq!(header.recipient, U256::from(8_u32));

        let body = &dispatch_event.message.body;
        assert_eq!(body.nb_updated, 0);
        assert!(body.updates.is_empty());
    }
}
