use std::path::PathBuf;

use anyhow::Result;
use serde_json::to_string_pretty;
use utoipa::OpenApi;
use utoipauto::utoipauto;

#[utoipauto(paths = "./theoros/src, ./pragma-utils/src")]
#[derive(OpenApi)]
#[openapi(
    tags(
        (name = "theoros", description = "Theoros - The Pragma Consultant")
    )
)]
pub struct ApiDoc;

impl ApiDoc {
    pub fn generate_openapi_json(output_path: PathBuf) -> Result<()> {
        let openapi = ApiDoc::openapi();
        let json = to_string_pretty(&openapi)?;

        if let Some(parent) = output_path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        let file_path = output_path.join("openapi.json");
        tracing::info!("Saving OpenAPI specs to {} ....", file_path.as_path().display());
        std::fs::write(file_path, json)?;
        tracing::info!("OpenAPI specs saved!");
        Ok(())
    }
}
