use std::collections::HashMap;

use alloy::network::Ethereum;
use alloy::primitives::Address;
use alloy::providers::fillers::{ChainIdFiller, FillProvider, GasFiller, JoinFill, NonceFiller};
use alloy::providers::{Identity, ProviderBuilder, RootProvider};
use alloy::transports::http::{Client, Http};
use alloy::{providers::fillers::BlobGasFiller, sol};
use anyhow::Result;
use pragma_utils::bytes::pad_left_to_32_bytes;
use starknet::core::types::Felt;
use url::Url;

sol! {
    #[sol(rpc)]
    interface IHyperlane {
        function _validators(uint256) external view returns (address);
    }
}

pub type HyperlaneContract = IHyperlane::IHyperlaneInstance<
    Http<Client>,
    FillProvider<
        JoinFill<Identity, JoinFill<GasFiller, JoinFill<BlobGasFiller, JoinFill<NonceFiller, ChainIdFiller>>>>,
        RootProvider<Http<Client>>,
        Http<Client>,
        Ethereum,
    >,
>;

#[derive(Debug, Clone)]
pub struct HyperlaneClient(HyperlaneContract);

impl HyperlaneClient {
    pub async fn new(rpc_url: Url, contract_address: Address) -> Self {
        let provider = ProviderBuilder::new().with_recommended_fillers().on_http(rpc_url);
        let hyperlane_client = IHyperlane::new(contract_address, provider);
        Self(hyperlane_client)
    }

    pub async fn get_validators(&self) -> Result<HashMap<Felt, u8>> {
        let mut validators = HashMap::new();
        let mut index = 0;

        while let Ok(address) = self.0._validators(index.try_into()?).call().await {
            if address._0 == Address::ZERO {
                break;
            }
            let validator = Felt::from_bytes_be(&pad_left_to_32_bytes(&address._0.into_array()));
            validators.insert(validator, index);
            index += 1;
        }

        Ok(validators)
    }
}
