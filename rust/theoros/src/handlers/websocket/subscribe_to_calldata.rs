use std::{
    collections::HashMap,
    net::SocketAddr,
    sync::{atomic::Ordering, Arc},
};

use alloy::hex;
use anyhow::Result;
use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        ConnectInfo, State as AxumState,
    },
    response::IntoResponse,
};
use futures::{
    stream::{SplitSink, SplitStream},
    SinkExt, StreamExt,
};
use serde::{Deserialize, Serialize};
use tokio::sync::broadcast::Receiver;
use utoipa::ToSchema;

use crate::{
    configs::evm_config::EvmChainName,
    constants::{MAX_CLIENT_MESSAGE_SIZE, PING_INTERVAL_DURATION},
    types::{
        calldata::{AsCalldata, Calldata},
        hyperlane::NewUpdatesAvailableEvent,
    },
    AppState,
};

#[derive(Clone)]
pub struct DataFeedClientConfig {}

#[derive(Deserialize, Debug, Clone)]
#[serde(tag = "type")]
enum ClientMessage {
    #[serde(rename = "subscribe")]
    Subscribe { feed_ids: Vec<String>, chain: EvmChainName },
    #[serde(rename = "unsubscribe")]
    Unsubscribe { feed_ids: Vec<String> },
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct RpcDataFeed {
    pub feed_id: String,
    /// The calldata binary represented as a hex string.
    pub encoded_calldata: String,
}

#[derive(Serialize, Debug, Clone)]
#[serde(tag = "type")]
enum ServerMessage {
    #[serde(rename = "response")]
    Response(ServerResponseMessage),
    #[serde(rename = "data_feed_update")]
    DataFeedUpdate { data_feeds: Vec<RpcDataFeed> },
}

#[derive(Serialize, Debug, Clone)]
#[serde(tag = "status")]
enum ServerResponseMessage {
    #[serde(rename = "success")]
    Success,
    #[serde(rename = "error")]
    Err { error: String },
}

/// WebSocket route handler.
///
/// Upgrades the HTTP connection to a WebSocket connection and spawns a new
/// subscriber to handle incoming and outgoing messages.
pub async fn ws_route_handler(
    ws: WebSocketUpgrade,
    AxumState(state): AxumState<AppState>,
    ConnectInfo(_): ConnectInfo<SocketAddr>,
) -> impl IntoResponse {
    ws.max_message_size(MAX_CLIENT_MESSAGE_SIZE).on_upgrade(move |socket| websocket_handler(socket, state))
}

/// Handles the WebSocket connection for a single client.
#[tracing::instrument(skip(stream, state))]
async fn websocket_handler(stream: WebSocket, state: AppState) {
    let ws_state = state.ws.clone();

    let (sender, receiver) = stream.split();
    let feeds_receiver = state.storage.feeds_updated_tx().subscribe();
    let id = ws_state.subscriber_counter.fetch_add(1, Ordering::SeqCst);
    let mut subscriber = Subscriber::new(id, Arc::new(state), feeds_receiver, receiver, sender);

    subscriber.run().await;
}

pub type SubscriberId = usize;

/// Represents a client connected via WebSocket.
///
/// Manages subscriptions to data feeds, handles incoming client messages,
/// and sends updates to the client.
pub struct Subscriber {
    id: SubscriberId,
    closed: bool,
    state: Arc<AppState>,
    feeds_receiver: Receiver<NewUpdatesAvailableEvent>,
    receiver: SplitStream<WebSocket>,
    sender: SplitSink<WebSocket, Message>,
    data_feeds_with_config: HashMap<String, DataFeedClientConfig>,
    active_chain: Option<EvmChainName>,
    ping_interval: tokio::time::Interval,
    responded_to_ping: bool,
}

impl Subscriber {
    /// Creates a new `Subscriber` instance.
    pub fn new(
        id: SubscriberId,
        state: Arc<AppState>,
        feeds_receiver: Receiver<NewUpdatesAvailableEvent>,
        receiver: SplitStream<WebSocket>,
        sender: SplitSink<WebSocket, Message>,
    ) -> Self {
        Self {
            id,
            closed: false,
            state,
            feeds_receiver,
            receiver,
            sender,
            data_feeds_with_config: HashMap::new(),
            active_chain: None,
            ping_interval: tokio::time::interval(PING_INTERVAL_DURATION),
            responded_to_ping: true,
        }
    }

    /// Runs the subscriber event loop, handling messages and updates.
    #[tracing::instrument(skip(self))]
    pub async fn run(&mut self) {
        while !self.closed {
            if self.handle_next().await.is_err() {
                break;
            }
        }
    }

    /// Handles the next event, whether it's an incoming message, a data feed update, or a ping.
    async fn handle_next(&mut self) -> Result<()> {
        tokio::select! {
            maybe_update = self.feeds_receiver.recv() => {
                match maybe_update {
                    Ok(_) => self.handle_data_feeds_update().await,
                    Err(e) => anyhow::bail!("Failed to receive update from store: {:?}", e),
                }
            },
            maybe_message = self.receiver.next() => {
                match maybe_message {
                    Some(Ok(message)) => self.handle_client_message(message).await,
                    Some(Err(e)) => anyhow::bail!("WebSocket error: {:?}", e),
                    None => {
                        self.closed = true;
                        Ok(())
                    }
                }
            },
            _ = self.ping_interval.tick() => {
                anyhow::ensure!(self.responded_to_ping, "Subscriber did not respond to ping. Closing connection.");
                self.responded_to_ping = false;
                self.sender.send(Message::Ping(vec![])).await?;
                Ok(())
            }
        }
    }

    /// Handles data feed updates by sending new data to the client for all subscribed feeds.
    async fn handle_data_feeds_update(&mut self) -> Result<()> {
        if self.active_chain.is_none() || self.data_feeds_with_config.is_empty() {
            return Ok(());
        }

        tracing::debug!(subscriber = self.id, "Handling data feeds update.");

        // Retrieve the list of subscribed feed IDs.
        let feed_ids: Vec<String> = self.data_feeds_with_config.keys().cloned().collect();

        let mut data_feeds = Vec::with_capacity(feed_ids.len());
        // Build calldata for each subscribed feed and collect them.
        for feed_id in feed_ids {
            match Calldata::build_from(self.state.as_ref(), self.active_chain.unwrap(), feed_id.clone()).await {
                Ok(calldata) => {
                    data_feeds.push(RpcDataFeed {
                        feed_id: feed_id.clone(),
                        encoded_calldata: hex::encode(calldata.as_bytes()),
                    });
                }
                Err(e) => {
                    self.send_error_to_client(format!("Error building calldata for {}: {}", feed_id, e)).await?;
                }
            }
        }

        // Send a single update containing all data feeds.
        if !data_feeds.is_empty() {
            let update = ServerMessage::DataFeedUpdate { data_feeds };
            let message = serde_json::to_string(&update)?;
            self.sender.send(Message::Text(message)).await?;
        }

        Ok(())
    }

    /// Processes messages received from the client.
    #[tracing::instrument(skip(self, message))]
    async fn handle_client_message(&mut self, message: Message) -> Result<()> {
        match message {
            Message::Close(_) => {
                tracing::trace!(id = self.id, "📨 [CLOSE]");
                self.sender.close().await?;
                self.closed = true;
                Ok(())
            }
            Message::Text(text) => self.process_client_message(&text).await,
            Message::Binary(data) => {
                let text = String::from_utf8(data)?;
                self.process_client_message(&text).await
            }
            Message::Ping(_) => Ok(()), // Axum handles PONG responses automatically.
            Message::Pong(_) => {
                self.responded_to_ping = true;
                Ok(())
            }
        }
    }

    /// Parses and processes a client message in text format.
    async fn process_client_message(&mut self, text: &str) -> Result<()> {
        let client_message: ClientMessage = match serde_json::from_str(text) {
            Ok(msg) => msg,
            Err(e) => {
                self.send_error_to_client(e.to_string()).await?;
                return Ok(());
            }
        };

        match client_message {
            ClientMessage::Subscribe { feed_ids, chain } => {
                // Check if the chain is supported
                if !self.state.hyperlane_validators_mapping.is_supported_chain(&chain) {
                    self.send_error_to_client(format!(
                        "The chain {} is not supported. Call /v1/chains to know the chains supported by Theoros.",
                        chain,
                    ))
                    .await?;
                    return Ok(());
                }
                // Check if all requested feed IDs are supported.
                let stored_feed_ids = self.state.storage.feed_ids();
                if let Some(missing_id) = stored_feed_ids.contains_vec(&feed_ids).await {
                    self.send_error_to_client(format!("Can't subscribe: feed ID not supported {:}", missing_id))
                        .await?;
                    return Ok(());
                }

                // Subscribe to the requested feed IDs.
                self.active_chain = Some(chain);
                for feed_id in feed_ids {
                    self.data_feeds_with_config.insert(feed_id, DataFeedClientConfig {});
                }
            }
            ClientMessage::Unsubscribe { feed_ids } => {
                for feed_id in feed_ids {
                    self.data_feeds_with_config.remove(&feed_id);
                }
            }
        }

        // Acknowledge the successful processing of the client message.
        self.sender
            .send(Message::Text(serde_json::to_string(&ServerMessage::Response(ServerResponseMessage::Success))?))
            .await?;
        Ok(())
    }

    async fn send_error_to_client(&mut self, msg: String) -> anyhow::Result<()> {
        let message = ServerResponseMessage::Err { error: msg };
        self.sender.send(Message::Text(serde_json::to_string(&ServerMessage::Response(message))?)).await?;
        Ok(())
    }
}
