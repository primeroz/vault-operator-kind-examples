# Example - Vault-sidekick with gostatic

* Vault-sidekick to authenticate and pull secrets into file
https://github.com/UKHomeOffice/vault-sidekick

Support 
* authentication and token renewal
* Custom refresh time on a per secret basis
* write out of data in `ini`, `json` or `yaml` format
* run commands on secret update

# STEPS

1. export BV_VERSION="0.4.17-rc.3"
1. ../../common/start-kind.sh
1. ../../common/vault-operator.sh
1. ../../common/vault-common.sh
1. ./vault-cm-kunernetes-kv.sh
1. ../../common/vault-file-storage.sh
1. ./sidekick-gostatic.sh
1. export KUBECONFIG=$(kind get kubeconfig-path)
1. stern -n default -l app=vault-client-demo
1. kubectl port-forward service/vault-client-demo 8043
1. curl http://localhost:8043/kv2_credentials
1. curl http://localhost:8043/kv1_credentials
1. curl http://localhost:8043/kv1_credentials_test2
1. kind delete cluster --name="kind"
