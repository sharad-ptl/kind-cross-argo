---
marp: true
theme: uncover
paginate: true
size: 16:9
---

<!-- _class: lead -->
# Kind + Crossplane + ArgoCD

A GitOps & Infrastructure as Code Demo

---

# Project Overview

**Kind-Cross-Argo** demonstrates:

- **Kind**: Local Kubernetes cluster
- **Crossplane**: Infrastructure composition
- **ArgoCD**: GitOps continuous delivery

Combining infrastructure as code with GitOps workflows

---

# Key Components

**Crossplane**
- XRD: `App` custom resource
- Composition: App → Deployments + Services
- Function: Patch-and-transform

**ArgoCD**
- GitOps sync from repository
- Monitors Crossplane resources
- Web UI for visualization

---

# Project Structure

```
kind-cross-argo/
├── applications-iac/    # Application manifests
│   ├── app/
│   └── guestbook/
├── argocd/
│   └── applications/   # ArgoCD app definitions
├── crossplane/
│   ├── xrd.yaml        # Composite Resource Definition
│   ├── composition.yaml
│   └── fn.yaml
└── scripts/            # Installation scripts
```

---

# Quick Start

1. **Install ArgoCD**
   ```bash
   ./scripts/install-argocd.sh
   ```

2. **Install Crossplane**
   ```bash
   ./scripts/install-crossplane.sh
   ```

3. **Apply ArgoCD Applications**
   ```bash
   kubectl apply -f argocd/applications/
   ```

---

# How It Works

1. **Define** infrastructure as `App` custom resources
2. **Crossplane** composes them into Kubernetes resources
3. **ArgoCD** syncs from Git and monitors health
4. **Result**: Declarative, Git-driven infrastructure

---

# Example: App Resource

```yaml
apiVersion: apps.example.crossplane.io/v1alpha1
kind: App
metadata:
  name: my-app
spec:
  image: nginx:latest
  replicas: 3
```

Crossplane transforms this into:
- Deployment (3 replicas)
- Service (ClusterIP)

---

# ArgoCD Integration

- **Monitors** Git repository for changes
- **Syncs** Crossplane resources automatically
- **Tracks** health status of composed resources
- **UI** at `https://localhost:8080`

---

# Benefits

✅ **Declarative**: Define what you want, not how

✅ **GitOps**: Version controlled infrastructure

✅ **Composable**: Reusable infrastructure patterns

✅ **Observable**: ArgoCD UI shows everything

---

# Use Cases

- **Local Development**: Test GitOps workflows
- **Learning**: Understand Crossplane + ArgoCD
- **POC**: Demonstrate infrastructure composition
- **CI/CD**: Integrate with pipelines

---

# Access ArgoCD UI

```bash
kubectl port-forward svc/argocd-server \
  -n argocd 8080:443
```

Visit: `https://localhost:8080`

**Credentials:**
- Username: `admin`
- Password: Get from secret

---

# Cleanup

```bash
./scripts/uninstall.sh
```

Removes all resources and namespaces

---

<!-- _class: lead -->
# Questions?

**Repository**: kind-cross-argo

GitOps + Infrastructure as Code in action
