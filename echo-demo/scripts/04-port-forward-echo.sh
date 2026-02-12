#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Port-forward the Echo service to localhost in background
echo "Forwarding localhost:3000 -> service/echo:80 (running in background)"
echo ""
sudo kubectl port-forward svc/echo 3000:80 &

echo "Port-forward started. You can now test it:"
echo "  curl http://localhost:3000"
echo ""
echo "To stop port-forward later, run: pkill -f 'kubectl port-forward'"
