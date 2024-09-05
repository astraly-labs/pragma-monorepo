use std::{fmt, sync::OnceLock, time::Duration};

use anyhow::{bail, Result};
use async_trait::async_trait;
use derive_new::new;
use futures_util::TryStreamExt;
use pragma_utils::http::http_client_with_timeout;
use prometheus::IntGauge;
use rusoto_core::{
    credential::{Anonymous, AwsCredentials, StaticProvider},
    Region, RusotoError,
};
use rusoto_s3::{GetObjectError, GetObjectRequest, S3Client, S3};
use tokio::time::timeout;

use crate::types::{CheckpointFetcher, CheckpointWithMessageId};

/// The timeout for S3 requests. Rusoto doesn't offer timeout configuration
/// out of the box, so S3 requests must be wrapped with a timeout.
/// See https://github.com/rusoto/rusoto/issues/1795.
const S3_REQUEST_TIMEOUT_SECONDS: u64 = 30;

#[allow(unused)]
#[derive(Clone, new)]
/// Type for reading/writing to S3
pub struct S3Storage {
    /// The name of the bucket.
    bucket: String,
    /// A specific folder inside the above repo - set to empty string to use the root of the bucket
    folder: Option<String>,
    /// The region of the bucket.
    region: Region,
    /// A client without credentials for anonymous requests.
    #[new(default)]
    anonymous_client: OnceLock<S3Client>,
    /// The latest seen signed checkpoint index.
    latest_index: Option<IntGauge>,
}

impl fmt::Debug for S3Storage {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("S3Storage")
            .field("bucket", &self.bucket)
            .field("folder", &self.folder)
            .field("region", &self.region)
            .finish()
    }
}

#[allow(unused)]
impl S3Storage {
    /// Uses an anonymous client. This should only be used for publicly accessible buckets.
    async fn anonymously_read_from_bucket(&self, key: String) -> Result<Option<Vec<u8>>> {
        let req =
            GetObjectRequest { key: self.get_composite_key(key), bucket: self.bucket.clone(), ..Default::default() };
        let get_object_result =
            timeout(Duration::from_secs(S3_REQUEST_TIMEOUT_SECONDS), self.anonymous_client().get_object(req)).await?;

        match get_object_result {
            Ok(res) => match res.body {
                Some(body) => Ok(Some(body.map_ok(|b| b.to_vec()).try_concat().await?)),
                None => Ok(None),
            },
            Err(RusotoError::Service(GetObjectError::NoSuchKey(_))) => Ok(None),
            Err(e) => bail!(e),
        }
    }

    /// Gets an anonymous S3Client, creating it if it doesn't already exist.
    /// An anonymous client doesn't have AWS credentials and will not sign S3
    /// requests with any credentials.
    /// We've experienced an inability to make GetObjectRequests to public
    /// S3 buckets when signing with credentials from an AWS account not from the
    /// S3 bucket's AWS account.
    fn anonymous_client(&self) -> &S3Client {
        self.anonymous_client.get_or_init(|| {
            // By default, these credentials are anonymous, see:
            // https://docs.rs/rusoto_credential/latest/rusoto_credential/struct.AwsCredentials.html#anonymous-example
            let credentials = AwsCredentials::default();
            assert!(credentials.is_anonymous(), "AWS credentials not anonymous");

            S3Client::new_with(
                http_client_with_timeout().unwrap(),
                StaticProvider::from(credentials),
                self.region.clone(),
            )
        })
    }

    fn get_composite_key(&self, key: String) -> String {
        match self.folder.as_deref() {
            None | Some("") => key,
            Some(folder_str) => format!("{}/{}", folder_str, key),
        }
    }

    fn checkpoint_key(index: u32) -> String {
        format!("checkpoint_{index}_with_id.json")
    }
}

#[async_trait]
impl CheckpointFetcher for S3Storage {
    async fn fetch(&self, index: u32) -> Result<Option<CheckpointWithMessageId>> {
        self.anonymously_read_from_bucket(S3Storage::checkpoint_key(index))
            .await?
            .map(|data| serde_json::from_slice(&data))
            .transpose()
            .map_err(Into::into)
    }

    fn announcement_location(&self) -> String {
        match self.folder.as_deref() {
            None | Some("") => format!("s3://{}/{}", self.bucket, self.region.name()),
            Some(folder_str) => {
                format!("s3://{}/{}/{}", self.bucket, self.region.name(), folder_str)
            }
        }
    }
}
