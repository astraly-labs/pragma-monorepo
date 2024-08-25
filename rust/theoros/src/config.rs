use serde::Deserialize;
use tokio::sync::OnceCell;

#[derive(Default, Debug, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum Mode {
    #[default]
    Dev,
    Production,
}

#[derive(Default, Debug, Deserialize)]
pub struct ModeConfig {
    mode: Mode,
}

#[derive(Debug, Deserialize)]
pub struct ServerConfig {
    host: String,
    port: u16,
}

impl Default for ServerConfig {
    fn default() -> Self {
        Self { host: "0.0.0.0".to_string(), port: 3000 }
    }
}

#[derive(Default, Debug, Deserialize)]
pub struct Config {
    mode: ModeConfig,
    server: ServerConfig,
}

impl Config {
    pub fn is_production_mode(&self) -> bool {
        self.mode.mode == Mode::Production
    }

    pub fn server_host(&self) -> &str {
        &self.server.host
    }

    pub fn server_port(&self) -> u16 {
        self.server.port
    }
}

pub static CONFIG: OnceCell<Config> = OnceCell::const_new();

async fn init_config() -> Config {
    let mode_config = envy::from_env::<ModeConfig>().unwrap_or_default();
    let server_config = envy::from_env::<ServerConfig>().unwrap_or_default();

    Config { mode: mode_config, server: server_config }
}

pub async fn config() -> &'static Config {
    CONFIG.get_or_init(init_config).await
}
