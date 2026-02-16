#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Querying echo service to see which pod handles the request..."
echo ""

for i in {1..5}; do
  echo "Request $i:"
  curl -s "http://127.0.0.1:30080?echo_env_body=HOSTNAME"
  echo ""
  sleep 1
done
