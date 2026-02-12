#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Port-forward the Echo service to localhost
echo "Forwarding localhost:3000 -> service/echo:80"
echo "Try: curl http://localhost:3000"
echo ""
sudo kubectl port-forward svc/echo 3000:80
