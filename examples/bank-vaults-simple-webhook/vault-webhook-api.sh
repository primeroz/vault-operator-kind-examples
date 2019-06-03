#!/usr/bin/env bash
set -e

export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: List
metadata:
items:
- apiVersion: admissionregistration.k8s.io/v1beta1
  kind: MutatingWebhookConfiguration
  metadata:
    name: release-name-vault-secrets-webhook
  webhooks:
  - name: pods.vault-secrets-webhook.admission.banzaicloud.com
    clientConfig:
      service:
        namespace: vault-webhook
        name: release-name-vault-secrets-webhook
        path: /pods
      caBundle: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM5ekNDQWQrZ0F3SUJBZ0lSQVBJUWdMVGo3UDlqd21DTXJRZnRnUmN3RFFZSktvWklodmNOQVFFTEJRQXcKRlRFVE1CRUdBMVVFQXhNS2MzWmpMV05oZEMxallUQWVGdzB4T1RBMk1ETXhOREF3TXpCYUZ3MHlPVEExTXpFeApOREF3TXpCYU1CVXhFekFSQmdOVkJBTVRDbk4yWXkxallYUXRZMkV3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBCkE0SUJEd0F3Z2dFS0FvSUJBUUMyTWY2UUxVU0VpNWZBSzVwdXRwL2dlVThGQzdSNFltMHYwK0J2SDdxdWdOd2oKaTIrVU9wNVgwRlZVMHlaY0hwWnJXdFhtVkcxVWlTUEV5NnkzamFOOWF1YU94NUJnbE0yWXBaMzNmUnNPa0YzNwptYUpoQWgra0NMZmJBblFpVEFiMFlxM0trOEY5dE9DNlRKMmZZVHhvRlRLc1cwZktxYkh5aXJtVEtCbUMxRHBxCm1LeDJHSTR4Q1RLUndaMG5qSnZqK0ZydmQ5R1U0Y3RFejJzTG5lOXFYSVMvRUZDL0tnWVJxTjhqVjVkM3FOV3cKTjFzSTU3RTZGRitxVlhTdUVDWXhIL1dabThONUhkVnN6UnZoWEFWVGZWVEw4aXlnUXJIbE9YTUxsVU5ERmRTVApZQlUrdGI1UUN4bjg5dDNzODRTWFpoZS9KbkM3RDhmVGtPa2F0U1ZuQWdNQkFBR2pRakJBTUE0R0ExVWREd0VCCi93UUVBd0lDcERBZEJnTlZIU1VFRmpBVUJnZ3JCZ0VGQlFjREFRWUlLd1lCQlFVSEF3SXdEd1lEVlIwVEFRSC8KQkFVd0F3RUIvekFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBc2J1Z3BUMWg2N1lLR2tSZVlQeTM1YzhDWmFTaApSbDJqc2VEamltZzhiRTFnT0FpT1Y4Uk1DenBXZUhZMDBpeWVJNEN3d2NuY2JsYnhuUy9lWDJldFBtWm1rMkRLClBydnE1YzJSb2Q1bVNIQS9LSDBVVzVwZ1VsVzgzVEMxNjRoVmNoTVRvaHhNTk9VZ1FVVzNzM3FuZllkTlBKaVUKa3BWVWdYcWJBVkZ1SGdEUzNCZVFiUDZnVVNpYXVwaHJyMUFZS1BWNVQ0cXZnbGVNdm5lTm9PcE1CVittSkVReQpReWFFaW1IeXVJckZBbk5FVWZYNTk1eWx2NjY5SUNucjRQbVJvY2V1cFh2OGtwdkpmekwreFcyRXkyYUxtMXFsCmNPbnRCTDB0SEdHTzR1cXVsWDFXN3U1MUYweUxVSGdlQjRiaEo0ZklGdVZ5ZjhZd1JxcENrcC9pL0E9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    rules:
    - operations:
      - CREATE
      apiGroups:
      - "*"
      apiVersions:
      - "*"
      resources:
      - pods
    failurePolicy: Fail
    namespaceSelector:
      matchExpressions:
      - key: name
        operator: NotIn
        values:
        - vault-webhook
EOF
