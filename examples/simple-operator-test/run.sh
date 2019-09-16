#!/bin/bash
set -e

export K8S_VERSION="v1.15.3@sha256:27e388752544890482a86b90d8ac50fcfa63a2e8656a96ec5337b902ec8e5157"
export BV_VERSION="0.5.3"
export VAULT_VERSION="1.2.2"
../../common/start-kind.sh
../../common/vault-operator.sh
../../common/vault-common.sh
#./run-dex.sh
./vault-cm-kunernetes-kv.sh
./vault-file-storage.sh
