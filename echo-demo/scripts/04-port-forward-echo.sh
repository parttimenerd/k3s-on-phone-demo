#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Checking Echo service..."
echo ""

# Check if service exists
if ! kubectl get svc echo > /dev/null 2>&1; then
  echo "Error: Echo service not found!"
  echo "Make sure to run deploy script first: ./echo-demo/scripts/03-deploy-echo.sh"
  exit 1
fi

# Get the NodePort
NODEPORT=$(kubectl get svc echo -o jsonpath='{.spec.ports[0].nodePort}')
echo "Echo service is available at: http://127.0.0.1:$NODEPORT"
echo ""
echo "You can test it with:"
echo "  curl http://127.0.0.1:$NODEPORT?echo_code=402"
echo ""
echo "Service details:"
kubectl get svc echo
