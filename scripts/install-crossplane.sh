#!/bin/bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "Installing Crossplane..."

# Add Crossplane Helm repo
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Create crossplane-system namespace
kubectl create namespace crossplane-system --dry-run=client -o yaml | kubectl apply -f -

# Install or upgrade Crossplane
if helm list -n crossplane-system | grep -q "^crossplane[[:space:]]"; then
  echo "Crossplane release already exists, upgrading..."
  helm upgrade crossplane \
    crossplane-stable/crossplane \
    --namespace crossplane-system \
    --wait
else
  echo "Installing Crossplane..."
  helm install crossplane \
    crossplane-stable/crossplane \
    --namespace crossplane-system \
    --create-namespace \
    --wait
fi

echo "Waiting for Crossplane to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/crossplane -n crossplane-system || true

echo "Crossplane installed successfully!"
echo ""
echo "Setting up RBAC for Kubernetes Provider..."
bash "$SCRIPT_DIR/setup-rbac.sh"

echo "Installing Kubernetes Provider..."
# Apply only the Provider resource first (not the ProviderConfig)
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.2.0
  packagePullPolicy: IfNotPresent
EOF

echo "Waiting for Kubernetes Provider to be ready..."
kubectl wait --for=condition=healthy --timeout=300s provider.pkg.crossplane.io/provider-kubernetes || true

echo "Waiting for ProviderConfig CRD to be available..."
# Wait for the ProviderConfig CRD to be installed by the provider
# The CRD name format is: providerconfigs.<group>
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if kubectl get crd providerconfigs.kubernetes.crossplane.io &>/dev/null; then
    echo "ProviderConfig CRD is available"
    break
  fi
  echo "Waiting for ProviderConfig CRD... ($RETRY_COUNT/$MAX_RETRIES)"
  sleep 2
  RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "Warning: ProviderConfig CRD not found after waiting. Continuing anyway..."
fi

echo "Installing ProviderConfig..."
# Now apply the ProviderConfig after CRDs are available
kubectl apply -f - <<EOF
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kubernetes-provider-config
spec:
  # Use in-cluster credentials (works with kind)
  credentials:
    source: InjectedIdentity
EOF

echo "Installing Crossplane Compositions..."
kubectl apply -f "$PROJECT_ROOT/crossplane/compositions/xrd.yaml"
kubectl apply -f "$PROJECT_ROOT/crossplane/compositions/hello-world-composition.yaml"

echo "Waiting for XRD to be ready..."
kubectl wait --for=condition=established --timeout=60s crd/xhelloworlds.example.org || true

echo "Kubernetes Provider and Compositions installed successfully!"

