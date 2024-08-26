#!/usr/bin/env bash
if ! [ -x "$(command -v psql)" ]; then
    echo >&2 "Error: psql is not installed."
    exit 1
fi

if ! [ -x "$(command -v sqlx)" ]; then
    echo >&2 "Error: sqlx is not installed."
    exit 1
fi

# Check if a custom user exists - otherwise defaults to "postgres"
DB_USER="${POSTGRES_USER:=postgres}"

# Check if a custom password exists - otherwise default to "password"
DB_PASSWORD="${POSTGRES_PASSWORD:=password}"

# Check if a custom database name exists - otherwise default to "indexing"
DB_NAME="${POSTGRES_DB:=indexing}"

# Check if a custom port exists - otherwise default to "5432"
DB_PORT="${POSTGRES_PORT:=5432}"

# Check if a custom host exists - otherwise default to "localhost"
DB_HOST="${POSTGRES_HOST:=localhost}"

CONTAINER_NAME="pragma-x-indexer-db"

# Skip if the postgres container is already running
if [[ -z "${SKIP_DOCKER}" ]]; then
    docker run \
        -e POSTGRES_USER=${DB_USER} \
        -e POSTGRES_PASSWORD=${DB_PASSWORD} \
        -e POSTGRES_DB=${DB_NAME} \
        -p "${DB_PORT}":5432 \
        --name ${CONTAINER_NAME} \
        -d postgres \
        postgres -N 1000 # Maximum number of connections
fi

# Wait for the postgres container to be healthy
until docker exec ${CONTAINER_NAME} pg_isready; do
    echo >&2 "🐘 Waiting for Postgres to be ready..."
    sleep 2
done

DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}
echo >&2 "Database URL: $DATABASE_URL"
export DATABASE_URL

echo >&2 "🥳 Postgres is up and running at ${DB_HOST}:${DB_PORT}"
