#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PERMISSION="${PERMISSION:-ask}"
AUTOSTART="${AUTOSTART:-true}"
XCODERREF="${XCODERREF:-a905425aeb5076894dfece0bd42b9e692f90895a}"
BROWSERMODE="${BROWSERMODE:-optional}"
BROWSERLESSREQUIRED="${BROWSERLESSREQUIRED:-false}"
INSTALL_ROOT="/opt/xcoder"
PACKAGE_ROOT="$INSTALL_ROOT/node_modules/@skrbe/xcoder"

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
case "$BROWSERMODE" in
  disabled|optional|required) ;;
  *) echo "[xcoder-feature] browserMode inválido: $BROWSERMODE" >&2; exit 1 ;;
esac
if [ "$BROWSERLESSREQUIRED" = "true" ]; then
  BROWSERMODE="required"
fi

install_system_dependencies() {
  if command -v git >/dev/null 2>&1 && [ -r /etc/ssl/certs/ca-certificates.crt ]; then
    return 0
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
  elif ! command -v git >/dev/null 2>&1; then
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
SOURCE_ROOT="$(mktemp -d)"
PACK_ROOT="$(mktemp -d)"
cleanup() {
  rm -rf "$SOURCE_ROOT" "$PACK_ROOT"
}
trap cleanup EXIT INT TERM

printf '%s\n' "[xcoder-feature] preparando XCoder ref=$XCODERREF"
git init -q "$SOURCE_ROOT"
git -C "$SOURCE_ROOT" remote add origin https://github.com/willfeerr/xcoder.git
git -C "$SOURCE_ROOT" fetch -q --depth 1 origin "$XCODERREF"
git -C "$SOURCE_ROOT" checkout -q --detach FETCH_HEAD

if [ ! -f "$SOURCE_ROOT/package.json" ] || [ ! -f "$SOURCE_ROOT/package-lock.json" ]; then
  echo "[xcoder-feature] o ref $XCODERREF não contém package.json e package-lock.json." >&2
  exit 1
fi

(
  cd "$SOURCE_ROOT"
  npm ci --ignore-scripts --no-audit --no-fund
  npm run build
  npm pack --pack-destination "$PACK_ROOT" >/dev/null
)

TARBALL="$(find "$PACK_ROOT" -maxdepth 1 -type f -name '*.tgz' -print -quit)"
if [ -z "$TARBALL" ]; then
  echo "[xcoder-feature] npm pack não produziu o tarball do XCoder." >&2
  exit 1
fi

rm -rf "$INSTALL_ROOT"
install -d -m 0755 "$INSTALL_ROOT"
npm install \
  --prefix "$INSTALL_ROOT" \
  --omit=dev \
  --ignore-scripts \
  --no-audit \
  --no-fund \
  "$TARBALL"

if [ ! -x "$PACKAGE_ROOT/bin/xcoder.mjs" ] || [ ! -f "$PACKAGE_ROOT/dist/cli.js" ]; then
  echo "[xcoder-feature] pacote instalado está incompleto em $PACKAGE_ROOT." >&2
  exit 1
fi

install -d -m 0755 /usr/local/bin
ln -sf "$PACKAGE_ROOT/bin/xcoder.mjs" /usr/local/bin/xcoder
ln -sf "$PACKAGE_ROOT/bin/xcoder.mjs" /usr/local/bin/skrbe-dev-agent

XCODER_VERSION="$(node -e "const p=require('$PACKAGE_ROOT/package.json'); process.stdout.write(p.version)")"
XCODER_COMMIT="$(git -C "$SOURCE_ROOT" rev-parse HEAD)"
install -d -m 0755 /etc/xcoder
cat > /etc/xcoder/feature.env <<EOF
XCODER_DEFAULT_PERMISSION=${PERMISSION}
XCODER_AUTO_START=${AUTOSTART}
XCODER_BROWSER_MODE=${BROWSERMODE}
XCODER_BROWSERLESS_REQUIRED=${BROWSERLESSREQUIRED}
XCODER_REF=${XCODER_COMMIT}
XCODER_VERSION=${XCODER_VERSION}
EOF
chmod 0644 /etc/xcoder/feature.env

install -m 0755 "$SCRIPT_DIR/xcoder-feature-autostart.sh" /usr/local/bin/xcoder-feature-autostart
install -m 0755 "$SCRIPT_DIR/xcoder-feature-start.sh" /usr/local/bin/xcoder-feature-start
install -m 0755 "$SCRIPT_DIR/xcoder-feature-status.sh" /usr/local/bin/xcoder-feature-status
install -m 0755 "$SCRIPT_DIR/xcoder-feature-stop.sh" /usr/local/bin/xcoder-feature-stop

test -L /usr/local/bin/xcoder
node --check "$PACKAGE_ROOT/dist/cli.js"
node --check "$PACKAGE_ROOT/dist/browser-worker.js"
node --check "$PACKAGE_ROOT/dist/browser-provider.js"
SKRBE_BRIDGE_TOKEN=install-check SKRBE_WORKSPACE=/tmp SKRBE_BROWSER_MODE="$BROWSERMODE" \
  /usr/local/bin/xcoder doctor --json >/tmp/xcoder-feature-doctor.json || {
    cat /tmp/xcoder-feature-doctor.json >&2 || true
    exit 1
  }
rm -f /tmp/xcoder-feature-doctor.json

echo "[xcoder-feature] XCoder ${XCODER_VERSION} instalado com ref=${XCODER_COMMIT}, permission=${PERMISSION} e browserMode=${BROWSERMODE}."
