use std::str::FromStr;
use std::{
    collections::HashMap,
    net::SocketAddr,
    sync::{atomic::Ordering, Arc},
};

use alloy::hex;
use alloy::primitives::U256;
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
use starknet::core::types::Felt;
use tokio::sync::{broadcast::Receiver, watch};

use crate::configs::evm_config::EvmChainName;
use crate::constants::{DEFAULT_ACTIVE_CHAIN, HYPERLANE_VERSION, MAX_CLIENT_MESSAGE_SIZE, PING_INTERVAL_DURATION};
use crate::types::calldata::ValidatorSignature;
use crate::types::{
    calldata::{AsCalldata, HyperlaneMessage, Payload},
    hyperlane::{CheckpointMatchEvent, DispatchUpdate},
    rpc::RpcDataFeed,
};
use crate::AppState;

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

    // TODO: add new connection to metrics

    let (sender, receiver) = stream.split();

    let feeds_receiver = state.storage.feeds_channel.subscribe();

    let id = ws_state.subscriber_counter.fetch_add(1, Ordering::SeqCst);

    let mut subscriber = Subscriber::new(id, Arc::new(state), feeds_receiver, receiver, sender);

    subscriber.run().await;
}

pub type SubscriberId = usize;

pub struct Subscriber {
    id: SubscriberId,
    closed: bool,
    state: Arc<AppState>,
    feeds_receiver: Receiver<CheckpointMatchEvent>,
    receiver: SplitStream<WebSocket>,
    sender: SplitSink<WebSocket, Message>,
    data_feeds_with_config: HashMap<String, DataFeedClientConfig>,
    active_chain: EvmChainName,
    ping_interval: tokio::time::Interval,
    exit: watch::Receiver<bool>,
    responded_to_ping: bool,
}

impl Subscriber {
    pub fn new(
        id: SubscriberId,
        state: Arc<AppState>,
        feeds_receiver: Receiver<CheckpointMatchEvent>,
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
            active_chain: DEFAULT_ACTIVE_CHAIN,
            ping_interval: tokio::time::interval(PING_INTERVAL_DURATION),
            exit: crate::EXIT.subscribe(),
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
                    Ok(event) => self.handle_data_feeds_update(event).await,
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
                    // self.metrics
                    //     .interactions
                    //     .get_or_create(&Labels {
                    //         interaction: Interaction::ClientHeartbeat,
                    //         status: Status::Error,
                    //     })
                    //     .inc();

                    return Err(anyhow!("Subscriber did not respond to ping. Closing connection."));
                }
                self.responded_to_ping = false;
                self.sender.send(Message::Ping(vec![])).await?;
                Ok(())
            },
            _ = self.exit.changed() => {
                self.sender.close().await?;
                self.closed = true;
                Err(anyhow!("Application is shutting down. Closing connection."))
            }
        }
    }

    async fn handle_data_feeds_update(&mut self, event: CheckpointMatchEvent) -> Result<()> {
        tracing::debug!(subscriber = self.id, n = event.block_number(), "Handling Data Feeds Update.");
        // Retrieve the updates for subscribed feed ids at the given slot
        let feed_ids = self.data_feeds_with_config.keys().cloned().collect::<Vec<_>>();

        // TODO: add support for multiple feeds
        let feed_id = feed_ids.first().unwrap();

        // TODO: refactor this code as it's reused from rest endpoint

        let checkpoints = self.state.storage.checkpoints().all().await;
        let num_validators = checkpoints.keys().len();

        let event = self.state.storage.dispatch_events().get(feed_id).await?.unwrap();

        let validators = self
            .state
            .hyperlane_validators_mapping
            .get_validators(self.active_chain)
            .ok_or(anyhow!("Chain not supported"))?;

        let _signatures =
            self.state.storage.checkpoints().get_validators_signed_checkpoints(validators, event.message_id).await?;

        let (_, checkpoint_infos) = checkpoints.iter().next().unwrap();

        let update = match event.update {
            DispatchUpdate::SpotMedian { update, feed_id: _ } => update,
        };

        let payload = Payload {
            checkpoint: checkpoint_infos.value.clone(),
            num_updates: 1,
            update_data_len: 1,
            proof_len: 0,
            proof: vec![],
            update_data: update.to_bytes(),
            feed_id: U256::from_str(feed_id).unwrap(),
            publish_time: update.metadata.timestamp,
        };

        let hyperlane_message = HyperlaneMessage {
            hyperlane_version: HYPERLANE_VERSION,
            signers_len: num_validators as u8,
            signatures: vec![ValidatorSignature { validator_index: 0, signature: checkpoint_infos.signature }],
            nonce: event.nonce,
            timestamp: update.metadata.timestamp,
            emitter_chain_id: event.emitter_chain_id,
            emitter_address: Felt::from_dec_str(&event.emitter_address).unwrap(),
            payload,
        };

        let message = serde_json::to_string(&ServerMessage::DataFeedUpdate {
            data_feed: RpcDataFeed {
                feed_id: feed_id.clone(),
                calldata: Some(hex::encode(hyperlane_message.as_bytes())),
            },
        })?;
        self.sender.send(message.into()).await?;

        // TODO: success metric

        // self.sender.flush().await?;
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
                // self.ws_state
                //     .metrics
                //     .interactions
                //     .get_or_create(&Labels { interaction: Interaction::CloseConnection, status: Status::Success })
                //     .inc();

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
                // This metric can be used to monitor the number of active connections
                // self.ws_state
                //     .metrics
                //     .interactions
                //     .get_or_create(&Labels { interaction: Interaction::ClientHeartbeat, status: Status::Success })
                //     .inc();

                self.responded_to_ping = true;
                return Ok(());
            }
        };

        match maybe_client_message {
            Err(e) => {
                // self.ws_state
                //     .metrics
                //     .interactions
                //     .get_or_create(&Labels { interaction: Interaction::ClientMessage, status: Status::Error })
                //     .inc();
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
                    Some(missing_id) => {
                        // TODO: return multiple missing ids
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
                            self.active_chain = chain_name;
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

        // self.ws_state
        //     .metrics
        //     .interactions
        //     .get_or_create(&Labels { interaction: Interaction::ClientMessage, status: Status::Success })
        //     .inc();

        self.sender
            .send(serde_json::to_string(&ServerMessage::Response(ServerResponseMessage::Success))?.into())
            .await?;

        Ok(())
    }
}
