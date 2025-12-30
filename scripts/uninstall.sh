#!/bin/bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "Uninstalling Argo CD and Crossplane..."

# Delete Argo CD Applications first (before deleting Argo CD itself)
echo "Deleting Argo CD Applications..."
kubectl delete -f "$PROJECT_ROOT/argocd/applications/app.yaml" 2>/dev/null || true
kubectl delete -f "$PROJECT_ROOT/argocd/applications/guestbook.yaml" 2>/dev/null || true

# Delete namespaces created by Argo CD applications
echo "Deleting application namespaces..."
kubectl delete namespace app 2>/dev/null || true
kubectl delete namespace guestbook 2>/dev/null || true

# Uninstall Argo CD
echo "Uninstalling Argo CD..."
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml 2>/dev/null || true
kubectl delete namespace argocd 2>/dev/null || true

# Delete Crossplane Composite Resources (instances of App)
echo "Deleting Crossplane Composite Resources..."
kubectl delete apps.example.crossplane.io --all --all-namespaces 2>/dev/null || true

# Delete Crossplane Compositions, Functions, and XRD
echo "Deleting Crossplane Compositions..."
kubectl delete -f "$PROJECT_ROOT/crossplane/composition.yaml" 2>/dev/null || true
kubectl delete -f "$PROJECT_ROOT/crossplane/fn.yaml" 2>/dev/null || true
kubectl delete -f "$PROJECT_ROOT/crossplane/xrd.yaml" 2>/dev/null || true

# Delete ProviderConfig
echo "Deleting Crossplane ProviderConfig..."
kubectl delete providerconfig kubernetes-provider-config 2>/dev/null || true

# Delete Provider
echo "Deleting Crossplane Provider..."
kubectl delete provider provider-kubernetes 2>/dev/null || true

# Delete RBAC resources
echo "Deleting Crossplane RBAC resources..."
kubectl delete clusterrolebinding crossplane-provider-kubernetes 2>/dev/null || true
kubectl delete clusterrole crossplane-provider-kubernetes 2>/dev/null || true
kubectl delete serviceaccount crossplane-provider-kubernetes -n crossplane-system 2>/dev/null || true

# Uninstall Crossplane Helm release
echo "Uninstalling Crossplane..."
helm uninstall crossplane -n crossplane-system 2>/dev/null || true

# Delete Crossplane namespace
kubectl delete namespace crossplane-system 2>/dev/null || true

echo "Cleanup complete!"

