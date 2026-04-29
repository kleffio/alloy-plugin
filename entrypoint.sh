#!/bin/sh
set -e

CONFIG=/etc/alloy/config.alloy
PLATFORM_URL="${KLEFF_PLATFORM_URL:-http://api:8080}"
POLL_INTERVAL=30

fetch_config() {
  curl -sf "${PLATFORM_URL}/api/v1/monitoring/alloy-config?platform_url=${PLATFORM_URL}" 2>/dev/null || true
}

# Write initial config; block until we get a non-empty response.
echo "Fetching initial Alloy config from ${PLATFORM_URL}..."
while true; do
  CONFIG_CONTENT=$(fetch_config)
  if [ -n "$CONFIG_CONTENT" ]; then
    echo "$CONFIG_CONTENT" > "$CONFIG"
    echo "Initial config written."
    break
  fi
  echo "Platform not ready, retrying in 5s..."
  sleep 5
done

# Start Alloy in the background.
/bin/alloy run \
  --server.http.listen-addr=0.0.0.0:12345 \
  --storage.path=/var/lib/alloy/data \
  "$CONFIG" &

ALLOY_PID=$!

# Poll for config changes and hot-reload Alloy when the config changes.
LAST_CONFIG=$(cat "$CONFIG")
while kill -0 "$ALLOY_PID" 2>/dev/null; do
  sleep "$POLL_INTERVAL"
  NEW_CONFIG=$(fetch_config)
  if [ -n "$NEW_CONFIG" ] && [ "$NEW_CONFIG" != "$LAST_CONFIG" ]; then
    echo "Config changed, reloading Alloy..."
    echo "$NEW_CONFIG" > "$CONFIG"
    curl -sf -X POST "http://localhost:12345/-/reload" >/dev/null 2>&1 || true
    LAST_CONFIG="$NEW_CONFIG"
  fi
done
