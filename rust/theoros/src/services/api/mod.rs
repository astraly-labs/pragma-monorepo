pub mod docs;
pub mod router;

use std::net::SocketAddr;

use anyhow::{Context, Result};
use docs::ApiDoc;
use router::api_router;
use tokio::{net::TcpListener, task::JoinSet};
use tower_http::{
    cors::CorsLayer,
    trace::{DefaultMakeSpan, TraceLayer},
};

use pragma_utils::services::Service;

use crate::AppState;

pub struct ApiService {
    state: AppState,
    host: String,
    port: u16,
}

impl ApiService {
    pub fn new(state: AppState, host: &str, port: u16) -> Self {
        Self { state, host: host.to_owned(), port }
    }
}

#[async_trait::async_trait]
impl Service for ApiService {
    async fn start(&mut self, join_set: &mut JoinSet<Result<()>>) -> anyhow::Result<()> {
        // Uncomment this line below in order to generate the OpenAPI specs in the theoros folder
        // ApiDoc::generate_openapi_json("./theoros".into())?;

        let host = self.host.to_owned();
        let port = self.port;
        let state = self.state.clone();

        join_set.spawn(async move {
            let address = format!("{}:{}", host, port);
            let socket_addr: SocketAddr = address.parse()?;
            let listener = TcpListener::bind(socket_addr).await?;

            let router = api_router::<ApiDoc>(state.clone())
                .with_state(state)
                .layer(TraceLayer::new_for_http().make_span_with(DefaultMakeSpan::default().include_headers(true)))
                .layer(CorsLayer::permissive());

            tracing::info!("🧩 API server started at http://{}", socket_addr);
            axum::serve(listener, router).await.context("😱 API server stopped!")
        });
        Ok(())
    }
}
