use axum::extract::State;
use axum::Json;
use serde::{Deserialize, Serialize};
use utoipa::{ToResponse, ToSchema};

use crate::configs::evm_config::EvmChainName;
use crate::errors::GetChainsError;
use crate::AppState;

#[derive(Debug, Default, Serialize, Deserialize, ToResponse, ToSchema)]
pub struct GetChainsResponse(pub Vec<EvmChainName>);

#[utoipa::path(
    get,
    path = "/v1/chains",
    responses(
        (status = 200, description = "Get all the supported chains", body = [GetDataFeedsResponse])
    ),
)]
pub async fn get_chains(State(state): State<AppState>) -> Result<Json<GetChainsResponse>, GetChainsError> {
    let started_at = std::time::Instant::now();

    let chains = state.evm_hyperlane_rpcs.chain_names();
    let response = GetChainsResponse(chains);

    tracing::info!("🌐 get_chains - {:?}", started_at.elapsed());
    Ok(Json(response))
}
