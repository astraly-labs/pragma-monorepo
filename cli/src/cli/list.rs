use crate::utils::constants::DATA_FEEDS;

pub fn list() {
    match get_data_feed_list() {
        Ok(feeds) => {
            log::info!("Data Feeds available: {:?}", feeds);
        }
        Err(err) => {
            panic!("Failed to list: {}", err);
        }
    }
}

fn get_data_feed_list() -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let data_feeds = DATA_FEEDS.iter().map(|x| x.to_string()).collect();
    Ok(data_feeds)
}
