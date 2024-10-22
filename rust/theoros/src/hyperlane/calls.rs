use alloy::network::Ethereum;
use alloy::primitives::Address;
use alloy::providers::fillers::{ChainIdFiller, FillProvider, GasFiller, JoinFill, NonceFiller};
use alloy::providers::{Identity, ProviderBuilder, RootProvider};
use alloy::transports::http::{Client, Http};
use alloy::{providers::fillers::BlobGasFiller, sol};
use anyhow::Result;
use pragma_utils::bytes::pad_to_32_bytes;
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

pub struct HyperlaneClient(HyperlaneContract);

impl HyperlaneClient {
    pub async fn new(contract_address: Address) -> Result<Self> {
        let rpc_url: Url = "https://zircuit1-testnet.p2pify.com".parse()?;
        let provider = ProviderBuilder::new().with_recommended_fillers().on_http(rpc_url);
        let hyperlane_client = IHyperlane::new(contract_address, provider);
        Ok(Self(hyperlane_client))
    }

    pub async fn get_validators(&self) -> Result<Vec<Felt>> {
        let mut validators = Vec::new();
        let mut index = 0;

        while let Ok(address) = self.0._validators(index.try_into()?).call().await {
            if address._0 == Address::ZERO {
                break;
            }
            validators.push(Felt::from_bytes_be(&pad_to_32_bytes(&address._0.into_array())));
            index += 1;
        }

        Ok(validators)
    }
}
