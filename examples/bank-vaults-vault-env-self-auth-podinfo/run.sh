#!/bin/bash
set -e

export BV_VERSION="0.5.3"
../../common/start-kind.sh
../../common/vault-operator.sh
../../common/vault-common.sh
./vault-cm-kunernetes-kv.sh
../../common/vault-file-storage.sh
./vault-env.sh
export KUBECONFIG=$(kind get kubeconfig-path --name="vault")
stern -n default -l app=vault-client-demo

