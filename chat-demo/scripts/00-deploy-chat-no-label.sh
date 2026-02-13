#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Deploying chat (no LLM label)..."
echo ""

sudo kubectl apply -f chat-demo/manifests/chat-config.yaml
sudo kubectl apply -f chat-demo/manifests/chat.yaml

echo ""
echo "Pods (should be Pending without llm label):"
kubectl get pods -l app=chat -o wide
