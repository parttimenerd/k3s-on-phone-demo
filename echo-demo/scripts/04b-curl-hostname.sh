#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Querying echo service nodePort to load balance across all pods..."
echo ""

for i in {1..5}; do
  echo "Request $i:"
  curl --connect-timeout 2 -s "http://localhost:30080?echo_env_body=HOSTNAME" || echo "timeout"
  echo ""
  sleep 1
done
  sleep 1
done
