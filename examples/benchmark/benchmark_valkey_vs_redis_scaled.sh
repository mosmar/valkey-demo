#!/usr/bin/env bash
set -euo pipefail

# Scaled benchmark runner for Valkey vs Redis
# Runs multiple scaled runs (default 6). Each run doubles concurrency and number of requests
# from the base values (1x, 2x, 4x, 8x...).
# Outputs a CSV with per-run RPS for SET/GET/INCR for both Valkey and Redis.
#
# Usage:
#   BASE_NUM_REQUESTS=50000 BASE_CONCURRENCY=20 RUNS=5 ./benchmark_valkey_vs_redis_scaled.sh
#
# Environment variables (defaults):
#   VALKEY_PORT (6380)
#   REDIS_PORT  (6379)
#   BASE_NUM_REQUESTS (100000)
#   BASE_CONCURRENCY  (50)
#   RUNS (6)
#   RESULTS_FILE (defaults to same folder: valkey_vs_redis_results.csv)

VALKEY_PORT=${VALKEY_PORT:-6380}
REDIS_PORT=${REDIS_PORT:-6379}
BASE_NUM_REQUESTS=${BASE_NUM_REQUESTS:-100000}
BASE_CONCURRENCY=${BASE_CONCURRENCY:-50}
RUNS=${RUNS:-6}

DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_FILE=${RESULTS_FILE:-"$DIR/valkey_vs_redis_results.csv"}

cleanup() {
  docker rm -f valkey redis >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Ensure no stale containers, then start both services so they run simultaneously
docker rm -f valkey redis >/dev/null 2>&1 || true
echo "Starting Valkey (port ${VALKEY_PORT})..."
docker run -d --name valkey -p ${VALKEY_PORT}:6379 valkey/valkey >/dev/null
sleep 3
echo "Starting Redis (port ${REDIS_PORT})..."
docker run -d --name redis -p ${REDIS_PORT}:6379 redis >/dev/null
sleep 3

extract_rps() {
    # $1 = command output
    # $2 = "first" or "last"
    if [ "$2" = "first" ]; then
        echo "$1" | grep -Eo "[0-9]+(\.[0-9]+)? requests per second" | head -n1 | grep -Eo "[0-9]+(\.[0-9]+)?" || true
    else
        echo "$1" | grep -Eo "[0-9]+(\.[0-9]+)? requests per second" | tail -n1 | grep -Eo "[0-9]+(\.[0-9]+)?" || true
    fi
}

echo "Results will be written to: $RESULTS_FILE"
mkdir -p "$(dirname "$RESULTS_FILE")"
if [ ! -f "$RESULTS_FILE" ]; then
    echo "run,concurrency,num_requests,valkey_set,valkey_get,valkey_incr,redis_set,redis_get,redis_incr" > "$RESULTS_FILE"
fi

run_num=0
# Record start time for the whole benchmark (seconds since epoch)
START_TS=$(date +%s)
while [ $run_num -lt "$RUNS" ]; do
    factor=$((2 ** run_num))
    NUM_REQUESTS_RUN=$((BASE_NUM_REQUESTS * factor))
    CONCURRENCY_RUN=$((BASE_CONCURRENCY * factor))

    echo "\n=== Run $((run_num+1))/$RUNS: concurrency=$CONCURRENCY_RUN, requests=$NUM_REQUESTS_RUN ==="

    # Valkey SET
    echo "Running Valkey SET..."
    set +e
    VALKEY_SET_OUTPUT=$(docker run --rm valkey/valkey valkey-benchmark -h host.docker.internal -p ${VALKEY_PORT} -n ${NUM_REQUESTS_RUN} -c ${CONCURRENCY_RUN} -t set 2>&1)
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
        echo "Valkey SET failed (rc=$rc)."
        VALKEY_SET_RPS="N/A"
    else
        VALKEY_SET_RPS=$(extract_rps "$VALKEY_SET_OUTPUT" last)
    fi

    # Valkey GET
    echo "Running Valkey GET..."
    set +e
    VALKEY_GET_OUTPUT=$(docker run --rm valkey/valkey valkey-benchmark -h host.docker.internal -p ${VALKEY_PORT} -n ${NUM_REQUESTS_RUN} -c ${CONCURRENCY_RUN} -t get 2>&1)
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
        echo "Valkey GET failed (rc=$rc)."
        VALKEY_GET_RPS="N/A"
    else
        VALKEY_GET_RPS=$(extract_rps "$VALKEY_GET_OUTPUT" last)
    fi

    # Valkey INCR
    echo "Running Valkey INCR..."
    set +e
    VALKEY_INCR_OUTPUT=$(docker run --rm valkey/valkey valkey-benchmark -h host.docker.internal -p ${VALKEY_PORT} -n ${NUM_REQUESTS_RUN} -c ${CONCURRENCY_RUN} -t incr 2>&1)
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
        echo "Valkey INCR failed (rc=$rc)."
        VALKEY_INCR_RPS="N/A"
    else
        VALKEY_INCR_RPS=$(extract_rps "$VALKEY_INCR_OUTPUT" last)
    fi

    # Redis SET
    echo "Running Redis SET..."
    set +e
    REDIS_SET_OUTPUT=$(docker run --rm redis redis-benchmark -h host.docker.internal -p ${REDIS_PORT} -n ${NUM_REQUESTS_RUN} -c ${CONCURRENCY_RUN} -t set 2>&1)
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
        echo "Redis SET failed (rc=$rc)."
        REDIS_SET_RPS="N/A"
    else
        REDIS_SET_RPS=$(extract_rps "$REDIS_SET_OUTPUT" first)
    fi

    # Redis GET
    echo "Running Redis GET..."
    set +e
    REDIS_GET_OUTPUT=$(docker run --rm redis redis-benchmark -h host.docker.internal -p ${REDIS_PORT} -n ${NUM_REQUESTS_RUN} -c ${CONCURRENCY_RUN} -t get 2>&1)
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
        echo "Redis GET failed (rc=$rc)."
        REDIS_GET_RPS="N/A"
    else
        REDIS_GET_RPS=$(extract_rps "$REDIS_GET_OUTPUT" first)
    fi

    # Redis INCR
    echo "Running Redis INCR..."
    set +e
    REDIS_INCR_OUTPUT=$(docker run --rm redis redis-benchmark -h host.docker.internal -p ${REDIS_PORT} -n ${NUM_REQUESTS_RUN} -c ${CONCURRENCY_RUN} -t incr 2>&1)
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
        echo "Redis INCR failed (rc=$rc)."
        REDIS_INCR_RPS="N/A"
    else
        REDIS_INCR_RPS=$(extract_rps "$REDIS_INCR_OUTPUT" first)
    fi

    # (both DB containers are running continuously)

    # Append to CSV
    echo "$((run_num+1)),$CONCURRENCY_RUN,$NUM_REQUESTS_RUN,${VALKEY_SET_RPS:-N/A},${VALKEY_GET_RPS:-N/A},${VALKEY_INCR_RPS:-N/A},${REDIS_SET_RPS:-N/A},${REDIS_GET_RPS:-N/A},${REDIS_INCR_RPS:-N/A}" >> "$RESULTS_FILE"

    # Print quick comparison for this run
    printf "%-10s | %-10s | %-10s | %-10s\n" "Database" "SET" "GET" "INCR"
    echo "-----------------------------------------------"
    printf "%-10s | %-10s | %-10s | %-10s\n" "Valkey" "${VALKEY_SET_RPS:-N/A}" "${VALKEY_GET_RPS:-N/A}" "${VALKEY_INCR_RPS:-N/A}"
    printf "%-10s | %-10s | %-10s | %-10s\n" "Redis"  "${REDIS_SET_RPS:-N/A}" "${REDIS_GET_RPS:-N/A}" "${REDIS_INCR_RPS:-N/A}"

    run_num=$((run_num+1))
done

END_TS=$(date +%s)
ELAPSED=$((END_TS-START_TS))
# humanize elapsed seconds to H:M:S
hours=$((ELAPSED/3600))
mins=$(((ELAPSED%3600)/60))
secs=$((ELAPSED%60))
printf "\nAll runs complete. Results CSV: %s\n" "$RESULTS_FILE"
printf "Total elapsed time: %02d:%02d:%02d (HH:MM:SS) — %d seconds\n" $hours $mins $secs $ELAPSED
