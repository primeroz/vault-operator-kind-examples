#!/usr/bin/env bash
set -e

export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
data:
  config.yaml: |
    method: kubernetes
    login_path: /v1/auth/kubernetes/login
kind: ConfigMap
metadata:
  labels:
    app: vault-client-demo
  name: auth-config
  namespace: default
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
      - args:
        - -auth=/config/config.yaml
        - -tls-skip-verify=true
        - -renew-token=true
        - -output=/secrets
        - -logtostderr=true
        - -v=10
        - -vault=https://vault.vault.svc.cluster.local:8200
        - -cn=secret:sandbox_v1/data/values/test1:file=kv1_credentials,update=1m
        - -cn=secret:sandbox_v1/data/values/test2:file=kv1_credentials_test2,update=1m
        - -cn=secret:sandbox_v2/data/values/test:file=kv2_credentials,update=1m
        image: quay.io/ukhomeofficedigital/vault-sidekick:v0.3.10
        name: vault-sidekick
        env:
        - name: VAULT_SIDEKICK_METHOD                                
          value: kubernetes
        - name: VAULT_SIDEKICK_ROLE
          value: default
        resources:
          limits:
            cpu: 100m
            memory: 256Mi
          requests:
            cpu: 50m
            memory: 64Mi
        volumeMounts:
        - mountPath: /secrets
          name: secrets
        - mountPath: /config
          name: auth-config
      - args:
        - sleep
        - "7200"
        image: busybox
        name: busybox
        resources:
          limits:
            cpu: 50m
            memory: 64Mi
          requests:
            cpu: 50m
            memory: 64Mi
        volumeMounts:
        - mountPath: /secrets
          name: secrets
      - args:
        - -path=/secrets
        - -port=8043
        image: pierrezemb/gostatic:latest
        name: gostatic
        ports:
        - containerPort: 8043
          name: http
        resources:
          limits:
            cpu: 50m
            memory: 64Mi
          requests:
            cpu: 50m
            memory: 64Mi
        volumeMounts:
        - mountPath: /secrets
          name: secrets
      volumes:
      - emptyDir:
          medium: Memory
        name: secrets
      - configMap:                      
          name: auth-config
        name: auth-config
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
