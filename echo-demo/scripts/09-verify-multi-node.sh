#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Verifying Multi-Node Cluster"
echo "============================="
echo ""

echo "All nodes in cluster:"
kubectl get nodes -o wide

echo ""
echo "Node details:"
kubectl get nodes
