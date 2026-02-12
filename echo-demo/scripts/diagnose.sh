#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== K3s Cluster Status ==="
echo ""
echo "Nodes:"
kubectl get nodes
echo ""

echo "=== Echo Deployment ==="
echo ""
echo "Deployment status:"
kubectl get deployment echo || echo "Deployment not found"
echo ""

echo "Pods:"
kubectl get pods -l app=echo || echo "No pods found"
echo ""

echo "Service:"
kubectl get svc echo || echo "Service not found"
echo ""

echo "=== Pod Details ==="
echo ""
PODS=$(kubectl get pods -l app=echo -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
if [ -z "$PODS" ]; then
  echo "No pods running"
else
  for POD in $PODS; do
    echo "Pod: $POD"
    echo "Status:"
    kubectl get pod "$POD" -o jsonpath='{.status.phase}' || echo "Unknown"
    echo ""
    echo "Logs:"
    kubectl logs "$POD" --tail=10 2>/dev/null || echo "No logs available"
    echo "---"
  done
fi
