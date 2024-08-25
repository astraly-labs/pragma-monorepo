pub mod router;

use std::{net::SocketAddr, path::PathBuf};

use anyhow::{Context, Result};
use router::api_router;
use tokio::task::JoinHandle;
use tower_http::{
    cors::CorsLayer,
    trace::{DefaultMakeSpan, TraceLayer},
};
use utoipa::OpenApi;
use utoipauto::utoipauto;

use crate::{config::Config, AppState};

#[tracing::instrument(skip(config, state))]
pub fn run_api_server(config: &Config, state: AppState) -> JoinHandle<Result<()>> {
    let host = config.server_host().to_owned();
    let port = config.server_port();

    tokio::spawn(async move {
        let address = format!("{}:{}", host, port);
        let socket_addr: SocketAddr = address.parse().context("Failed to parse socket address")?;

        let listener = tokio::net::TcpListener::bind(socket_addr).await.context("Failed to bind TcpListener")?;
        let router = api_router::<ApiDoc>(state.clone())
            .with_state(state.clone())
            .layer(TraceLayer::new_for_http().make_span_with(DefaultMakeSpan::default().include_headers(true)))
            .layer(CorsLayer::permissive());

        tracing::info!("🧩 API server started at http://{}", socket_addr);
        axum::serve(listener, router).await.context("😱 API server stopped!")
    })
}

const OPENAPI_FILENAME: &str = "openapi.json";

#[utoipauto(paths = "./theoros/src")]
#[derive(OpenApi)]
#[openapi(
        tags(
            (name = "theoros", description = "Theoros Pragma Consultant")
        )
    )]
pub struct ApiDoc;

impl ApiDoc {
    pub fn generate_openapi_json(output_path: PathBuf) -> Result<()> {
        let json = ApiDoc::openapi().to_json()?;
        if let Some(parent) = output_path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        let file_path = output_path.join(OPENAPI_FILENAME);
        std::fs::write(file_path, json)?;
        Ok(())
    }
}
