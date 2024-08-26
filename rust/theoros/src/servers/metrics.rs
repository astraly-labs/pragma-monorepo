// Source:
// https://github.com/madara-alliance/madara/blob/main/crates/client/metrics/src/lib.rs#L66

use std::net::{Ipv4Addr, SocketAddr};

use anyhow::{Context, Result};
use hyper::{
    service::{make_service_fn, service_fn},
    Body, Request, Response, Server, StatusCode,
};
use prometheus::{Encoder, TextEncoder};
use tokio::{net::TcpListener, task::JoinHandle};

#[allow(unused)]
pub use prometheus::{
    self,
    core::{
        AtomicF64 as F64, AtomicI64 as I64, AtomicU64 as U64, GenericCounter as Counter,
        GenericCounterVec as CounterVec, GenericGauge as Gauge, GenericGaugeVec as GaugeVec,
    },
    exponential_buckets, Error as PrometheusError, Histogram, HistogramOpts, HistogramVec, IntGaugeVec, Opts, Registry,
};

#[derive(thiserror::Error, Debug)]
#[error("error while handling request in prometheus endpoint: {0}")]
enum MetricsError {
    Prometheus(#[from] prometheus::Error),
    Hyper(#[from] hyper::Error),
    HyperHttp(#[from] hyper::http::Error),
}

pub struct MetricsService {
    prometheus_external: bool,
    prometheus_port: u16,
    registry: Registry,
}

impl MetricsService {
    pub fn new(prometheus_external: bool, prometheus_port: u16) -> Result<Self> {
        let service = Self { prometheus_external, prometheus_port, registry: Default::default() };
        Ok(service)
    }

    pub fn registry(&self) -> Registry {
        self.registry.clone()
    }

    pub fn start(&self) -> Result<JoinHandle<Result<()>>> {
        let listen_addr = if self.prometheus_external {
            Ipv4Addr::UNSPECIFIED // listen on 0.0.0.0
        } else {
            Ipv4Addr::LOCALHOST
        };
        let addr = SocketAddr::new(listen_addr.into(), self.prometheus_port);

        let registry = self.registry.clone();
        let service = make_service_fn(move |_| {
            let registry = registry.clone();
            async move {
                Ok::<_, hyper::Error>(service_fn(move |req: Request<Body>| {
                    let registry = registry.clone();
                    async move {
                        match endpoint(req, registry.clone()).await {
                            Ok(res) => Ok::<_, MetricsError>(res),
                            Err(err) => {
                                tracing::error!("Error when handling prometheus request: {}", err);
                                Ok(Response::builder()
                                    .status(StatusCode::INTERNAL_SERVER_ERROR)
                                    .body(Body::from("Internal server error"))?)
                            }
                        }
                    }
                }))
            }
        });

        let handle = tokio::spawn(async move {
            let socket = TcpListener::bind(addr).await.with_context(|| format!("Opening socket server at {addr}"))?;
            let listener = hyper::server::conn::AddrIncoming::from_listener(socket)
                .with_context(|| format!("Opening socket server at {addr}"))?;
            tracing::info!("🧩 Metrics endpoint started at http://{}", listener.local_addr());
            Server::builder(listener).serve(service).await.context("Running prometheus server")
        });

        Ok(handle)
    }
}

async fn endpoint(req: Request<Body>, registry: Registry) -> Result<Response<Body>, MetricsError> {
    if req.uri().path() == "/metrics" {
        let metric_families = registry.gather();
        let mut buffer = vec![];
        let encoder = TextEncoder::new();
        encoder.encode(&metric_families, &mut buffer)?;

        Ok(Response::builder()
            .status(StatusCode::OK)
            .header("Content-Type", encoder.format_type())
            .body(Body::from(buffer))?)
    } else {
        Ok(Response::builder()
            .status(StatusCode::NOT_FOUND)
            .header("Content-Type", "text/html")
            .body(Body::from("Not found.<br><br><a href=\"/metrics\">See Metrics</a>"))?)
    }
}
