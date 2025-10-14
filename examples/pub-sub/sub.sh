#!/usr/bin/env bash
set -euo pipefail

# Subscribe to a channel and print incoming messages
CHANNEL=${1:-my-channel}

echo "Subscribing to channel: ${CHANNEL} (press Ctrl+C to exit)"
valkey-cli subscribe "${CHANNEL}"