#!/bin/bash

set -e

echo "Setting up RBAC for Crossplane Kubernetes Provider..."

# Create ServiceAccount for Crossplane
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: crossplane-provider-kubernetes
  namespace: crossplane-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: crossplane-provider-kubernetes
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: crossplane-provider-kubernetes
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: crossplane-provider-kubernetes
subjects:
- kind: ServiceAccount
  name: crossplane-provider-kubernetes
  namespace: crossplane-system
EOF

echo "RBAC setup complete!"

