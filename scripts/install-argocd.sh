#!/bin/bash

set -e

echo "Installing Argo CD..."

# Create argocd namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || true

echo "Argo CD installed successfully!"
echo ""
echo "To access Argo CD UI, run:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "Get admin password with:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d && echo"

