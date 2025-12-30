# Argo CD + Crossplane Hello World

This project demonstrates a hello world setup using Argo CD and Crossplane on a local kind Kubernetes cluster.

## Prerequisites

- kind installed and a cluster running (`kind get clusters` should show your cluster)
- kubectl configured to connect to your kind cluster
- Helm 3 (for installing Argo CD and Crossplane)

## Quick Start

1. Install Argo CD:
```bash
./scripts/install-argocd.sh
```

2. Install Crossplane (includes RBAC setup):
```bash
./scripts/install-crossplane.sh
```

3. Apply Crossplane resources:
```bash
kubectl apply -f crossplane/compositions/xrd.yaml
kubectl apply -f crossplane/compositions/hello-world-composition.yaml
kubectl apply -f crossplane/claims/hello-world-claim.yaml
```

4. Apply the Argo CD Application (optional):
```bash
kubectl apply -f argocd/applications/crossplane-app.yaml
```

5. Access Argo CD UI:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Then visit https://localhost:8080 (accept the self-signed certificate)

Default credentials:
- Username: `admin`
- Password: Get it with `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

## Project Structure

```
.
├── argocd/
│   └── applications/          # Argo CD Application definitions
├── crossplane/
│   ├── providers/             # Crossplane Provider configurations
│   ├── compositions/          # Crossplane Compositions
│   └── claims/                # Crossplane Composite Resources (XRs) - v2 uses namespaced XRs instead of claims
├── scripts/
│   ├── install-argocd.sh      # Argo CD installation script
│   └── install-crossplane.sh  # Crossplane installation script
└── README.md
```

## Hello World Example

The hello world example creates a simple ConfigMap resource managed by Crossplane and synced by Argo CD.

Apply the Composite Resource (XR):
```bash
kubectl apply -f crossplane/claims/hello-world-claim.yaml
```

Note: In Crossplane v2, claims have been removed. This file now creates a namespaced `XHelloWorld` Composite Resource directly.

## Cleanup

To remove everything:
```bash
./scripts/uninstall.sh
```

