### File: `infra-repo/README.md`

```markdown
# 🚀 DevOps Platform

**Production-grade Kubernetes platform with CI/CD, microservices, and full observability.**

!<img width="1672" height="941" alt="Image" src="https://github.com/user-attachments/assets/0c543426-1002-4ed1-af62-cd36350d8d71" />

---

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Repository Structure](#-repository-structure)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Component Details](#-component-details)
- [Accessing Services](#-accessing-services)
- [Day-2 Operations](#-day-2-operations)
- [Troubleshooting](#-troubleshooting)
- [Security Notes](#-security-notes)

---

## 🏗 Architecture Overview


```

```
                ┌─────────────────────────────┐
                │      GitHub (Source Code)     │
                └──────────────┬──────────────┘
                               │ Webhook
                               ▼

```

┌─────────────────────────────────────────────────────────────┐
│                      KUBERNETES CLUSTER                      │
│                                                               │
│  ┌──────────────┐     ┌─────────────────────────────┐        │
│  │   Jenkins     │────▶│  Ephemeral Build Agents     │        │
│  │  StatefulSet  │     │  (Kaniko → Build & Push)    │        │
│  └──────────────┘     └─────────────────────────────┘        │
│                                                               │
│  ┌──────────────────────────────────────────────────┐        │
│  │  NGINX Ingress + Cert-Manager (TLS Termination)   │        │
│  └──────┬───────────────┬───────────────┬───────────┘        │
│         │               │               │                     │
│    ┌────▼────┐    ┌─────▼─────┐   ┌─────▼─────┐              │
│    │Frontend │    │   API     │   │   Auth    │              │
│    │  :80    │    │  :3000    │   │  :4000    │              │
│    │ HPA 2-10│    │ HPA 3-20  │   │ HPA 2-10  │              │
│    └─────────┘    └─────┬─────┘   └─────┬─────┘              │
│                         │               │                     │
│                    ┌────▼────┐    ┌─────▼─────┐              │
│                    │PostgreSQL│    │   Redis   │              │
│                    │  :5432  │    │  :6379    │              │
│                    │StatefulSet│   │StatefulSet│              │
│                    └─────────┘    └───────────┘              │
│                                                               │
│  ┌──────────────────────────────────────────────────┐        │
│  │  Observability Stack                              │        │
│  │  Prometheus (Metrics) + Loki (Logs) + Grafana     │        │
│  │  Alertmanager → Slack/Email Alerts                │        │
│  └──────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────┘

```

### Data Flow

| Path | Service | Port | Scaling |
| :--- | :--- | :--- | :--- |
| `/` | Frontend (React) | 80 | 2–10 pods |
| `/api/*` | API (Node.js) | 3000 | 3–20 pods |
| `/auth/*` | Auth (Node.js + JWT) | 4000 | 2–10 pods |

---

## 📁 Repository Structure


```

infra-repo/
├── deploy.sh                          # One-command deployment
├── destroy.sh                         # Teardown everything
│
├── apps/                              # Application microservices
│   ├── namespace.yaml
│   ├── frontend/
│   │   ├── deployment.yaml            # React app
│   │   ├── service.yaml
│   │   └── hpa.yaml                   # Autoscaling 2-10 pods
│   ├── api/
│   │   ├── deployment.yaml            # Core API
│   │   ├── service.yaml
│   │   └── hpa.yaml                   # Autoscaling 3-20 pods
│   └── auth/
│       ├── deployment.yaml            # JWT Authentication
│       ├── service.yaml
│       └── hpa.yaml                   # Autoscaling 2-10 pods
│
├── data/                              # Stateful data services
│   ├── namespace.yaml
│   ├── postgres/
│   │   ├── statefulset.yaml           # PostgreSQL 16
│   │   ├── service.yaml               # Headless service
│   │   └── secrets.yaml               # DB creds + JWT secret
│   └── redis/
│       ├── statefulset.yaml           # Redis 7
│       └── service.yaml
│
├── ingress-controller/                # Traffic management
│   ├── namespace.yaml
│   ├── nginx-ingress.yaml             # NGINX Ingress Controller
│   └── cert-manager/                  # Automatic TLS certificates
│       ├── namespace.yaml
│       ├── crds.yaml
│       ├── serviceaccount.yaml
│       ├── clusterrole.yaml
│       ├── clusterrolebinding.yaml
│       ├── deployment.yaml
│       └── clusterissuer.yaml         # Let's Encrypt production
│
├── ingress-routes/
│   └── app-ingress.yaml               # Path-based routing rules
│
├── jenkins/                           # CI/CD pipeline
│   ├── namespace.yaml
│   ├── pvc.yaml                       # Persistent workspace
│   ├── statefulset.yaml               # Jenkins LTS
│   ├── service.yaml
│   ├── serviceaccount.yaml            # For K8s plugin
│   ├── clusterrole.yaml
│   ├── clusterrolebinding.yaml
│   └── ingress.yaml
│
├── src/                               # Application source code
│   ├── frontend/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── public/index.html
│   │   └── src/
│   │       ├── index.js
│   │       └── project-architecture.png
│   ├── api/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── index.js
│   └── auth/
│       ├── Dockerfile
│       ├── package.json
│       └── index.js
│
├── storage/                           # Persistent storage
│   ├── longhorn.yaml                  # Longhorn StorageClass
│   ├── local-storage.yaml             # Fallback local provisioner
│   └── install-longhorn.sh            # Helm installation script
│
└── system/                            # Cluster services
├── metrics-server.yaml            # Required for HPA
├── cluster-autoscaler.yaml        # Node auto-provisioning
└── monitoring/                    # Observability stack
├── namespace.yaml
├── prometheus.yaml            # Metrics collection + alerting rules
├── loki.yaml                  # Log aggregation
├── promtail.yaml              # Log shipper (DaemonSet)
├── grafana.yaml               # Dashboards + datasources
└── alertmanager.yaml          # Alert routing to Slack

```

---

## 📦 Prerequisites

### Required Tools

| Tool | Version | Purpose |
| :--- | :--- | :--- |
| `kubectl` | ≥ 1.29 | Kubernetes CLI |
| `docker` | ≥ 24.x | Build container images |
| `helm` | ≥ 3.x | Install Longhorn (optional) |

### Infrastructure

- Kubernetes cluster (1.29+)
  - 3+ worker nodes (for HA)
  - 4+ vCPU / 8+ GB RAM per node (minimum)
  - 50+ GB disk per node
- Container registry (Docker Hub, Harbor, ECR, etc.)
- Domain name (for TLS) with DNS access
- Slack webhook URL (for alerts)

### Node Setup

```bash
# Install open-iscsi on all worker nodes (for Longhorn)
sudo apt-get update && sudo apt-get install -y open-iscsi nfs-common

# Or for RHEL/CentOS
sudo yum install -y iscsi-initiator-utils nfs-utils

```

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd infra-repo

```

### 2. Configure Variables

Edit these files with your actual values:

| File | Variable | Description |
| --- | --- | --- |
| `apps/*/deployment.yaml` | `image:` | Your container registry path |
| `ingress-routes/app-ingress.yaml` | `app.yourdomain.com` | Your application domain |
| `jenkins/ingress.yaml` | `jenkins.yourdomain.com` | Your Jenkins domain |
| `ingress-controller/cert-manager/clusterissuer.yaml` | `admin@yourdomain.com` | Your email for Let's Encrypt |
| `system/monitoring/alertmanager.yaml` | `slack_configs.api_url` | Your Slack webhook |

### 3. Build & Push Images

```bash
# Set your registry
export REGISTRY="your-dockerhub-username"

# Login
docker login

# Build all three services
docker build -t $REGISTRY/frontend:latest src/frontend/
docker build -t $REGISTRY/api:latest src/api/
docker build -t $REGISTRY/auth:latest src/auth/

# Push to registry
docker push $REGISTRY/frontend:latest
docker push $REGISTRY/api:latest
docker push $REGISTRY/auth:latest

```

### 4. Deploy Everything

```bash
# Make scripts executable
chmod +x deploy.sh destroy.sh storage/install-longhorn.sh

# Deploy!
./deploy.sh

```

### 5. Verify Deployment

```bash
# Check all pods
kubectl get pods --all-namespaces

# Watch the deployment progress
kubectl get pods -n apps -w
kubectl get pods -n data -w
kubectl get pods -n jenkins -w
kubectl get pods -n monitoring -w

```

---

## 🔧 Component Details

### CI/CD Pipeline

```
Git Push → GitHub Webhook → Jenkins → Kaniko Build → Push Image → Deploy to K8s

```

* **Jenkins**: StatefulSet with persistent configuration
* **Build Agents**: Ephemeral Kubernetes pods (no idle workers)
* **Kaniko**: Daemonless container building (no Docker socket, no root)
* **Image Registry**: Your registry of choice (Docker Hub shown)

### Application Layer

| Service | Tech | Port | Min/Max Pods | Probes |
| --- | --- | --- | --- | --- |
| **Frontend** | React + Nginx | 80 | 2 / 10 | `/` |
| **API** | Node.js / Express | 3000 | 3 / 20 | `/health` |
| **Auth** | Node.js / Express + JWT | 4000 | 2 / 10 | `/health` |

### Data Layer

| Service | Version | Port | Storage | Access |
| --- | --- | --- | --- | --- |
| PostgreSQL | 16-alpine | 5432 | 10Gi | Internal only |
| Redis | 7-alpine | 6379 | 5Gi | Internal only |

### Monitoring Stack

| Component | Purpose | Port | Storage |
| --- | --- | --- | --- |
| Prometheus | Metrics collection | 9090 | 20Gi |
| Loki | Log aggregation | 3100 | 10Gi |
| Promtail | Log shipping (DaemonSet) | 9080 | — |
| Grafana | Dashboards | 3000 | — |
| Alertmanager | Alert routing | 9093 | — |

### Pre-configured Alerts

* **PodCrashLooping**: Pod restarting repeatedly
* **HighCPUUsage**: Container CPU > 80%
* **HighMemoryUsage**: Container memory > 90%

---

## 🌐 Accessing Services

### Via Ingress (Production)

| Service | URL |
| --- | --- |
| Application | `https://app.yourdomain.com` |
| Jenkins | `https://jenkins.yourdomain.com` |

> **DNS Setup**: Point your domain's A record to the Ingress Controller's external IP.

### Via Port Forward (Development)

```bash
# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
# → http://localhost:3000

# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# → http://localhost:9090

# Jenkins
kubectl port-forward -n jenkins svc/jenkins 8080:8080
# → http://localhost:8080

# Frontend
kubectl port-forward -n apps svc/frontend 8081:80
# → http://localhost:8081

```

### Default Credentials

| Service | Username | Password |
| --- | --- | --- |
| Grafana | `admin` | `admin` |
| PostgreSQL | `admin` | `supersecret` |
| Auth API | `admin` | `admin123` |

> ⚠️ **Change all default credentials in production!**

---

## 📊 Day-2 Operations

### Scaling

```bash
# Manual scale
kubectl scale deployment frontend -n apps --replicas=5

# Check HPA status
kubectl get hpa -n apps

# View HPA details
kubectl describe hpa api-hpa -n apps

```

### Logs

```bash
# Application logs
kubectl logs -n apps deployment/api --tail=100 -f

# All logs via Loki (Grafana UI)
# → http://localhost:3000 → Explore → Select Loki datasource

```

### Database Access

```bash
# PostgreSQL
kubectl exec -it -n data statefulset/postgres -- psql -U admin devops_db

# Redis
kubectl exec -it -n data statefulset/redis -- redis-cli

```

### Updates & Rollbacks

```bash
# Update image
kubectl set image deployment/api api=$REGISTRY/api:v2 -n apps

# Check rollout status
kubectl rollout status deployment/api -n apps

# Rollback if needed
kubectl rollout undo deployment/api -n apps

# View rollout history
kubectl rollout history deployment/api -n apps

```

### Backup

```bash
# PostgreSQL backup
kubectl exec -n data statefulset/postgres -- \
  pg_dump -U admin devops_db > backup_$(date +%Y%m%d).sql

# Redis backup (RDB is automatic when appendonly is enabled)
kubectl exec -n data statefulset/redis -- redis-cli BGSAVE

```

---

## 🔍 Troubleshooting

| Issue | Command |
| --- | --- |
| Pod not starting | `kubectl describe pod -n apps <pod-name>` |
| PVC pending | `kubectl get pvc --all-namespaces` |
| HPA not working | `kubectl describe hpa -n apps` |
| Ingress not routing | `kubectl describe ingress -n apps` |
| Cert-Manager issues | `kubectl describe certificate -A` |
| Pod crash loop | `kubectl logs -n apps <pod-name> --previous` |
| Node resource pressure | `kubectl top nodes` |
| Pod resource usage | `kubectl top pods -n apps` |

### Common Problems

**PVC stuck in Pending:**

```bash
# Check if StorageClass is set as default
kubectl get storageclass
# If not, update PVCs with the correct storageClassName

```

**HPA shows unknown metrics:**

```bash
# Verify Metrics Server is running
kubectl get pods -n kube-system | grep metrics-server
# Wait 2-3 minutes after Metrics Server starts

```

**Cert-Manager not issuing certificates:**

```bash
# Check the challenge
kubectl describe challenge -A
# Ensure DNS is correctly pointing to Ingress IP

```

---

## 🔒 Security Notes

* **Secrets**: All sensitive values use Kubernetes Secrets (base64 encoded — use Sealed Secrets or Vault for production)
* **Kaniko**: Builds run without Docker socket, no privileged pods
* **RBAC**: Each component has minimal required permissions
* **Network**: Databases use internal ClusterIP only (no external exposure)
* **TLS**: All external traffic encrypted via Let's Encrypt
* **JWT**: Auth service fails fast if `JWT_SECRET` is not set (no defaults)

### Production Hardening Checklist

* [ ] Change all default passwords in `data/postgres/secrets.yaml`
* [ ] Use a strong, unique JWT secret
* [ ] Enable network policies between namespaces
* [ ] Add Pod Security Standards
* [ ] Use Sealed Secrets or External Secrets Operator
* [ ] Configure Grafana with SSO (LDAP/OAuth)
* [ ] Set up proper persistent storage for Grafana dashboards
* [ ] Add resource quotas per namespace
* [ ] Enable audit logging
* [ ] Set up off-site backups for PostgreSQL

---

## 📝 License

MIT

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

---

**Built with ❤️ using Kubernetes, React, Node.js, and DevOps best practices.**
