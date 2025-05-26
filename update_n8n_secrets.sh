#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# update_n8n_secrets.sh
#
# Rotates all Docker Swarm secrets for the n8n_stack based on the files
# in ./secrets/*.txt, then forces the n8n service to pick up the new values.
#
# Secrets files (basename → secret name):
#   secrets/n8n_basic_auth_password.txt    → n8n_basic_auth_password
#   secrets/n8n_db_host.txt                → n8n_db_host
#   secrets/n8n_db_port.txt                → n8n_db_port
#   secrets/n8n_db_schema.txt              → n8n_db_schema
#   secrets/n8n_db_user.txt                → n8n_db_user
#   secrets/n8n_db_password.txt            → n8n_db_password
#   secrets/n8n_db_name.txt                → n8n_db_name
#   secrets/n8n_encryption_key.txt         → n8n_encryption_key
#
# Usage:
#   ./update_n8n_secrets.sh
#
# Prerequisites:
#   - You are in the repo root containing ./secrets/ directory.
#   - Docker Swarm is initialized and the n8n_stack is deployed.
#   - You have permission to manage Docker (either in the docker group or via sudo).
#
# What it does:
#   1. Scales the n8n service down to 0 replicas so secrets can be removed.
#   2. Removes each old secret (ignoring “not found” errors).
#   3. Creates a new secret from each corresponding file in ./secrets/.
#   4. Scales the n8n service back to 1 replica, forcing it to pull the new secrets.
#

#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

STACK_NAME="n8n_stack"
SERVICE_NAME="${STACK_NAME}_n8n"
SECRETS_DIR="./secrets"

echo "🔄 Scaling down service ${SERVICE_NAME} to 0 replicas…"
docker service update --replicas=0 "$SERVICE_NAME"

echo "🔐 Rotating secrets from ${SECRETS_DIR}/*.txt…"
for secret_file in "$SECRETS_DIR"/*.txt; do
  [[ -e "$secret_file" ]] || continue

  base_secret_name=$(basename "$secret_file" .txt)
  swarm_secret_name="${STACK_NAME}_${SERVICE_NAME##${STACK_NAME}_}_$base_secret_name"

  echo " • Removing old secret (if exists): $swarm_secret_name"
  docker secret rm "$swarm_secret_name" 2>/dev/null || true

  echo " • Creating new secret: $swarm_secret_name"
  docker secret create "$swarm_secret_name" "$secret_file"
done

echo "🔄 Scaling up service ${SERVICE_NAME} to 1 replica…"
docker service update --replicas=1 "$SERVICE_NAME"

echo "✅ All secrets rotated and stack-compatible secret names updated."
