#!/bin/bash
# Install Longhorn on Kubernetes cluster

set -e

echo "============================================"
echo " Kubernetes Storage Setup - Longhorn"
echo " Installing Longhorn Storage"
echo "============================================"

# Check prerequisites
echo "[1/4] Checking prerequisites..."
if ! command -v helm &> /dev/null; then
    echo "ERROR: Helm is not installed. Install it first: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Add Longhorn Helm repo#!/bin/bash
# Install Longhorn on Kubernetes cluster

set -e

echo "============================================"
echo " Kubernetes Storage Setup - Longhorn"
echo " Installing Longhorn Storage"
echo "============================================"

# Check prerequisites
echo "[1/4] Checking prerequisites..."
if ! command -v helm &> /dev/null; then
    echo "ERROR: Helm is not installed. Install it first: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Add Longhorn Helm repo
echo "[2/4] Adding Longhorn Helm repository..."
helm repo add longhorn https://charts.longhorn.io
helm repo update

# Install Longhorn
echo "[3/4] Installing Longhorn..."
helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --set defaultSettings.replicaCount=2 \
  --set defaultSettings.defaultDataPath=/var/lib/longhorn \
  --set defaultSettings.createDefaultDiskLabeledNodes=true \
  --set persistence.createStorageClass=false \

# Apply StorageClass
echo "[4/4] Applying StorageClass..."
# Wipes out any existing immutable storage class so the configuration below can drop in cleanly
kubectl delete storageclass longhorn --ignore-not-found

kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: driver.longhorn.io
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  numberOfReplicas: "2"
  staleReplicaTimeout: "30"
  dataLocality: "best-effort"
EOF
echo ""
echo "============================================"
echo " Longhorn installed successfully!"
echo " Access dashboard: kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80"
echo "============================================"
echo "[2/4] Adding Longhorn Helm repository..."
helm repo add longhorn https://charts.longhorn.io
helm repo update

# Install Longhorn
echo "[3/4] Installing Longhorn..."
helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --set defaultSettings.replicaCount=2 \
  --set defaultSettings.defaultDataPath=/var/lib/longhorn \
  --set defaultSettings.createDefaultDiskLabeledNodes=true \
  --set persistence.createStorageClass=false
  # <-- Notice `--wait` is removed from here

# Give the API server a few seconds to register the heavy definitions, then track the rollout safely
echo "⏳ Waiting for Longhorn controllers to pull images and stabilize..."
sleep 15
kubectl rollout status deployment/longhorn-driver-deployer -n longhorn-system --timeout=300s
kubectl rollout status daemonset/longhorn-manager -n longhorn-system --timeout=300s

# Apply StorageClass
echo "[4/4] Applying StorageClass..."
kubectl delete storageclass longhorn --ignore-not-found

kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: driver.longhorn.io
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  numberOfReplicas: "2"
  staleReplicaTimeout: "30"
  dataLocality: "best-effort"
EOF