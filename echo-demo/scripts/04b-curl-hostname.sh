#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Set up port-forward to the service for load balancing
PORT_FORWARD_PID=""

cleanup() {
  if [ -n "$PORT_FORWARD_PID" ]; then
    kill $PORT_FORWARD_PID 2>/dev/null || true
  fi
}

trap cleanup EXIT

echo "Setting up port-forward to echo service..."
kubectl port-forward svc/echo 8080:80 > /dev/null 2>&1 &
PORT_FORWARD_PID=$!
sleep 1

echo "Querying echo service at localhost:8080 to see which pod handles the request..."
echo ""

for i in {1..5}; do
  echo "Request $i:"
  curl -s "http://localhost:8080?echo_env_body=HOSTNAME"
  echo ""
  sleep 1
done
