pub async fn schedule(rpc_url: &Option<String>, frequency: &Option<u128>, assets: &[String], data_feed: &String) {
    match schedule_data_feed(frequency, assets, data_feed).await {
        Ok(_) => {
            log::info!("Madara setup successful");
        }
        Err(err) => {
            log::error!("Failed to setup Madara: {}", err);
        }
    }
}

async fn schedule_data_feed(
    frequency: &Option<u128>,
    assets: &[String],
    data_feed: &String,
) -> Result<(), Box<dyn std::error::Error>> {
    let frequency = frequency.unwrap_or(10);

    log::info!("Scheduling data feed with frequency: {}, assets: {:?}, data feed: {}", frequency, assets, data_feed);

    Ok(())
}
