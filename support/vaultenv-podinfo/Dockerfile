FROM ubuntu:18.04

RUN apt-get update && apt-get install -y \
    netbase \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY --from=stefanprodan/podinfo:1.5.1 /podinfo /usr/bin/podinfo

ADD https://github.com/channable/vaultenv/releases/download/v0.9.0/vaultenv-0-9-0 /usr/bin/vaultenv
RUN chmod +x /usr/bin/vaultenv

COPY /entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
