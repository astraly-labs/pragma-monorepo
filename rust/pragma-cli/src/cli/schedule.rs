use super::types::DataFeed;

pub async fn schedule(rpc_url: &Option<String>, frequency: &Option<u128>, data_feed: &DataFeed) {
    let rpc_url = rpc_url.as_deref().unwrap_or("ws://127.0.0.1:9944");
    let frequency = frequency.unwrap_or(10);

    match schedule_data_feed(rpc_url, &frequency, data_feed).await {
        Ok(_) => {
            tracing::info!("Data Feed successfully scheduled!");
        }
        Err(err) => {
            tracing::error!("Failed to schedule the given data feed: {}", err);
        }
    }
}

async fn schedule_data_feed(
    _rpc_url: &str,
    frequency: &u128,
    data_feed: &DataFeed,
) -> Result<(), Box<dyn std::error::Error>> {
    tracing::info!("Scheduling data feed with frequency: {}, data feed: {:?}", frequency, data_feed);
    Ok(())
}
