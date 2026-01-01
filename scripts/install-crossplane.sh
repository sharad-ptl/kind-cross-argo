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

echo "Installing Crossplane Compositions..."
kubectl apply -f "$PROJECT_ROOT/crossplane/xrd.yaml"
kubectl apply -f "$PROJECT_ROOT/crossplane/fn.yaml"
kubectl apply -f "$PROJECT_ROOT/crossplane/composition.yaml"

echo "Waiting for XRD to be ready..."
kubectl wait --for=condition=established --timeout=60s crd/apps.example.crossplane.io || true

echo "Crossplane Compositions installed successfully!"

