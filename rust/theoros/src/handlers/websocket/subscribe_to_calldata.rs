use std::{
    collections::HashMap,
    net::SocketAddr,
    sync::{atomic::Ordering, Arc},
};

use alloy::hex;
use anyhow::{anyhow, Result};
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

use crate::constants::{MAX_CLIENT_MESSAGE_SIZE, PING_INTERVAL_DURATION};
use crate::types::calldata::AsCalldata;
use crate::types::hyperlane::NewUpdatesAvailableEvent;
use crate::AppState;
use crate::{configs::evm_config::EvmChainName, types::calldata::Calldata};

// TODO: add config for the client
/// Configuration for a specific data feed.
#[derive(Clone)]
pub struct DataFeedClientConfig {}

#[derive(Deserialize, Debug, Clone)]
#[serde(tag = "type")]
enum ClientMessage {
    #[serde(rename = "subscribe")]
    Subscribe { ids: Vec<String>, chain_name: EvmChainName },
    #[serde(rename = "unsubscribe")]
    Unsubscribe { ids: Vec<String> },
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct RpcDataFeed {
    pub feed_id: String,
    /// The calldata binary represented as a hex string.
    #[serde(skip_serializing_if = "Option::is_none")]
    #[schema(value_type = Option<String>)]
    pub encoded_calldata: Option<String>,
}

#[derive(Serialize, Debug, Clone)]
#[serde(tag = "type")]
enum ServerMessage {
    #[serde(rename = "response")]
    Response(ServerResponseMessage),
    #[serde(rename = "data_feed_update")]
    DataFeedUpdate { data_feed: RpcDataFeed },
}

#[derive(Serialize, Debug, Clone)]
#[serde(tag = "status")]
enum ServerResponseMessage {
    #[serde(rename = "success")]
    Success,
    #[serde(rename = "error")]
    Err { error: String },
}

pub async fn ws_route_handler(
    ws: WebSocketUpgrade,
    AxumState(state): AxumState<AppState>,
    ConnectInfo(_): ConnectInfo<SocketAddr>,
) -> impl IntoResponse {
    ws.max_message_size(MAX_CLIENT_MESSAGE_SIZE).on_upgrade(move |socket| websocket_handler(socket, state))
}

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

    #[tracing::instrument(skip(self))]
    pub async fn run(&mut self) {
        while !self.closed {
            if let Err(e) = self.handle_next().await {
                tracing::error!(subscriber = self.id, error = ?e, "Error Handling Subscriber Message.");
                break;
            }
        }
    }

    async fn handle_next(&mut self) -> Result<()> {
        tokio::select! {
            maybe_update_feeds_event = self.feeds_receiver.recv() => {
                match maybe_update_feeds_event {
                    Ok(_) => self.handle_data_feeds_update().await,
                    Err(e) => Err(anyhow!("Failed to receive update from store: {:?}", e)),
                }
            },
            maybe_message_or_err = self.receiver.next() => {
                self.handle_client_message(
                    maybe_message_or_err.ok_or(anyhow!("Client channel is closed"))??
                ).await
            },
            _  = self.ping_interval.tick() => {
                if !self.responded_to_ping {
                    return Err(anyhow!("Subscriber did not respond to ping. Closing connection."));
                }
                self.responded_to_ping = false;
                self.sender.send(Message::Ping(vec![])).await?;
                Ok(())
            }
        }
    }

    async fn handle_data_feeds_update(&mut self) -> Result<()> {
        if self.active_chain.is_none() {
            return Ok(());
        }
        tracing::debug!(subscriber = self.id, "Handling Data Feeds Update.");
        // Retrieve the updates for subscribed feed ids at the given slot
        let feed_ids = self.data_feeds_with_config.keys().cloned().collect::<Vec<_>>();

        // TODO: add support for multiple feeds
        let feed_id = feed_ids.first().unwrap();
        let calldata =
            Calldata::build_from(self.state.as_ref(), self.active_chain.unwrap(), feed_id.to_owned()).await?;

        let message = serde_json::to_string(&ServerMessage::DataFeedUpdate {
            data_feed: RpcDataFeed {
                feed_id: feed_id.clone(),
                encoded_calldata: Some(hex::encode(calldata.as_bytes())),
            },
        })?;
        self.sender.send(message.into()).await?;
        Ok(())
    }

    #[tracing::instrument(skip(self, message))]
    async fn handle_client_message(&mut self, message: Message) -> Result<()> {
        let maybe_client_message = match message {
            Message::Close(_) => {
                // Closing the connection. We don't remove it from the subscribers
                // list, instead when the Subscriber struct is dropped the channel
                // to subscribers list will be closed and it will eventually get
                // removed.
                tracing::trace!(id = self.id, "📨 [CLOSE]");

                // Send the close message to gracefully shut down the connection
                // Otherwise the client might get an abnormal Websocket closure
                // error.
                self.sender.close().await?;
                self.closed = true;
                return Ok(());
            }
            Message::Text(text) => serde_json::from_str::<ClientMessage>(&text),
            Message::Binary(data) => serde_json::from_slice::<ClientMessage>(&data),
            Message::Ping(_) => {
                // Axum will send Pong automatically
                return Ok(());
            }
            Message::Pong(_) => {
                self.responded_to_ping = true;
                return Ok(());
            }
        };

        match maybe_client_message {
            Err(e) => {
                tracing::error!("😶‍🌫️ Client disconnected/error occurred. Closing the channel.");
                self.sender
                    .send(
                        serde_json::to_string(&ServerMessage::Response(ServerResponseMessage::Err {
                            error: e.to_string(),
                        }))?
                        .into(),
                    )
                    .await?;
                return Ok(());
            }

            Ok(ClientMessage::Subscribe { ids: feed_ids, chain_name }) => {
                let stored_feed_ids = self.state.storage.feed_ids();

                // If there is a single feed id that is not found, we don't subscribe to any of the
                // asked feed ids and return an error to be more explicit and clear.
                match stored_feed_ids.contains_vec(&feed_ids).await {
                    // TODO: return multiple missing ids
                    Some(missing_id) => {
                        self.sender
                            .send(
                                serde_json::to_string(&ServerMessage::Response(ServerResponseMessage::Err {
                                    error: format!("Can't subscribe: at least one of the requested feed ids is not supported ({:?})", missing_id),
                                }))?
                                .into(),
                            )
                            .await?;
                        return Ok(());
                    }
                    None => {
                        for feed_id in feed_ids {
                            self.data_feeds_with_config.insert(feed_id, DataFeedClientConfig {});
                            // TODO: Assert that the chain is supported by theoros
                            self.active_chain = Some(chain_name);
                        }
                    }
                }
            }
            Ok(ClientMessage::Unsubscribe { ids: feed_ids }) => {
                for feed_id in feed_ids {
                    self.data_feeds_with_config.remove(&feed_id);
                }
            }
        }

        self.sender
            .send(serde_json::to_string(&ServerMessage::Response(ServerResponseMessage::Success))?.into())
            .await?;

        Ok(())
    }
}
