docker stack rm n8n_stack
docker secret ls | awk '/n8n_stack_/ {print $1}' | xargs -r docker secret rm
docker image rm my-n8n:latest
