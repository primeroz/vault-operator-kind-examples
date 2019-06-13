# Example - Simple webhook example 

* uses bank-vaults mutating webhook
  * https://banzaicloud.com/blog/inject-secrets-into-pods-vault/
	* https://github.com/banzaicloud/bank-vaults/tree/master/docs/mutating-webhook

![Example Gif](https://banzaicloud.com/img/blog/admission-webhooks/vault-mutating-webhook.gif)

# STEPS

1. export BV_VERSION="0.4.17-rc.3"
1. ../../common/start-kind.sh
1. ../../common/vault-operator.sh
1. ../../common/vault-common.sh
1. ./vault-cm-kunernetes-kv.sh
1. ../../common/vault-file-storage.sh
1. ./vault-webhook.sh*
1. ./vault-webhook-api.sh*
1. ./vault-client-demo.sh*
1. export KUBECONFIG=$(kind get kubeconfig-path)
1. stern -n default -l app=vault-client-demo
1. kind delete cluster --name="kind"

output should be:
```

```
