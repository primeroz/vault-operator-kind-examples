#!/usr/bin/env bash
set -e

export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-env-secrets
  namespace: default
data:
  secrets.file: |
    VERSION 2            
                                                               
    MOUNT sandbox_v1
    USERNAME=data/values/test#Username
    PASSWORD=data/values/test#Password
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: vault-client-demo
  name: vault-client-demo
  namespace: default
spec:
  selector:
    matchLabels:
      app: vault-client-demo
  template:
    metadata:
      labels:
        app: vault-client-demo
    spec:
      initContainers:
      - env:
        - name: VAULT_SKIP_VERIFY
          value: "true"
        - name: VAULT_ADDR
          value: https://vault.vault.svc.cluster.local:8200
        - name: VAULT_ROLE
          value: default
        - name: TOKEN_DEST_PATH
          value: /home/vault/.vault-token
        - name: TOKEN_ACCESSOR_PATH
          value: /home/vault/.vault-token-accessor
        image: sethvargo/vault-kubernetes-authenticator:0.2.0
        name: vault-authenticator
        resources:
          limits:
            cpu: 50m
            memory: 64Mi
          requests:
            cpu: 10m
            memory: 32Mi
        securityContext:
          allowPrivilegeEscalation: false
        volumeMounts:
        - mountPath: /home/vault
          name: vault-auth
      containers:
      - image: primeroz/podinfo:latest
        imagePullPolicy: Always
        name: podinfo
        env:
        - name: VAULT_SERVICE_HOST
          value: vault.vault.svc.cluster.local
        - name: VAULT_SERVICE_PORT_VAULT
          value: "8200"
        - name: VAULTENV_CONNECT_TLS
          value: "true"
        - name: VAULTENV_VALIDATE_CERTS
          value: "false"
        ports:
        - containerPort: 8043
          name: http
        resources:
          limits:
            cpu: 100m
            memory: 128Mi
          requests:
            cpu: 50m
            memory: 64Mi
        volumeMounts:
        - mountPath: /secrets
          name: vault-env-secrets
        - mountPath: /home/vault
          name: vault-auth
      securityContext:
        fsGroup: 1000
        runAsUser: 1001
      volumes:
      - emptyDir:
          medium: Memory
        name: vault-auth
      - configMap:
          name: vault-env-secrets
        name: vault-env-secrets
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: vault-client-demo
  name: vault-client-demo
  namespace: default
spec:
  ports:
  - port: 8043
    protocol: TCP
    targetPort: http
  selector:
    app: vault-client-demo
  type: ClusterIP
EOF
