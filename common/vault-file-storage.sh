#!/usr/bin/env bash
set -e

BV_VERSION=${BV_VERSION:-0.4.17-rc.3}
export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

cat <<EOF | kubectl apply -f -
apiVersion: "vault.banzaicloud.com/v1alpha1"
kind: "Vault"
metadata:
  name: "vault"
  namespace: vault
spec:
  size: 1
  image: vault:1.1.2
  bankVaultsImage: banzaicloud/bank-vaults:${BV_VERSION}

  # Support for custom Vault (and sidecar) pod annotations
  annotations:
    fc.com/test: "true"

  vaultAnnotations:
    fc.com/vault: "true"

  vaultConfigurerAnnotations:
    fc.com/configurer: "true"

  watchedSecretsLabels:
    - certmanager.k8s.io/certificate-name: vault-letsencrypt-cert
    - mintel.com/scope: gcp
      mintel.com/credentials: vault

  # Specify the ServiceAccount where the Vault Pod and the Bank-Vaults configurer/unsealer is running
  serviceAccount: vault

  # Specify the Service's type where the Vault Service is exposed
  serviceType: ClusterIP

  # Use local disk to store Vault file data, see config section.
  volumes:
    - name: vault-file
      persistentVolumeClaim:
        claimName: vault-file

  volumeMounts:
    - name: vault-file
      mountPath: /vault/file

  # Describe where you would like to store the Vault unseal keys and root token.
  unsealConfig:
    options:
      # The preFlightChecks flag enables unseal and root token storage tests
      preFlightChecks: true
    kubernetes:
      secretNamespace: vault

  # A YAML representation of a final vault config file.
  # See https://www.vaultproject.io/docs/configuration/ for more information.
  config:
    storage:
      file:
        path: "/vault/file"
    listener:
      tcp:
        address: "0.0.0.0:8200"
        # Uncommenting the following line and deleting tls_cert_file and tls_key_file disables TLS
        # tls_disable: true
        tls_cert_file: /vault/tls/server.crt
        tls_key_file: /vault/tls/server.key
    telemetry:
      statsd_address: localhost:9125
    ui: true

  # See: https://github.com/banzaicloud/bank-vaults#example-external-vault-configuration for more details.
  externalConfig:
    audit:
      - type: file
        description: "STDOUT Audit logging"
        options:
          file_path: stdout
    policies:
      - name: allow_secrets
        rules: path "secret/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
          }

  vaultEnvsConfig:
    - name: VAULT_LOG_LEVEL
      value: debug
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: vault-file
  namespace: vault
spec:
  # https://kubernetes.io/docs/concepts/storage/persistent-volumes/#class-1
  # storageClassName: ""
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
