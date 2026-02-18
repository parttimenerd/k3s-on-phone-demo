#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Defaults: control plane = phone-a, node name = phone-b
CONTROL_PLANE_HOSTNAME="${1:-phone-a}"
NODE_NAME="${2:-phone-b}"

echo "Join Second Phone to Cluster"
echo "============================="
echo ""
echo "Prerequisites:"
echo "- Tailscale is running on both phones"
echo "- Control plane phone has k3s server installed"
echo ""

echo "Step 1: Connecting to control plane at '$CONTROL_PLANE_HOSTNAME'"

echo ""
echo "Step 2: Using pre-configured token 'abc'"
echo "NOTE: This simple token is ONLY acceptable in a VPN."
echo "      Never use simple tokens in production!"
K3S_TOKEN="abc"

echo ""
echo "Step 3: Installing k3s agent on this phone..."
echo "Node name: $NODE_NAME"
echo "This will join the cluster as a worker node."
echo ""

curl -sfL https://get.k3s.io | K3S_URL=https://$CONTROL_PLANE_HOSTNAME:6443 K3S_TOKEN=$K3S_TOKEN K3S_NODE_NAME=$NODE_NAME K3S_CLUSTER_CIDR=10.42.0.0/16 sh -

echo ""
echo "Join complete! Verify on control plane with:"
echo "  kubectl get nodes"
