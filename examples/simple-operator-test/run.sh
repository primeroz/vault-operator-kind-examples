#!/bin/bash
set -e

export BV_VERSION="0.4.18"
../../common/start-kind.sh
../../common/vault-operator.sh
../../common/vault-common.sh
./run-dex.sh
./vault-cm-kunernetes-kv.sh
./vault-file-storage.sh
