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
sleep 3
docker run -d --name redis -p ${REDIS_PORT}:6379 redis >/dev/null
sleep 3

extract_rps() {
    if [ "$2" == "first" ]; then
        echo "$1" | grep -Eo "[0-9]+(\.[0-9]+)? requests per second" | head -n1 | grep -Eo "[0-9]+(\.[0-9]+)?" || true
    else
        echo "$1" | grep -Eo "[0-9]+(\.[0-9]+)? requests per second" | tail -n1 | grep -Eo "[0-9]+(\.[0-9]+)?" || true
    fi
}

# Valkey
echo "Running Valkey SET benchmark..."
VALKEY_SET_OUTPUT=$(docker run --rm valkey/valkey valkey-benchmark -h host.docker.internal -p ${VALKEY_PORT} -n ${NUM_REQUESTS} -c ${CONCURRENCY} -t set)
VALKEY_SET_RPS=$(extract_rps "$VALKEY_SET_OUTPUT" last)

echo "Running Valkey GET benchmark..."
VALKEY_GET_OUTPUT=$(docker run --rm valkey/valkey valkey-benchmark -h host.docker.internal -p ${VALKEY_PORT} -n ${NUM_REQUESTS} -c ${CONCURRENCY} -t get)
VALKEY_GET_RPS=$(extract_rps "$VALKEY_GET_OUTPUT" last)

echo "Running Valkey INCR benchmark..."
VALKEY_INCR_OUTPUT=$(docker run --rm valkey/valkey valkey-benchmark -h host.docker.internal -p ${VALKEY_PORT} -n ${NUM_REQUESTS} -c ${CONCURRENCY} -t incr)
VALKEY_INCR_RPS=$(extract_rps "$VALKEY_INCR_OUTPUT" last)

# Redis
echo "Running Redis SET benchmark..."
REDIS_SET_OUTPUT=$(docker run --rm redis redis-benchmark -h host.docker.internal -p ${REDIS_PORT} -n ${NUM_REQUESTS} -c ${CONCURRENCY} -t set)
REDIS_SET_RPS=$(extract_rps "$REDIS_SET_OUTPUT" first)

echo "Running Redis GET benchmark..."
REDIS_GET_OUTPUT=$(docker run --rm redis redis-benchmark -h host.docker.internal -p ${REDIS_PORT} -n ${NUM_REQUESTS} -c ${CONCURRENCY} -t get)
REDIS_GET_RPS=$(extract_rps "$REDIS_GET_OUTPUT" first)

echo "Running Redis INCR benchmark..."
REDIS_INCR_OUTPUT=$(docker run --rm redis redis-benchmark -h host.docker.internal -p ${REDIS_PORT} -n ${NUM_REQUESTS} -c ${CONCURRENCY} -t incr)
REDIS_INCR_RPS=$(extract_rps "$REDIS_INCR_OUTPUT" first)

# Print comparison
printf "%-10s | %-10s | %-10s | %-10s\n" "Database" "SET" "GET" "INCR"
echo "-----------------------------------------------"
printf "%-10s | %-10s | %-10s | %-10s\n" "Valkey" "${VALKEY_SET_RPS:-N/A}" "${VALKEY_GET_RPS:-N/A}" "${VALKEY_INCR_RPS:-N/A}"
printf "%-10s | %-10s | %-10s | %-10s\n" "Redis"  "${REDIS_SET_RPS:-N/A}" "${REDIS_GET_RPS:-N/A}" "${REDIS_INCR_RPS:-N/A}"
