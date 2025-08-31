#!/usr/bin/env bash
set -euo pipefail
if command -v op >/dev/null 2>&1; then
  op whoami >/dev/null 2>&1 || op signin
fi
