const Redis = require('ioredis');

const host = process.env.VALKEY_HOST || '127.0.0.1';
const port = process.env.VALKEY_PORT ? parseInt(process.env.VALKEY_PORT, 10) : 6380;

const client = new Redis({ host, port });

// Retry helper: try to run fn until it succeeds or retries are exhausted
async function retry(fn, { retries = 10, delayMs = 500 } = {}) {
  let lastErr;
  for (let i = 0; i < retries; i++) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      // If connection refused, wait and retry
      if (err && err.code === 'ECONNREFUSED') {
        await new Promise(r => setTimeout(r, delayMs));
        continue;
      }
      // Non-connection errors -> rethrow
      throw err;
    }
  }
  throw lastErr;
}

async function run() {
  await retry(async () => {
    await client.set('demo:key', 'hello from node demo');
    return true;
  }, { retries: 12, delayMs: 500 });

  const v = await client.get('demo:key');
  console.log('demo:key =>', v);

  // pub/sub demo
  const sub = new Redis({ host, port });
  await retry(async () => {
    // subscribe returns a promise if callback not provided in ioredis v5
    await sub.subscribe('demo-channel');
    return true;
  }, { retries: 12, delayMs: 500 });

  console.log('Subscribed to demo-channel. Waiting for a message...');

  sub.on('message', (channel, message) => {
    console.log('Received message on', channel, ':', message);
    process.exit(0);
  });

  // publish a message
  await client.publish('demo-channel', `hello at ${new Date().toISOString()}`);
}

run().catch(err => {
  if (err && err.code === 'ECONNREFUSED') {
    console.error('Unable to connect to Valkey at', `${host}:${port}`, '\nPlease ensure Docker is running and Valkey is available (try `docker-compose up -d` or start Docker Desktop).');
  } else {
    console.error(err);
  }
  process.exit(1);
});
