use std::time::Duration;

use pragma_utils::services::Service;
use tokio::task::JoinSet;

use crate::AppState;

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

    pub async fn run_forever(&self) -> anyhow::Result<()> {
        loop {
            let storage = self.state.storage.validators().all().await;
            for (validator, checkpoint) in storage {
                let fetcher = checkpoint.build().await?;
                let value = fetcher.fetch_latest().await?;

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
            tokio::time::sleep(Duration::from_secs(1)).await;
        }
    }
}
