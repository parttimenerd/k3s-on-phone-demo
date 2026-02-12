#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Undeploy Echo Server deployment and service
echo "Undeploying Echo Server deployment and service..."
sudo kubectl delete -f manifests/echo.yaml

echo ""
echo "Waiting for pods to be terminated..."
sudo kubectl wait --for=delete pod -l app=echo --timeout=30s || true

echo ""
echo "Remaining pods:"
echo "kubectl get pods"
sudo kubectl get pods || echo "No pods remaining"
