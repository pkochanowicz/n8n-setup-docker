#!/bin/bash
# SPDX-License-Identifier: MIT
set -e

# Read secrets into env variables (n8n expects them to be available as env vars)
export N8N_BASIC_AUTH_USER=$(< /run/secrets/n8n_basic_auth_user)
export N8N_BASIC_AUTH_PASSWORD=$(< /run/secrets/n8n_basic_auth_password)
export N8N_ENCRYPTION_KEY=$(< /run/secrets/n8n_encryption_key)

export DB_POSTGRESDB_HOST=$(< /run/secrets/n8n_db_host)
export DB_POSTGRESDB_SCHEMA=$(< /run/secrets/n8n_db_schema)
export DB_POSTGRESDB_PORT=$(< /run/secrets/n8n_db_port)
export DB_POSTGRESDB_USER=$(< /run/secrets/n8n_db_user)
export DB_POSTGRESDB_PASSWORD=$(< /run/secrets/n8n_db_password)
export DB_POSTGRESDB_DATABASE=$(< /run/secrets/n8n_db_name)

set -euo pipefail

if [[ "${RESET_CREDENTIALS:-false}" == "true" ]]; then
  echo "🔁 Resetting n8n user management..."
  n8n user-management:reset
fi

# continue normal start
exec n8n
