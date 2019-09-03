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
      - type: approle
        path: approle
        roles:
        - name: test
          policies: "terraform,sandbox"
          bind_secret_id: true
          secret_id_ttl: ""
          secret_id_num_uses: 0
          token_num_uses: 0
          token_ttl: 10m
          token_max_ttl: 240m
      - type: jwt
        path: jwt
        config:
          oidc_discovery_url: http://dex.kube-auth.svc.cluster.local:5556
          bound_issuer: http://dex.kube-auth.svc.cluster.local:5556
          oidc_client_id: "vault"
          oidc_client_secret: "secret"
          default_role: mintel
        roles:
          - name: mintel
            role_type: jwt
            bound_audiences:
              - vault-oidc
              - vault
            user_claim: email
            groups_claim: "groups"
            policies: "terraform,sandbox"
            ttl: 10m
            max_ttl: 24h
          - name: oidc
            role_type: oidc
            bound_audiences:
              - vault-oidc
              - vault
            user_claim: email
            groups_claim: "groups"
            oidc_scopes: "email,groups"
            policies: "terraform,sandbox"
            ttl: 10m
            max_ttl: 24h
            allowed_redirect_uris: "http://localhost:8250/oidc/callback,http://vault.kube-auth.svc.cluster.local/ui/vault/auth/jwt/oidc/callback"
    startupSecrets:
      - type: kv
        path: sandbox_v2/data/values/test
        data:
          data:
            Value1: aws_secret_id
            Value2: aws_secret_key
    groups:
      - name: admin
        policies:
          - admin_access
          - gcp_admin_access
          - gcp_project_ci_admin_access
        metadata:
          privileged: "true"
        type: external
    group-aliases:
      - name: k8s-admin
        mountpath: jwt
        group: admin
EOF
