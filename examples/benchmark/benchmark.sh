# Run client benchmark if Valkey installed locally
valkey-cli valkey-benchmark -n 10000 -c 50

# run it client benchmark inside a separate container

# Valkey
docker run --rm valkey/valkey valkey-benchmark -h host.docker.internal -p 6380 -n 100000 -c 50

# Redis
docker run --rm redis redis-benchmark -h host.docker.internal -p 6379 -n 100000 -c 50
