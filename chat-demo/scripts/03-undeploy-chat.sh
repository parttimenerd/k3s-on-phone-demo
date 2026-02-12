#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Undeploying chat application..."
echo ""

kubectl delete -f chat-demo/manifests/chat.yaml
kubectl delete -f chat-demo/manifests/chat-config.yaml

echo ""
echo "Chat application removed!"
