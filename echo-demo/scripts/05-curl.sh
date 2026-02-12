#!/usr/bin/env bash
set -euo pipefail

echo "curl http://localhost:3000?echo_code=402"
curl http://localhost:3000?echo_code=402
