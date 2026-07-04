#!/bin/sh
set -eu

if [ -r /etc/xcoder/feature.env ]; then
  . /etc/xcoder/feature.env
fi

if [ "${XCODER_AUTO_START:-true}" != "true" ]; then
  echo "[xcoder-feature] autoStart desabilitado."
  exit 0
fi

exec /usr/local/bin/xcoder-feature-start
