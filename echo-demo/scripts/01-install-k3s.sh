#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

sudo apt install -y curl > /dev/null 2>&1 || apt install -y curl > /dev/null 2>&1

echo "Installing k3s with simple token 'abc'..."
echo "NOTE: Using a simple token is ONLY acceptable because we're in a VPN."
echo "      In production, NEVER use simple tokens like this!"
echo ""

curl -sfL https://get.k3s.io | K3S_TOKEN=abc sh -
