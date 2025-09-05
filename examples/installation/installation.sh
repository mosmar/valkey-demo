# Option 1: install valkey via brew
brew install valkey

# Option 2: install docker via brew
brew install --cask docker

# Run docker desktop to run docker daemon

docker run -d --name valkey-server -p 6380:6379 valkey/valkey
docker exec -it valkey-server valkey-cli

docker run -d --name redis-server -p 6379:6379 redis
docker exec -it redis-server redis-cli