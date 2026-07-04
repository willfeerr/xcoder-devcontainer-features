#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PERMISSION="${PERMISSION:-ask}"
AUTOSTART="${AUTOSTART:-true}"
XCODERREF="${XCODERREF:-release/install-without-build}"
BROWSERLESSREQUIRED="${BROWSERLESSREQUIRED:-true}"

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

npm install --global --no-audit --no-fund \
  "github:willfeerr/xcoder#${XCODERREF}" \
  "playwright@1.61.1"

GLOBAL_ROOT="$(npm root --global)"
XCODER_ROOT="$(node - "$GLOBAL_ROOT" <<'NODE'
const fs = require('node:fs');
const path = require('node:path');

const root = process.argv[2];
const queue = [{ directory: root, depth: 0 }];

while (queue.length > 0) {
  const { directory, depth } = queue.shift();
  const packageFile = path.join(directory, 'package.json');

  if (fs.existsSync(packageFile)) {
    try {
      const pkg = JSON.parse(fs.readFileSync(packageFile, 'utf8'));
      if (pkg.name === '@skrbe/xcoder') {
        process.stdout.write(directory);
        process.exit(0);
      }
    } catch {}
  }

  if (depth >= 4) continue;

  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (!entry.isDirectory() || entry.name === '.bin') continue;
    queue.push({ directory: path.join(directory, entry.name), depth: depth + 1 });
  }
}

process.exit(1);
NODE
)"

if [ -z "$XCODER_ROOT" ] || [ ! -f "$XCODER_ROOT/dist/cli.js" ]; then
  echo "[xcoder-feature] @skrbe/xcoder não localizado dentro de $GLOBAL_ROOT" >&2
  find "$GLOBAL_ROOT" -maxdepth 3 -name package.json -print >&2 || true
  exit 1
fi

echo "[xcoder-feature] XCoder localizado em $XCODER_ROOT"

chmod 0755 "$XCODER_ROOT/dist/cli.js"
ln -sf "$XCODER_ROOT/dist/cli.js" /usr/local/bin/xcoder
ln -sf "$XCODER_ROOT/dist/cli.js" /usr/local/bin/skrbe-dev-agent

node "$SCRIPT_DIR/patch-xcoder.mjs" "$XCODER_ROOT" "$SCRIPT_DIR/browser-worker.mjs"

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

echo "[xcoder-feature] XCoder instalado com Browserless remoto e permission=${PERMISSION}."
