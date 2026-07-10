#!/bin/sh
set -eu

command -v node
command -v npm
command -v xcoder
command -v xcoder-feature-autostart
command -v xcoder-feature-start
command -v xcoder-feature-status
command -v xcoder-feature-stop

test -r /etc/xcoder/feature.env
grep -q '^XCODER_DEFAULT_PERMISSION=' /etc/xcoder/feature.env
grep -q '^XCODER_AUTO_START=' /etc/xcoder/feature.env
grep -q '^XCODER_BROWSER_MODE=' /etc/xcoder/feature.env
grep -q '^XCODER_REF=[0-9a-f]\{40\}$' /etc/xcoder/feature.env
grep -q '^XCODER_VERSION=0.5.0$' /etc/xcoder/feature.env

PACKAGE_ROOT=/opt/xcoder/node_modules/@skrbe/xcoder
test -d "$PACKAGE_ROOT"
test -x "$PACKAGE_ROOT/bin/xcoder.mjs"
test -f "$PACKAGE_ROOT/dist/cli.js"
test -f "$PACKAGE_ROOT/dist/browser-worker.js"
test -f "$PACKAGE_ROOT/dist/browser-provider.js"
test -L /usr/local/bin/xcoder
test ! -e /opt/xcoder-runtime

node --check "$PACKAGE_ROOT/dist/cli.js"
node --check "$PACKAGE_ROOT/dist/browser-worker.js"
node --check "$PACKAGE_ROOT/dist/browser-provider.js"
grep -q 'connectOverCDP' "$PACKAGE_ROOT/dist/browser-provider.js"

SKRBE_BRIDGE_TOKEN=test SKRBE_WORKSPACE=/tmp SKRBE_BROWSER_MODE=disabled \
  xcoder doctor --json | grep -q '"ok": true'

if find /opt/xcoder -type f -path '*/.local-browsers/*' | grep -q .; then
  echo "Navegador local do Playwright encontrado." >&2
  exit 1
fi

echo "Feature XCoder validada."
