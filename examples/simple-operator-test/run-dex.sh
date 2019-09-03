#!/usr/bin/env bash
set -e

export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    name: kube-auth
  name: kube-auth
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    name: dex
  name: dex
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: dex
subjects:
- kind: ServiceAccount
  name: dex
  namespace: kube-auth
---
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    name: dex
  name: dex
rules:
- apiGroups:
  - dex.coreos.com
  resources:
  - '*'
  verbs:
  - '*'
- apiGroups:
  - apiextensions.k8s.io
  resources:
  - customresourcedefinitions
  verbs:
  - create
- apiGroups:
  - ""
  resources:
  - configmaps
  - secrets
  verbs:
  - list
  - watch
  - get
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs:
  - list
  - watch
  - get
---
apiVersion: v1
data:
  config.yaml: |
    issuer: http://dex.kube-auth.svc.cluster.local
    storage:
      type: kubernetes
      config:
        inCluster: true
        namespace: "/dex/"

    web:
      http: 0.0.0.0:5556

    grpc:
      addr: 127.0.0.1:5557

    frontend:
      theme: "coreos"
      issuer: "Test"
      issuerUrl: "http://dex.kube-auth.svc.cluster.local"
      logoUrl: https://i.pinimg.com/originals/d3/97/8a/d3978a3830404998788e8c83dfa6f476.png
    
    telemetry:
      http: 0.0.0.0:5558

    expiry:
      signingKeys: "10m"
      idTokens: "240m"

    logger:
      level: debug
      format: json

    staticClients:
    - id: "vault"
      name: "vault"
      secret: secret
      redirectURIs:
      - http://localhost:8250/oidc/callback
      - http://vault.vault.svc.cluster.local/ui/vault/auth/jwt/oidc/callback"

    enablePasswordDB: true
    staticPasswords:
    - email: "admin@example.com"
      # bcrypt hash of the string "password"
      hash: "\$2a\$10\$2b2cU8CPhOTaGrs1HRQuAueS7JTT5ZHsHSzYiFPm1leZck7Mc8T4W"
      username: "admin"
      userID: "08a8684b-db88-4b73-90a9-3cd1661f5466"
kind: ConfigMap
metadata:
  labels:
    name: dex
  name: dex
  namespace: kube-auth
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    name: dex
  name: dex
  namespace: kube-auth
spec:
  minReadySeconds: 30
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      name: dex
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 0
    type: RollingUpdate
  template:
    metadata:
      labels:
        name: dex
    spec:
      containers:
      - command:
        - /usr/local/bin/dex
        - serve
        - /etc/dex/conf/config.yaml
        image: quay.io/dexidp/dex:v2.18.0
        imagePullPolicy: IfNotPresent
        livenessProbe:
          initialDelaySeconds: 5
          tcpSocket:
            port: 5556
          timeoutSeconds: 3
        name: dex
        ports:
        - containerPort: 5556
          name: http
          protocol: TCP
        - containerPort: 5558
          name: metrics
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /healthz
            port: 5556
            scheme: HTTP
          initialDelaySeconds: 5
          periodSeconds: 10
        volumeMounts:
        - mountPath: /etc/dex/conf
          name: config
      - command:
        - /app/bin/dex-k8s-ingress-watcher
        - serve
        - --incluster
        - --ingress-controller
        - --configmap-controller
        - --secret-controller
        - --dex-grpc-address
        - 127.0.0.1:5557
        image: mintel/dex-k8s-ingress-watcher:latest
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        name: dex-k8s-ingress-watcher
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /readiness
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
      serviceAccount: dex
      serviceAccountName: dex
      terminationGracePeriodSeconds: 30
      volumes:
      - configMap:
          defaultMode: 420
          items:
          - key: config.yaml
            path: config.yaml
          name: dex
        name: config
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    name: dex
  name: dex
  namespace: kube-auth
---
apiVersion: v1
kind: Service
metadata:
  labels:
    name: dex
  name: dex
  namespace: kube-auth
spec:
  ports:
  - name: http
    port: 5556
    protocol: TCP
    targetPort: http
  - name: metrics
    port: 5558
    protocol: TCP
    targetPort: metrics
  selector:
    app.kubernetes.io/part-of: dex
    name: dex
  sessionAffinity: None
  type: ClusterIP
EOF
