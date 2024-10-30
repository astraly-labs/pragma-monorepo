pub mod gcs;
pub mod local;
pub mod s3;

// Source:
// https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/3e90734310fb1ca9a607ce3d334015fa7aaa9208/rust/hyperlane-base/src/settings/checkpoint_syncer.rs#L14

use std::fmt::Debug;
use std::{env, path::PathBuf};

use anyhow::{anyhow, bail, Context, Error, Result};
use async_trait::async_trait;
use core::str::FromStr;
use rusoto_core::Region;
use ya_gcp::{AuthFlow, ServiceAccountAuth};

use crate::types::hyperlane::{
    gcs::{GcsStorageClientBuilder, GCS_SERVICE_ACCOUNT_KEY, GCS_USER_SECRET},
    local::LocalStorage,
    s3::S3Storage,
};

use super::SignedCheckpointWithMessageId;

/// A generic trait to read/write Checkpoints offchain
#[async_trait]
pub trait FetchFromStorage: Debug + Send + Sync {
    /// Attempt to fetch the signed (checkpoint, messageId) tuple at this index
    async fn fetch(&self, index: u32) -> Result<Option<SignedCheckpointWithMessageId>>;
    /// Attemps to fetch the latest (checkpoint, messageId) tuple
    async fn fetch_latest(&self) -> Result<Option<SignedCheckpointWithMessageId>>;
    /// Return the announcement storage location for this syncer
    fn announcement_location(&self) -> String;
}

#[derive(Debug, Clone, Eq, Hash, PartialEq)]
pub enum CheckpointStorage {
    /// A checkpoint storage on S3
    /// A local checkpoint storage
    LocalStorage {
        /// Path
        path: PathBuf,
    },
    S3 {
        /// Bucket name
        bucket: String,
        /// Folder name inside bucket - defaults to the root of the bucket
        folder: Option<String>,
        /// S3 Region
        region: Region,
    },
    /// A checkpoint storage on Google Cloud
    Gcs {
        /// Bucket name
        bucket: String,
        /// Folder name inside bucket - defaults to the root of the bucket
        folder: Option<String>,
        /// A path to the oauth service account key json file.
        service_account_key: Option<String>,
        /// Path to oauth user secrets, like those created by
        /// `gcloud auth application-default login`
        user_secrets: Option<String>,
    },
}

/// Builds a [CheckpointStorage] from a storage location.
impl FromStr for CheckpointStorage {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self> {
        let [prefix, suffix]: [&str; 2] = s
            .split("://")
            .collect::<Vec<_>>()
            .try_into()
            .map_err(|_| anyhow!("Error parsing storage location; could not split prefix and suffix ({s})"))?;

        match prefix {
            "s3" => {
                let url_components = suffix.split('/').collect::<Vec<&str>>();
                let (bucket, region, folder): (&str, &str, Option<String>) = match url_components.len() {
                    2 => Ok((url_components[0], url_components[1], None)),
                    3.. => Ok((url_components[0], url_components[1], Some(url_components[2..].join("/")))),
                    _ => Err(anyhow!(
                        "Error parsing storage location; could not split bucket, region and folder ({suffix})"
                    )),
                }?;
                Ok(CheckpointStorage::S3 {
                    bucket: bucket.into(),
                    folder,
                    region: region.parse().context("Invalid region when parsing storage location")?,
                })
            }
            "file" => Ok(CheckpointStorage::LocalStorage { path: suffix.into() }),
            // for google cloud both options (with or without folder) from str are for anonymous access only
            // or env variables parsing
            "gs" => {
                let service_account_key = env::var(GCS_SERVICE_ACCOUNT_KEY).ok();
                let user_secrets = env::var(GCS_USER_SECRET).ok();
                if let Some(ind) = suffix.find('/') {
                    let (bucket, folder) = suffix.split_at(ind);
                    Ok(Self::Gcs {
                        bucket: bucket.into(),
                        folder: Some(folder.into()),
                        service_account_key,
                        user_secrets,
                    })
                } else {
                    Ok(Self::Gcs { bucket: suffix.into(), folder: None, service_account_key, user_secrets })
                }
            }
            _ => bail!("Unknown storage location prefix `{prefix}`"),
        }
    }
}

impl CheckpointStorage {
    /// Turn conf info a Checkpoint Syncer
    pub async fn build(&self) -> Result<Box<dyn FetchFromStorage>> {
        Ok(match self {
            CheckpointStorage::LocalStorage { path } => Box::new(LocalStorage::new(path.clone())?),
            CheckpointStorage::S3 { bucket, folder, region } => {
                Box::new(S3Storage::new(bucket.clone(), folder.clone(), region.clone()))
            }
            CheckpointStorage::Gcs { bucket, folder, service_account_key, user_secrets } => {
                let auth = if let Some(path) = service_account_key {
                    AuthFlow::ServiceAccount(ServiceAccountAuth::Path(path.into()))
                } else if let Some(path) = user_secrets {
                    AuthFlow::UserAccount(path.into())
                } else {
                    // Public data access only - no `insert`
                    AuthFlow::NoAuth
                };

                Box::new(GcsStorageClientBuilder::new(auth).build(bucket, folder.to_owned()).await?)
            }
        })
    }
}
