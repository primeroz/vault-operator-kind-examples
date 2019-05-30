#!/bin/bash
set -e

export BV_VERSION="0.4.16"
../../common/start-kind.sh
../../common/vault-operator.sh
../../common/vault-common.sh
./vault-cm-kunernetes-kv.sh
../../common/vault-file-storage.sh
./consul-template-vault-agent-sidecar.sh
export KUBECONFIG=$(kind get kubeconfig-path)
stern -n default -l app=vault-client-demo

