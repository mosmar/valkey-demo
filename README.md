
# valkey-demo

Small, hands-on examples for demonstrating Valkey (a Redis-compatible key-value store).

This repository contains quick CLI examples, install/run snippets, pub/sub demos, benchmark scripts, and a tiny Node.js demo.

Table of contents

- What you'll find
- Quickstart (docker-compose)
- Quick CLI demos
- Node demo
- Benchmarks
- Troubleshooting
- Next steps

## What you'll find

- `crud.md` — CRUD cheat-sheet for Valkey data types (strings, hashes, lists, sets, etc.).
- `examples/basic-operations/` — quick CLI commands demonstrating SET/GET, lists, hashes, and more.
- `examples/installation/` — helper script to start/stop demo containers.
- `examples/pub-sub/` — publish/subscribe helper scripts.
- `examples/benchmark/` — benchmark wrappers comparing Valkey and Redis.
- `examples/node-demo/` — a minimal Node.js demo using `ioredis` (SET/GET + pub/sub).
- `docker-compose.yml` — compose file to start Valkey + Redis for demos.

## Quickstart (docker-compose) — recommended

Bring up Valkey and Redis for local demos:

```bash
docker-compose up -d
```

# valkey-demo

Small, hands-on examples for demonstrating Valkey (a Redis-compatible key-value store).

This repo contains executable examples, helper scripts, benchmark wrappers, and a tiny Node.js demo.

Contents

- `crud.md` — CRUD cheat-sheet for Valkey data types.
- `examples/basic-operations/` — quick CLI commands demonstrating SET/GET, lists, hashes, and more.
- `examples/installation/installation.sh` — start/stop/status script for demo containers.
- `examples/pub-sub/` — executable `pub.sh` and `sub.sh` for publish/subscribe demos.
- `examples/benchmark/` — benchmark scripts (`benchmark.sh`, `benchmark_valkey_vs_redis.sh`, `benchmark_full_feature_valkey_vs_redis.sh`).
- `examples/node-demo/` — minimal Node.js demo using `ioredis`.
- `docker-compose.yml` — bring up Valkey + Redis for demos.
- `.gitignore` — excludes node_modules, Docker artifacts, editor files, etc.

Quick setup (recommended)

1. Start demo services with Docker Compose:

```bash
docker-compose up -d
```

2. Verify services:

```bash
docker ps --filter "name=valkey" --filter "name=redis"
```

3. Tear down when done:

```bash
docker-compose down
```

Installation helper

Use the installation helper to start/stop demo containers (script defaults to `start`):

```bash
./examples/installation/installation.sh start
./examples/installation/installation.sh status
./examples/installation/installation.sh stop
```

CLI examples

Make the example scripts executable and run the basic commands:

```bash
chmod +x ./examples/*/*.sh
./examples/basic-operations/commands.sh
```

Pub/sub demo (two terminals):

Terminal A (subscriber):

```bash
./examples/pub-sub/sub.sh demo-channel
```

Terminal B (publisher):

```bash
./examples/pub-sub/pub.sh demo-channel "hello from terminal B"
```

Benchmarks

- `examples/benchmark/benchmark.sh` — lightweight, configurable runner (env vars: `VALKEY_PORT`, `REDIS_PORT`, `NUM_REQUESTS`, `CONCURRENCY`).
- `examples/benchmark/benchmark_valkey_vs_redis.sh` — detailed comparison script with SET/GET/INCR tests.
- `examples/benchmark/benchmark_full_feature_valkey_vs_redis.sh` — older/full-feature example with hard-coded defaults.

Quick smoke test (fast):

```bash
VALKEY_PORT=6380 REDIS_PORT=6379 NUM_REQUESTS=1000 CONCURRENCY=10 ./examples/benchmark/benchmark.sh
```

Node demo

```bash
cd examples/node-demo
npm install
npm start
```

The Node demo accepts `VALKEY_HOST` and `VALKEY_PORT` environment variables. The demo includes a short retry/backoff to handle waiting for Valkey to be ready.

Notes & troubleshooting

- Ensure Docker daemon is running before using `docker-compose` or the benchmark scripts.
- `host.docker.internal` works on Docker Desktop (macOS/Windows). On Linux replace with the host IP or use `--network host` when appropriate.
- If containers fail to start due to port conflicts, change the ports in `docker-compose.yml` or pass environment variables to the scripts.
- If you accidentally committed generated files, `.gitignore` now excludes `node_modules/`, logs, Docker artifacts, and common editor files.

Want improvements?

- Add `shellcheck` in CI and a smoke-test workflow for the Node demo
- Record raw benchmark output to timestamped files for reproducibility
- Add a small Express app demo using Valkey as a session store

---

See `crud.md` and the `examples/` folder for runnable demos and details.
