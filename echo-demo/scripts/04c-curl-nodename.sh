#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Testing Cross-Node Load Balancing"
echo "================================="
echo ""

echo "Querying echo service to see which node handles the request..."
echo ""

for i in {1..5}; do
  echo "Request $i:"
  curl -s "http://127.0.0.1:30080?echo_env_body=NODE_NAME" | grep -A 1 '"NODE_NAME"'
  echo ""
  sleep 1
done

echo "Notice how requests are distributed across different nodes!"
