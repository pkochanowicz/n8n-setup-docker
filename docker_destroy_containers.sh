#!/usr/bin/env bash
set -euo pipefail

read -rp "⚠️  This will STOP and DELETE all containers, volumes, and Swarm! Are you sure? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "❌ Aborted. Nothing was destroyed."
  exit 1
fi

echo "🔥 Removing all containers, volumes, and Swarm stack..."

docker stack rm n8n_stack
docker system prune -af --volumes
docker swarm leave --force

echo "✅ All containers, volumes, and Swarm removed."