use anyhow::{anyhow, Context, Result};
use apibara_core::starknet::v1alpha2::FieldElement;
use bigdecimal::BigDecimal;
use starknet::core::types::U256;

#[derive(Debug, Clone)]
pub struct Dispatch {
    sender: U256,
    destination_domain: u32,
    recipient_address: U256,
    message: Message,
}

impl Dispatch {
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
    pub fn from_event_data(_data: Vec<FieldElement>) -> Self {
        Self::default()
    }
}

#[derive(Debug, Clone)]
pub struct Message {
    header: MessageHeader,
    body: MessageBody,
}

#[derive(Debug, Clone)]
pub struct MessageHeader {
    version: u8,
    nonce: u32,
    origin: u32,
    sender: U256,
    destination: u32,
    recipient: U256,
}

#[derive(Debug, Clone)]
pub struct MessageBody {
    nb_updated: u32,
    updates: Vec<Update>,
}

#[derive(Debug, Clone)]
pub enum Update {
    Spot(SpotUpdate),
    Future(FutureUpdate),
}

impl Update {
    pub fn from_data_type(data_type: u8, _data: Vec<FieldElement>) -> Result<Self> {
        match data_type {
            0 => Ok(Update::Spot(SpotUpdate {
                feed_id: U256::from(0_u32),
                price: BigDecimal::from(0),
                decimals: 0,
                timestamp: 0,
                num_sources_aggregated: 0,
            })),
            1 => {
                // Parse data as FutureUpdate
                // This is a placeholder implementation
                Ok(Update::Future(FutureUpdate {
                    feed_id: U256::from(0_u32),
                    price: BigDecimal::from(0),
                    decimals: 0,
                    timestamp: 0,
                    expiration_timestamp: 0,
                    num_sources_aggregated: 0,
                }))
            }
            _ => Err(anyhow!("Invalid data type")),
        }
    }
}

#[derive(Debug, Clone)]
pub struct SpotUpdate {
    feed_id: U256,
    price: BigDecimal,
    decimals: u32,
    timestamp: i64,
    num_sources_aggregated: usize,
}

#[derive(Debug, Clone)]
pub struct FutureUpdate {
    feed_id: U256,
    price: BigDecimal,
    decimals: u32,
    timestamp: i64,
    expiration_timestamp: i64,
    num_sources_aggregated: usize,
}
