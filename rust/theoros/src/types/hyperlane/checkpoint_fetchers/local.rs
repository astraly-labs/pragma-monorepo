// Source:
// https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/3e90734310fb1ca9a607ce3d334015fa7aaa9208/rust/hyperlane-base/src/types/local_storage.rs#L51
use std::path::PathBuf;

use anyhow::{Context, Result};
use async_trait::async_trait;

use crate::types::hyperlane::{FetchFromStorage, SignedCheckpointWithMessageId};

#[derive(Debug, Clone)]
/// Type for reading/write to LocalStorage
pub struct LocalStorage {
    path: PathBuf,
}

impl LocalStorage {
    pub fn new(path: PathBuf) -> Result<Self> {
        if !path.exists() {
            std::fs::create_dir_all(&path).with_context(|| {
                format!("Failed to create local checkpoint fetcher storage directory at {:?}", path)
            })?;
        }
        Ok(Self { path })
    }

    fn checkpoint_file_path(&self, index: u32) -> PathBuf {
        self.path.join(format!("{}_with_id.json", index))
    }

    fn latest_checkpoint_file_path(&self) -> PathBuf {
        self.path.join("index.json")
    }
}

#[async_trait]
impl FetchFromStorage for LocalStorage {
    async fn fetch(&self, index: u32) -> Result<Option<SignedCheckpointWithMessageId>> {
        let Ok(data) = tokio::fs::read(self.checkpoint_file_path(index)).await else {
            return Ok(None);
        };
        let checkpoint = serde_json::from_slice(&data)?;
        Ok(Some(checkpoint))
    }

    async fn fetch_latest(&self) -> Result<Option<SignedCheckpointWithMessageId>> {
        let latest_index = serde_json::from_slice(&tokio::fs::read(self.latest_checkpoint_file_path()).await?)?;
        let Ok(data) = tokio::fs::read(self.checkpoint_file_path(latest_index)).await else {
            return Ok(None);
        };
        let checkpoint = serde_json::from_slice(&data)?;
        Ok(Some(checkpoint))
    }

    fn announcement_location(&self) -> String {
        format!("file://{}", self.path.to_str().unwrap())
    }
}
