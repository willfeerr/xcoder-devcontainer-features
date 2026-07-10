#!/bin/sh
set -eu

grep -q '^XCODER_DEFAULT_PERMISSION=full-control$' /etc/xcoder/feature.env
grep -q '^XCODER_AUTO_START=false$' /etc/xcoder/feature.env
grep -q '^XCODER_BROWSER_MODE=required$' /etc/xcoder/feature.env
grep -q '^XCODER_BROWSERLESS_REQUIRED=true$' /etc/xcoder/feature.env

OUTPUT="$(xcoder-feature-start 2>&1)"
printf '%s\n' "$OUTPUT" | grep -q 'variáveis obrigatórias ausentes'
printf '%s\n' "$OUTPUT" | grep -q 'SKRBE_BRIDGE_TOKEN'
printf '%s\n' "$OUTPUT" | grep -q 'BROWSERLESS_URL'

echo "Cenário full-control sem auto-start validado."
