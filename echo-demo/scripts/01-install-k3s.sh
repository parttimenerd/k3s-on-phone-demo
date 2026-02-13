#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

sudo apt install -y curl > /dev/null 2>&1 || apt install -y curl > /dev/null 2>&1

if [ -d "/var/lib/rancher/k3s/server" ]; then
	echo "Existing k3s data detected."
	read -r -p "Wipe existing k3s data and reinstall? [y/N] " confirm
	if [[ "${confirm}" =~ ^[Yy]$ ]]; then
		echo "Stopping k3s service (if running)..."
		sudo systemctl stop k3s > /dev/null 2>&1 || true

		if [ -x "/usr/local/bin/k3s-uninstall.sh" ]; then
			echo "Running k3s uninstall script..."
			sudo /usr/local/bin/k3s-uninstall.sh || true
		fi

		if [ -x "/usr/local/bin/k3s-agent-uninstall.sh" ]; then
			echo "Running k3s agent uninstall script..."
			sudo /usr/local/bin/k3s-agent-uninstall.sh || true
		fi

		echo "Removing k3s data directory..."
		sudo rm -rf /var/lib/rancher/k3s/server
	else
		echo "Keeping existing data. Install may fail if token differs."
	fi
fi

echo "Installing k3s with simple token 'abc'..."
echo "NOTE: Using a simple token is ONLY acceptable because we're in a VPN."
echo "      In production, NEVER use simple tokens like this!"
echo ""

curl -sfL https://get.k3s.io | K3S_TOKEN=abc sh -
