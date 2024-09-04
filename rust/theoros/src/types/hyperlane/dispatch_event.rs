use anyhow::{anyhow, Context, Result};
use apibara_core::starknet::v1alpha2::FieldElement;
use bigdecimal::BigDecimal;
use starknet::core::types::U256;

use pragma_utils::conversions::apibara::FromFieldBytes;

#[derive(Debug, Clone)]
#[allow(unused)]
pub struct DispatchEvent {
    pub sender: U256,
    pub destination_domain: u32,
    pub recipient_address: U256,
    pub message: DispatchMessage,
}

impl DispatchEvent {
    // Creates a Dispatch from a Dispatch Event data, which is:
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
    //            - felt => data_type (given it, we know update_size)
    //            - felt => ID
    //            - felt => price
    //            - felt => decimals
    //            - felt => timestamp
    //            - felt => sources_aggregated
    //            - IF FUTURE: felt => expiration_timestamp
    pub fn from_event_data(data: Vec<FieldElement>) -> Result<Self> {
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

        let header = DispatchMessageHeader::from_event_data(&mut data.by_ref().take(HEADER_SIZE))?;
        let body = DispatchMessageBody::from_event_data(&mut data)?;
        let message = DispatchMessage { header, body };

        let dispatch = Self { sender, destination_domain, recipient_address, message };
        Ok(dispatch)
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

impl DispatchMessageHeader {
    pub fn from_event_data(mut data: impl Iterator<Item = FieldElement>) -> Result<Self> {
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

impl DispatchMessageBody {
    pub fn from_event_data(mut data: impl Iterator<Item = FieldElement>) -> Result<Self> {
        let nb_updated = u32::from_field_bytes(data.next().context("Missing number of updates")?.to_bytes());

        let mut updates = Vec::with_capacity(nb_updated as usize);

        for _ in 0..nb_updated {
            let update = DispatchUpdate::from_event_data(&mut data).context("Failed to parse update")?;
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

#[derive(Debug, Clone, Copy)]
pub enum UpdateType {
    Spot = 0,
    Future = 1,
}

#[derive(Debug, Clone)]
#[allow(unused)]
pub enum DispatchUpdate {
    Spot(SpotUpdate),
    Future(FutureUpdate),
}

impl UpdateType {
    fn from_u8(value: u8) -> Result<Self> {
        match value {
            0 => Ok(UpdateType::Spot),
            1 => Ok(UpdateType::Future),
            _ => Err(anyhow!("Invalid update type: {}", value)),
        }
    }
}

impl DispatchUpdate {
    pub fn from_event_data(mut data: impl Iterator<Item = FieldElement>) -> Result<Self> {
        let data_type =
            UpdateType::from_u8(u8::from_field_bytes(data.next().context("Missing data type")?.to_bytes()))?;

        match data_type {
            UpdateType::Spot => Ok(DispatchUpdate::Spot(SpotUpdate::from_event_data(&mut data)?)),
            UpdateType::Future => Ok(DispatchUpdate::Future(FutureUpdate::from_event_data(&mut data)?)),
        }
    }
}

#[derive(Debug, Clone)]
#[allow(unused)]
pub struct SpotUpdate {
    pub feed_id: U256,
    pub price: BigDecimal,
    pub decimals: u32,
    pub timestamp: u64,
    pub num_sources_aggregated: u32,
}

impl SpotUpdate {
    pub fn from_event_data(mut data: impl Iterator<Item = FieldElement>) -> Result<Self> {
        let feed_id = U256::from_words(
            u128::from_field_bytes(data.next().context("Missing feed ID part 1")?.to_bytes()),
            u128::from_field_bytes(data.next().context("Missing feed ID part 2")?.to_bytes()),
        );

        let price_felt = data.next().context("Missing price")?;
        let decimals = u32::from_field_bytes(data.next().context("Missing decimals")?.to_bytes());
        let price =
            BigDecimal::from(u128::from_field_bytes(price_felt.to_bytes())) / BigDecimal::from(10u32.pow(decimals));

        let timestamp = u64::from_field_bytes(data.next().context("Missing timestamp")?.to_bytes());
        let num_sources_aggregated =
            u32::from_field_bytes(data.next().context("Missing sources aggregated")?.to_bytes());

        Ok(Self { feed_id, price, decimals, timestamp, num_sources_aggregated })
    }
}

#[derive(Debug, Clone)]
#[allow(unused)]
pub struct FutureUpdate {
    pub feed_id: U256,
    pub price: BigDecimal,
    pub decimals: u32,
    pub timestamp: u64,
    pub expiration_timestamp: u64,
    pub num_sources_aggregated: u32,
}

impl FutureUpdate {
    pub fn from_event_data(mut data: impl Iterator<Item = FieldElement>) -> Result<Self> {
        let feed_id = U256::from_words(
            u128::from_field_bytes(data.next().context("Missing feed ID part 1")?.to_bytes()),
            u128::from_field_bytes(data.next().context("Missing feed ID part 2")?.to_bytes()),
        );

        let price_felt = data.next().context("Missing price")?;
        let decimals = u32::from_field_bytes(data.next().context("Missing decimals")?.to_bytes());
        let price =
            BigDecimal::from(u128::from_field_bytes(price_felt.to_bytes())) / BigDecimal::from(10u32.pow(decimals));

        let timestamp = u64::from_field_bytes(data.next().context("Missing timestamp")?.to_bytes());
        let num_sources_aggregated =
            u32::from_field_bytes(data.next().context("Missing sources aggregated")?.to_bytes());
        let expiration_timestamp =
            u64::from_field_bytes(data.next().context("Missing expiration timestamp")?.to_bytes());

        Ok(Self { feed_id, price, decimals, timestamp, expiration_timestamp, num_sources_aggregated })
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
            create_field_element(0),          // update type (Spot)
            create_field_element(9),          // feed_id part 1
            create_field_element(0),          // feed_id part 2
            create_field_element(1000),       // price
            create_field_element(2),          // decimals
            create_field_element(1234567890), // timestamp
            create_field_element(5),          // num_sources_aggregated
        ];

        let dispatch_event = DispatchEvent::from_event_data(event_data).unwrap();

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
            DispatchUpdate::Spot(update) => {
                assert_eq!(update.feed_id, U256::from(9_u32));
                assert_eq!(update.price, BigDecimal::from(10)); // 1000 / 10^2
                assert_eq!(update.decimals, 2);
                assert_eq!(update.timestamp, 1234567890);
                assert_eq!(update.num_sources_aggregated, 5);
            }
            DispatchUpdate::Future(_) => panic!("Expected Spot update"),
        }
    }

    #[test]
    fn test_dispatch_message_header_from_event_data() {
        let header_data = vec![
            create_field_element(1), // version
            create_field_element(2), // nonce
            create_field_element(3), // origin
            create_field_element(4), // sender part 1
            create_field_element(0), // sender part 2
            create_field_element(5), // destination
            create_field_element(6), // recipient part 1
            create_field_element(0), // recipient part 2
        ];

        let header = DispatchMessageHeader::from_event_data(header_data.into_iter()).unwrap();

        assert_eq!(header.version, 1);
        assert_eq!(header.nonce, 2);
        assert_eq!(header.origin, 3);
        assert_eq!(header.sender, U256::from(4_u32));
        assert_eq!(header.destination, 5);
        assert_eq!(header.recipient, U256::from(6_u32));
    }

    #[test]
    fn test_dispatch_message_body_from_event_data() {
        let body_data = vec![
            create_field_element(2),          // nb_updated
            create_field_element(0),          // update type (Spot)
            create_field_element(1),          // feed_id part 1
            create_field_element(0),          // feed_id part 2
            create_field_element(1000),       // price
            create_field_element(2),          // decimals
            create_field_element(1234567890), // timestamp
            create_field_element(5),          // num_sources_aggregated
            create_field_element(1),          // update type (Future)
            create_field_element(2),          // feed_id part 1
            create_field_element(0),          // feed_id part 2
            create_field_element(2000),       // price
            create_field_element(3),          // decimals
            create_field_element(1234567891), // timestamp
            create_field_element(6),          // num_sources_aggregated
            create_field_element(1234567892), // expiration_timestamp
        ];

        let body = DispatchMessageBody::from_event_data(body_data.into_iter()).unwrap();

        assert_eq!(body.nb_updated, 2);
        assert_eq!(body.updates.len(), 2);

        match &body.updates[0] {
            DispatchUpdate::Spot(update) => {
                assert_eq!(update.feed_id, U256::from(1_u32));
                assert_eq!(update.price, BigDecimal::from(10)); // 1000 / 10^2
                assert_eq!(update.decimals, 2);
                assert_eq!(update.timestamp, 1234567890);
                assert_eq!(update.num_sources_aggregated, 5);
            }
            DispatchUpdate::Future(_) => panic!("Expected Spot update"),
        }

        match &body.updates[1] {
            DispatchUpdate::Future(update) => {
                assert_eq!(update.feed_id, U256::from(2_u32));
                assert_eq!(update.price, BigDecimal::from(2)); // 2000 / 10^3
                assert_eq!(update.decimals, 3);
                assert_eq!(update.timestamp, 1234567891);
                assert_eq!(update.num_sources_aggregated, 6);
                assert_eq!(update.expiration_timestamp, 1234567892);
            }
            DispatchUpdate::Spot(_) => panic!("Expected Future update"),
        }
    }

    #[test]
    fn test_update_from_event_data() {
        let spot_data = vec![
            create_field_element(0),          // update type (Spot)
            create_field_element(1),          // feed_id part 1
            create_field_element(0),          // feed_id part 2
            create_field_element(1000),       // price
            create_field_element(2),          // decimals
            create_field_element(1234567890), // timestamp
            create_field_element(5),          // num_sources_aggregated
        ];

        let future_data = vec![
            create_field_element(1),          // update type (Future)
            create_field_element(2),          // feed_id part 1
            create_field_element(0),          // feed_id part 2
            create_field_element(2000),       // price
            create_field_element(3),          // decimals
            create_field_element(1234567891), // timestamp
            create_field_element(6),          // num_sources_aggregated
            create_field_element(1234567892), // expiration_timestamp
        ];

        let spot_update = DispatchUpdate::from_event_data(spot_data.into_iter()).unwrap();
        let future_update = DispatchUpdate::from_event_data(future_data.into_iter()).unwrap();

        match spot_update {
            DispatchUpdate::Spot(update) => {
                assert_eq!(update.feed_id, U256::from(1_u32));
                assert_eq!(update.price, BigDecimal::from(10)); // 1000 / 10^2
                assert_eq!(update.decimals, 2);
                assert_eq!(update.timestamp, 1234567890);
                assert_eq!(update.num_sources_aggregated, 5);
            }
            DispatchUpdate::Future(_) => panic!("Expected Spot update"),
        }

        match future_update {
            DispatchUpdate::Future(update) => {
                assert_eq!(update.feed_id, U256::from(2_u32));
                assert_eq!(update.price, BigDecimal::from(2)); // 2000 / 10^3
                assert_eq!(update.decimals, 3);
                assert_eq!(update.timestamp, 1234567891);
                assert_eq!(update.num_sources_aggregated, 6);
                assert_eq!(update.expiration_timestamp, 1234567892);
            }
            DispatchUpdate::Spot(_) => panic!("Expected Future update"),
        }
    }
}
