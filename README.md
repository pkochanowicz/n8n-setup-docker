# README.md

# # n8n-setup-docker Swarm Deployment

A production-ready, Swarm-optimized setup for [n8n](https://n8n.io/), with:

- **Custom Docker image** (`my-n8n:latest`) that includes `psql` for health-checks  
- **Docker Swarm** stack deployment  
- **Docker secrets** for all sensitive credentials  
- A **startup script** (`docker_run.sh`) that loads secrets, sets environment vars, checks DB connectivity, and then launches n8n  

---

## 📁 Repository Layout

```text
.
├── Dockerfile
├── docker-compose.yaml
├── docker_run.sh
├── secret_update.sh      # (optional) recreates Docker secrets from ./secrets/*.txt
└── secrets/
    ├── n8n_basic_auth_user.txt
    ├── n8n_basic_auth_password.txt
    ├── n8n_encryption_key.txt
    ├── n8n_db_host.txt
    ├── n8n_db_schema.txt
    ├── n8n_db_port.txt
    ├── n8n_db_user.txt
    └── n8n_db_name.txt
```

- **`Dockerfile`**  
  Builds `my-n8n:latest` image on `node:18-slim`, installs `postgresql-client`, and copies your `docker_run.sh` entrypoint.

- **`docker-compose.yaml`**  
  Defines the `n8n` service for Docker Swarm: mounts secrets, publishes port 5678, constrains to manager nodes, and calls your script.

- **`docker_run.sh`**
  
  - Reads all required secrets from `/run/secrets/...` (inside Docker container)
  
  - Exports the corresponding `N8N_…` & `DB_POSTGRESDB_…` env vars
  
  - (Optional) Wait-for-it logic could be added here to retry the DB check
  
  - Finally `exec n8n` to hand over to the official n8n entrypoint

- **`secret_update.sh`** (optional)  
  A helper to recreate or rotate your Docker secrets from the files in `./secrets/`.

---

## 🔐 Managing Secrets

Place your plaintext credentials into the `.n8n/secrets/` folder:

```textile
# example
echo "admin"    > secrets/n8n_basic_auth_user.txt
echo "hunter2"  > secrets/n8n_basic_auth_password.txt
echo "myKeyBase" > secrets/n8n_encryption_key.txt

echo "db.example.com" > secrets/n8n_db_host.txt
echo "public"         > secrets/n8n_db_schema.txt
echo "5432"           > secrets/n8n_db_port.txt
echo "n8n_user"       > secrets/n8n_db_user.txt
echo "pa$$w0rd"       > secrets/n8n_db_password.txt
echo "n8n"            > secrets/n8n_db_name.txt
```

--- 

Setup:

## ⚙️ 1. Initialize Docker Swarm (If Not Already)

```bash
docker swarm init
```

If you already ran `swarm init` on this node before, you’re good.

---

## 🔐 2. Create Docker Secrets

Ensure all your secrets exist in `./secrets/` as `.txt` files.

Then:

```bash
chmod +x update_n8n_secrets.sh
./update_n8n_secrets.sh
```

This will:

✅ Scale down the service (if any)  
✅ Delete all old secrets (with `n8n_stack_n8n_*` names)  
✅ Create fresh secrets from your `secrets/*.txt`  
✅ Scale up service again

> No service exists yet? That’s fine — this script will just rotate secrets. When we deploy the stack next, it’ll work perfectly.

---

## 🛠️ 3. Build the Custom n8n Image

```bash
docker build -t my-n8n:latest .
```

This:

- Installs `psql`, `n8n`, and your `docker_run.sh` launcher

- Makes your secrets-friendly startup script executable

---

## 📦 4. Deploy the Stack

```bash
docker stack deploy -c docker-compose.yaml n8n_stack
```

🎉 This will:

- Deploy the `my-n8n:latest` image as a Swarm service

- Use `docker_run.sh` to inject secrets into the environment

- Mount your secrets securely via `docker secrets`

- Run `n8n` with the proper DB and auth config

---

## 🧪 5. Confirm It’s Running

```bash
docker service ls
```

Check that the `n8n_stack_n8n` service has `1/1` replicas.

Then:

```bash
docker ps
```

Find the container ID and logs:

```bash
docker logs <container-id>
```

Or simply:

```bash
docker service logs -f n8n_stack_n8n
```

---

## 🌐 6. Access n8n in Browser

Open: [http://localhost:5678](http://localhost:5678) (or your server’s IP)

Use credentials defined in:

```
secrets/n8n_basic_auth_user.txt

secrets/n8n_basic_auth_password.txt
```

Boom. You’re in. 🎛️

---

## 🔁 7. Rotate Secrets Later

Want to reset encryption key or user password later?

Just run:

```bash
./update_n8n_secrets.sh
```

---

## 🧼 Optional: Clean Up Everything

If you ever want to nuke the deployment:

```bash
./nuke_deployment.sh
```

---

## 📝 How It Works

1. **Swarm Secrets**: All credentials are injected as files in `/run/secrets/…`. (inside repository)

2. **`docker_run.sh`**:
   
   - Exports the secrets into the environment (`N8N_…` & `DB_POSTGRESDB_…`).
   
   - Performs an optional database readiness check.
   
   - On success, `exec n8n` hands control to the official n8n process.

3. **Port 5678** is published in Swarm (`"5678:5678"`).

4. **Redeployment**: To update env or code, rebuild the image, rotate secrets (`secret_update.sh`), then run `docker stack deploy` … again.

---

## ⚙️ Tips & Troubleshooting

- **DB Connectivity Failures**  
  If the container logs show it can’t reach the DB, exec into the container and test:
  
  ```bash
  docker exec -it $(docker ps -qf "name=n8n_stack_n8n") /bin/sh
  # inside:
  psql -h "$(cat /run/secrets/n8n_db_host)" \
       -p "$(cat /run/secrets/n8n_db_port)" \
       -U "$(cat /run/secrets/n8n_db_user)" \
       -d "$(cat /run/secrets/n8n_db_name)" -c '\q'--- 
  ```

- **Updating Secrets**  
  Secrets are immutable. Always remove and recreate them via `secret_update.sh` before stack redeploy.

- **Scaling**  
  To run multiple replicas, adjust `deploy.replicas` in `docker-compose.yaml`. Remember each replica will share the same secrets and volume.

- **Swarm Constraints**  
  We’ve locked `n8n` to manager nodes by default—remove `placement` if you want worker nodes to run it as well.

---

## 🛡️ Security Considerations

- Keep `./secrets/` out of Git (`.gitignore`).

- Use a secure vault or CI/CD secrets store in production.

- Rotate your `n8n_encryption_key` and database credentials regularly.

---

## ##BONUS##

#### 🚀 Docker Swarm & Container Management **Cheat Sheet:**

### # 1 - Initialize Docker Swarm

```bash
docker swarm init
```

*Optional: specify advertise address (useful for multi-node setups):*

```bash
docker swarm init --advertise-addr
```

### # 2 - Deploy docker-compose.yaml to Docker Swarm

```bash
docker stack deploy -c docker-compose.yaml n8n_stack
```

Replace n8n_stack with your desired stack name.

### #3 - Build image from Dockerfile:

```bash
docker build -t my-n8n:latest .
```

### # 4 - Stop a Single Docker Container

```bash
docker stop <container_name_or_id>
```

### # 5 - Stop All Running Docker Containers

```bash
docker stop $(docker ps -q)
```

*Optionally remove all stopped containers:*

```bash
docker rm $(docker ps -a -q)
```

### # 6 - Leave and Stop Docker Swarm

```bash
docker swarm leave --force
```

### # 7 - View Logs for a Specific Container

```bash
docker logs <container_name_or_id>
```

To follow logs in real-time:

```bash
docker logs -f
```

### # 8 - View Logs from All Containers in a Stack (Swarm):

```bash
docker service logs <stack_name>_<service_name>
```

*Example:*

```bash
docker service logs n8n_stack_n8n
```

To follow logs in real-time:

```bash
docker service logs -f n8n_stack_n8n
```

To list services in the stack (if you're unsure of the service name):

```bash
docker service ls
```

### # 9 - Find Container ID or Name

```bash
docker ps
```

### # 10 - Inspect Swarm Nodes, Services, or Networks

```bash
docker node ls
docker service ls
docker network ls
```

### # 11 - Inspect a Container or Service in Detail

```bash
docker inspect <container_name_or_id>
docker service inspect <service_name>
```

### # 12 - Make sure your secrets are in place:

```bash
./secret_update.sh
```

### # 13 - Deploy

```bash
docker stack deploy -c docker-compose.yaml n8n_stack
```

---

© 2025 Paweł Kochanowicz · [GitHub](https://github.com/pkochanowicz)

This project is licensed under the [MIT License](LICENSE).

The containerized software is n8n - a simple and powerful node based automation tool  · [n8n-io/n8n](https://github.com/n8n-io/n8n)
