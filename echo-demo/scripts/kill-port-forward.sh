#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Stopping port-forward..."
pkill -f 'kubectl port-forward' || echo "No port-forward process found"

echo "Port-forward stopped"
