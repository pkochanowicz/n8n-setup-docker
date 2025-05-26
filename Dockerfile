# SPDX-License-Identifier: MIT
FROM node:18-slim

# Install psql and deps
RUN apt-get update && \
    apt-get install -y postgresql-client curl gnupg && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install n8n
RUN npm install -g n8n

# Set workdir
WORKDIR /home/node

# Copy the startup script
COPY docker_run.sh /docker_run.sh
RUN chmod +x /docker_run.sh

# Use script as entrypoint (Compose overrides CMD)
ENTRYPOINT ["/docker_run.sh"]
