#!/bin/bash
set -e

# Docker publish script for phone-chat backend
# Usage: ./publish.sh [registry/image:tag]
# Example: ./publish.sh docker.io/parttimenerd/phone-chat:v1.0.0

if [ -z "$1" ]; then
  echo "Usage: $0 <image:tag>"
  echo "Example: $0 docker.io/myuser/phone-chat:v1.0.0"
  exit 1
fi

IMAGE="$1"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Building Docker image: $IMAGE"
docker build -t "$IMAGE" "$DIR"

echo "Pushing image to registry..."
docker push "$IMAGE"

echo "Done! Image: $IMAGE"
