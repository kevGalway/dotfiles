#!/usr/bin/env bash
set -euo pipefail

if ! command -v mise >/dev/null 2>&1; then
  echo "mise not installed (check AUR step)"
  exit 0
fi

mise use -g node@lts || true
mise use -g python@3 || true
