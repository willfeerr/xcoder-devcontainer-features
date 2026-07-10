#!/bin/sh
set -eu

STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
PID_FILE="${STATE_HOME}/xcoder/xcoder.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "XCoder não está registrado como ativo."
  exit 0
fi

PID="$(cat "$PID_FILE" 2>/dev/null || true)"
if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
  ARGS="$(ps -o args= -p "$PID" 2>/dev/null || true)"
  case "$ARGS" in
    *xcoder.mjs*|*/usr/local/bin/xcoder*) ;;
    *)
      echo "PID $PID pertence a outro processo; recusando encerramento." >&2
      rm -f "$PID_FILE"
      exit 1
      ;;
  esac
  if kill -TERM "-$PID" 2>/dev/null; then
    :
  else
    kill -TERM "$PID" 2>/dev/null || true
  fi
  i=0
  while kill -0 "$PID" 2>/dev/null && [ "$i" -lt 20 ]; do
    sleep 0.25
    i=$((i + 1))
  done
  if kill -0 "$PID" 2>/dev/null; then
    kill -KILL "-$PID" 2>/dev/null || kill -KILL "$PID" 2>/dev/null || true
  fi
fi

rm -f "$PID_FILE"
echo "XCoder encerrado."
