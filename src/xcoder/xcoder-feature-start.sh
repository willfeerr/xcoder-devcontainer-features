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
  echo "[xcoder-feature] configure-as no ambiente do container ou use autoStart=false." >&2
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

is_running() {
  candidate="$1"
  [ -n "$candidate" ] || return 1
  kill -0 "$candidate" 2>/dev/null || return 1
  state="$(ps -o stat= -p "$candidate" 2>/dev/null | tr -d ' ' || true)"
  [ -n "$state" ] || return 1
  case "$state" in
    Z*) return 1 ;;
  esac
  return 0
}

if [ -f "$PID_FILE" ]; then
  PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if is_running "$PID"; then
    echo "[xcoder-feature] XCoder já está rodando com PID $PID."
    exit 0
  fi
  rm -f "$PID_FILE"
fi

XCODER_BIN="$(command -v xcoder 2>/dev/null || true)"
if [ -z "$XCODER_BIN" ]; then
  echo "[xcoder-feature] binário xcoder não encontrado no PATH." >&2
  exit 1
fi

printf '[xcoder-feature] iniciando em %s com workspace=%s\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SKRBE_WORKSPACE" >>"$LOG_FILE"

PID="$(
  XCODER_BIN="$XCODER_BIN" LOG_FILE="$LOG_FILE" node --input-type=module <<'NODE'
import fs from "node:fs";
import { spawn } from "node:child_process";

const executable = process.env.XCODER_BIN;
const logFile = process.env.LOG_FILE;
if (!executable || !logFile) process.exit(1);

const output = fs.openSync(logFile, "a");
const child = spawn(executable, [], {
  cwd: process.cwd(),
  env: process.env,
  detached: true,
  stdio: ["ignore", output, output],
});
fs.closeSync(output);

if (!child.pid) process.exit(1);
child.unref();
process.stdout.write(String(child.pid));
NODE
)"

if [ -z "$PID" ]; then
  echo "[xcoder-feature] não foi possível obter o PID do XCoder." >&2
  tail -n 80 "$LOG_FILE" >&2 || true
  exit 1
fi

printf '%s\n' "$PID" >"$PID_FILE"

sleep 3
if ! is_running "$PID"; then
  echo "[xcoder-feature] XCoder encerrou durante a inicialização. Últimos logs:" >&2
  tail -n 80 "$LOG_FILE" >&2 || true
  rm -f "$PID_FILE"
  exit 1
fi

echo "[xcoder-feature] XCoder iniciado em sessão destacada com PID $PID. Logs: $LOG_FILE"
