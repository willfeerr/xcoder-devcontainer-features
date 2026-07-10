#!/bin/sh
set -eu

if [ -r /etc/xcoder/feature.env ]; then
  . /etc/xcoder/feature.env
fi

STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
STATE_DIR="${STATE_HOME}/xcoder"
PID_FILE="${STATE_DIR}/xcoder.pid"
LOG_FILE="${STATE_DIR}/xcoder.log"

printf 'XCoder version: %s\n' "${XCODER_VERSION:-unknown}"
printf 'XCoder ref: %s\n' "${XCODER_REF:-unknown}"
printf 'Browser mode: %s\n' "${SKRBE_BROWSER_MODE:-${XCODER_BROWSER_MODE:-optional}}"

if [ ! -f "$PID_FILE" ]; then
  echo "XCoder não está registrado como ativo."
  xcoder doctor --json 2>/dev/null || true
  exit 1
fi

PID="$(cat "$PID_FILE" 2>/dev/null || true)"
STATE=""
ARGS=""
if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
  STATE="$(ps -o stat= -p "$PID" 2>/dev/null | tr -d ' ' || true)"
  ARGS="$(ps -o args= -p "$PID" 2>/dev/null || true)"
fi

case "$STATE:$ARGS" in
  :*|Z*:*)
    echo "PID obsoleto encontrado: ${PID:-desconhecido}"
    rm -f "$PID_FILE"
    if [ -s "$LOG_FILE" ]; then
      echo "Últimos logs:"
      tail -n 40 "$LOG_FILE"
    fi
    exit 1
    ;;
  *:*xcoder.mjs*|*:*\/usr\/local\/bin\/xcoder*) ;;
  *)
    echo "PID $PID pertence a outro processo; removendo registro obsoleto."
    rm -f "$PID_FILE"
    exit 1
    ;;
esac

echo "XCoder ativo. PID: $PID"
echo "Estado: $STATE"
echo "Logs: $LOG_FILE"
echo "Doctor:"
xcoder doctor --json 2>/dev/null || true
