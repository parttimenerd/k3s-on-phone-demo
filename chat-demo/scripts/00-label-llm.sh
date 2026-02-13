#!/usr/bin/env bash
set -euo pipefail

NODE_NAME="$(hostname)"

echo "Labeling node ${NODE_NAME} with llm=true..."
sudo kubectl label node "${NODE_NAME}" llm=true --overwrite

echo ""
kubectl get node "${NODE_NAME}" --show-labels
