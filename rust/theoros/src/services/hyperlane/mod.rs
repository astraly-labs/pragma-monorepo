use pragma_utils::services::Service;
use starknet::core::types::Felt;
use tokio::task::JoinSet;

use crate::rpc::starknet::hyperlane::HyperlaneCalls;
use crate::AppState;

#[derive(Clone)]
pub struct HyperlaneService {
    state: AppState,
    merkle_tree_hook_address: Felt,
}

#[async_trait::async_trait]
impl Service for HyperlaneService {
    async fn start(&mut self, join_set: &mut JoinSet<anyhow::Result<()>>) -> anyhow::Result<()> {
        let service = self.clone();
        join_set.spawn(async move {
            tracing::info!("🧩 Hyperlane service started");
            service.run_forever().await?;
            Ok(())
        });
        Ok(())
    }
}

impl HyperlaneService {
    pub fn new(state: AppState, merkle_tree_hook_address: Felt) -> Self {
        Self { state, merkle_tree_hook_address }
    }

    pub async fn run_forever(&self) -> anyhow::Result<()> {
        loop {
            let storage = self.state.storage.validators().all().await;
            for (validator, checkpoint) in storage {
                tracing::debug!("Validator: {:?} - Storage: {:?}", validator, checkpoint);
                let index = self.get_latest_index().await?;
                let fetcher = checkpoint.build().await?;
                let value = fetcher.fetch(index).await?;

                if let Some(checkpoint_value) = value {
                    tracing::info!("Retrieved latest checkpoint with hash: {:?}", checkpoint_value.value.message_id);
                    self.state
                        .storage
                        .checkpoints()
                        .add(validator, checkpoint_value.value.message_id, checkpoint_value)
                        .await?;
                } else {
                    tracing::debug!("No checkpoint value found");
                }
            }
        }
    }

    pub async fn get_latest_index(&self) -> anyhow::Result<u32> {
        let latest_checkpoint = self.state.rpc_client.get_latest_checkpoint(&self.merkle_tree_hook_address).await?;
        Ok(latest_checkpoint[2].to_biguint().to_u32_digits()[0])
    }
}
