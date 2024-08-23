use clap::{Parser, Subcommand};
use log::LevelFilter;
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
async fn main() {
    env_logger::Builder::from_default_env()
        .filter_level(LevelFilter::Info)
        .format_timestamp(None)
        .format_level(false)
        .format_target(false)
        .init();

    let cli = Cli::parse();

    match &cli.command {
        Some(Commands::List) => cli::list::list(),
        Some(Commands::Schedule { rpc_url, frequency, assets, data_feed_name: _ }) => {
            let data_feed =
                DataFeed::new(assets.to_vec(), ORACLE_ADDRESS.to_string(), StateUpdate::Checkpoint.to_selector());
            cli::schedule::schedule(rpc_url, frequency, &data_feed).await
        }
        None => log::info!("Use --help to see the complete list of available commands"),
    }
}
