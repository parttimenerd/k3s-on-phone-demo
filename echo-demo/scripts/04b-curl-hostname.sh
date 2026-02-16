#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Testing Echo Service - Getting Hostname"
echo ""
echo "curl http://127.0.0.1:30080?echo_env_body=HOSTNAME"
curl "http://127.0.0.1:30080?echo_env_body=HOSTNAME"