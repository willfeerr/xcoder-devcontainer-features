#!/bin/sh
set -eu

grep -q '^XCODER_DEFAULT_PERMISSION=full-control$' /etc/xcoder/feature.env
grep -q '^XCODER_AUTO_START=false$' /etc/xcoder/feature.env
grep -q '^XCODER_BROWSER_MODE=required$' /etc/xcoder/feature.env
grep -q '^XCODER_BROWSERLESS_REQUIRED=true$' /etc/xcoder/feature.env

OUTPUT="$(xcoder-feature-start 2>&1)"
printf '%s\n' "$OUTPUT" | grep -q 'variáveis obrigatórias ausentes'
printf '%s\n' "$OUTPUT" | grep -q 'SKRBE_BRIDGE_TOKEN'
printf '%s\n' "$OUTPUT" | grep -q 'BROWSERLESS_URL'

STATE_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/xcoder"
mkdir -p "$STATE_DIR"
sleep 60 &
FOREIGN_PID=$!
printf '%s\n' "$FOREIGN_PID" >"$STATE_DIR/xcoder.pid"
if xcoder-feature-stop >/tmp/xcoder-stop.out 2>&1; then
  echo "stop aceitou PID estrangeiro" >&2
  kill "$FOREIGN_PID" 2>/dev/null || true
  exit 1
fi
grep -q 'pertence a outro processo' /tmp/xcoder-stop.out
kill -0 "$FOREIGN_PID"
kill "$FOREIGN_PID"
wait "$FOREIGN_PID" 2>/dev/null || true
rm -f /tmp/xcoder-stop.out

echo "Cenário full-control sem auto-start validado."
