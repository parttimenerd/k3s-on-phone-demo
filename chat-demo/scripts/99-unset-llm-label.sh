#!/usr/bin/env bash
set -euo pipefail

NODE_NAME="$(hostname)"

echo "Removing llm label from node ${NODE_NAME}..."
sudo kubectl label node "${NODE_NAME}" llm-

echo ""
kubectl get node "${NODE_NAME}" --show-labels
