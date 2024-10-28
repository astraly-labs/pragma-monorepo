pub mod docs;
pub mod router;

use std::{net::SocketAddr, sync::Arc, time::Duration};

use anyhow::{Context, Result};
use docs::ApiDoc;
use router::api_router;
use tokio::{net::TcpListener, task::JoinSet};
use tower_governor::governor::GovernorConfigBuilder;
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
        // ApiDoc::generate_openapi_json("./theoros".into())?;

        let host = self.host.to_owned();
        let port = self.port;
        let state = self.state.clone();

        let governor_conf = Arc::new(GovernorConfigBuilder::default().per_second(4).burst_size(2).finish().unwrap());
        let governor_limiter = governor_conf.limiter().clone();
        // a separate background task to clean up
        std::thread::spawn(move || loop {
            std::thread::sleep(Duration::from_secs(60));
            tracing::info!("❌ Rate limiting storage size: {}", governor_limiter.len());
            governor_limiter.retain_recent();
        });

        join_set.spawn(async move {
            let address = format!("{}:{}", host, port);
            let socket_addr: SocketAddr = address.parse()?;
            let listener = TcpListener::bind(socket_addr).await?;

            let app = api_router::<ApiDoc>(state.clone())
                .with_state(state)
                .layer(TraceLayer::new_for_http().make_span_with(DefaultMakeSpan::default().include_headers(true)))
                .layer(CorsLayer::permissive());

            tracing::info!("🧩 API server started at http://{}", socket_addr);
            axum::serve(listener, app.into_make_service_with_connect_info::<SocketAddr>())
                .with_graceful_shutdown(async {
                    let _ = crate::EXIT.subscribe().changed().await;
                    tracing::info!("🛑 Shutting down API server...");
                })
                .await
                .context("😱 API server stopped!")
        });
        Ok(())
    }
}
