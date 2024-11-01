use std::collections::HashMap;
use std::{sync::Arc, time::Duration};

use starknet::core::types::Felt;
use tokio::task::JoinSet;

use pragma_utils::{conversions::alloy::hex_str_to_u256, services::Service};

use crate::storage::TheorosStorage;
use crate::types::hyperlane::{
    DispatchUpdateInfos, FetchFromStorage, NewUpdatesAvailableEvent, SignedCheckpointWithMessageId,
};

/// Every [FETCH_INTERVAL] seconds, we check the pending checkpoints for all validators.
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

    /// Processes validator checkpoints by fetching signed checkpoints from all validators for each unsigned nonce.
    ///
    /// This function performs the following steps:
    ///
    /// 1. **Retrieve Unsigned Nonces**: Fetches all the nonces currently stored in the `UnsignedCheckpointsStorage`.
    ///    - If there are no unsigned nonces, the function returns early.
    ///
    /// 2. **Retrieve Validators and Fetchers**: Gets all registered validators and their corresponding fetchers from the `ValidatorsFetchersStorage`.
    ///
    /// 3. **Fetch Signed Checkpoints**:
    ///    - Iterates over each unsigned nonce.
    ///    - For each nonce, it iterates over all validators.
    ///    - Attempts to fetch the signed checkpoint for the given nonce from each validator's fetcher.
    ///    - These fetch attempts are spawned as asynchronous tasks and collected into a `futures` vector.
    ///    - Waits for all fetch tasks to complete using `futures::future::join_all(futures).await`.
    ///
    /// 4. **Process Completed Nonces**:
    ///    - After all fetches are completed, iterates over the unsigned nonces again.
    ///    - Checks if all validators have signed the nonce using the `all_validators_signed_nonce` method.
    ///    - **Note**: Currently, the function only proceeds if **all** validators have signed the nonce.
    ///      - There's a `TODO` to modify this behavior to use a quorum method (e.g., consider a nonce as valid if 66% of validators have signed it).
    ///    - If all validators have signed the nonce:
    ///        - Calls `store_event_updates(nonce)` to process and store the updates associated with that nonce.
    ///        - Removes the nonce from the `UnsignedCheckpointsStorage`, as it has been fully processed.
    ///
    /// **Behavior Summary**:
    /// - The function ensures that for every unsigned nonce, it collects signed checkpoints from all validators.
    /// - Only when a nonce has been signed by all validators does it proceed to process the associated updates.
    /// - This mechanism ensures data consistency and integrity by waiting for consensus among validators.
    async fn process_validator_checkpoints(&self) {
        let unsigned_nonces = self.storage.unsigned_checkpoints().nonces().await;
        if unsigned_nonces.is_empty() {
            return;
        }

        let validators_fetchers = self.storage.validators_fetchers().all().await;
        let mut futures = Vec::new();
        for &nonce in &unsigned_nonces {
            for (validator, fetcher) in &validators_fetchers {
                let fut = self.process_single_validator_nonce(*validator, fetcher.clone(), nonce);
                futures.push(fut);
            }
        }
        futures::future::join_all(futures).await;

        // NOTE: At the moment, we only process updates when ALL validators have signed a message.
        // TODO: We should instead use a quorum method - if 66% have signed, consider it ok.
        for &nonce in &unsigned_nonces {
            if self.all_validators_signed_nonce(&validators_fetchers, nonce).await {
                if let Err(e) = self.store_event_updates(nonce).await {
                    tracing::error!("😱 Failed to store event updates for nonce {}: {:?}", nonce, e);
                }
                self.storage.unsigned_checkpoints().remove(nonce).await;
            }
        }
    }

    /// Checks if all validators have signed a given nonce.
    async fn all_validators_signed_nonce(
        &self,
        validators_fetchers: &HashMap<Felt, Arc<Box<dyn FetchFromStorage>>>,
        nonce: u32,
    ) -> bool {
        let validators: Vec<Felt> = validators_fetchers.keys().cloned().collect();
        self.storage.signed_checkpoints().all_validators_signed_nonce(&validators, nonce).await
    }

    async fn process_single_validator_nonce(
        &self,
        validator: Felt,
        fetcher: Arc<Box<dyn FetchFromStorage>>,
        nonce: u32,
    ) -> anyhow::Result<()> {
        // If the validator already signed this nonce, ignore
        if self.storage.signed_checkpoints().validator_signed_nonce(validator, nonce).await {
            return Ok(());
        }

        match fetcher.fetch(nonce).await {
            Ok(Some(checkpoint)) => {
                self.store_signed_checkpoint(validator, checkpoint).await?;
            }
            Ok(None) => {
                tracing::debug!("🌉 [Hyperlane] Validator {:#x} has not yet signed nonce {}", validator, nonce);
            }
            Err(e) => {
                tracing::error!(
                    "🌉 [Hyperlane] Failed to fetch checkpoint for validator {:#x} and nonce {}: {:?}",
                    validator,
                    nonce,
                    e
                );
            }
        }
        Ok(())
    }

    /// Store the signed checkpoint for the validator ; nonce couple.
    async fn store_signed_checkpoint(
        &self,
        validator: Felt,
        checkpoint: SignedCheckpointWithMessageId,
    ) -> anyhow::Result<()> {
        let nonce = checkpoint.value.checkpoint.index;

        if self.storage.signed_checkpoints().validator_signed_nonce(validator, nonce).await {
            tracing::debug!("🌉 [Hyperlane] Skipping duplicate checkpoint for validator {:#x}: #{}", validator, nonce);
            return Ok(());
        }

        tracing::info!("🌉 [Hyperlane] Validator {:#x} signed checkpoint #{}", validator, nonce);
        self.storage.signed_checkpoints().add(validator, nonce, checkpoint).await?;

        Ok(())
    }

    /// Stores the event updates once it has been signed.
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

        // Send websocket notification
        match self.storage.feeds_updated_tx().send(NewUpdatesAvailableEvent::New) {
            Ok(_) => {
                tracing::debug!("🕸️ [Websocket] 🔔 Successfully sent websocket notification");
            }
            Err(e) => {
                // Only log as debug since this is expected when there are no subscribers
                tracing::debug!("🕸️ [Websocket] 📪 No active websocket subscribers to receive notification: {}", e);
            }
        }

        Ok(())
    }
}
