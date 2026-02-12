#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Echo service available at: http://127.0.0.1:30080"
echo "Test: curl http://127.0.0.1:30080?echo_code=402"
