#!/bin/bash

# ============================================
# DevOps Platform - Teardown Script
# ============================================

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
echo -e "${RED}║  ⚠️  DESTROY DevOps Platform  ⚠️        ║${NC}"
echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This will DELETE all platform resources!${NC}"
echo ""
read -p "Type 'DESTROY' to confirm: " -r
echo ""

if [ "$REPLY" != "DESTROY" ]; then
    echo "Cancelled."
    exit 0
fi

echo "Deleting in reverse order..."

# 9. Monitoring
echo "[9/9] Deleting monitoring..."
kubectl delete -f system/monitoring/ --ignore-not-found=true

# 8. Ingress Routes
echo "[8/9] Deleting ingress routes..."
kubectl delete -f ingress-routes/ --ignore-not-found=true

# 7. Apps
echo "[7/9] Deleting applications..."
kubectl delete -f apps/ --ignore-not-found=true

# 6. System
echo "[6/9] Deleting system services..."
kubectl delete -f system/metrics-server.yaml --ignore-not-found=true
kubectl delete -f system/cluster-autoscaler.yaml --ignore-not-found=true

# 5. Ingress Controller
echo "[5/9] Deleting ingress controller..."
kubectl delete -f ingress-controller/ --ignore-not-found=true

# 4. Jenkins
echo "[4/9] Deleting Jenkins..."
kubectl delete -f jenkins/ --ignore-not-found=true

# 3. Data
echo "[3/9] Deleting data layer..."
kubectl delete -f data/ --ignore-not-found=true

# 2. Delete PVCs
echo "[2/9] Deleting PVCs..."
kubectl delete pvc --all -n jenkins --ignore-not-found=true
kubectl delete pvc --all -n data --ignore-not-found=true
kubectl delete pvc --all -n monitoring --ignore-not-found=true

# 1. Delete namespaces
echo "[1/9] Deleting namespaces..."
kubectl delete namespace apps jenkins data monitoring --ignore-not-found=true

echo ""
echo "✅ Platform destroyed."