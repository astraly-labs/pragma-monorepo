use std::{sync::Arc, time::Duration};

use pragma_utils::services::Service;
use starknet::core::types::Felt;
use tokio::task::JoinSet;

use crate::{
    types::hyperlane::{FetchFromStorage, SignedCheckpointWithMessageId},
    AppState,
};

const FETCH_INTERVAL: Duration = Duration::from_secs(2);

#[derive(Clone)]
pub struct HyperlaneService {
    state: AppState,
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
    pub fn new(state: AppState) -> Self {
        Self { state }
    }

    /// Every [FETCH_INTERVAL] seconds, fetch the latest checkpoint signed for all
    /// registered validators.
    pub async fn run_forever(&self) -> anyhow::Result<()> {
        loop {
            self.process_validator_checkpoints().await;
            tokio::time::sleep(FETCH_INTERVAL).await;
        }
    }

    async fn process_validator_checkpoints(&self) {
        let validators_locations = self.state.storage.validators_locations().all().await;
        let futures = validators_locations
            .into_iter()
            .map(|(validator, fetcher)| self.process_single_validator(validator, fetcher));

        futures::future::join_all(futures).await;
    }

    async fn process_single_validator(&self, validator: Felt, fetcher: Arc<Box<dyn FetchFromStorage>>) {
        match fetcher.fetch_latest().await {
            Ok(Some(checkpoint)) => self.handle_checkpoint(validator, checkpoint).await,
            Ok(None) => {
                tracing::debug!("🌉 [Hyperlane] No new checkpoint for validator {:#x}", validator)
            }
            Err(e) => {
                tracing::error!("🌉 [Hyperlane] Failed to fetch checkpoint for validator {:#x}: {:?}", validator, e)
            }
        }
    }

    async fn handle_checkpoint(&self, validator: Felt, checkpoint: SignedCheckpointWithMessageId) {
        let message_id = checkpoint.value.message_id;

        if self.state.storage.validators_checkpoints().exists(validator, message_id).await {
            tracing::debug!(
                "🌉 [Hyperlane] Skipping duplicate checkpoint for validator {:#x}: {:#x}",
                validator,
                message_id
            );
            return;
        }

        tracing::info!(
            "🌉 [Hyperlane] Validator {:#x} retrieved latest checkpoint for message [#{}] {:#x}",
            validator,
            checkpoint.value.checkpoint.index,
            message_id
        );
        if let Err(e) = self.state.storage.validators_checkpoints().add(validator, message_id, checkpoint).await {
            tracing::error!("🌉 [Hyperlane] Failed to store checkpoint for validator {:#x}: {:?}", validator, e);
        }
    }
}
