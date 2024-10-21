use std::sync::Arc;

use anyhow::Result;
use ethers::{
    contract::abigen,
    providers::{Http, Provider},
    types::Address,
};
use starknet::core::types::Felt;

// TODO: Use
abigen!(
    IHyperlane,
    r#"[
        function _validators(uint256) external view returns (address)
    ]"#,
);

pub struct HyperlaneClient {
    pub contract: IHyperlane<Provider<Http>>,
}

impl HyperlaneClient {
    pub async fn new(contract_address: Address) -> Result<Self> {
        let rpc_url = "https://zircuit1-testnet.p2pify.com".to_string();
        let provider: Provider<Http> = Provider::<Http>::try_from(rpc_url)?;
        let provider = Arc::new(provider);
        let contract = IHyperlane::new(contract_address, provider);

        Ok(Self { contract })
    }

    pub async fn get_validators(&self) -> Result<Vec<Felt>> {
        let mut validators = Vec::new();
        let mut index = 0;

        while let Ok(address) = self.contract.validators(index.into()).call().await {
            if address == Address::zero() {
                break;
            }
            validators.push(Felt::from_bytes_be(&pad_to_32_bytes(address.as_bytes())));
            index += 1;
        }

        Ok(validators)
    }
}

fn pad_to_32_bytes(input: &[u8]) -> [u8; 32] {
    let mut result = [0u8; 32];
    result[32 - input.len()..].copy_from_slice(input);
    result
}
