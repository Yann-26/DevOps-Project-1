## File: `infra-repo/README.md`

<p align="center">
<img width="1672" height="941" alt="Image" src="https://github.com/user-attachments/assets/e5c67a45-313b-4cef-a895-22ed2963c6db" />
</p>

<h1 align="center">🚀 DevOps Platform</h1>
<p align="center"><strong>Production-grade Kubernetes platform with GitOps, CI/CD, microservices, and full observability</strong></p>

<p align="center">
  <img src="https://img.shields.io/badge/Kubernetes-1.35-blue?logo=kubernetes" alt="Kubernetes"/>
  <img src="https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo" alt="ArgoCD"/>
  <img src="https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?logo=jenkins" alt="Jenkins"/>
  <img src="https://img.shields.io/badge/Docker-Containers-2496ED?logo=docker" alt="Docker"/>
  <img src="https://img.shields.io/badge/Prometheus-Monitoring-E6522C?logo=prometheus" alt="Prometheus"/>
  <img src="https://img.shields.io/badge/Grafana-Dashboards-F46800?logo=grafana" alt="Grafana"/>
</p>

---

## 📋 Table of Contents

- [✨ Overview](#-overview)
- [🏗 Architecture](#-architecture)
- [📁 Repository Structure](#-repository-structure)
- [🚀 Quick Start](#-quick-start)
- [🔄 GitOps with ArgoCD](#-gitops-with-argocd)
- [🔧 CI/CD Pipeline](#-cicd-pipeline)
- [🌐 Accessing Services](#-accessing-services)
- [📊 Day-2 Operations](#-day-2-operations)
- [🔍 Troubleshooting](#-troubleshooting)
- [🔒 Security](#-security)

---

## ✨ Overview

This platform implements a complete **GitOps-driven DevOps workflow**:

| Capability | Implementation |
|------------|---------------|
| **GitOps** | ArgoCD watches GitHub, auto-syncs cluster |
| **CI/CD** | Jenkins builds images, pushes to registry |
| **Orchestration** | Kubernetes (K3s) with HPA autoscaling |
| **Ingress** | NGINX + Cert-Manager for TLS |
| **Storage** | Longhorn distributed block storage + local-path |
| **Monitoring** | Prometheus + Grafana + Alertmanager |
| **Logging** | Promtail + Loki |
| **Secrets** | Sealed Secrets (Git-safe encryption) |
| **Databases** | PostgreSQL + Redis StatefulSets |

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GITOPS LOOP                              │
│                                                                   │
│  ┌──────────┐    git push    ┌──────────┐    auto-sync    ┌──────┐│
│  │ Developer │──────────────▶│  GitHub   │──────────────▶│ArgoCD││
│  └──────────┘                └──────────┘                └──┬───┘│
│                                                            │    │
└────────────────────────────────────────────────────────────┼────┘
                                                             │
┌────────────────────────────────────────────────────────────┼────┐
│                      KUBERNETES CLUSTER                     │    │
│                                                            ▼    │
│  ┌──────────┐  Webhook  ┌──────────┐  Build & Push  ┌──────────┐│
│  │  GitHub   │─────────▶│  Jenkins  │──────────────▶│  Docker   ││
│  └──────────┘           │ StatefulSet│               │   Hub     ││
│                         └──────────┘               └──────────┘│
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │         NGINX Ingress + Cert-Manager (TLS)                │ │
│  └──────┬───────────────┬───────────────┬───────────────────┘ │
│         │               │               │                      │
│    ┌────▼────┐    ┌─────▼─────┐   ┌─────▼─────┐               │
│    │Frontend │    │    API    │   │   Auth    │               │
│    │ React   │    │ Node.js   │   │   JWT     │               │
│    │  :80    │    │  :3000    │   │  :4000    │               │
│    │ 2-10 HPA│    │ 3-20 HPA  │   │ 2-10 HPA  │               │
│    └─────────┘    └─────┬─────┘   └─────┬─────┘               │
│                         │               │                      │
│                    ┌────▼────┐    ┌─────▼─────┐               │
│                    │PostgreSQL│    │   Redis   │               │
│                    │  :5432  │    │  :6379    │               │
│                    │ 10Gi PV  │    │  5Gi PV   │               │
│                    └─────────┘    └───────────┘               │
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              Observability Stack                           │ │
│  │  Prometheus 📊  Loki 📝  Grafana 📈  Alertmanager 🚨      │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
```

### Data Flow

| Path | Service | Technology | Port | Scaling |
|------|---------|-----------|------|---------|
| `/` | Frontend | React + Nginx | 80 | 2–10 pods |
| `/api/*` | Core API | Node.js / Express | 3000 | 3–20 pods |
| `/auth/*` | Authentication | Node.js / JWT | 4000 | 2–10 pods |

---

## 📁 Repository Structure

```
infra-repo/
│
├── 📜 deploy.sh # One-command full platform deployment
├── 📜 destroy.sh # Teardown everything safely
├── 📜 Jenkinsfile # CI/CD pipeline (GitHub → Build → Deploy)
├── 📜 argocd-app.yaml # ArgoCD GitOps application definition
├── 📜 secrets-template.yaml # Template for required secrets (fill before deploy)
├── 📜 get_helm.sh # Helm installer utility
│
├── 📦 apps/ # Application microservices
│ ├── namespace.yaml # 'apps' namespace definition
│ ├── frontend/ # React frontend
│ │ ├── deployment.yaml # Frontend deployment (2 replicas)
│ │ ├── service.yaml # Internal ClusterIP service
│ │ └── hpa.yaml # Horizontal Pod Autoscaler (2-10 pods)
│ ├── api/ # Core REST API
│ │ ├── deployment.yaml # API deployment (3 replicas)
│ │ ├── service.yaml # Internal ClusterIP service
│ │ └── hpa.yaml # Horizontal Pod Autoscaler (3-20 pods)
│ └── auth/ # JWT Authentication service
│ ├── deployment.yaml # Auth deployment (2 replicas)
│ ├── service.yaml # Internal ClusterIP service
│ └── hpa.yaml # Horizontal Pod Autoscaler (2-10 pods)
│
├── 🗄️ data/ # Stateful data services
│ ├── namespace.yaml # 'data' namespace definition
│ ├── image.png # Data layer architecture diagram
│ ├── postgres/ # PostgreSQL database
│ │ ├── statefulset.yaml # StatefulSet with 10Gi persistent storage
│ │ ├── service.yaml # Headless service for StatefulSet
│ │ ├── secrets.yaml # DB credentials + JWT secret (base64)
│ │ └── sealed-secret.yaml # Sealed Secrets encrypted version (Git-safe)
│ └── redis/ # Redis cache
│ ├── statefulset.yaml # StatefulSet with 5Gi persistent storage
│ └── service.yaml # Headless service for StatefulSet
│
├── 🌐 ingress-controller/ # Traffic management & TLS
│ ├── namespace.yaml # 'ingress-nginx' namespace definition
│ ├── nginx-ingress.yaml # NGINX Ingress Controller deployment
│ ├── info.txt # Ingress configuration notes
│ └── cert-manager/ # Automatic TLS certificate management
│ ├── namespace.yaml # 'cert-manager' namespace definition
│ ├── crds.yaml # Custom Resource Definitions
│ ├── serviceaccount.yaml # ServiceAccount for cert-manager
│ ├── clusterrole.yaml # Cluster-wide permissions
│ ├── clusterrolebinding.yaml # Bind ClusterRole to ServiceAccount
│ ├── deployment.yaml # Cert-Manager controller deployment
│ └── clusterissuer.yaml # Let's Encrypt ACME issuer configuration
│
├── 🔀 ingress-routes/ # Application routing rules
│ ├── app-ingress.yaml # Path-based routing (/ → Frontend, /api → API, /auth → Auth)
│ └── image.png # Ingress routing diagram
│
├── ⚙️ jenkins/ # CI/CD server
│ ├── namespace.yaml # 'jenkins' namespace definition
│ ├── statefulset.yaml # Jenkins LTS with persistent configuration
│ ├── service.yaml # Internal service + agent port
│ ├── serviceaccount.yaml # ServiceAccount for Kubernetes plugin
│ ├── clusterrole.yaml # Permissions to create/delete build pods
│ ├── clusterrolebinding.yaml # Bind ClusterRole to ServiceAccount
│ └── ingress.yaml # External access to Jenkins UI
│
├── 💾 storage/ # Persistent storage providers
│ ├── longhorn.yaml # Longhorn distributed block storage config
│ ├── local-storage.yaml # Local path provisioner (dev fallback)
│ └── install-longhorn.sh # Helm installation script for Longhorn
│
├── 🔬 system/ # Cluster-level services
│ ├── metrics-server.yaml # Metrics Server (required for HPA + kubectl top)
│ ├── cluster-autoscaler.yaml # Auto-provisions new nodes when resources low
│ └── monitoring/ # Observability stack
│ ├── namespace.yaml # 'monitoring' namespace definition
│ ├── prometheus.yaml # Metrics collection + alerting rules
│ ├── grafana.yaml # Dashboards with Prometheus + Loki datasources
│ ├── alertmanager.yaml # Alert routing to Slack/Email
│ ├── loki.yaml # Log aggregation (tsdb storage)
│ ├── promtail.yaml # Log collector DaemonSet (ships to Loki)
│ └── sealed-slack-secret.yaml # Encrypted Slack webhook (Git-safe)
│
└── 🖥️ src/ # Application source code
├── frontend/ # React frontend application
│ ├── Dockerfile # Multi-stage build (Node → Nginx)
│ ├── package.json # React dependencies
│ ├── public/index.html # HTML entry point
│ └── src/
│ ├── index.js # React app with architecture viewer
│ └── project-architecture.png # Architecture diagram displayed in UI
├── api/ # Node.js REST API
│ ├── Dockerfile # Production Node.js image
│ ├── package.json # Express + pg + redis dependencies
│ └── index.js # API server with /health endpoint
└── auth/ # JWT Authentication service
├── Dockerfile # Production Node.js image
├── package.json # Express + jsonwebtoken + bcryptjs
└── index.js # Auth server with JWT verify endpoint

**21 directories, 66 files** — fully documented Infrastructure as Code.
```

---

## 🚀 Quick Start

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| `kubectl` | ≥ 1.29 | Kubernetes CLI |
| `docker` | ≥ 24.x | Build container images |
| `helm` | ≥ 3.x | Package manager (Longhorn) |
| Kubernetes | 1.29+ | K3s, Minikube, or cloud |

### 1️⃣ Clone & Configure

```bash
git clone https://github.com/Yann-26/DevOps-Project-1.git
cd DevOps-Project-1/infra-repo
```

### 2️⃣ Build & Push Images

```bash
export REGISTRY="your-dockerhub-username"
docker login

docker build -t $REGISTRY/frontend:latest src/frontend/
docker build -t $REGISTRY/api:latest src/api/
docker build -t $REGISTRY/auth:latest src/auth/

docker push $REGISTRY/frontend:latest
docker push $REGISTRY/api:latest
docker push $REGISTRY/auth:latest
```

### 3️⃣ Deploy

```bash
chmod +x deploy.sh
./deploy.sh
```

### 4️⃣ Verify

```bash
kubectl get pods --all-namespaces | grep -v kube-system
```

---

## 🔄 GitOps with ArgoCD

Every push to `main` is automatically synced to the cluster.

### ArgoCD Dashboard

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Access UI
kubectl port-forward -n argocd svc/argocd-server 8443:443
```

Open **https://localhost:8443** → Login `admin` / password above

### How It Works

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ git push │───▶│  GitHub   │───▶│  ArgoCD  │───▶│   K3s    │
│   main   │    │ Webhook   │    │  Detect  │    │  Apply   │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
     ⏱️ 0s           ⏱️ 1s          ⏱️ 3min         ⏱️ 3min
```

| Feature | Behavior |
|---------|----------|
| **Auto-Sync** | Changes in Git → Applied to cluster within 3 minutes |
| **Self-Heal** | Manual changes reverted to match Git state |
| **Prune** | Deleted YAMLs removed from cluster automatically |
| **Drift Detection** | ArgoCD shows differences between Git and live cluster |

### Application Status

```
NAME              SYNC STATUS   HEALTH STATUS
devops-platform   Synced        Healthy        ✅
```

### Manual Sync

```bash
# Force sync via CLI
kubectl patch application devops-platform -n argocd \
  --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

---

## 🔧 CI/CD Pipeline

### Jenkins Pipeline Stages

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Checkout │───▶│  Build   │───▶│   Push   │───▶│  Deploy  │
│  GitHub  │    │  Docker  │    │Docker Hub│    │   K3s    │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

| Stage | Tool | Description |
|-------|------|-------------|
| Checkout | Git | Pulls latest code from GitHub |
| Build | Docker | Builds frontend, API, and auth images |
| Push | Docker Hub | Tags with build number, pushes to registry |
| Deploy | kubectl | Updates K3s deployments, verifies rollout |

### Trigger Options

| Method | Setup |
|--------|-------|
| **GitHub Webhook** | `git push` → Jenkins auto-builds |
| **Manual** | Click "Build Now" in Jenkins UI |
| **ArgoCD** | Jenkins pushes image → ArgoCD syncs to cluster |

---

## 🌐 Accessing Services

### Port Forwards (Local Development)

| Service | Command | URL |
|---------|---------|-----|
| **Frontend** | `kubectl port-forward -n apps svc/frontend 8081:80` | `http://localhost:8081` |
| **API** | `kubectl port-forward -n apps svc/api 3000:3000` | `http://localhost:3000` |
| **Grafana** | `kubectl port-forward -n monitoring svc/grafana 3000:3000` | `http://localhost:3000` |
| **Prometheus** | `kubectl port-forward -n monitoring svc/prometheus 9090:9090` | `http://localhost:9090` |
| **Jenkins** | `kubectl port-forward -n jenkins svc/jenkins 8081:8080` | `http://localhost:8081` |
| **ArgoCD** | `kubectl port-forward -n argocd svc/argocd-server 8443:443` | `https://localhost:8443` |

### Default Credentials

| Service | Username | Password | Notes |
|---------|----------|----------|-------|
| Grafana | `admin` | `admin` | Change immediately |
| ArgoCD | `admin` | (from secret) | `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" \| base64 -d` |
| PostgreSQL | `admin` | `supersecret` | In `data/postgres/secrets.yaml` |
| Auth API | `admin` | `admin123` | Hardcoded for dev |

---

## 📊 Day-2 Operations

### Scaling

```bash
# Manual scale
kubectl scale deployment frontend -n apps --replicas=5

# Check HPA
kubectl get hpa -n apps
kubectl describe hpa api-hpa -n apps
```

### Updates & Rollbacks

```bash
# Update image
kubectl set image deployment/api api=$REGISTRY/api:v2 -n apps

# Monitor rollout
kubectl rollout status deployment/api -n apps

# Rollback
kubectl rollout undo deployment/api -n apps

# History
kubectl rollout history deployment/api -n apps
```

### Database Access

```bash
# PostgreSQL
kubectl exec -it -n data statefulset/postgres -- psql -U admin devops_db

# Redis
kubectl exec -it -n data statefulset/redis -- redis-cli
```

### Backup

```bash
# PostgreSQL dump
kubectl exec -n data statefulset/postgres -- \
  pg_dump -U admin devops_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Redis snapshot
kubectl exec -n data statefulset/redis -- redis-cli BGSAVE
```

---

## 🔍 Troubleshooting

| Symptom | Diagnostic |
|---------|-----------|
| Pod not starting | `kubectl describe pod -n apps <pod>` |
| PVC pending | `kubectl get pvc --all-namespaces` |
| HPA unknown metrics | Check: `kubectl get pods -n kube-system \| grep metrics-server` |
| ArgoCD OutOfSync | `kubectl get application -n argocd -o yaml \| grep -A50 status` |
| Certificate not issued | `kubectl describe certificate -A` |
| Crash loop | `kubectl logs -n apps <pod> --previous` |

### Common Fixes

**ArgoCD can't reach API server:**
```bash
kubectl rollout restart statefulset argocd-application-controller -n argocd
kubectl rollout restart deployment argocd-server -n argocd
```

**Prometheus stuck on PVC:**
```bash
kubectl delete statefulset prometheus -n monitoring
kubectl delete pvc -n monitoring -l app=prometheus
# Then redeploy — uses emptyDir for dev
```

**Jenkins webhook cert missing:**
```bash
kubectl delete validatingwebhookconfiguration ingress-nginx-admission
kubectl delete pod -n ingress-nginx -l app=nginx-ingress
```

---

## 🔒 Security

| Feature | Implementation |
|---------|---------------|
| **Secrets Management** | Sealed Secrets (encrypted, Git-safe) |
| **Image Building** | Kaniko (daemonless, no root) |
| **RBAC** | Minimum required permissions per component |
| **Network** | Databases on internal ClusterIP only |
| **TLS** | Let's Encrypt via Cert-Manager |
| **JWT** | Auth service fails fast if secret not set |

### Production Checklist

- [ ] Enable Network Policies between namespaces
- [ ] Enforce Pod Security Standards (restricted)
- [ ] Configure Grafana with SSO (LDAP/OAuth)
- [ ] Add Resource Quotas per namespace
- [ ] Set up off-site encrypted backups
- [ ] Enable Kubernetes Audit Logging
- [ ] Replace base64 secrets with Sealed Secrets

---

## 📝 License

MIT © 2026

---

<p align="center">
  <strong>Built with ❤️ using Kubernetes, React, Node.js, ArgoCD, and DevOps best practices.</strong>
</p>
```

