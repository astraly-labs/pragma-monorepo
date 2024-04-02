use anyhow::Result;
use scale::{Decode, Encode};
use subxt::{
    backend::legacy::LegacyRpcMethods,
    blocks,
    config::{DefaultExtrinsicParams, DefaultExtrinsicParamsBuilder, ExtrinsicParams},
    tx, Config, OnlineClient,
};

/// Wait for the transaction to be included successfully into a block.
///
/// # Errors
///
/// If a runtime Module error occurs, this will only display the pallet and error indices.
/// Dynamic lookups of the actual error will be available once the following issue is
/// resolved: <https://github.com/paritytech/subxt/issues/443>.
///
/// # Finality
///
/// Currently this will report success once the transaction is included in a block. In the
/// future there could be a flag to wait for finality before reporting success.
async fn submit_extrinsic<C, Call, Signer>(
    client: &OnlineClient<C>,
    rpc: &LegacyRpcMethods<C>,
    call: &Call,
    signer: &Signer,
) -> core::result::Result<blocks::ExtrinsicEvents<C>, subxt::Error>
where
    C: Config,
    Call: tx::TxPayload,
    Signer: tx::Signer<C>,
    <C::ExtrinsicParams as ExtrinsicParams<C>>::Params: From<<DefaultExtrinsicParams<C> as ExtrinsicParams<C>>::Params>,
{
    let account_id = Signer::account_id(signer);
    let account_nonce = get_account_nonce(client, rpc, &account_id).await?;

    let params = DefaultExtrinsicParamsBuilder::new().nonce(account_nonce).build();
    let mut tx = client.tx().create_signed_offline(call, signer, params.into())?.submit_and_watch().await?;

    // Below we use the low level API to replicate the `wait_for_in_block` behaviour which
    // was removed in subxt 0.33.0. See https://github.com/paritytech/subxt/pull/1237.
    //
    // We require this because we use `substrate-contracts-node` as our development node,
    // which does not currently support finality, so we just want to wait until it is
    // included in a block.
    use subxt::error::{RpcError, TransactionError};
    use tx::TxStatus;

    while let Some(status) = tx.next().await {
        match status? {
            TxStatus::InBestBlock(tx_in_block) | TxStatus::InFinalizedBlock(tx_in_block) => {
                let events = tx_in_block.wait_for_success().await?;
                return Ok(events);
            }
            TxStatus::Error { message } => return Err(TransactionError::Error(message).into()),
            TxStatus::Invalid { message } => return Err(TransactionError::Invalid(message).into()),
            TxStatus::Dropped { message } => return Err(TransactionError::Dropped(message).into()),
            _ => continue,
        }
    }
    Err(RpcError::SubscriptionDropped.into())
}

/// Return the account nonce at the *best* block for an account ID.
async fn get_account_nonce<C>(
    client: &OnlineClient<C>,
    rpc: &LegacyRpcMethods<C>,
    account_id: &C::AccountId,
) -> core::result::Result<u64, subxt::Error>
where
    C: Config,
{
    let best_block = rpc.chain_get_block_hash(None).await?.ok_or(subxt::Error::Other("Best block not found".into()))?;
    let account_nonce = client.blocks().at(best_block).await?.account_nonce(account_id).await?;
    Ok(account_nonce)
}

async fn state_call<C, A: Encode, R: Decode>(rpc: &LegacyRpcMethods<C>, func: &str, args: A) -> Result<R>
where
    C: Config,
{
    let params = args.encode();
    let bytes = rpc.state_call(func, Some(&params), None).await?;
    Ok(R::decode(&mut bytes.as_ref())?)
}

/// Fetch the hash of the *best* block (included but not guaranteed to be finalized).
async fn get_best_block<C>(rpc: &LegacyRpcMethods<C>) -> core::result::Result<C::Hash, subxt::Error>
where
    C: Config,
{
    rpc.chain_get_block_hash(None).await?.ok_or(subxt::Error::Other("Best block not found".into()))
}

// Converts a Url into a String representation without excluding the default port.
pub fn url_to_string(url: &url::Url) -> String {
    match (url.port(), url.port_or_known_default()) {
        (None, Some(port)) => {
            format!("{}:{port}{}", &url[..url::Position::AfterHost], &url[url::Position::BeforePath..]).to_string()
        }
        _ => url.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn url_to_string_works() {
        // with custom port
        let url = url::Url::parse("ws://127.0.0.1:9944").unwrap();
        assert_eq!(url_to_string(&url), "ws://127.0.0.1:9944/");

        // with default port
        let url = url::Url::parse("wss://127.0.0.1:443").unwrap();
        assert_eq!(url_to_string(&url), "wss://127.0.0.1:443/");

        // with default port and path
        let url = url::Url::parse("wss://127.0.0.1:443/test/1").unwrap();
        assert_eq!(url_to_string(&url), "wss://127.0.0.1:443/test/1");

        // with default port and domain
        let url = url::Url::parse("wss://test.io:443").unwrap();
        assert_eq!(url_to_string(&url), "wss://test.io:443/");

        // with default port, domain and path
        let url = url::Url::parse("wss://test.io/test/1").unwrap();
        assert_eq!(url_to_string(&url), "wss://test.io:443/test/1");
    }
}
