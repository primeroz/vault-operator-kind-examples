#!/usr/bin/env bash
set -e

export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    name: vault-webhook
  name: vault-webhook
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: release-name-vault-secrets-webhook
  namespace: vault-webhook
  labels:
    app: vault-secrets-webhook
    component: mutating-webhook
spec:
  replicas: 2
  selector:
    matchLabels:
      app: vault-secrets-webhook
      release: release-name
  template:
    metadata:
      labels:
        app: vault-secrets-webhook
        release: release-name
      annotations:
        checksum/config: c00cefd265ad92d2ceb973ca4a0b54ce1c6609c25bab8793e94c20154835d8af
    spec:
      serviceAccountName: release-name-vault-secrets-webhook
      volumes:
      - name: serving-cert
        secret:
          defaultMode: 420
          secretName: release-name-vault-secrets-webhook
      containers:
        - name: vault-secrets-webhook
          image: "banzaicloud/vault-secrets-webhook:0.4.16"
          env:
          - name: TLS_CERT_FILE
            value: /var/serving-cert/servingCert
          - name: TLS_PRIVATE_KEY_FILE
            value: /var/serving-cert/servingKey
          - name: DEBUG
            value: "true"
          - name: VAULT_ENV_IMAGE
            value: "banzaicloud/vault-env:0.4.16"
          - name: VAULT_IMAGE
            value: "vault:1.1.2"
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8443
          volumeMounts:
          - mountPath: /var/serving-cert
            name: serving-cert
          securityContext:
            runAsUser: 65534
            allowPrivilegeEscalation: false
          resources:
            {}
---
# Source: vault-secrets-webhook/templates/webhook-rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: vault-webhook
  name: release-name-vault-secrets-webhook
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: release-name-vault-secrets-webhook
rules:
  - apiGroups:
      - ""
    resources:
      - secrets
      - configmaps
    verbs:
      - "get"
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - "create"
      - "update"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: release-name-vault-secrets-webhook-limited
roleRef:
  kind: ClusterRole
  apiGroup: rbac.authorization.k8s.io
  name: release-name-vault-secrets-webhook
subjects:
- kind: ServiceAccount
  namespace: vault-webhook
  name: release-name-vault-secrets-webhook
---
# Source: vault-secrets-webhook/templates/webhook-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: release-name-vault-secrets-webhook
  namespace: vault-webhook
  labels:
    app: release-name-vault-secrets-webhook
    component: mutating-webhook
spec:
  type: ClusterIP
  ports:
    - port: 443
      targetPort: 8443
      protocol: TCP
      name: vault-secrets-webhook
  selector:
    app: vault-secrets-webhook
    release: release-name
---
apiVersion: v1
kind: List
metadata:
items:
- apiVersion: v1
  kind: Secret
  metadata:
    name: release-name-vault-secrets-webhook
    namespace: vault-webhook
  data:
    servingCert: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURIakNDQWdhZ0F3SUJBZ0lSQUw0Q0JxaFVPSldtWk5SK29NM2l6bE13RFFZSktvWklodmNOQVFFTEJRQXcKRlRFVE1CRUdBMVVFQXhNS2MzWmpMV05oZEMxallUQWVGdzB4T1RBMk1ETXhOREF3TXpCYUZ3MHlNREEyTURJeApOREF3TXpCYU1EOHhQVEE3QmdOVkJBTVROSEpsYkdWaGMyVXRibUZ0WlMxMllYVnNkQzF6WldOeVpYUnpMWGRsClltaHZiMnN1ZG1GMWJIUXRkMlZpYUc5dmF5NXpkbU13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXcKZ2dFS0FvSUJBUURJNFNUSTBoY200TE5YQ2NtTzBRNm96NmN6V0MrbkdLbUFmNXNIN3pEeTgrbVg1TzhjNHZINQpxQnR5OTZYRFZldUhzN0swYUt4OENKVVFSUXVvUjB0SU9YWldPMUM5VjJTSTVBbE14b3JtWmdsVzg5WnhXYUhTCmZSYlJ1QUFBQ2MrUE1laHhDd2ZSMDluaitJVGQraW9BcDJ4Y0JHSDRwVzZSM28xTVlNVVFEVnRaamplQ094RUsKejV3d1hlQ2Y4c21RbUdTcUxrVGkxb1BsVi8vUFZSOVo3L3dyZmVGMUMzT0djdlpEQUNUd0N6WXRXeUVoNUVlNwpwVVlHMlpRTUt5a1RMUmI3TWd1b002NWNra21TVUlBa094M25vK28vclpFLzNSOVMrY2QwSzhicDZiNmVVNUhWCksyVTQyZHJjYVY1OUFOS09jdXRNRzhxQ3NTM2JTZ250QWdNQkFBR2pQekE5TUE0R0ExVWREd0VCL3dRRUF3SUYKb0RBZEJnTlZIU1VFRmpBVUJnZ3JCZ0VGQlFjREFRWUlLd1lCQlFVSEF3SXdEQVlEVlIwVEFRSC9CQUl3QURBTgpCZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUFxWWhPSkEranV1cDJ4dFRkVU54QUZ0SnpkcVFvMndBbitONU9hSXFvCnFlQlViLzRwSk9vazJMN1hUdGMrY003ZS9IbVhUZXdMYi9Ib1RFRkFtK2xESXhobS9mank0VCtLWUtCaHYySloKb2VDMDVsSEVhcEVaRmYrV1R6NTZQRlVSY1NnVFRVQ0JmbFROV05rZTc0QmoxVERMZmgrTkdZbTBrdmdGOFpXbwoyMEZ3OEpvTTdkR2pvK0UzeDBTQ2hxc1gwbDdxVStHbExGdzFDRjZwYlVMUldleHl0bnVyZDJaVzljZEdGMVdwCkgxUTBLcDNlVUZtRUVRa2tCaitJYTAzcnhYRmhERDQyKzlNN2c3M2pEZUZiV1N1cVdlYVJseFFTbks0b25Td2QKZmpCWFVxZ3ViWklXOTJkcGpwS0VtbzlOREZVTzV4aFVWYlBrWjZESnU4NnhVUT09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    servingKey: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBeU9Fa3lOSVhKdUN6VnduSmp0RU9xTStuTTFndnB4aXBnSCtiQis4dzh2UHBsK1R2CkhPTHgrYWdiY3ZlbHcxWHJoN095dEdpc2ZBaVZFRVVMcUVkTFNEbDJWanRRdlZka2lPUUpUTWFLNW1ZSlZ2UFcKY1ZtaDBuMFcwYmdBQUFuUGp6SG9jUXNIMGRQWjQvaUUzZm9xQUtkc1hBUmgrS1Z1a2Q2TlRHREZFQTFiV1k0MwpnanNSQ3MrY01GM2duL0xKa0poa3FpNUU0dGFENVZmL3oxVWZXZS84SzMzaGRRdHpobkwyUXdBazhBczJMVnNoCkllUkh1NlZHQnRtVURDc3BFeTBXK3pJTHFET3VYSkpKa2xDQUpEc2Q1NlBxUDYyUlA5MGZVdm5IZEN2RzZlbSsKbmxPUjFTdGxPTm5hM0dsZWZRRFNqbkxyVEJ2S2dyRXQyMG9KN1FJREFRQUJBb0lCQVFDYnZIa2hQRWY0dXpJdQo0NGFoTTVEeTdYS0tTdTgrMDg3dHNZQ0c2VGtBMG5zaWFMbThvbkhKQlR5cXFEYWFOeTJRR3BBTWNDNXhSdElTCk9BVnVwRDlJTWt4OVZDVW5kZTZhZG5pRFRsWDNnOW52ME1GTFJadEFyZndZQVZmMnI2UjhOc3duZjg3RExVUjcKQ253d0FEZTZKQkxOVUJTSWlmRXNJK2RWOUp3eThWYm1FN29mbzA1SklaVHFyNjh6bStQZk14YmFpTWpUVzE1eApDODZqZC9UR0hRWFZvTlpVT1Q1aFdickFpM0UvUVpNd3l1V29yRUZLYTdQSGU0em5WNDlqY1pzMlFjWS82WWVvCjVFaGpqZWNlTXpHMnVmK3NFYkpoNVdGdSttQXIzaW1EOWNTU3B3dTRwUk5WOG9pNDB0ZUYyTjBwMG1PczJxeDgKQXdnbHZLUWRBb0dCQVBpM1JmRjNsQ01CRG80R2dSRWpMMVV1ZDVvbTZnZ0hhOUxGUldDRkpUUUxQS0VWL3JLQgpHQkVrRzRTVDBqWE5jMU9KaHNBWExad090T1dpVHRybkhFQnNGeld2MzJXQTBqT3VYU2t1TVpSdXliYjJTSExDCkt3L0FMbzdsS0tzSzZmV1h6WURvY2VlTmIrbC91SzNFcHdlSVp5dXdCNURraHpBQTBsVEVmT2VuQW9HQkFNN0QKT0lIWGFlT1o2U0dTQlJ2YXBSMlRMdEt0VHpiNStxd2xLbGNGZ241Wm1aQm9ib3FoL0tidC9NcVJFdFFDYmJZRQpjU1RjQWQ2OHN3bC9pK1V1Zk9rQ3FPb2x4QitCMDkxcGtaSXpkOEF3MzhBUVZJd0MrM1BGWFgrYWkxdUlMOGNwCm5WbHZZcEtkdEhXeWNHeEltV3VpaS9Fc1B2VGtwMlUyUFllL3dmUkxBb0dBRk1VeGFSM2tXQndCZkNqYzVISjgKeEc5Uis2U2VUTGRaOE1zYXBSblpab1E5dHZJZ1NBWHgzWlNYVzdZQWl3K3lQdHF3VHlCZ1piVHd0SENlaHpkZgpxNTJiUHBlR1gzS25tenRIZW1YcUxBd29la2dNK3RCdVNpMXhkZXQ3UHZWMVhsWWtDa3pmSGtnNGZWWjJOTVRFCmNpT1pBaFA4UGNSbjZjRlh6MDV0WStjQ2dZRUFpMSs3S29NYnBNbXVCZXdaTjRKMlJPNWU1TExncisxb0ZUeGsKUXc2NnZSTUcyZm9iY2FYcDJsaVlTNi9wSWpLVTQ5b3dycWtETmJLN2VRNmFMWjNkbzNBZ2p0MXdTOURIRVB4RgpuV2pHTXk1KzFVZnN4Z2lJbWF5VDd4MHREVUZLKzVUSXRXM0k0NDRkQkMySmJPU3ZUb2ZlajI3RTdXMW9qV2czCnA5Y1NGZXNDZ1lBUk5sTUR6SXFzQ2I2MW11bXhFbGx3S3BmRFpnL1czbFN6aGhBSkI2eGE5VW52bEpaRGthb1IKaERxRzZWWEovQ2Jhdm1XdmJuNU5DbXV2ekcvR2pSRlhRVDVJUUFLNmRadTFQUmUreHdaODNzN09UQnRXRGNyQgo1S2lwREFtTko1VXJSa0J5aEhEY0VnbUlQL3BJQzd3MHRxZUxaZW9KTVRMOXRJYksxc2xQd2c9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
    caCert: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM5ekNDQWQrZ0F3SUJBZ0lSQVBJUWdMVGo3UDlqd21DTXJRZnRnUmN3RFFZSktvWklodmNOQVFFTEJRQXcKRlRFVE1CRUdBMVVFQXhNS2MzWmpMV05oZEMxallUQWVGdzB4T1RBMk1ETXhOREF3TXpCYUZ3MHlPVEExTXpFeApOREF3TXpCYU1CVXhFekFSQmdOVkJBTVRDbk4yWXkxallYUXRZMkV3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBCkE0SUJEd0F3Z2dFS0FvSUJBUUMyTWY2UUxVU0VpNWZBSzVwdXRwL2dlVThGQzdSNFltMHYwK0J2SDdxdWdOd2oKaTIrVU9wNVgwRlZVMHlaY0hwWnJXdFhtVkcxVWlTUEV5NnkzamFOOWF1YU94NUJnbE0yWXBaMzNmUnNPa0YzNwptYUpoQWgra0NMZmJBblFpVEFiMFlxM0trOEY5dE9DNlRKMmZZVHhvRlRLc1cwZktxYkh5aXJtVEtCbUMxRHBxCm1LeDJHSTR4Q1RLUndaMG5qSnZqK0ZydmQ5R1U0Y3RFejJzTG5lOXFYSVMvRUZDL0tnWVJxTjhqVjVkM3FOV3cKTjFzSTU3RTZGRitxVlhTdUVDWXhIL1dabThONUhkVnN6UnZoWEFWVGZWVEw4aXlnUXJIbE9YTUxsVU5ERmRTVApZQlUrdGI1UUN4bjg5dDNzODRTWFpoZS9KbkM3RDhmVGtPa2F0U1ZuQWdNQkFBR2pRakJBTUE0R0ExVWREd0VCCi93UUVBd0lDcERBZEJnTlZIU1VFRmpBVUJnZ3JCZ0VGQlFjREFRWUlLd1lCQlFVSEF3SXdEd1lEVlIwVEFRSC8KQkFVd0F3RUIvekFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBc2J1Z3BUMWg2N1lLR2tSZVlQeTM1YzhDWmFTaApSbDJqc2VEamltZzhiRTFnT0FpT1Y4Uk1DenBXZUhZMDBpeWVJNEN3d2NuY2JsYnhuUy9lWDJldFBtWm1rMkRLClBydnE1YzJSb2Q1bVNIQS9LSDBVVzVwZ1VsVzgzVEMxNjRoVmNoTVRvaHhNTk9VZ1FVVzNzM3FuZllkTlBKaVUKa3BWVWdYcWJBVkZ1SGdEUzNCZVFiUDZnVVNpYXVwaHJyMUFZS1BWNVQ0cXZnbGVNdm5lTm9PcE1CVittSkVReQpReWFFaW1IeXVJckZBbk5FVWZYNTk1eWx2NjY5SUNucjRQbVJvY2V1cFh2OGtwdkpmekwreFcyRXkyYUxtMXFsCmNPbnRCTDB0SEdHTzR1cXVsWDFXN3U1MUYweUxVSGdlQjRiaEo0ZklGdVZ5ZjhZd1JxcENrcC9pL0E9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
EOF

kubectl rollout status deployment -n vault-webhook release-name-vault-secrets-webhook --timeout=180s
