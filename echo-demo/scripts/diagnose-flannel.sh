#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== Flannel Networking Diagnostic ==="
echo ""

echo "1. Flannel pod status:"
kubectl get pods -n kube-system -l app=flannel -o wide
echo ""

echo "2. Flannel configuration:"
kubectl get configmap -n kube-system kube-flannel-cfg -o jsonpath='{.data.net-conf\.json}' | jq .
echo ""

echo "3. Node annotations (pod CIDR assignments):"
kubectl get nodes -o custom-columns=NAME:.metadata.name,POD_CIDR:.spec.podCIDR
echo ""

echo "4. Flannel tunnel interface status on each node:"
echo "localhost:"
ip -d link show flannel.1 2>/dev/null || echo "  flannel.1 not found"
echo ""

echo "5. Flannel routing table:"
ip route | grep flannel
echo ""

echo "6. Test connectivity to remote node's IP:"
REMOTE_IP=$(kubectl get node phone-b -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "")
if [ -n "$REMOTE_IP" ]; then
  echo "Remote node (phone-b) InternalIP: $REMOTE_IP"
  ping -c 1 "$REMOTE_IP" 2>&1 | head -2 || echo "  Ping failed"
else
  echo "Could not get remote node IP"
fi
echo ""

echo "7. Check if Flannel backend is VXLAN:"
ps aux | grep flanneld | grep -v grep | head -1
echo ""

echo "Done. If remote pod is unreachable but route exists, Flannel tunnel isn't working properly."
