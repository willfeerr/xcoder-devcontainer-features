#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PERMISSION="${PERMISSION:-ask}"
AUTOSTART="${AUTOSTART:-true}"
XCODERREF="${XCODERREF:-release/install-without-build}"
BROWSERLESSREQUIRED="${BROWSERLESSREQUIRED:-true}"
XCODER_ROOT="/opt/xcoder"

case "$PERMISSION" in
  ask|auto-approve|full-control) ;;
  *) echo "[xcoder-feature] permission inválida: $PERMISSION" >&2; exit 1 ;;
esac

case "$AUTOSTART" in
  true|false) ;;
  *) echo "[xcoder-feature] autoStart deve ser true ou false." >&2; exit 1 ;;
esac

case "$BROWSERLESSREQUIRED" in
  true|false) ;;
  *) echo "[xcoder-feature] browserlessRequired deve ser true ou false." >&2; exit 1 ;;
esac

install_system_dependencies() {
  if command -v git >/dev/null 2>&1; then
    return
  fi

  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends git ca-certificates
    rm -rf /var/lib/apt/lists/*
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache git ca-certificates
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y git ca-certificates
    dnf clean all
  elif command -v yum >/dev/null 2>&1; then
    yum install -y git ca-certificates
    yum clean all
  else
    echo "[xcoder-feature] não foi possível instalar git nesta distribuição." >&2
    exit 1
  fi
}

install_system_dependencies

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo "[xcoder-feature] Node.js e npm são obrigatórios." >&2
  exit 1
fi

export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

rm -rf "$XCODER_ROOT"
install -d -m 0755 "$XCODER_ROOT"
git init -q "$XCODER_ROOT"
git -C "$XCODER_ROOT" remote add origin https://github.com/willfeerr/xcoder.git
git -C "$XCODER_ROOT" fetch -q --depth 1 origin "$XCODERREF"
git -C "$XCODER_ROOT" checkout -q --detach FETCH_HEAD

if [ ! -f "$XCODER_ROOT/dist/cli.js" ]; then
  echo "[xcoder-feature] o ref $XCODERREF não contém dist/cli.js pré-compilado." >&2
  echo "[xcoder-feature] use release/install-without-build ou outro ref publicável." >&2
  exit 1
fi

npm install \
  --prefix "$XCODER_ROOT" \
  --omit=dev \
  --ignore-scripts \
  --no-package-lock \
  --no-audit \
  --no-fund \
  playwright@1.61.1

node "$SCRIPT_DIR/patch-xcoder.mjs" "$XCODER_ROOT" "$SCRIPT_DIR/browser-worker.mjs"

chmod 0755 "$XCODER_ROOT/dist/cli.js"
ln -sf "$XCODER_ROOT/dist/cli.js" /usr/local/bin/xcoder
ln -sf "$XCODER_ROOT/dist/cli.js" /usr/local/bin/skrbe-dev-agent

install -d -m 0755 /etc/xcoder
cat > /etc/xcoder/feature.env <<EOF
XCODER_DEFAULT_PERMISSION=${PERMISSION}
XCODER_AUTO_START=${AUTOSTART}
XCODER_BROWSERLESS_REQUIRED=${BROWSERLESSREQUIRED}
EOF
chmod 0644 /etc/xcoder/feature.env

install -m 0755 "$SCRIPT_DIR/xcoder-feature-autostart.sh" /usr/local/bin/xcoder-feature-autostart
install -m 0755 "$SCRIPT_DIR/xcoder-feature-start.sh" /usr/local/bin/xcoder-feature-start
install -m 0755 "$SCRIPT_DIR/xcoder-feature-status.sh" /usr/local/bin/xcoder-feature-status
install -m 0755 "$SCRIPT_DIR/xcoder-feature-stop.sh" /usr/local/bin/xcoder-feature-stop

command -v xcoder >/dev/null 2>&1
node --check "$XCODER_ROOT/dist/cli.js"
node --check "$XCODER_ROOT/dist/browser-worker.js"
node --check "$XCODER_ROOT/dist/browser-tools.js"
node --check "$XCODER_ROOT/dist/browser-record-tool.js"
test -f "$XCODER_ROOT/node_modules/playwright/package.json"

echo "[xcoder-feature] XCoder instalado em $XCODER_ROOT com permission=${PERMISSION}."
