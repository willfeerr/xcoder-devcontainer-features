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

GLOBAL_ROOT="$(npm root --global)"
XCODER_ROOT="${GLOBAL_ROOT}/@skrbe/xcoder"
test -d "$XCODER_ROOT"
grep -q 'connectOverCDP' "$XCODER_ROOT/dist/browser-worker.js"
grep -q 'BROWSERLESS_URL' "$XCODER_ROOT/dist/browser-worker.js"

if find "$XCODER_ROOT" -type f -path '*/.local-browsers/*' | grep -q .; then
  echo "Navegador local do Playwright encontrado." >&2
  exit 1
fi

echo "Feature XCoder validada."
