#!/bin/sh
set -eu

STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
STATE_DIR="${STATE_HOME}/xcoder"
PID_FILE="${STATE_DIR}/xcoder.pid"
LOG_FILE="${STATE_DIR}/xcoder.log"

if [ ! -f "$PID_FILE" ]; then
  echo "XCoder não está registrado como ativo."
  exit 1
fi

PID="$(cat "$PID_FILE" 2>/dev/null || true)"
STATE=""
if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
  STATE="$(ps -o stat= -p "$PID" 2>/dev/null | tr -d ' ' || true)"
fi

case "$STATE" in
  ""|Z*)
    echo "PID obsoleto encontrado: ${PID:-desconhecido}"
    rm -f "$PID_FILE"
    if [ -s "$LOG_FILE" ]; then
      echo "Últimos logs:"
      tail -n 40 "$LOG_FILE"
    fi
    exit 1
    ;;
esac

echo "XCoder ativo. PID: $PID"
echo "Estado: $STATE"
echo "Logs: $LOG_FILE"
