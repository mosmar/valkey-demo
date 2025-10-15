#!/usr/bin/env bash
set -euo pipefail

VALKEY_PORT=${VALKEY_PORT:-6380}
REDIS_PORT=${REDIS_PORT:-6379}
NUM_REQUESTS=${NUM_REQUESTS:-100000}
CONCURRENCY=${CONCURRENCY:-50}

cleanup() {
  docker rm -f valkey redis >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Start containers
docker rm -f valkey redis >/dev/null 2>&1 || true
docker run -d --name valkey -p ${VALKEY_PORT}:6379 valkey/valkey >/dev/null
sleep 2
docker run -d --name redis -p ${REDIS_PORT}:6379 redis >/dev/null
sleep 2

# Run Valkey benchmark
echo "Running Valkey benchmark..."
VALKEY_OUTPUT=$(docker run --rm valkey/valkey valkey-benchmark -h host.docker.internal -p ${VALKEY_PORT} -n ${NUM_REQUESTS} -c ${CONCURRENCY})
VALKEY_RPS=$(echo "$VALKEY_OUTPUT" | grep -Eo "[0-9]+(\.[0-9]+)? requests per second" | tail -n1 | grep -Eo "[0-9]+(\.[0-9]+)?" || true)

# Run Redis benchmark
echo "Running Redis benchmark..."
REDIS_OUTPUT=$(docker run --rm redis redis-benchmark -h host.docker.internal -p ${REDIS_PORT} -n ${NUM_REQUESTS} -c ${CONCURRENCY})
REDIS_RPS=$(echo "$REDIS_OUTPUT" | grep -Eo "[0-9]+(\.[0-9]+)? requests per second" | head -n1 | grep -Eo "[0-9]+(\.[0-9]+)?" || true)

# Print results
printf "%-10s | %-20s\n" "Database" "Requests per second"
printf "%-10s | %-20s\n" "Valkey" "${VALKEY_RPS:-N/A}"
printf "%-10s | %-20s\n" "Redis"  "${REDIS_RPS:-N/A}"

# cleanup runs via trap
