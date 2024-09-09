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
    fn from_starknet_event_data(mut data: impl Iterator<Item = FieldElement>) -> anyhow::Result<Self> {
        let validator_as_felt = apibara_field_as_felt(&data.next().context("Missing validator")?);
        let validator = EthAddress::from_felt(&validator_as_felt).context("Invalid validator ETH address")?;

        let storage_location_felts: Vec<Felt> = data.map(|f| apibara_field_as_felt(&f)).collect();
        let storage_location = storage_location_felts.to_string();

        let new_event = Self { validator, storage_location };
        Ok(new_event)
    }
}
