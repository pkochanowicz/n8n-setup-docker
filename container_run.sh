#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -e

echo "🛠️ [container_run.sh] Exporting secrets to env vars..."

# Loop through all *_FILE variables
for file_var in \
  N8N_BASIC_AUTH_USER \
  N8N_BASIC_AUTH_PASSWORD \
  N8N_ENCRYPTION_KEY \
  DB_POSTGRESDB_HOST \
  DB_POSTGRESDB_PORT \
  DB_POSTGRESDB_DATABASE \
  DB_POSTGRESDB_SCHEMA \
  DB_POSTGRESDB_USER \
  DB_POSTGRESDB_PASSWORD
do
  file_path_var="${file_var}_FILE"
  val="$(< "${!file_path_var}")"
  export "$file_var"="$val"
done

# Setup encryptionKey config
if [ ! -f /root/.n8n/config ]; then
  echo "🔐 Creating /root/.n8n/config..."
  mkdir -p /root/.n8n
  echo "{\"encryptionKey\": \"$N8N_ENCRYPTION_KEY\"}" > /root/.n8n/config
else
  echo "🛡️ Using existing encryptionKey in /root/.n8n/config"
fi


# 3. Test Postgres connection
echo "🔎 [container_run.sh] Verifying connection to PostgreSQL…"

export PGPASSWORD="${DB_POSTGRESDB_PASSWORD:?DB password not set}"

if psql -h "$DB_POSTGRESDB_HOST" -p "$DB_POSTGRESDB_PORT" -U "$DB_POSTGRESDB_USER" -d "$DB_POSTGRESDB_DATABASE" -c '\conninfo' >/tmp/dbinfo.txt 2>/dev/null; then
  echo "✅ PostgreSQL reachable! Connection info:"
  cat /tmp/dbinfo.txt
else
  echo "❌ [container_run.sh] PostgreSQL connection failed!"
  echo "   Host: $DB_POSTGRESDB_HOST"
  echo "   Port: $DB_POSTGRESDB_PORT"
  echo "   User: $DB_POSTGRESDB_USER"
  echo "   DB:   $DB_POSTGRESDB_DATABASE"
  exit 1
fi

# 6. Run n8n
echo "✅ All checks passed — launching n8n 🧠"
exec n8n