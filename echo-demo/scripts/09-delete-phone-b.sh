#!/usr/bin/env bash
set -euo pipefail

echo "Delete Phone B from Cluster"
echo "============================"
echo ""
echo "This will remove phone-b (the worker node) from the cluster."
echo ""

NODE_NAME="phone-b"

echo "Draining node '$NODE_NAME'..."
kubectl drain "$NODE_NAME" --ignore-daemonsets --delete-emptydir-data --force || true

echo ""
echo "Deleting node '$NODE_NAME'..."
kubectl delete node "$NODE_NAME" || true

echo ""
echo "Node '$NODE_NAME' has been removed from the cluster."
echo "To completely clean up phone-b, run the uninstall script on that device:"
echo "  ./echo-demo/scripts/10-uninstall-k3s.sh"
