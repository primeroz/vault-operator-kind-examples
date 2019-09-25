FROM debian:9-slim

RUN apt-get update && apt-get install -y \
    netbase \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY --from=stefanprodan/podinfo:1.5.1 /podinfo /usr/bin/podinfo
COPY --from=banzaicloud/vault-env:0.5.3 /usr/local/bin/vault-env /usr/bin/vault-env
