#!/bin/bash
# SPDX-License-Identifier: MIT
set -euo pipefail

# Path to fallback secrets
SECRETS_DIR="./secrets"

# Helper: use env var if defined, else fallback to file
load_env_or_file() {
  local var="$1"
  local file="$SECRETS_DIR/${2:-$var}.txt"
  if [[ -z "${!var:-}" && -f "$file" ]]; then
    export "$var"="$(< "$file")"
  fi
}

# Load secrets (use env var if set, otherwise fallback to file)
load_env_or_file N8N_BASIC_AUTH_USER
load_env_or_file N8N_BASIC_AUTH_PASSWORD
load_env_or_file N8N_ENCRYPTION_KEY

load_env_or_file DB_POSTGRESDB_HOST
load_env_or_file DB_POSTGRESDB_SCHEMA
load_env_or_file DB_POSTGRESDB_PORT
load_env_or_file DB_POSTGRESDB_USER
load_env_or_file DB_POSTGRESDB_PASSWORD
load_env_or_file DB_POSTGRESDB_DATABASE

# Final validation: all vars must now be set
required_vars=(
  N8N_BASIC_AUTH_USER
  N8N_BASIC_AUTH_PASSWORD
  N8N_ENCRYPTION_KEY
  DB_POSTGRESDB_HOST
  DB_POSTGRESDB_SCHEMA
  DB_POSTGRESDB_PORT
  DB_POSTGRESDB_USER
  DB_POSTGRESDB_PASSWORD
  DB_POSTGRESDB_DATABASE
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ Required variable '$var' is not set and no fallback secret found."
    exit 1
  fi
done

if [[ "${RESET_CREDENTIALS:-false}" == "true" ]]; then
  echo "🔁 Resetting n8n user management..."
  n8n user-management:reset
fi

# Launch n8n
echo "🚀 Starting n8n..."
exec n8n

