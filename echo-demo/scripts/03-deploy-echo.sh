#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Deploy Echo Server with 2 pods behind a service
echo "Deploying Echo Server deployment and service..."
sudo kubectl apply -f echo-demo/manifests/echo.yaml

echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=echo --timeout=60s

echo ""
echo "Pods are running:"
kubectl get pods -o wide