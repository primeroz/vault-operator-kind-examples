#!/bin/bash
set -e

VAULT_TOKEN_FILE=${VAULT_TOKEN_FILE:-/home/vault/.vault-token}
SECRETS_FILE=${SECRETS_FILE:-/secrets/secrets.file}

# Expect token from vault-agent in "/home/vault/.vault-token"
VAULT_TOKEN=$(cat $VAULT_TOKEN_FILE)

exec /usr/bin/vaultenv \
     --host ${VAULT_SERVICE_HOST} \
     --port ${VAULT_SERVICE_PORT_VAULT} \
     --token ${VAULT_TOKEN} \
     --secrets-file ${SECRETS_FILE} \
     /usr/bin/podinfo \
     -- \
     --port 8043
