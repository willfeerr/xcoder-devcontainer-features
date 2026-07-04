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

test -d /opt/xcoder
test -x /opt/xcoder/dist/cli.js
test -L /usr/local/bin/xcoder
grep -q 'connectOverCDP' /opt/xcoder/dist/browser-worker.js
grep -q 'BROWSERLESS_URL' /opt/xcoder/dist/browser-worker.js

(
  cd /opt/xcoder
  node --input-type=module -e "await import('playwright'); await import('ws')"
)

if find /opt/xcoder -type f -path '*/.local-browsers/*' | grep -q .; then
  echo "Navegador local do Playwright encontrado." >&2
  exit 1
fi

echo "Feature XCoder validada."
