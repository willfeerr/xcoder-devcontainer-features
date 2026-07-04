#!/bin/sh
set -eu

grep -q '^XCODER_DEFAULT_PERMISSION=full-control$' /etc/xcoder/feature.env
grep -q '^XCODER_AUTO_START=false$' /etc/xcoder/feature.env
grep -q '^XCODER_BROWSERLESS_REQUIRED=true$' /etc/xcoder/feature.env

xcoder-feature-start

echo "Cenário full-control sem auto-start validado."
