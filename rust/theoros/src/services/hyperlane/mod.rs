use std::{sync::Arc, time::Duration};

use starknet::core::types::Felt;
use tokio::task::JoinSet;

use pragma_utils::{conversions::alloy::hex_str_to_u256, services::Service};

use crate::storage::TheorosStorage;
use crate::types::hyperlane::{
    DispatchUpdateInfos, FetchFromStorage, NewUpdatesAvailableEvent, SignedCheckpointWithMessageId,
};

const FETCH_INTERVAL: Duration = Duration::from_secs(1);

#[derive(Clone)]
pub struct HyperlaneService {
    storage: Arc<TheorosStorage>,
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
    pub fn new(storage: Arc<TheorosStorage>) -> Self {
        Self { storage }
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
        let validators_fetchers = self.storage.validators_fetchers().all().await;
        let unsigned_nonces = self.storage.unsigned_checkpoints().nonces().await;

        if unsigned_nonces.is_empty() {
            return;
        }

        for &nonce in &unsigned_nonces {
            let mut any_signed = false;
            let mut futures = Vec::new();

            for (validator, fetcher) in &validators_fetchers {
                let fut = self.try_fetch_signed_checkpoint(*validator, fetcher.clone(), nonce);
                futures.push(fut);
            }

            let results = futures::future::join_all(futures).await;

            // Check if any validator has signed this nonce
            for signed in results.into_iter().flatten() {
                if signed {
                    any_signed = true;
                }
            }

            if any_signed {
                if let Err(e) = self.store_event_updates(nonce).await {
                    tracing::error!("Failed to store event updates for nonce {}: {:?}", nonce, e);
                }
                self.storage.unsigned_checkpoints().remove(nonce).await;
            } else {
                // If none of the validators have signed this nonce,
                // we can skip processing higher nonces for now
                break;
            }
        }
    }

    /// Checks if a nonce has been signed by the validator by querying its fetcher.
    /// Returns true if signed, else false.
    async fn try_fetch_signed_checkpoint(
        &self,
        validator: Felt,
        fetcher: Arc<Box<dyn FetchFromStorage>>,
        nonce: u32,
    ) -> anyhow::Result<bool> {
        if self.storage.signed_checkpoints().exists(validator, nonce).await {
            return Ok(true);
        }

        match fetcher.fetch(nonce).await {
            Ok(Some(checkpoint)) => {
                self.store_signed_checkpoint(validator, checkpoint).await?;
                Ok(true)
            }
            Ok(None) => {
                tracing::debug!("🌉 [Hyperlane] Checkpoint #{} not yet signed for validator {:#x}", nonce, validator,);
                Ok(false)
            }
            Err(e) => {
                tracing::error!(
                    "🌉 [Hyperlane] Failed to fetch checkpoint #{} for validator {:#x}: {:?}",
                    nonce,
                    validator,
                    e
                );
                Ok(false)
            }
        }
    }

    async fn store_signed_checkpoint(
        &self,
        validator: Felt,
        checkpoint: SignedCheckpointWithMessageId,
    ) -> anyhow::Result<()> {
        let nonce = checkpoint.value.checkpoint.index;

        if self.storage.signed_checkpoints().exists(validator, nonce).await {
            tracing::debug!(
                "🌉 [Hyperlane] Skipping already signed checkpoint #{} for validator {:#x}",
                nonce,
                validator
            );
            return Ok(());
        }

        tracing::info!("🌉 [Hyperlane] Validator {:#x} signed the checkpoint with nonce #{}", validator, nonce);
        self.storage.signed_checkpoints().add(validator, nonce, checkpoint).await?;
        Ok(())
    }

    async fn store_event_updates(&self, nonce: u32) -> anyhow::Result<()> {
        let event = match self.storage.unsigned_checkpoints().get(nonce).await {
            Some(e) => e,
            None => {
                tracing::error!("Event not found for nonce {}", nonce);
                return Ok(());
            }
        };
        for update in event.message.body.updates.iter() {
            let feed_id = update.feed_id();
            let feed_id = hex_str_to_u256(&feed_id)?;
            let dispatch_update_infos = DispatchUpdateInfos::new(&event, update);
            self.storage.latest_update_per_feed().add(feed_id, dispatch_update_infos).await?;
        }
        let _ = self.storage.feeds_updated_tx().send(NewUpdatesAvailableEvent::New);
        Ok(())
    }
}
