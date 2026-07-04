#!/bin/sh
set -eu

STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
PID_FILE="${STATE_HOME}/xcoder/xcoder.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "XCoder não está registrado como ativo."
  exit 0
fi

PID="$(cat "$PID_FILE")"
if kill -0 "$PID" 2>/dev/null; then
  kill -TERM "$PID"
  i=0
  while kill -0 "$PID" 2>/dev/null && [ "$i" -lt 20 ]; do
    sleep 0.25
    i=$((i + 1))
  done
fi

rm -f "$PID_FILE"
echo "XCoder encerrado."
