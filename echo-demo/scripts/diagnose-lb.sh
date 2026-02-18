#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== Kubernetes Load Balancing Diagnostic ==="
echo ""

echo "1. Service Endpoints (should show pods from both nodes):"
kubectl get endpoints echo -o wide
echo ""

echo "2. All Pods:"
kubectl get pods -o wide -l app=echo
echo ""

echo "3. Try reaching each pod directly by IP:"
kubectl get pods -l app=echo -o jsonpath='{range .items[*]}{.status.podIP} {.spec.nodeName} {.metadata.name}{"\n"}{end}' | while read POD_IP NODE POD_NAME; do
  echo "  Pod $POD_NAME on $NODE ($POD_IP):"
  curl --connect-timeout 1 -s "http://$POD_IP/" 2>&1 | head -1 || echo "    -> unreachable"
done
echo ""

echo "4. NodePort test from localhost (goes through kube-proxy):"
curl --connect-timeout 2 -s "http://localhost:30080/" 2>&1 | head -5 || echo "  -> unreachable"
echo ""

echo "5. Check kube-proxy iptables rules:"
sudo iptables -t nat -L -n | grep -A2 "30080" || echo "  (no rules found)"
echo ""

echo "6. Check route to remote pod CIDR:"
REMOTE_PODS=$(kubectl get nodes -o jsonpath='{.items[1].spec.podCIDR}' 2>/dev/null || echo "")
if [ -n "$REMOTE_PODS" ]; then
  echo "  Remote node pod CIDR: $REMOTE_PODS"
  ip route | grep "$REMOTE_PODS" || echo "  -> no route to remote pods"
else
  echo "  (only one node or can't get CIDR)"
fi
echo ""

echo "Done."

