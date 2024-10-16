use anyhow::Context;
use apibara_core::starknet::v1alpha2::FieldElement;
use starknet::core::types::{EthAddress, Felt};

use pragma_utils::conversions::{apibara::apibara_field_as_felt, starknet::FeltVecToString};

use super::FromStarknetEventData;

#[derive(Debug, Clone)]
#[allow(unused)]
pub struct ValidatorAnnouncementEvent {
    pub validator: EthAddress,
    pub storage_location: String,
}

impl FromStarknetEventData for ValidatorAnnouncementEvent {
    fn from_starknet_event_data(data: Vec<Felt>) -> anyhow::Result<Self> {
        let mut data = data.iter();
        let validator = &data.next().context("Missing validator")?;
        let validator = EthAddress::from_felt(&validator).context("Invalid validator ETH address")?;

        let storage_location: String = data.cloned().collect::<Vec<Felt>>().to_string();

        let new_event = Self { validator, storage_location };
        Ok(new_event)
    }
}
