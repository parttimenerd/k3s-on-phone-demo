#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Check for required argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <hostname>"
  echo "Example: $0 phone-a"
  exit 1
fi

HOSTNAME=$1

echo "Setting up Tailscale as '$HOSTNAME'..."
echo ""

# Check for API key file
if [ ! -f .tailscale-key ]; then
  echo "Error: .tailscale-key file not found"
  echo "Please create a .tailscale-key file with your Tailscale auth key"
  exit 1
fi

AUTH_KEY=$(cat .tailscale-key)

echo "Step 1: Install Tailscale"
curl -fsSL https://tailscale.com/install.sh | sh

echo ""
echo "Step 2: Connect to Tailscale network"
sudo tailscale up --auth-key "$AUTH_KEY" --hostname "$HOSTNAME"

echo ""
echo "Step 3: Verify connection"
tailscale status
