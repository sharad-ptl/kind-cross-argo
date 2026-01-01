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

2. Install Crossplane:
```bash
./scripts/install-crossplane.sh
```

3. Apply Crossplane resources (already done by install-crossplane.sh, but you can apply manually if needed):
```bash
kubectl apply -f crossplane/xrd.yaml
kubectl apply -f crossplane/fn.yaml
kubectl apply -f crossplane/composition.yaml
```

4. Apply the Argo CD Applications:
```bash
kubectl apply -f argocd/applications/app.yaml
kubectl apply -f argocd/applications/guestbook.yaml
```

5. Access Argo CD UI:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Then visit https://localhost:8080 (accept the self-signed certificate)

Default credentials:
- Username: `admin`
- Password: Get it with `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo`

## Project Structure

```
.
├── applications-iac/          # Infrastructure as Code definitions (Deployments, Services, etc.)
│   ├── app/                   # App resources
│   └── guestbook/             # Guestbook resources
├── argocd/
│   └── applications/          # Argo CD Application definitions
│       ├── app.yaml           # Argo CD app for the app resources
│       └── guestbook.yaml     # Argo CD app for guestbook resources
├── crossplane/
│   ├── xrd.yaml               # Composite Resource Definition
│   ├── fn.yaml                # Crossplane Function (patch-and-transform)
│   ├── composition.yaml       # Crossplane Composition
│   └── README.md              # Crossplane configuration details
├── scripts/
│   ├── install-argocd.sh      # Argo CD installation script
│   ├── install-crossplane.sh  # Crossplane installation script
│   └── uninstall.sh           # Cleanup script
└── README.md
```

## Using Crossplane Compositions

The Crossplane setup includes:
- **XRD (Composite Resource Definition)**: Defines the `App` custom resource at `apps.example.crossplane.io`
- **Function**: Uses the patch-and-transform function for resource composition
- **Composition**: Defines how to create Kubernetes Deployments and Services from an `App` resource

See `crossplane/README.md` for more details on configuring Argo CD to work with Crossplane resources.

## Cleanup

To remove everything:
```bash
./scripts/uninstall.sh
```

