#!/usr/bin/env bash
set -euo pipefail

# Installation and quick-run snippets for Valkey and Redis (macOS-focused examples)
# Usage: run this file line-by-line or copy the sections you need.

# --- Option 1: install valkey locally via Homebrew (macOS) ---
# brew install valkey

# --- Option 2: install Docker (recommended for reproducible demos) ---
# brew install --cask docker
# Start Docker Desktop and ensure the daemon is running before continuing.

# Default exposed port on the host for Valkey
VALKEY_PORT=${VALKEY_PORT:-6380}
REDIS_PORT=${REDIS_PORT:-6379}

show_help() {
	cat <<EOF
Usage: ${0##*/} [start|stop|status]

Commands:
	start   Start Valkey and Redis containers (used for demos)
	stop    Stop and remove demo containers
	status  Show running demo containers

Environment variables:
	VALKEY_PORT  Host port to bind Valkey (default: ${VALKEY_PORT})
	REDIS_PORT   Host port to bind Redis  (default: ${REDIS_PORT})

EOF
}

case ${1:-start} in
	start)
		echo "Starting Valkey in Docker (host port ${VALKEY_PORT} -> container 6379)..."
		docker run -d --name valkey-server -p ${VALKEY_PORT}:6379 valkey/valkey >/dev/null
		echo "You can connect with: docker exec -it valkey-server valkey-cli"

		echo "Starting Redis in Docker (host port ${REDIS_PORT} -> container 6379)..."
		docker run -d --name redis-server -p ${REDIS_PORT}:6379 redis >/dev/null
		echo "You can connect with: docker exec -it redis-server redis-cli"
		;;

	stop)
		echo "Stopping and removing containers..."
		docker rm -f valkey-server redis-server >/dev/null 2>&1 || true
		echo "Done."
		;;

	status)
		docker ps --filter "name=valkey-server" --filter "name=redis-server"
		;;

	-h|--help)
		show_help
		;;

	*)
		echo "Unknown command: ${1:-}
"
		show_help
		exit 2
		;;
esac
