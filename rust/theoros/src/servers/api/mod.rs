pub mod docs;
pub mod router;

use std::net::SocketAddr;

use anyhow::{Context, Result};
use router::api_router;
use tokio::{net::TcpListener, task::JoinHandle};
use tower_http::{
    cors::CorsLayer,
    trace::{DefaultMakeSpan, TraceLayer},
};

use crate::{config::Config, servers::api::docs::ApiDoc, AppState};

#[tracing::instrument(skip(config, state))]
pub fn start_api_server(config: &Config, state: AppState) -> Result<JoinHandle<Result<()>>> {
    let host = config.server_host().to_owned();
    let port = config.server_port();

    // Uncomment this line below in order to generate the OpenAPI specs in the theoros folder
    // ApiDoc::generate_openapi_json("./theoros".into())?;

    let handle = tokio::spawn(async move {
        let address = format!("{}:{}", host, port);
        let socket_addr: SocketAddr = address.parse()?;
        let listener = TcpListener::bind(socket_addr).await?;

        let router = api_router::<ApiDoc>(state.clone())
            .with_state(state.clone())
            .layer(TraceLayer::new_for_http().make_span_with(DefaultMakeSpan::default().include_headers(true)))
            .layer(CorsLayer::permissive());

        tracing::info!("🧩 API server started at http://{}", socket_addr);
        axum::serve(listener, router).await.context("😱 API server stopped!")
    });

    Ok(handle)
}
