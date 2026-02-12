#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Check for required argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <control-plane-hostname>"
  echo "Example: $0 phone-a"
  exit 1
fi

CONTROL_PLANE_HOSTNAME=$1

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
echo "This will join the cluster as a worker node."
echo ""

curl -sfL https://get.k3s.io | K3S_URL=https://$CONTROL_PLANE_HOSTNAME:6443 K3S_TOKEN=$K3S_TOKEN sh -

echo ""
echo "Join complete! Verify on control plane with:"
echo "  kubectl get nodes"
