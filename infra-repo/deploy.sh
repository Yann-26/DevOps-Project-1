#!/bin/bash

# ============================================
# DevOps Platform - Complete Deployment Script
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_LOG="/tmp/devops-platform-deploy.log"
START_TIME=$(date +%s)

# ============================================
# Helper Functions
# ============================================

log() {
    echo -e "$(date '+%H:%M:%S') $1" | tee -a "$DEPLOY_LOG"
}

header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
    log "✅ $1"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log "⚠️  $1"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    log "❌ $1"
}

check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed. Please install it first."
        exit 1
    fi
}

check_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster. Check your kubeconfig."
        exit 1
    fi
    success "Connected to Kubernetes cluster"
}

wait_for_pods() {
    local namespace=$1
    local label=$2
    local timeout=${3:-300}
    
    log "Waiting for pods in namespace '$namespace' with label '$label'..."
    
    local start_time=$(date +%s)
    while true; do
        local ready=$(kubectl get pods -n "$namespace" -l "$label" \
            -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | \
            tr ' ' '\n' | grep -c "True" || true)
        local total=$(kubectl get pods -n "$namespace" -l "$label" \
            --no-headers 2>/dev/null | wc -l || true)
        
        if [ "$ready" -eq "$total" ] && [ "$total" -gt 0 ]; then
            success "All $total pods ready in $namespace"
            return 0
        fi
        
        local elapsed=$(( $(date +%s) - start_time ))
        if [ "$elapsed" -gt "$timeout" ]; then
            warning "Timeout waiting for pods in $namespace ($ready/$total ready)"
            return 1
        fi
        
        echo -ne "\r  ⏳ $ready/$total pods ready... (${elapsed}s)   "
        sleep 5
    done
}

apply_manifests() {
    local path=$1
    local description=$2
    
    header "$description"
    if kubectl apply -f "$path" >> "$DEPLOY_LOG" 2>&1; then
        success "Applied: $path"
        return 0
    else
        error "Failed to apply: $path"
        echo -e "${RED}Check the log: $DEPLOY_LOG${NC}"
        return 1
    fi
}

# ============================================
# Main Deployment
# ============================================

main() {
    > "$DEPLOY_LOG"  # Clear log
    log "============================================="
    log " DevOps Platform Deployment Started"
    log "============================================="
    
    # Pre-flight checks
    header "PRE-FLIGHT CHECKS"
    check_kubectl
    check_cluster
    
    # Display cluster info
    echo ""
    kubectl get nodes -o wide 2>/dev/null | head -5
    echo ""
    
    # Ask for confirmation
    echo -e "${YELLOW}This will deploy the entire DevOps platform to your cluster.${NC}"
    echo -e "${YELLOW}Make sure your kubeconfig points to the correct cluster.${NC}"
    echo ""
    read -p "Continue? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warning "Deployment cancelled."
        exit 0
    fi
    
    # ==========================================
    # Step 1: Storage Layer
    # ==========================================
    header "STEP 1: STORAGE LAYER"
    
    if [ -f "$SCRIPT_DIR/storage/local-storage.yaml" ]; then
        apply_manifests "$SCRIPT_DIR/storage/local-storage.yaml" "Local Path StorageClass"
    fi
    
    if [ -f "$SCRIPT_DIR/storage/install-longhorn.sh" ]; then
        echo ""
        echo -e "${YELLOW}Longhorn installation script found.${NC}"
        read -p "Install Longhorn now? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            bash "$SCRIPT_DIR/storage/install-longhorn.sh"
            success "Longhorn installed"
        else
            warning "Skipping Longhorn. Using local-path storage."
            warning "You must update all PVCs to use 'storageClassName: local-path'"
        fi
    fi
    
    # ==========================================
    # Step 2: Namespaces
    # ==========================================
    header "STEP 2: NAMESPACES"
    
    NAMESPACES=(
        "jenkins/namespace.yaml"
        "data/namespace.yaml"
        "apps/namespace.yaml"
        "system/monitoring/namespace.yaml"
    )
    
    for ns in "${NAMESPACES[@]}"; do
        if [ -f "$SCRIPT_DIR/$ns" ]; then
            apply_manifests "$SCRIPT_DIR/$ns" "Namespace: $ns"
        fi
    done
    
    sleep 3
    
    # ==========================================
    # Step 3: Data Layer
    # ==========================================
    header "STEP 3: DATA LAYER (PostgreSQL + Redis)"
    
    if [ -d "$SCRIPT_DIR/data" ]; then
        apply_manifests "$SCRIPT_DIR/data" "Data Layer"
        sleep 10
        wait_for_pods "data" "app" 180
    else
        error "Data layer directory not found"
        exit 1
    fi
    
    # ==========================================
    # Step 4: Jenkins
    # ==========================================
    header "STEP 4: JENKINS CI/CD"
    
    if [ -d "$SCRIPT_DIR/jenkins" ]; then
        apply_manifests "$SCRIPT_DIR/jenkins" "Jenkins"
        sleep 10
        echo ""
        echo -e "${CYAN}Jenkins initial admin password (waiting for pod to be ready):${NC}"
        echo "  kubectl exec -n jenkins statefulset/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword"
        wait_for_pods "jenkins" "app=jenkins" 300
    else
        error "Jenkins directory not found"
        exit 1
    fi
    
    # ==========================================
    # Step 5: Ingress Controller + Cert-Manager
    # ==========================================
    header "STEP 5: INGRESS CONTROLLER + CERT-MANAGER"
    
    if [ -d "$SCRIPT_DIR/ingress-controller" ]; then
        apply_manifests "$SCRIPT_DIR/ingress-controller/namespace.yaml" "Ingress NGINX Namespace"
        
        if [ -d "$SCRIPT_DIR/ingress-controller/cert-manager" ]; then
            apply_manifests "$SCRIPT_DIR/ingress-controller/cert-manager" "Cert-Manager"
        fi
        
        apply_manifests "$SCRIPT_DIR/ingress-controller/nginx-ingress.yaml" "NGINX Ingress Controller"
        
        sleep 15
        wait_for_pods "ingress-nginx" "app=nginx-ingress" 180
    else
        error "Ingress controller directory not found"
        exit 1
    fi
    
    # ==========================================
    # Step 6: System Services
    # ==========================================
    header "STEP 6: SYSTEM SERVICES (Metrics Server + Cluster Autoscaler)"
    
    if [ -f "$SCRIPT_DIR/system/metrics-server.yaml" ]; then
        apply_manifests "$SCRIPT_DIR/system/metrics-server.yaml" "Metrics Server"
        sleep 10
        wait_for_pods "kube-system" "app=metrics-server" 120
    fi
    
    if [ -f "$SCRIPT_DIR/system/cluster-autoscaler.yaml" ]; then
        apply_manifests "$SCRIPT_DIR/system/cluster-autoscaler.yaml" "Cluster Autoscaler"
    fi
    
    # ==========================================
    # Step 7: Applications
    # ==========================================
    header "STEP 7: APPLICATIONS (Frontend + API + Auth)"
    
    if [ -d "$SCRIPT_DIR/apps" ]; then
        apply_manifests "$SCRIPT_DIR/apps" "Applications"
        sleep 15
        wait_for_pods "apps" "app" 300
    else
        error "Apps directory not found"
        exit 1
    fi
    
    # ==========================================
    # Step 8: Ingress Routes
    # ==========================================
    header "STEP 8: INGRESS ROUTES"
    
    if [ -f "$SCRIPT_DIR/ingress-routes/app-ingress.yaml" ]; then
        apply_manifests "$SCRIPT_DIR/ingress-routes/app-ingress.yaml" "Application Ingress Routes"
    fi
    
    # ==========================================
    # Step 9: Monitoring Stack
    # ==========================================
    header "STEP 9: MONITORING STACK"
    
    if [ -d "$SCRIPT_DIR/system/monitoring" ]; then
        apply_manifests "$SCRIPT_DIR/system/monitoring" "Monitoring Stack"
        
        echo ""
        echo -e "${CYAN}Waiting for monitoring components to be ready...${NC}"
        sleep 15
        wait_for_pods "monitoring" "app" 300
        
        success "Monitoring stack deployed"
    else
        warning "Monitoring directory not found. Skipping."
    fi
    
    # ==========================================
    # Deployment Summary
    # ==========================================
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    header "🎉 DEPLOYMENT COMPLETE!"
    
    echo -e "${BOLD}Deployment took ${DURATION} seconds.${NC}"
    echo ""
    echo -e "${BOLD}────────────────────────────────────────────${NC}"
    echo -e "${BOLD}  Access URLs:${NC}"
    echo -e "${BOLD}────────────────────────────────────────────${NC}"
    echo ""
    
    # Get ingress info
    INGRESS_IP=$(kubectl get svc -n ingress-nginx nginx-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "PENDING")
    INGRESS_HOSTNAME=$(kubectl get svc -n ingress-nginx nginx-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ "$INGRESS_IP" != "PENDING" ] && [ -n "$INGRESS_IP" ]; then
        echo -e "  ${GREEN}Application:${NC}   https://app.yourdomain.com (point DNS to $INGRESS_IP)"
        echo -e "  ${GREEN}Jenkins:${NC}       https://jenkins.yourdomain.com (point DNS to $INGRESS_IP)"
    elif [ -n "$INGRESS_HOSTNAME" ]; then
        echo -e "  ${GREEN}Application:${NC}   https://app.yourdomain.com (CNAME to $INGRESS_HOSTNAME)"
        echo -e "  ${GREEN}Jenkins:${NC}       https://jenkins.yourdomain.com (CNAME to $INGRESS_HOSTNAME)"
    else
        NODE_PORT=$(kubectl get svc -n ingress-nginx nginx-ingress -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null || echo "N/A")
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "N/A")
        echo -e "  ${YELLOW}Application:${NC}   http://$NODE_IP:$NODE_PORT (NodePort - update hosts file)"
        echo -e "  ${YELLOW}Jenkins:${NC}       http://$NODE_IP:$NODE_PORT (with proper Host header)"
    fi
    
    echo ""
    echo -e "${BOLD}────────────────────────────────────────────${NC}"
    echo -e "${BOLD}  Port Forwards (for local access):${NC}"
    echo -e "${BOLD}────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${CYAN}Grafana:${NC}       kubectl port-forward -n monitoring svc/grafana 3000:3000"
    echo -e "  ${CYAN}Prometheus:${NC}    kubectl port-forward -n monitoring svc/prometheus 9090:9090"
    echo -e "  ${CYAN}Jenkins:${NC}       kubectl port-forward -n jenkins svc/jenkins 8080:8080"
    echo -e "  ${CYAN}Frontend:${NC}      kubectl port-forward -n apps svc/frontend 80:80"
    echo ""
    echo -e "${BOLD}────────────────────────────────────────────${NC}"
    echo -e "${BOLD}  Default Credentials:${NC}"
    echo -e "${BOLD}────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${CYAN}Grafana:${NC}       admin / admin"
    echo -e "  ${CYAN}PostgreSQL:${NC}    admin / supersecret"
    echo -e "  ${CYAN}Auth API:${NC}     admin / admin123"
    echo ""
    echo -e "${BOLD}────────────────────────────────────────────${NC}"
    echo -e "${BOLD}  Useful Commands:${NC}"
    echo -e "${BOLD}────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${CYAN}Check all pods:${NC}        kubectl get pods --all-namespaces"
    echo -e "  ${CYAN}Watch pods:${NC}            kubectl get pods -n apps -w"
    echo -e "  ${CYAN}View logs:${NC}             kubectl logs -n apps deployment/api"
    echo -e "  ${CYAN}Check HPA:${NC}             kubectl get hpa -n apps"
    echo -e "  ${CYAN}Check PVC:${NC}             kubectl get pvc --all-namespaces"
    echo -e "  ${CYAN}Full log:${NC}              cat $DEPLOY_LOG"
    echo ""
    
    log "============================================="
    log " DevOps Platform Deployment Completed"
    log " Duration: ${DURATION}s"
    log "============================================="
}

# ============================================
# Run
# ============================================
main "$@"