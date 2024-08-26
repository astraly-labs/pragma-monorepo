use std::path::PathBuf;

use anyhow::Result;
use utoipa::OpenApi;
use utoipauto::utoipauto;

#[utoipauto(paths = "./theoros/src")]
#[derive(OpenApi)]
#[openapi(
    tags(
        (name = "theoros", description = "Theoros - the Pragma Consultant")
    )
)]
pub struct ApiDoc;

impl ApiDoc {
    pub fn generate_openapi_json(output_path: PathBuf) -> Result<()> {
        let json = ApiDoc::openapi().to_json()?;
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
