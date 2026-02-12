#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Testing chat service..."
echo ""

echo "Accessing chat web UI at http://localhost"
echo ""
echo "You can also test the API:"
echo "  curl http://localhost/api/healthz"
echo ""

curl -s http://localhost/api/healthz && echo "" || echo "Service not ready yet"
