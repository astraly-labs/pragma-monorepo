use {
    crate::{types::pragma::constants::MAX_CLIENT_MESSAGE_SIZE, AppState},
    anyhow::{anyhow, Result},
    axum::{
        extract::{
            ws::{Message, WebSocket, WebSocketUpgrade},
            State as AxumState,
        },
        http::HeaderMap,
        response::IntoResponse,
    },
    futures::{
        stream::{SplitSink, SplitStream},
        SinkExt, StreamExt,
    },
    prometheus_client::{
        encoding::{EncodeLabelSet, EncodeLabelValue},
        metrics::{counter::Counter, family::Family},
    },
    serde::{Deserialize, Serialize},
    std::{
        collections::HashMap,
        net::IpAddr,
        num::NonZeroU32,
        sync::{
            atomic::{AtomicUsize, Ordering},
            Arc,
        },
    },
    tokio::sync::{broadcast::Receiver, watch},
};

#[derive(Clone)]
pub struct PriceFeedClientConfig {
    verbose: bool,
    binary: bool,
    allow_out_of_order: bool,
}

#[derive(Clone, Debug, Hash, PartialEq, Eq, EncodeLabelValue)]
pub enum Interaction {
    NewConnection,
    CloseConnection,
    ClientHeartbeat,
    PriceUpdate,
    ClientMessage,
    RateLimit,
}

#[derive(Clone, Debug, Hash, PartialEq, Eq, EncodeLabelValue)]
pub enum Status {
    Success,
    Error,
}

#[derive(Clone, Debug, PartialEq, Eq, Hash, EncodeLabelSet)]
pub struct Labels {
    pub interaction: Interaction,
    pub status: Status,
}

pub struct WsMetrics {
    pub interactions: Family<Labels, Counter>,
}

pub fn ws_route_handler(
    ws: WebSocketUpgrade,
    AxumState(state): AxumState<AppState>,
    headers: HeaderMap,
) -> impl IntoResponse {
    ws.max_message_size(MAX_CLIENT_MESSAGE_SIZE).on_upgrade(move |socket| websocket_handler(socket, state))
}

#[tracing::instrument(skip(stream, state))]
async fn websocket_handler(stream: WebSocket, state: AppState) {
    todo!();
}
