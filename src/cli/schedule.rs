use subxt::{
    utils::{AccountId32, MultiAddress},
    OnlineClient, SubstrateConfig,
};
use subxt_signer::sr25519::dev::{self};

use crate::runtimes::support::madara;

pub async fn schedule(rpc_url: &Option<String>, frequency: &Option<u128>, assets: &[String], data_feed: &String) {
    let rpc_url = rpc_url.as_deref().unwrap_or("ws://127.0.0.1:9944");
    let frequency = frequency.unwrap_or(10);

    match schedule_data_feed(&rpc_url.to_string(), &frequency, assets, data_feed).await {
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
    assets: &[String],
    data_feed: &String,
) -> Result<(), Box<dyn std::error::Error>> {
    let api = OnlineClient::<SubstrateConfig>::from_url(rpc_url).await?;

    let alice: MultiAddress<AccountId32, ()> = dev::alice().public_key().into();
    let alice_pair_signer = dev::alice();

    let schedule_tx = madara::tx().autonomous().register_job(user_job);

    log::info!("Scheduling data feed with frequency: {}, assets: {:?}, data feed: {}", frequency, assets, data_feed);

    Ok(())
}
