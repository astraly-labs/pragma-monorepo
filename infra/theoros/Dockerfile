
FROM public.ecr.aws/docker/library/rust:1.81.0-slim-bookworm AS build

ARG PACKAGE_NAME=theoros

RUN apt-get update && apt-get install -y --no-install-recommends  \
    build-essential pkg-config libssl-dev protobuf-compiler curl libprotobuf-dev && \
    apt-get autoremove -y  && \
    apt-get clean  && \
    rm -rf /var/lib/apt/lists/*       

RUN apt-get update && apt-get install -y bash curl && curl -1sLf \
'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | bash \
&& apt-get update && apt-get install -y infisical

WORKDIR /app

COPY ./rust .

RUN cargo build --release --package ${PACKAGE_NAME}

FROM public.ecr.aws/docker/library/debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends  \
    libssl-dev wget ca-certificates && \
    apt-get autoremove -y  && \
    apt-get clean  && \
    rm -rf /var/lib/apt/lists/*  
RUN groupadd pragma

RUN useradd -g pragma pragma

USER pragma

WORKDIR /home/pragma
EXPOSE 3000
EXPOSE 8080
COPY --from=build /usr/bin/infisical /usr/bin/infisical
COPY infra/theoros/entrypoint.sh /home/pragma/entrypoint.sh
# Copy artifacts from other images
COPY --from=build /app/target/release/theoros /usr/local/bin/

ENTRYPOINT ["/bin/bash","/home/pragma/entrypoint.sh"]
