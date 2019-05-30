#!/usr/bin/env bash
set -e

export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
BV_VERSION=${BV_VERSION:-0.4.16}


echo "Creating Operator" 
cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  annotations: {}
  labels:
    project: vault
  name: vault
---
EOF

sleep 2

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-operator
  namespace: vault
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: vault-operator
  namespace: vault
rules:
  - apiGroups:
      - ""
    resources:
      - pods
      - services
      - configmaps
      - secrets
    verbs:
      - '*'
  - apiGroups:
      - ""
    resources:
      - namespaces
    verbs:
      - get
  - apiGroups:
      - extensions
    resources:
      - ingresses
    verbs:
      - list
      - get
      - create
      - update
      - watch
  - apiGroups:
      - apps
    resources:
      - replicasets
    verbs:
      - get
  - apiGroups:
      - apps
    resources:
      - deployments
      - statefulsets
    verbs:
      - '*'
  - apiGroups:
      - monitoring.coreos.com
    resources:
      - servicemonitors
    verbs:
      - update
      - list
      - get
      - create
  - apiGroups:
      - vault.banzaicloud.com
    resources:
      - '*'
    verbs:
      - '*'
  - apiGroups:
      - etcd.database.coreos.com
    resources:
      - "*"
    verbs:
      - "*"
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: vault-operator
  namespace: vault
subjects:
  - kind: ServiceAccount
    name: vault-operator
    namespace: vault
roleRef:
  kind: Role
  name: vault-operator
  apiGroup: rbac.authorization.k8s.io
EOF

cat <<EOF | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: vaults.vault.banzaicloud.com
spec:
  group: vault.banzaicloud.com
  names:
    kind: Vault
    listKind: VaultList
    plural: vaults
    singular: vault
  scope: Namespaced
  version: v1alpha1
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vault-operator
  namespace: vault
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      name: vault-operator
  template:
    metadata:
      labels:
        name: vault-operator
    spec:
      serviceAccountName: vault-operator
      containers:
        - name: vault-operator
          image: banzaicloud/vault-operator:$BV_VERSION
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8083
              name: metrics
          command:
            - vault-operator
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 4
            periodSeconds: 10
            failureThreshold: 1
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            initialDelaySeconds: 4
            periodSeconds: 10
            failureThreshold: 1
          env:
            - name: WATCH_NAMESPACE
              # Use this to watch all namespaces
              # value: ""
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: OPERATOR_NAME
              value: "vault-operator"
EOF

