#!/bin/sh
set -eu

command -v xcoder
command -v xcoder-feature-start

grep -q '^XCODER_DEFAULT_PERMISSION=ask$' /etc/xcoder/feature.env
grep -q '^XCODER_AUTO_START=true$' /etc/xcoder/feature.env
grep -q '^XCODER_BROWSERLESS_REQUIRED=true$' /etc/xcoder/feature.env

echo "Cenário padrão validado."
