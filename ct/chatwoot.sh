#!/bin/bash

# Script to manage a Chatwoot container

# --- Configuration ---
CHATWOOT_CONTAINER_NAME="chatwoot"
POSTGRES_CONTAINER_NAME="chatwoot-postgres"
REDIS_CONTAINER_NAME="chatwoot-redis"
POSTGRES_PASSWORD="your_postgres_password"
REDIS_PASSWORD="your_redis_password"

# --- Helper Functions ---

function start_chatwoot() {
  echo "Starting Chatwoot..."
  docker compose up -d
  if [ $? -eq 0 ]; then
    echo "Chatwoot started successfully."
  else
    echo "Failed to start Chatwoot."
  fi
}

function stop_chatwoot() {
  echo "Stopping Chatwoot..."
  docker compose down
  if [ $? -eq 0 ]; then
    echo "Chatwoot stopped successfully."
  else
    echo "Failed to stop Chatwoot."
  fi
}

function restart_chatwoot() {
  echo "Restarting Chatwoot..."
  stop_chatwoot
  start_chatwoot
  if [ $? -eq 0 ]; then
        echo "Chatwoot restarted."
  fi
}

function help() {
  echo "Usage: ./chatwoot.sh [command]"
  echo "Commands:"
  echo "  start   - Start the Chatwoot container"
  echo "  stop    - Stop the Chatwoot container"
  echo "  restart - Restart the Chatwoot container"
  echo "  help    - Show this help message"
}

function create_docker_compose(){
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  postgres:
    container_name: ${POSTGRES_CONTAINER_NAME}
    image: postgres:14-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    container_name: ${REDIS_CONTAINER_NAME}
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis-data:/data

  chatwoot:
    container_name: ${CHATWOOT_CONTAINER_NAME}
    image: chatwoot/chatwoot:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
    environment:
      - DATABASE_URL=postgres://postgres:${POSTGRES_PASSWORD}@postgres:5432/postgres
      - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0
      - RAILS_ENV=production
    volumes:
      - chatwoot-data:/app/storage

volumes:
  postgres-data:
  redis-data:
  chatwoot-data:
EOF
echo "docker-compose file create successful"
}


# --- Main Script Logic ---

# Check if docker-compose.yml exists if not create it
if [ ! -f "docker-compose.yml" ]; then
    create_docker_compose
fi

if [ -z "$1" ]; then
  help
  exit 1
fi

case "$1" in
  start)
    start_chatwoot
    ;;
  stop)
    stop_chatwoot
    ;;
  restart)
    restart_chatwoot
    ;;
  help)
    help
    ;;
  *)
    echo "Invalid command: $1"
    help
    exit 1
    ;;
esac

exit 0