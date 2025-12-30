#!/bin/bash

set -e

echo "Uninstalling Argo CD and Crossplane..."

# Uninstall Argo CD
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml 2>/dev/null || true
kubectl delete namespace argocd 2>/dev/null || true

# Uninstall Crossplane
helm uninstall crossplane -n crossplane-system 2>/dev/null || true
kubectl delete namespace crossplane-system 2>/dev/null || true

echo "Cleanup complete!"

