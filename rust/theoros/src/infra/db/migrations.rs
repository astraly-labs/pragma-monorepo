use anyhow::{anyhow, Result};
use deadpool_diesel::postgres::Pool;
use diesel_migrations::{embed_migrations, EmbeddedMigrations, MigrationHarness};

pub const MIGRATIONS: EmbeddedMigrations = embed_migrations!("./migrations/");

pub async fn run_migrations(pool: &Pool) -> Result<()> {
    let conn = pool.get().await?;
    conn.interact(|conn| conn.run_pending_migrations(MIGRATIONS).map(|_| ()))
        .await
        .map_err(|e| anyhow!("Could not run migrations: {e}"))?
        .map_err(|e| anyhow!("Could not run migrations: {e}"))?;

    Ok(())
}
