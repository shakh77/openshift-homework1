#!/bin/sh

set -e

buildFrontend() {
  DOCKER_BUILDKIT=1 docker build -f frontend.Dockerfile frontend/ --tag frontend:v1.0-"$STUDENT_LABEL"
}

buildBackend() {
  ./backend/gradlew clean build -p backend -x test
  DOCKER_BUILDKIT=1 docker build -f backend.Dockerfile backend/ --tag backend:v1.0-"$STUDENT_LABEL"
}

createNetworks() {
  docker network create --driver bridge backend_frontend-"$STUDENT_LABEL" --label "$BASE_LABEL-$STUDENT_LABEL"
  docker network create --driver bridge postgres_network-"$STUDENT_LABEL" --label "$BASE_LABEL-$STUDENT_LABEL"
  echo "TODO create networks"
}

createVolume() {
  docker volume create postgres-data-"$STUDENT_LABEL" --label "$BASE_LABEL-$STUDENT_LABEL"
  echo "TODO create volume for postgres"
}

runPostgres() {
  docker run -d \
  --name postgres \
  -p 5432:5432 \
  --label "$BASE_LABEL-$STUDENT_LABEL" \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=postgres \
  --volume postgres-data-"$STUDENT_LABEL":/var/lib/postgresql/data \
  --volume "$PWD"/backend/postgres:/docker-entrypoint-initdb.d \
  --network postgres_network-"$STUDENT_LABEL" \
  postgres:13
  echo "TODO run postgres"
}

runBackend() {
sleep 10
  docker run -d \
  --name backend-"$STUDENT_LABEL" \
  --label "$BASE_LABEL-$STUDENT_LABEL" \
  -p 8080:8080 \
  -e "SPRING_PROFILES_ACTIVE=docker" \
  --network postgres_network-"$STUDENT_LABEL" \
  backend:v1.0-"$STUDENT_LABEL"
  docker network connect backend_frontend-"$STUDENT_LABEL" backend-"$STUDENT_LABEL"
  echo "TODO run backend"
}

runFrontend() {
  docker run -d \
  --name frontend-"$STUDENT_LABEL" \
  --label "$BASE_LABEL-$STUDENT_LABEL" \
  -p 3000:80 \
  --network backend_frontend-"$STUDENT_LABEL" \
  frontend:v1.0-"$STUDENT_LABEL"
  echo "RUN frontend"
}

checkResult() {
  sleep 10
  http_response=$(
    docker exec \
      frontend-"$STUDENT_LABEL" \
      curl -s -o response.txt -w "%{http_code}" http://backend-"$STUDENT_LABEL":8080/api/v1/public/items
  )

  if [ "$http_response" != "200" ]; then
    echo "Check failed"
    exit 1
  fi
}

BASE_LABEL=homework1
# TODO student surname name
STUDENT_LABEL=akramov

echo "=== Build backend backend:v1.0-$STUDENT_LABEL ==="
buildBackend

echo "=== Build frontend frontend:v1.0-$STUDENT_LABEL ==="
buildFrontend

echo "=== Create networks between backend <-> postgres and backend <-> frontend ==="
createNetworks

echo "=== Create persistence volume for postgres ==="
createVolume

echo "== Run Postgres ==="
runPostgres

echo "=== Run backend backend:v1.0-$STUDENT_LABEL ==="
runBackend

echo "=== Run frontend frontend:v1.0-$STUDENT_LABEL ==="
runFrontend

echo "=== Run check ==="
checkResult

