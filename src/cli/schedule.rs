use subxt::{OnlineClient, SubstrateConfig};
use subxt_signer::sr25519::dev::{self};

use crate::{
    runtimes::support::madara::{
        self,
        runtime_types::pallet_autonomous::types::{UserJob, UserPolicy},
    },
    utils::conversion::{string_to_felt_252_wrapper, u128_to_felt_252_wrapper},
};

use super::types::DataFeed;

pub async fn schedule(rpc_url: &Option<String>, frequency: &Option<u128>, data_feed: &DataFeed) {
    let rpc_url = rpc_url.as_deref().unwrap_or("ws://127.0.0.1:9944");
    let frequency = frequency.unwrap_or(10);

    match schedule_data_feed(&rpc_url.to_string(), &frequency, data_feed).await {
        Ok(_) => {
            log::info!("Data Feed successfully scheduled!");
        }
        Err(err) => {
            log::error!("Failed to schedule the given data feed: {}", err);
        }
    }
}

async fn schedule_data_feed(
    rpc_url: &String,
    frequency: &u128,
    data_feed: &DataFeed,
) -> Result<(), Box<dyn std::error::Error>> {
    let api = OnlineClient::<SubstrateConfig>::from_url(rpc_url).await?;

    let alice_pair_signer = dev::alice();

    let mut call = vec![
        string_to_felt_252_wrapper(&data_feed.contract_address), /* contract_address */
        string_to_felt_252_wrapper(&data_feed.selector),         /* selector for the `with_arg` external */
        u128_to_felt_252_wrapper(data_feed.calldata.len() as u128), /* calldata_len */
    ];
    call.extend(data_feed.calldata.iter().map(|s| string_to_felt_252_wrapper(s)));

    let user_job = UserJob { calls: vec![call], policy: UserPolicy { frequency: 10 } };

    let schedule_tx = madara::tx().autonomous().register_job(user_job);
    let _schedule_events = api
        .tx()
        .sign_and_submit_then_watch_default(&schedule_tx, &alice_pair_signer)
        .await
        .map(|e| {
            log::info!("Job scheduling submitted, waiting for transaction to be finalized...");
            e
        })?
        .wait_for_finalized_success()
        .await?;

    log::info!("Scheduling data feed with frequency: {}, data feed: {:?}", frequency, data_feed);

    Ok(())
}
