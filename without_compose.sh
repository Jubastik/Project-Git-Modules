#!/bin/sh

# Пример того как можно сделать без Docker Compose

set -e

buildFrontend() {
  DOCKER_BUILDKIT=1 docker build frontend -t frontend
}

buildBackend() {
  export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.23.0.9-1.fc40.x86_64
  ./backend/gradlew clean build -p backend
  DOCKER_BUILDKIT=1 docker build backend -t backend
}

createNetworks() {
  docker network create backend
  docker network create frontend
}

createVolume() {
  docker volume create postgres
}

runPostgres() {
  docker run -d \
        -p 5432:5432 \
        --name postgres \
        --network backend \
        -e POSTGRES_USER=program \
        -e POSTGRES_PASSWORD=test \
        -e POSTGRES_DB=todo_list \
        -v postgres:/var/lib/postgresql/data \
        postgres:13
}

runBackend() {
  sleep 10
  docker run -d \
        --name backend-service \
        --network backend \
        --network frontend \
        -p 8080:8080 \
        -e SPRING_PROFILES_ACTIVE=docker \
        backend
}

runFrontend() {
  docker run -d \
        --name frontend \
        --network frontend \
        -p 3000:80 \
        frontend
}

checkResult() {
  sleep 10
  http_response=$(
    docker exec \
      frontend \
      curl -s -o response.txt -w "%{http_code}" http://backend:8080/backend/api/v1/public/items
  )

  if [ "$http_response" != "200" ]; then
    echo "Check failed"
    exit 1
  fi
}

echo "=== Build backend ==="
buildBackend

echo "=== Build frontend ==="
buildFrontend

echo "=== Create networks between backend <-> postgres and backend <-> frontend ==="
createNetworks

echo "=== Create persistence volume for postgres ==="
createVolume

echo "== Run Postgres ==="
runPostgres

echo "=== Run backend ==="
runBackend

echo "=== Run frontend==="
runFrontend

echo "=== Run check ==="
checkResult
