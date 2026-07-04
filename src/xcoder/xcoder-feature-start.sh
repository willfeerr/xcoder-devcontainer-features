#!/bin/sh
set -eu

if [ -r /etc/xcoder/feature.env ]; then
  . /etc/xcoder/feature.env
fi

missing=""
for name in SKRBE_BRIDGE_TOKEN; do
  eval "value=\${$name:-}"
  [ -n "$value" ] || missing="$missing $name"
done

if [ "${XCODER_BROWSERLESS_REQUIRED:-true}" = "true" ]; then
  for name in BROWSERLESS_URL BROWSERLESS_TOKEN; do
    eval "value=\${$name:-}"
    [ -n "$value" ] || missing="$missing $name"
  done
fi

if [ -n "$missing" ]; then
  echo "[xcoder-feature] variáveis obrigatórias ausentes:$missing" >&2
  echo "[xcoder-feature] configure-as em containerEnv/remoteEnv ou use autoStart=false." >&2
  exit 0
fi

export SKRBE_PERMISSION="${SKRBE_PERMISSION:-${XCODER_DEFAULT_PERMISSION:-ask}}"
export SKRBE_WORKSPACE="${SKRBE_WORKSPACE:-$PWD}"
export SKRBE_ROOTS="${SKRBE_ROOTS:-$SKRBE_WORKSPACE}"
export SKRBE_AGENT_ID="${SKRBE_AGENT_ID:-xcoder-$(hostname)}"

STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
STATE_DIR="${STATE_HOME}/xcoder"
PID_FILE="${STATE_DIR}/xcoder.pid"
LOG_FILE="${STATE_DIR}/xcoder.log"
mkdir -p "$STATE_DIR"

if [ -f "$PID_FILE" ]; then
  PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    echo "[xcoder-feature] XCoder já está rodando com PID $PID."
    exit 0
  fi
  rm -f "$PID_FILE"
fi

nohup xcoder >>"$LOG_FILE" 2>&1 &
PID=$!
printf '%s\n' "$PID" > "$PID_FILE"

sleep 1
if ! kill -0 "$PID" 2>/dev/null; then
  echo "[xcoder-feature] XCoder encerrou durante a inicialização. Últimos logs:" >&2
  tail -n 80 "$LOG_FILE" >&2 || true
  rm -f "$PID_FILE"
  exit 1
fi

echo "[xcoder-feature] XCoder iniciado com PID $PID. Logs: $LOG_FILE"
