#!/usr/bin/env bash
set -e

export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-cm-kubernetes-kv
  namespace: vault
  labels:
    vault_cr: vault
    app: vault-configurator
data:
  vault-config.yml: |-
    secrets:
      - path: sandbox_v2
        type: kv-v2
        description: General secrets for the Sandbox
      - path: sandbox_v1
        type: kv
    policies:
      - name: sandbox
        rules: |
          path "sandbox_v1/data/*"
          {
            capabilities = ["create","update","read","list", "delete"]
          }
          path "sandbox_v2/data/*"
          {
            capabilities = ["create","update","read","list", "delete"]
          }
          path "sandbox_v2/metadata/*"
          {
            capabilities = ["create","update","read","list", "delete"]
          }
    auth:
      - type: kubernetes
        roles:
          # Allow every pod in the default namespace to use the secret kv store
          - name: default
            bound_service_account_names: "*"
            bound_service_account_namespaces: default
            policies: sandbox
            ttl: 10m
    startupSecrets:
      - type: kv
        path: sandbox_v2/data/values/test
        data:
          data:
            Value1: secretId
            Value2: s3cr3t
      - type: kv
        path: sandbox_v1/data/values/test1
        data:
          data:
            Value1: aValue
            Value2: anotherValue
      - type: kv
        path: sandbox_v1/data/values/test2
        data:
          ttl: 60s
          data:
            Value1: aShorterTTLValue
            Value2: anotherShorterTTLValue
EOF
