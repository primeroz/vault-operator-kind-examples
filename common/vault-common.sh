#!/usr/bin/env bash
set -e


export KUBECONFIG="$(kind get kubeconfig-path --name="vault")"

cat <<EOF | kubectl apply -f -
kind: ServiceAccount
apiVersion: v1
metadata:
  name: vault
  namespace: vault
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: vault-secrets
  namespace: vault
rules:
  - apiGroups:
      - ""
    resources:
      - secrets
    verbs:
      - "*"
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: vault-secrets
  namespace: vault
roleRef:
  kind: Role
  name: vault-secrets
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: ServiceAccount
    name: vault
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: vault-auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: vault
    namespace: vault
EOF

