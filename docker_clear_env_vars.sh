#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="n8n_stack"

echo "🧹 Removing stack: $STACK_NAME..."
docker stack rm "$STACK_NAME"

echo "🧼 Cleaning up secrets related to $STACK_NAME..."
docker secret ls --format '{{.Name}}' | grep "^${STACK_NAME}_" | xargs -r docker secret rm

echo "🗑️ Removing custom Docker image: my-n8n:latest..."
docker image rm my-n8n:latest || echo "Image my-n8n:latest not found."

echo "✅ Cleanup completed."
