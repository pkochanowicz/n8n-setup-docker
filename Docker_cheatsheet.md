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

### # 2 - Build image from Dockerfile:

```bash
docker build -t my-n8n:latest .
```

### # 3 - Deploy docker-compose.yaml to Docker Swarm

```bash
docker stack deploy --with-registry-auth -c docker-compose.yaml n8n_stack
```

Replace n8n_stack with your desired stack name.

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

### # 8 - View Logs from All Containers in a Stack (Swarm)

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

### # 12 - Make sure your secrets are in place

```bash
./update_n8n_secrets.sh
```

### # 13 - Deploy

```bash
docker stack deploy --with-registry-auth -c docker-compose.yaml n8n_stack

```

### # 14 - Execute command inside Docker Container

```bash
docker exec -it <container_name_or_id> <command>
```

© 2025 Paweł Kochanowicz · [GitHub](https://github.com/pkochanowicz)

This project is licensed under the [MIT License](LICENSE).