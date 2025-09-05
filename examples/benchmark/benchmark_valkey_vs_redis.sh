#!/bin/bash

VALKEY_PORT=6380
REDIS_PORT=6379
NUM_REQUESTS=500000
CONCURRENCY=200

# Cleanup old containers
docker rm -f valkey redis >/dev/null 2>&1

# Start Valkey
echo "Starting Valkey container..."
docker run -d --name valkey -p ${VALKEY_PORT}:6379 valkey/valkey >/dev/null
sleep 3

# Start Redis
echo "Starting Redis container..."
docker run -d --name redis -p ${REDIS_PORT}:6379 redis >/dev/null
sleep 3

# Run Valkey benchmark
echo "Running Valkey benchmark..."
VALKEY_OUTPUT=$(docker run --rm valkey/valkey valkey-benchmark -h host.docker.internal -p ${VALKEY_PORT} -n ${NUM_REQUESTS} -c ${CONCURRENCY})
VALKEY_RPS=$(echo "$VALKEY_OUTPUT" | grep -Eo "[0-9]+(\.[0-9]+)? requests per second" | tail -n1 | grep -Eo "[0-9]+(\.[0-9]+)?")

# Run Redis benchmark
echo "Running Redis benchmark..."
REDIS_OUTPUT=$(docker run --rm redis redis-benchmark -h host.docker.internal -p ${REDIS_PORT} -n ${NUM_REQUESTS} -c ${CONCURRENCY})
REDIS_RPS=$(echo "$REDIS_OUTPUT" | grep -Eo "[0-9]+(\.[0-9]+)? requests per second" | head -n1 | grep -Eo "[0-9]+(\.[0-9]+)?")

# Print results
echo
echo "==== Benchmark Results ===="
printf "%-10s | %-20s\n" "Database" "Requests per second"
echo "-------------------------------"
printf "%-10s | %-20s\n" "Valkey" "$VALKEY_RPS"
printf "%-10s | %-20s\n" "Redis"  "$REDIS_RPS"
echo "=============================="

# Cleanup containers
docker rm -f valkey redis >/dev/null 2>&1
