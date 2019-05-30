#!/usr/bin/env bash
set -e

export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
data:
  config.hcl: |
    exit_after_auth = false
    pid_file = "/home/vault/pidfile"
    
    auto_auth {
        method "kubernetes" {
            mount_path = "auth/kubernetes"
            config = {
                role = "default"
            }
        }
    
        sink "file" {
            config = {
                path = "/home/vault/.vault-token"
            }
        }
    }
kind: ConfigMap
metadata:
  labels:
    app: vault-client-demo
  name: vault-agent-config
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
        - -vault-addr=https://vault.vault.svc.cluster.local:8200
        - -vault-grace=5m
        - -vault-ssl-verify=false
        - -vault-renew-token=false
        - -vault-agent-token-file=/home/vault/.vault-token
        - -vault-retry=true
        - -log-level=trace
        - -template=/var/run/templates/html-template.html:/tmp/rendered/test1.html
        env:
        - name: HOME
          value: /home/vault
        image: hashicorp/consul-template:0.20.0-scratch
        name: consul-template
        resources:
          limits:
            cpu: 100m
            memory: 256Mi
          requests:
            cpu: 50m
            memory: 64Mi
        volumeMounts:
        - mountPath: /home/vault
          name: vault-auth
        - mountPath: /tmp/rendered
          name: rendered
        - mountPath: /var/run/templates/
          name: html-template
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
        - mountPath: /home/vault
          name: vault-auth
      - args:
        - -path=/tmp/rendered
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
        - mountPath: /tmp/rendered
          name: rendered
      - env:
        - name: VAULT_SKIP_VERIFY
          value: "true"
        - name: VAULT_ADDR
          value: https://vault.vault.svc.cluster.local:8200
        image: vault:1.1.2
        name: vault-agent
        command: ["vault"]
        args:
          - agent
          - "-config=/tmp/vault/config.hcl"
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
        - mountPath: /tmp/vault
          name: vault-agent-config
      securityContext:
        fsGroup: 1000
        runAsUser: 1001
      volumes:
      - emptyDir:
          medium: Memory
        name: vault-auth
      - emptyDir:
          medium: Memory
        name: rendered
      - configMap:
          name: html-template
        name: html-template
      - configMap:
          name: vault-agent-config
        name: vault-agent-config
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
---
apiVersion: v1
data:
  html-template.html: |
    <html>
    <body>
    This is a Consul template generated at {{ timestamp }}<br><br>

    Vault Values:<br>
    {{ with secret "sandbox/data/values/test" }}
    value1 : {{ .Data.data.Value1 }}<br>
    value2 : {{ .Data.data.Value2 }}<br>
    {{end}}
    </body>
    </html>
kind: ConfigMap
metadata:
  labels:
    app: vault-client-demo
  name: html-template
  namespace: default
EOF
