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
      - path: terraform
        type: kv
        description: General secrets for using Terraform
        options:
          version: 2
        configuration:
          config:
            - max_versions: 10
    policies:
      - name: sandbox
        rules: |
          path "sandbox_v2/data/*"
          {
            capabilities = ["create","update","read","list", "delete"]
          }
          path "sandbox_v2/metadata/*"
          {
            capabilities = ["create","update","read","list", "delete"]
          }
      - name: terraform
        rules: |
          path "terraform/data/*"
          {
            capabilities = ["read", "list"]
          }
          path "terraform/metadata/*"
          {
            capabilities = ["read", "list"]
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
      - type: token
        roles:
          - name: terraform
            allowed_policies:
              - terraform_ci
            orphan: true
            renewable: true
            period: "30m"
            explicit_max_ttl: "43200"
            path_suffix: terraform
    startupSecrets:
      - type: kv
        path: sandbox_v2/data/values/test
        data:
          data:
            Value1: aws_secret_id
            Value2: aws_secret_key
EOF
