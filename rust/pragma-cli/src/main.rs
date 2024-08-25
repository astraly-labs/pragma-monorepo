use anyhow::Result;
use clap::{Parser, Subcommand};
use tracing::Level;
use utils::tracing::init_tracing;

use pragma_cli::{
    cli::{
        self,
        types::{DataFeed, HasSelector, StateUpdate},
    },
    utils::constants::ORACLE_ADDRESS,
};

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Lists all the existing data feeds
    List,
    /// Schedule a new data feed automation
    Schedule {
        /// RPC Url for the Madara node
        #[clap(short, long = "rpc-url")]
        rpc_url: Option<String>,
        /// Frequency of updates in blocks
        #[clap(short)]
        frequency: Option<u128>,
        /// Assets to be included in the data feed
        #[clap(short)]
        assets: Vec<String>,
        /// Data feed name
        #[clap(short, long = "data-feed-name")]
        data_feed_name: String,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    init_tracing("pragma-cli", Level::INFO)?;

    let cli = Cli::parse();
    match &cli.command {
        Some(Commands::List) => cli::list::list(),
        Some(Commands::Schedule { rpc_url, frequency, assets, data_feed_name: _ }) => {
            let data_feed =
                DataFeed::new(assets.to_vec(), ORACLE_ADDRESS.to_string(), StateUpdate::Checkpoint.to_selector());
            cli::schedule::schedule(rpc_url, frequency, &data_feed).await
        }
        None => tracing::info!("Use --help to see the complete list of available commands"),
    }

    Ok(())
}
