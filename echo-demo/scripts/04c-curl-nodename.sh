#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Get a node name to query (defaults to first node)
NODE_NAME="${1:-}"

if [ -z "$NODE_NAME" ]; then
  NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
fi

# Get the node's internal IP (works across Tailscale VPN)
NODE_IP=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

if [ -z "$NODE_IP" ]; then
  echo "Error: Could not get IP for node $NODE_NAME"
  exit 1
fi

# Use nodePort (30080) which load balances across all pods
SERVICE_ADDR="$NODE_IP:30080"

echo "Querying echo service at $SERVICE_ADDR (node: $NODE_NAME) to see which node handles the request..."
echo ""

for i in {1..5}; do
  echo "Request $i:"
  curl -s "http://$SERVICE_ADDR?echo_env_body=NODE_NAME"
  echo ""
  sleep 1
done
