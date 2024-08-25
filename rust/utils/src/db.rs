use anyhow::{anyhow, Result};

use deadpool_diesel::postgres::{Manager, Pool};

pub fn init_db_pool(app_name: &str, database_url: &str) -> Result<Pool> {
    let manager_url = format!("{}?application_name={}", database_url, app_name);
    let manager = Manager::new(manager_url, deadpool_diesel::Runtime::Tokio1);

    Pool::builder(manager)
        // TODO: configurable db max conn
        .max_size(25)
        .build()
        .map_err(|e| anyhow!("Could not build database Pool: {e}"))
}
