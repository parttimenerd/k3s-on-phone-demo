#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

trap cleanup EXIT

echo "Setting up port-forward to echo service..."
kubectl port-forward svc/echo 8080:80 &

sleep 1

echo "Querying echo service at localhost:8080 to see which pod handles the request..."
echo ""

for i in {1..5}; do
  echo "Request $i:"
  curl -s "http://localhost:8080?echo_env_body=HOSTNAME"
  echo ""
  sleep 1
done
