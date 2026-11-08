#!/bin/sh
set -eu
if [ -z "${KANZO_PASSWORD:-}" ]; then
  echo "KANZO_PASSWORD is not set; refusing to expose the board without a password." >&2
  exit 1
fi
mkdir -p "$KANZO_HOME"
[ -f "$KANZO_HOME/config.toml" ] || kanzo --home "$KANZO_HOME" init
# Keep the board on loopback: only Caddy (with the login gate) may reach it.
CFG="$KANZO_HOME/config.toml"
if grep -q '^listen *=' "$CFG"; then
  sed -i 's/^listen *=.*/listen = "127.0.0.1"/' "$CFG"
else
  printf '\nlisten = "127.0.0.1"\n' >> "$CFG"
fi

GATE_PASSWORD="$KANZO_PASSWORD" GATE_USER="$KANZO_USERNAME" GATE_APP_NAME="Kanzo" GATE_COOKIE="kanzo_gate" \
  node /etc/kanzo-railway/gate.mjs &
GATE_PID=$!
kanzo --home "$KANZO_HOME" --port "$KANZO_PORT" --no-open &
KANZO_PID=$!
caddy run --config /etc/kanzo-railway/Caddyfile --adapter caddyfile &
CADDY_PID=$!

trap 'kill $KANZO_PID $CADDY_PID $GATE_PID 2>/dev/null; exit 0' TERM INT
while kill -0 "$KANZO_PID" 2>/dev/null && kill -0 "$CADDY_PID" 2>/dev/null && kill -0 "$GATE_PID" 2>/dev/null; do sleep 5; done
echo "kanzo, gate or proxy exited" >&2
kill $KANZO_PID $CADDY_PID $GATE_PID 2>/dev/null || true
exit 1
