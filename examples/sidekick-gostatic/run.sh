#!/bin/bash
set -e

export BV_VERSION="0.4.17-rc.3"
../../common/start-kind.sh
../../common/vault-operator.sh
../../common/vault-common.sh
./vault-cm-kunernetes-kv.sh
../../common/vault-file-storage.sh
./sidekick-gostatic.sh
export KUBECONFIG=$(kind get kubeconfig-path)
stern -n default -l app=vault-client-demo
