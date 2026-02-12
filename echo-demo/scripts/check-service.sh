#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Checking Echo Service status..."
echo ""
echo "kubectl get svc echo"
sudo kubectl get svc echo

echo ""
echo "kubectl get pods -l app=echo"
sudo kubectl get pods -l app=echo

echo ""
echo "kubectl describe svc echo"
sudo kubectl describe svc echo
