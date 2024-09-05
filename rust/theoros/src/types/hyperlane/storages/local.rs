use std::path::PathBuf;

use anyhow::{Context, Result};
use async_trait::async_trait;
use prometheus::IntGauge;

use crate::types::{CheckpointFetcher, CheckpointWithMessageId};

#[allow(unused)]
#[derive(Debug, Clone)]
/// Type for reading/write to LocalStorage
pub struct LocalStorage {
    /// base path
    path: PathBuf,
    latest_index: Option<IntGauge>,
}

#[allow(unused)]
impl LocalStorage {
    pub fn new(path: PathBuf, latest_index: Option<IntGauge>) -> Result<Self> {
        if !path.exists() {
            std::fs::create_dir_all(&path).with_context(|| {
                format!("Failed to create local checkpoint fetcher storage directory at {:?}", path)
            })?;
        }
        Ok(Self { path, latest_index })
    }

    fn checkpoint_file_path(&self, index: u32) -> PathBuf {
        self.path.join(format!("{}_with_id.json", index))
    }
}

#[async_trait]
impl CheckpointFetcher for LocalStorage {
    async fn fetch(&self, index: u32) -> Result<Option<CheckpointWithMessageId>> {
        let Ok(data) = tokio::fs::read(self.checkpoint_file_path(index)).await else {
            return Ok(None);
        };
        let checkpoint = serde_json::from_slice(&data)?;
        Ok(Some(checkpoint))
    }

    fn announcement_location(&self) -> String {
        format!("file://{}", self.path.to_str().unwrap())
    }
}
