#!/bin/sh
set -eu

command -v xcoder
command -v xcoder-feature-start

grep -q '^XCODER_DEFAULT_PERMISSION=ask$' /etc/xcoder/feature.env
grep -q '^XCODER_AUTO_START=true$' /etc/xcoder/feature.env
grep -q '^XCODER_BROWSER_MODE=optional$' /etc/xcoder/feature.env
grep -q '^XCODER_BROWSERLESS_REQUIRED=false$' /etc/xcoder/feature.env
grep -q '^XCODER_VERSION=0.5.0$' /etc/xcoder/feature.env

test -x /opt/xcoder/node_modules/@skrbe/xcoder/bin/xcoder.mjs
test -f /opt/xcoder/node_modules/@skrbe/xcoder/dist/browser-provider.js
test ! -e /opt/xcoder-runtime

SKRBE_BRIDGE_TOKEN=test SKRBE_WORKSPACE=/tmp SKRBE_BROWSER_MODE=disabled \
  xcoder doctor --json | grep -q '"ok": true'

echo "Cenário padrão validado."
