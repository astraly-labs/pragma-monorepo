use {
    crate::{
        storage::DispatchUpdateInfos,
        types::{
            pragma::constants::{MAX_CLIENT_MESSAGE_SIZE, PING_INTERVAL_DURATION},
            rpc::RpcDataFeed,
        },
        AppState,
    },
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
pub struct PriceFeedClientConfig {}

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

pub struct WsState {
    pub subscriber_counter: AtomicUsize,
}

impl WsState {
    pub fn new() -> Self {
        Self { subscriber_counter: AtomicUsize::new(0) }
    }
}

#[derive(Deserialize, Debug, Clone)]
#[serde(tag = "type")]
enum ClientMessage {
    #[serde(rename = "subscribe")]
    Subscribe { ids: Vec<String> },
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

pub fn ws_route_handler(
    ws: WebSocketUpgrade,
    AxumState(state): AxumState<AppState>,
    headers: HeaderMap,
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

    let mut subscriber = Subscriber::new(id, Arc::new(state.clone()), feeds_receiver, receiver, sender);

    subscriber.run().await;
}

pub type SubscriberId = usize;

pub struct Subscriber {
    id: SubscriberId,
    closed: bool,
    state: Arc<AppState>,
    feeds_receiver: Receiver<DispatchUpdateInfos>,
    receiver: SplitStream<WebSocket>,
    sender: SplitSink<WebSocket, Message>,
    ping_interval: tokio::time::Interval,
    exit: watch::Receiver<bool>,
    responded_to_ping: bool,
}

impl Subscriber {
    pub fn new(
        id: SubscriberId,
        state: Arc<AppState>,
        feeds_receiver: Receiver<DispatchUpdateInfos>,
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
            ping_interval: tokio::time::interval(PING_INTERVAL_DURATION),
            exit: crate::EXIT.subscribe(),
            responded_to_ping: true,
        }
    }

    #[tracing::instrument(skip(self))]
    pub async fn run(&mut self) {
        while !self.closed {
            if let Err(e) = self.handle_next().await {
                tracing::debug!(subscriber = self.id, error = ?e, "Error Handling Subscriber Message.");
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

    async fn handle_data_feeds_update(&mut self, update_infos: DispatchUpdateInfos) -> Result<()> {
        todo!()
    }

    #[tracing::instrument(skip(self, message))]
    async fn handle_client_message(&mut self, message: Message) -> Result<()> {
        let maybe_client_message = match message {
            Message::Close(_) => {
                // Closing the connection. We don't remove it from the subscribers
                // list, instead when the Subscriber struct is dropped the channel
                // to subscribers list will be closed and it will eventually get
                // removed.
                tracing::trace!(id = self.id, "Subscriber Closed Connection.");
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

            Ok(ClientMessage::Subscribe { ids }) => {
                // let price_ids: Vec<PriceIdentifier> = ids.into_iter().map(|id| id.into()).collect();
                // let available_price_ids = Aggregates::get_price_feed_ids(&*self.state).await;

                // let not_found_price_ids: Vec<&PriceIdentifier> =
                //     price_ids.iter().filter(|price_id| !available_price_ids.contains(price_id)).collect();

                // // If there is a single price id that is not found, we don't subscribe to any of the
                // // asked correct price feed ids and return an error to be more explicit and clear.
                // if !not_found_price_ids.is_empty() {
                //     self.sender
                //         .send(
                //             serde_json::to_string(&ServerMessage::Response(ServerResponseMessage::Err {
                //                 error: format!("Price feed(s) with id(s) {:?} not found", not_found_price_ids),
                //             }))?
                //             .into(),
                //         )
                //         .await?;
                //     return Ok(());
                // } else {
                //     for price_id in price_ids {
                //         self.price_feeds_with_config
                //             .insert(price_id, PriceFeedClientConfig { verbose, binary, allow_out_of_order });
                //     }
                // }
            }
            Ok(ClientMessage::Unsubscribe { ids }) => {
                // for id in ids {
                //     let price_id: PriceIdentifier = id.into();
                //     self.price_feeds_with_config.remove(&price_id);
                // }
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
