#!/usr/bin/env bash
set -euo pipefail

# Quick demo commands for Valkey (run line-by-line or as a script)
docker exec -it valkey-server valkey-cli

valkey-cli ping

# key
valkey-cli set mykey "hello"
valkey-cli get mykey

# string: The simplest data type in Valkey is a string
valkey-cli SET user:1000 "mosmar"
valkey-cli GET user:1000
valkey-cli DEL user:1000

# Hashes: Hashes allow you to store multiple fields and values under one key, similar to a JSON object or dictionary
valkey-cli HSET user:1000 name "Alice" email "alice@example.com" age "30"
valkey-cli HGET user:1000 name
valkey-cli HGETALL user:1000
valkey-cli DEL user:1000

# Sets: Add the specified members to the set stored at key. Specified members that are already a member of this set are ignored. 
valkey-cli SADD colors red blue green
valkey-cli SMEMBERS colors

# Lists: Insert all the specified values at the head of the list stored at key
valkey-cli LPUSH tasks "task1"
valkey-cli LPUSH tasks "task2"
valkey-cli LRANGE tasks 0 -1

# Increment number stored by key
valkey-cli INCR player:42:points
valkey-cli INCR player:42:points
valkey-cli GET player:42:points
