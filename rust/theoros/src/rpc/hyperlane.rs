use starknet::core::types::Felt;

#[async_trait::async_trait]
pub trait HyperlaneCalls {
    /// Retrieves the announced storage locations as a [Vec<String>] from the
    /// hyperlane core contract.
    /// The strings are all storage locations path.
    async fn get_announced_storage_locations(
        &self,
        hyperlane_core_address: &Felt,
        validators: &[Felt],
    ) -> anyhow::Result<Vec<String>>;

    /// Retrieves all the announced validators as a [Vec<Felt>] from the hyperlane
    /// core contract.
    /// The felts are validators addresses.
    async fn get_announced_validators(&self, hyperlane_core_address: &Felt) -> anyhow::Result<Vec<Felt>>;
}
