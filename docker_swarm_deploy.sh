#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

STACK_NAME="n8n_stack"
IMAGE_NAME="my-n8n:latest"
SECRETS_DIR="./secrets"
COMPOSE_FILE="docker-compose.yaml"

echo "🚦 n8n Docker Swarm deploy script"
echo "🔄 Ensuring you're in a Swarm cluster..."

if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
  echo "🌀 Swarm not initialized. Running: docker swarm init"
  docker swarm init || {
    echo "❌ Failed to init Docker Swarm. Are you root? Is Docker running?"
    exit 1
  }
else
  echo "✅ Swarm already initialized."
fi

echo "🔐 [1/4] Loading Docker secrets from '${SECRETS_DIR}'..."

if [[ ! -d "$SECRETS_DIR" ]]; then
  echo "❌ Secrets directory '$SECRETS_DIR' does not exist."; exit 1;
fi

secret_files=("$SECRETS_DIR"/*.txt)
if [[ ! -e "${secret_files[0]}" ]]; then
  echo "⚠️  No *.txt files in '$SECRETS_DIR'. Skipping secret creation."
else
  for file in "${secret_files[@]}"; do
    secret_name="$(basename "$file" .txt)"
    if docker secret ls --format '{{.Name}}' | grep -q "^${secret_name}$"; then
      echo "🔁 Updating existing secret: ${secret_name}"
      docker secret rm "$secret_name" >/dev/null
    else
      echo "➕ Creating secret: ${secret_name}"
    fi
    docker secret create "$secret_name" "$file" >/dev/null
  done
  echo "✅ Secrets are now up to date in Docker Swarm."
fi

echo "🌐 [2/4] Detecting system timezone..."
GENERIC_TIMEZONE="$(timedatectl show -p Timezone --value 2>/dev/null || echo UTC)"
export GENERIC_TIMEZONE
echo "🕒 Timezone detected: ${GENERIC_TIMEZONE}"

echo "🧼 [3/4] Cleaning previous stack (if exists)..."
if docker stack ls | grep -q "$STACK_NAME"; then
  echo "🧯 Removing old stack: $STACK_NAME"
  docker stack rm "$STACK_NAME"
  echo "⏳ Waiting for services to stop..."
  sleep 5
fi

echo "🐳 Building image: $IMAGE_NAME ..."
docker build -t "$IMAGE_NAME" . > /dev/null
echo "✅ Docker image built."

echo "🚀 [4/4] Deploying stack: $STACK_NAME..."
docker stack deploy --with-registry-auth -c "$COMPOSE_FILE" "$STACK_NAME"

echo ""
echo "🎉 All done!"
echo "📡 n8n launching"
echo "🧠 Tip: Monitor it with:"
echo "  docker service logs -f ${STACK_NAME}_n8n"
