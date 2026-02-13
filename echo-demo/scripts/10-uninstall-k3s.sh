#!/usr/bin/env bash
set -euo pipefail

echo "Uninstalling k3s server (if present)..."
if [ -x "/usr/local/bin/k3s-uninstall.sh" ]; then
  sudo /usr/local/bin/k3s-uninstall.sh
else
  echo "k3s server uninstall script not found."
fi

echo "Uninstalling k3s agent (if present)..."
if [ -x "/usr/local/bin/k3s-agent-uninstall.sh" ]; then
  sudo /usr/local/bin/k3s-agent-uninstall.sh
else
  echo "k3s agent uninstall script not found."
fi

echo "Uninstall complete."
