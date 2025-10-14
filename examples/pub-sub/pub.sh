#!/usr/bin/env bash
set -euo pipefail

# Publish example: run this in a terminal to publish messages to a channel
CHANNEL=${1:-my-channel}
shift || true

MESSAGE=${*:-"Hello from publisher"}

valkey-cli publish "${CHANNEL}" "${MESSAGE}"

# Notes:
# 1) The first element printed by a subscribe client is the message type (subscribe/message)
# 2) The second element is the channel name
# 3) The third element is usually the number of active subscriptions for that client