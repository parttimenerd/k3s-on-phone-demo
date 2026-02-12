#!/usr/bin/env bash
set -euo pipefail

echo "curl http://localhost:30080?echo_code=402"
curl http://localhost:30080?echo_code=402
