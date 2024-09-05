use std::{env, path::PathBuf};

use anyhow::{anyhow, Context, Error, Result};
use core::str::FromStr;
use prometheus::IntGauge;
use rusoto_core::Region;
use ya_gcp::{AuthFlow, ServiceAccountAuth};

use std::fmt::Debug;

use async_trait::async_trait;

use crate::types::{
    gcs_storage::{GcsStorageClientBuilder, GCS_SERVICE_ACCOUNT_KEY, GCS_USER_SECRET},
    local::LocalStorage,
    s3::S3Storage,
};

use super::CheckpointWithMessageId;

pub type StorageLocation = String;

#[allow(unused)]
/// A generic trait to read/write Checkpoints offchain
#[async_trait]
pub trait CheckpointFetcher: Debug + Send + Sync {
    /// Attempt to fetch the signed (checkpoint, messageId) tuple at this index
    async fn fetch(&self, index: u32) -> Result<Option<CheckpointWithMessageId>>;
    /// Return the announcement storage location for this syncer
    fn announcement_location(&self) -> String;
}

#[derive(Debug, Clone)]
pub enum CheckpointFetcherConf {
    /// A local checkpoint syncer
    LocalStorage {
        /// Path
        path: PathBuf,
    },
    /// A checkpoint syncer on S3
    S3 {
        /// Bucket name
        bucket: String,
        /// Folder name inside bucket - defaults to the root of the bucket
        folder: Option<String>,
        /// S3 Region
        region: Region,
    },
    /// A checkpoint syncer on Google Cloud Storage
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

impl FromStr for CheckpointFetcherConf {
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
                Ok(CheckpointFetcherConf::S3 {
                    bucket: bucket.into(),
                    folder,
                    region: region.parse().context("Invalid region when parsing storage location")?,
                })
            }
            "file" => Ok(CheckpointFetcherConf::LocalStorage { path: suffix.into() }),
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
            _ => Err(anyhow!("Unknown storage location prefix `{prefix}`")),
        }
    }
}

impl CheckpointFetcherConf {
    /// Turn conf info a Checkpoint Syncer
    pub async fn build(&self, latest_index_gauge: Option<IntGauge>) -> Result<Box<dyn CheckpointFetcher>> {
        Ok(match self {
            CheckpointFetcherConf::LocalStorage { path } => {
                Box::new(LocalStorage::new(path.clone(), latest_index_gauge)?)
            }
            CheckpointFetcherConf::S3 { bucket, folder, region } => {
                Box::new(S3Storage::new(bucket.clone(), folder.clone(), region.clone(), latest_index_gauge))
            }
            CheckpointFetcherConf::Gcs { bucket, folder, service_account_key, user_secrets } => {
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
