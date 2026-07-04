#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PERMISSION="${PERMISSION:-ask}"
AUTOSTART="${AUTOSTART:-true}"
XCODERREF="${XCODERREF:-main}"
BROWSERLESSREQUIRED="${BROWSERLESSREQUIRED:-true}"
XCODER_ROOT="/opt/xcoder"
RUNTIME_ROOT="/opt/xcoder-runtime"

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

if ! command -v git >/dev/null 2>&1; then
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
fi

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo "[xcoder-feature] Node.js e npm são obrigatórios." >&2
  exit 1
fi

export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

rm -rf "$XCODER_ROOT" "$RUNTIME_ROOT"
install -d -m 0755 "$XCODER_ROOT" "$RUNTIME_ROOT"

git init -q "$XCODER_ROOT"
git -C "$XCODER_ROOT" remote add origin https://github.com/willfeerr/xcoder.git
git -C "$XCODER_ROOT" fetch -q --depth 1 origin "$XCODERREF"
git -C "$XCODER_ROOT" checkout -q --detach FETCH_HEAD

if [ ! -f "$XCODER_ROOT/package.json" ]; then
  echo "[xcoder-feature] o ref $XCODERREF não contém package.json." >&2
  exit 1
fi

if [ ! -f "$XCODER_ROOT/dist/cli.js" ]; then
  echo "[xcoder-feature] dist ausente no ref $XCODERREF; compilando XCoder..."
  (
    cd "$XCODER_ROOT"
    npm install --include=dev --ignore-scripts --no-package-lock --no-audit --no-fund
    npm run build
  )
fi

if [ ! -f "$XCODER_ROOT/dist/cli.js" ]; then
  echo "[xcoder-feature] a compilação não gerou dist/cli.js." >&2
  exit 1
fi

rm -rf "$XCODER_ROOT/node_modules"

cat > "$RUNTIME_ROOT/package.json" <<'EOF'
{
  "name": "xcoder-runtime",
  "private": true,
  "type": "module",
  "dependencies": {
    "playwright": "1.61.1",
    "ws": "8.18.3"
  }
}
EOF

(
  cd "$RUNTIME_ROOT"
  npm install --omit=dev --ignore-scripts --no-package-lock --no-audit --no-fund
)

[ -d "$RUNTIME_ROOT/node_modules/playwright" ] || {
  echo "[xcoder-feature] playwright não foi instalado." >&2
  exit 1
}

[ -d "$RUNTIME_ROOT/node_modules/ws" ] || {
  echo "[xcoder-feature] ws não foi instalado." >&2
  exit 1
}

ln -s "$RUNTIME_ROOT/node_modules" "$XCODER_ROOT/node_modules"

node "$SCRIPT_DIR/patch-xcoder.mjs" "$XCODER_ROOT" "$SCRIPT_DIR/browser-worker.mjs"

chmod 0755 "$XCODER_ROOT/dist/cli.js"
install -d -m 0755 /usr/local/bin
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

test -L /usr/local/bin/xcoder
test -L "$XCODER_ROOT/node_modules"
test -x "$XCODER_ROOT/dist/cli.js"
node --check "$XCODER_ROOT/dist/cli.js"
node --check "$XCODER_ROOT/dist/browser-worker.js"
node --check "$XCODER_ROOT/dist/browser-tools.js"
node --check "$XCODER_ROOT/dist/browser-record-tool.js"
(
  cd "$XCODER_ROOT"
  node --input-type=module -e "await import('playwright'); await import('ws')"
)

echo "[xcoder-feature] XCoder instalado em $XCODER_ROOT com ref=${XCODERREF} e permission=${PERMISSION}."
