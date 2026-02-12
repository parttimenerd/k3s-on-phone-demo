#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Scale the deployment to 3 replicas
echo "Scaling Echo deployment to 3 replicas..."
sudo kubectl scale deployment echo --replicas=3

echo ""
echo "Waiting for new pods to be ready..."
sudo kubectl wait --for=condition=ready pod -l app=echo --timeout=60s

echo ""
echo "All pods running:"
echo "kubectl get pods -o wide"
sudo kubectl get pods -o wide