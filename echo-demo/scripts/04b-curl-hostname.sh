#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Get the service's ClusterIP for cross-node load balancing
CLUSTER_IP=$(kubectl get svc echo -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")

if [ -z "$CLUSTER_IP" ]; then
  echo "Error: Could not get service ClusterIP"
  exit 1
fi

echo "Querying echo service at $CLUSTER_IP to see which pod handles the request..."
echo ""

for i in {1..5}; do
  echo "Request $i:"
  kubectl run -it --rm curl-test-$$ --image=curlimages/curl --restart=Never -- \
    curl -s "http://$CLUSTER_IP?echo_env_body=HOSTNAME" || true
  echo ""
  sleep 1
done
