# SPDX-License-Identifier: MIT
FROM node:18-slim

# Install psql and other dependencies
RUN apt-get update && \
    apt-get install -y postgresql-client curl gnupg && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install n8n globally
RUN npm install -g n8n

# Set a safe working directory
WORKDIR /home/node

# Copy our two scripts into the image
COPY container_run.sh        /container_run.sh

# Make sure they are executable
RUN chmod +x /container_run.sh

# Use container_run.sh as the entrypoint
ENTRYPOINT ["/container_run.sh"]
