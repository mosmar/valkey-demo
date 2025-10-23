#!/usr/bin/env bash
set -euo pipefail

# Repeat-capable benchmark runner for Valkey vs Redis
# Runs each configuration multiple times (REPEATS) and computes mean and stddev per op.
# Outputs two CSVs:
#  - valkey_vs_redis_raw.csv: one row per individual benchmark run
#  - valkey_vs_redis_summary.csv: one row per configuration with mean/stddev for each op/db
#
# Usage:
#   REPEATS=3 RUNS=5 BASE_NUM_REQUESTS=100000 BASE_CONCURRENCY=50 ./benchmark_valkey_vs_redis_repeats.sh

VALKEY_PORT=${VALKEY_PORT:-6380}
REDIS_PORT=${REDIS_PORT:-6379}
BASE_NUM_REQUESTS=${BASE_NUM_REQUESTS:-100000}
BASE_CONCURRENCY=${BASE_CONCURRENCY:-50}
RUNS=${RUNS:-5}
REPEATS=${REPEATS:-3}

DIR="$(cd "$(dirname "$0")" && pwd)"
RAW_CSV=${RAW_CSV:-"$DIR/valkey_vs_redis_raw.csv"}
SUMMARY_CSV=${SUMMARY_CSV:-"$DIR/valkey_vs_redis_summary.csv"}

cleanup() {
  docker rm -f valkey redis >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Results (raw): $RAW_CSV"
echo "Results (summary): $SUMMARY_CSV"

mkdir -p "$(dirname "$RAW_CSV")"

# Headers
if [ ! -f "$RAW_CSV" ]; then
  echo "run,repeat,concurrency,num_requests,db,op,rps" > "$RAW_CSV"
fi
if [ ! -f "$SUMMARY_CSV" ]; then
  echo "run,concurrency,num_requests,valkey_set_mean,valkey_set_std,valkey_get_mean,valkey_get_std,valkey_incr_mean,valkey_incr_std,redis_set_mean,redis_set_std,redis_get_mean,redis_get_std,redis_incr_mean,redis_incr_std" > "$SUMMARY_CSV"
fi

# Start both containers (simultaneous mode)
docker rm -f valkey redis >/dev/null 2>&1 || true
echo "Starting Valkey (port ${VALKEY_PORT})..."
docker run -d --name valkey -p ${VALKEY_PORT}:6379 valkey/valkey >/dev/null
sleep 2

echo "Starting Redis (port ${REDIS_PORT})..."
docker run -d --name redis -p ${REDIS_PORT}:6379 redis >/dev/null
sleep 2

extract_rps() {
  # $1 = output, $2 = first|last
  if [ "$2" = "first" ]; then
    echo "$1" | grep -Eo "[0-9]+(\.[0-9]+)? requests per second" | head -n1 | grep -Eo "[0-9]+(\.[0-9]+)?" || true
  else
    echo "$1" | grep -Eo "[0-9]+(\.[0-9]+)? requests per second" | tail -n1 | grep -Eo "[0-9]+(\.[0-9]+)?" || true
  fi
}

run_num=0
while [ $run_num -lt "$RUNS" ]; do
  factor=$((2 ** run_num))
  NUM_REQUESTS_RUN=$((BASE_NUM_REQUESTS * factor))
  CONCURRENCY_RUN=$((BASE_CONCURRENCY * factor))

  echo "\n=== Run $((run_num+1))/$RUNS: concurrency=$CONCURRENCY_RUN, requests=$NUM_REQUESTS_RUN ==="

  repeat_idx=0
  while [ $repeat_idx -lt "$REPEATS" ]; do
    echo "  Repeat $((repeat_idx+1))/$REPEATS"

    # Valkey SET
    set +e
    OUT=$(docker run --rm valkey/valkey valkey-benchmark -h host.docker.internal -p ${VALKEY_PORT} -n ${NUM_REQUESTS_RUN} -c ${CONCURRENCY_RUN} -t set 2>&1)
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
      RPS="N/A"
      echo "    Valkey SET failed (rc=$rc)"
    else
      RPS=$(extract_rps "$OUT" last)
    fi
    echo "$((run_num+1)),$((repeat_idx+1)),$CONCURRENCY_RUN,$NUM_REQUESTS_RUN,valkey,set,${RPS:-N/A}" >> "$RAW_CSV"

    # Valkey GET
    set +e
    OUT=$(docker run --rm valkey/valkey valkey-benchmark -h host.docker.internal -p ${VALKEY_PORT} -n ${NUM_REQUESTS_RUN} -c ${CONCURRENCY_RUN} -t get 2>&1)
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
      RPS="N/A"
      echo "    Valkey GET failed (rc=$rc)"
    else
      RPS=$(extract_rps "$OUT" last)
    fi
    echo "$((run_num+1)),$((repeat_idx+1)),$CONCURRENCY_RUN,$NUM_REQUESTS_RUN,valkey,get,${RPS:-N/A}" >> "$RAW_CSV"

    # Valkey INCR
    set +e
    OUT=$(docker run --rm valkey/valkey valkey-benchmark -h host.docker.internal -p ${VALKEY_PORT} -n ${NUM_REQUESTS_RUN} -c ${CONCURRENCY_RUN} -t incr 2>&1)
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
      RPS="N/A"
      echo "    Valkey INCR failed (rc=$rc)"
    else
      RPS=$(extract_rps "$OUT" last)
    fi
    echo "$((run_num+1)),$((repeat_idx+1)),$CONCURRENCY_RUN,$NUM_REQUESTS_RUN,valkey,incr,${RPS:-N/A}" >> "$RAW_CSV"

    # Redis SET
    set +e
    OUT=$(docker run --rm redis redis-benchmark -h host.docker.internal -p ${REDIS_PORT} -n ${NUM_REQUESTS_RUN} -c ${CONCURRENCY_RUN} -t set 2>&1)
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
      RPS="N/A"
      echo "    Redis SET failed (rc=$rc)"
    else
      RPS=$(extract_rps "$OUT" first)
    fi
    echo "$((run_num+1)),$((repeat_idx+1)),$CONCURRENCY_RUN,$NUM_REQUESTS_RUN,redis,set,${RPS:-N/A}" >> "$RAW_CSV"

    # Redis GET
    set +e
    OUT=$(docker run --rm redis redis-benchmark -h host.docker.internal -p ${REDIS_PORT} -n ${NUM_REQUESTS_RUN} -c ${CONCURRENCY_RUN} -t get 2>&1)
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
      RPS="N/A"
      echo "    Redis GET failed (rc=$rc)"
    else
      RPS=$(extract_rps "$OUT" first)
    fi
    echo "$((run_num+1)),$((repeat_idx+1)),$CONCURRENCY_RUN,$NUM_REQUESTS_RUN,redis,get,${RPS:-N/A}" >> "$RAW_CSV"

    # Redis INCR
    set +e
    OUT=$(docker run --rm redis redis-benchmark -h host.docker.internal -p ${REDIS_PORT} -n ${NUM_REQUESTS_RUN} -c ${CONCURRENCY_RUN} -t incr 2>&1)
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
      RPS="N/A"
      echo "    Redis INCR failed (rc=$rc)"
    else
      RPS=$(extract_rps "$OUT" first)
    fi
    echo "$((run_num+1)),$((repeat_idx+1)),$CONCURRENCY_RUN,$NUM_REQUESTS_RUN,redis,incr,${RPS:-N/A}" >> "$RAW_CSV"

    repeat_idx=$((repeat_idx+1))
  done

  # Compute mean and stddev for this run across repeats and write summary line
  compute_stats() {
    local runid="$1"; local db="$2"; local op="$3"; local raw="$4"
    awk -F"," -v run="$runid" -v db="$db" -v op="$op" '
      function isnum(s){ return (s ~ /^[0-9]+(\.[0-9]+)?$/) }
      $1==run && $5==db && $6==op {
        if(isnum($7)){
          x=$7+0; sum+=x; sumsq+=x*x; n++
        }
      }
      END{
        if(n==0){ print "N/A,N/A"; exit }
        mean=sum/n; var=(sumsq/n)-(mean*mean); if(var<0) var=0; sd=sqrt(var);
        printf "%.2f,%.2f", mean, sd
      }
    ' "$raw"
  }

  v_set=$(compute_stats $((run_num+1)) valkey set "$RAW_CSV")
  v_get=$(compute_stats $((run_num+1)) valkey get "$RAW_CSV")
  v_incr=$(compute_stats $((run_num+1)) valkey incr "$RAW_CSV")
  r_set=$(compute_stats $((run_num+1)) redis set "$RAW_CSV")
  r_get=$(compute_stats $((run_num+1)) redis get "$RAW_CSV")
  r_incr=$(compute_stats $((run_num+1)) redis incr "$RAW_CSV")

  echo "$((run_num+1)),$CONCURRENCY_RUN,$NUM_REQUESTS_RUN,$v_set,$v_get,$v_incr,$r_set,$r_get,$r_incr" >> "$SUMMARY_CSV"

  run_num=$((run_num+1))
done

END_TS=$(date +%s)
ELAPSED=$((END_TS-START_TS)) || true
if [ -n "${ELAPSED:-}" ]; then
  hours=$((ELAPSED/3600))
  mins=$(((ELAPSED%3600)/60))
  secs=$((ELAPSED%60))
  printf "\nAll runs complete. Raw CSV: %s\n" "$RAW_CSV"
  printf "Summary CSV: %s\n" "$SUMMARY_CSV"
  printf "Total elapsed time: %02d:%02d:%02d (HH:MM:SS) — %d seconds\n" $hours $mins $secs $ELAPSED
fi
