
FROM rust:1.81.0-slim-bookworm AS build

ARG PACKAGE_NAME=theoros

RUN apt-get update && apt-get install -y --no-install-recommends  \
    build-essential pkg-config libssl-dev protobuf-compiler curl libprotobuf-dev && \
    apt-get autoremove -y  && \
    apt-get clean  && \
    rm -rf /var/lib/apt/lists/*       

WORKDIR /app

COPY . .

RUN cargo build --release --package ${PACKAGE_NAME}

FROM debian:bookworm-slim

WORKDIR /usr/local/bin

# Copy artifacts from other images
COPY --from=build /app/target/release/theoros .

ENTRYPOINT ["./theoros"]
