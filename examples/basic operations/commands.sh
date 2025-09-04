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

