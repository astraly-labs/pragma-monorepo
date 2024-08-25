pub mod router;

use std::{net::SocketAddr, path::PathBuf};

use anyhow::Result;
use router::api_router;
use tower_http::{
    cors::CorsLayer,
    trace::{DefaultMakeSpan, TraceLayer},
};
use utoipa::OpenApi;
use utoipauto::utoipauto;

use crate::{config::Config, AppState};

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

#[tracing::instrument(skip(state))]
pub async fn run_api_server(config: &Config, state: &AppState) {
    let host = config.server_host();
    let port = config.server_port();
    let address = format!("{}:{}", host, port);
    let socket_addr: SocketAddr = address.parse().unwrap();

    let listener = tokio::net::TcpListener::bind(socket_addr).await.unwrap();
    let router = api_router::<ApiDoc>(state.clone())
        .with_state(state.clone())
        // Logging so we can see whats going on
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(DefaultMakeSpan::default().include_headers(true)),
        )
        // Permissive CORS layer to allow all origins
        .layer(CorsLayer::permissive());

    tracing::info!("🚀 API started at http://{}", socket_addr);
    tokio::spawn(async move { axum::serve(listener, router).await.unwrap() });
}
