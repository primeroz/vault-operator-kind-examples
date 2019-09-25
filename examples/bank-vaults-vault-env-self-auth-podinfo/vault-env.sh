#!/usr/bin/env bash
set -e

export KUBECONFIG="$(kind get kubeconfig-path --name="vault")"

cat <<EOF | kubectl apply -f -
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
      containers:
      - image: primeroz/vaultenv-podinfo:0.5.3
        imagePullPolicy: Always
        name: podinfo
        command:
          - vault-env
          - /usr/bin/podinfo
          - --port
          - "8043"
        env:
        - name: VAULT_SKIP_VERIFY
          value: "true"
        - name: VAULT_ADDR
          value: https://vault.vault.svc.cluster.local:8200
        - name: VAULT_ROLE
          value: default
        - name: Value1
          value: vault:sandbox_v2/data/values/test#Value1
        - name: Value2
          value: vault:sandbox_v2/data/values/test#Value2
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
        - mountPath: /home/vault
          name: vault-auth
      securityContext:
        fsGroup: 1000
        runAsUser: 1001
      volumes:
      - emptyDir:
          medium: Memory
        name: vault-auth
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
