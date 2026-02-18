#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/"

echo "Performing complete k3s cleanup..."
echo ""

# Stop service
sudo systemctl stop k3s > /dev/null 2>&1 || true

# Run uninstall scripts
if [ -x "/usr/local/bin/k3s-uninstall.sh" ]; then
  echo "Running k3s server uninstall..."
  sudo /usr/local/bin/k3s-uninstall.sh || true
fi

if [ -x "/usr/local/bin/k3s-agent-uninstall.sh" ]; then
  echo "Running k3s agent uninstall..."
  sudo /usr/local/bin/k3s-agent-uninstall.sh || true
fi

# Remove all k3s data
echo "Removing k3s data and configuration..."
sudo rm -rf /var/lib/rancher/k3s /etc/rancher/k3s /var/lib/kubelet /opt/cni 2>/dev/null || true

echo ""
echo "Installing fresh k3s with Flannel and cluster CIDR..."
echo "NOTE: Using a simple token is ONLY acceptable because we're in a VPN."
echo "      In production, NEVER use simple tokens like this!"
echo ""

curl -sfL https://get.k3s.io | K3S_TOKEN=abc K3S_CLUSTER_CIDR=10.42.0.0/16 sh -