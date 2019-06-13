# Example - Consul Template with Vault Agent mode 

* Vault-agent to authenticate and renew token
* Consul-template to watch vault and render template
* gostatic to expose simple html page

# STEPS

1. export BV_VERSION="0.4.17-rc3"
1. ../../common/start-kind.sh
1. ../../common/vault-operator.sh
1. ../../common/vault-common.sh
1. ./vault-cm-kunernetes-kv.sh
1. ../../common/vault-file-storage.sh
1. ./consul-template-vault-agent-sidecar.sh
1. export KUBECONFIG=$(kind get kubeconfig-path)
1. stern -n default -l app=vault-client-demo
1. kubectl port-forward service/vault-client-demo 8043
1. curl http://localhost:8043/test1.html
1. kind delete cluster --name="kind"
