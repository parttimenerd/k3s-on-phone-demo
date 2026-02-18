#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Get the LoadBalancer external IP
EXTERNAL_IP=$(kubectl get svc echo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -z "$EXTERNAL_IP" ]; then
  echo "Error: LoadBalancer external IP not available"
  echo "Make sure the echo service is deployed with 'kubectl apply -f echo-demo/manifests/echo.yaml'"
  exit 1
fi

echo "Querying echo service at $EXTERNAL_IP to see which pod handles the request..."
echo ""

for i in {1..5}; do
  echo "Request $i:"
  curl -s "http://$EXTERNAL_IP?echo_env_body=HOSTNAME"
  echo ""
  sleep 1
done
