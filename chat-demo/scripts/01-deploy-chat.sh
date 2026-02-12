#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Deploying chat application..."
echo ""

kubectl apply -f chat-demo/manifests/chat-config.yaml
kubectl apply -f chat-demo/manifests/chat.yaml

echo ""
echo "Waiting for chat pods to be ready..."
kubectl wait --for=condition=ready pod -l app=chat --timeout=120s

echo ""
echo "Chat deployment complete!"
echo ""
echo "Pods:"
kubectl get pods -l app=chat -o wide

echo ""
echo "Service:"
kubectl get svc chat
