#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Querying echo service nodePort - k3s handles load balancing..."
echo ""

for i in {1..5}; do
  echo "Request $i:"
  curl --connect-timeout 2 -s "http://localhost:30080?echo_env_body=NODE_NAME"
  echo ""
  sleep 1
done
