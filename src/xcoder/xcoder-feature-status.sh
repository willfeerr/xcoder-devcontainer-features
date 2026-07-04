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

PID="$(cat "$PID_FILE")"
if kill -0 "$PID" 2>/dev/null; then
  echo "XCoder ativo. PID: $PID"
  echo "Logs: $LOG_FILE"
  exit 0
fi

echo "PID obsoleto encontrado: $PID"
exit 1
