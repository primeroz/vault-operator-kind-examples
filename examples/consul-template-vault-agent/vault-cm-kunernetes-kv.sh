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
      - path: sandbox
        type: kv-v2
        description: General secrets for the Sandbox
    policies:
      - name: sandbox
        rules: |
          path "sandbox/data/*"
          {
            capabilities = ["create","update","read","list", "delete"]
          }
          path "sandbox/metadata/*"
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
        path: sandbox/data/values/test
        data:
          data:
            Value1: secretId
            Value2: s3cr3t
EOF
