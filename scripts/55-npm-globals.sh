#!/usr/bin/env bash
set -euo pipefail

# Install global npm packages after Node (via mise) is available.

PACKAGES=(
  wrangler
  @openai/codex
)

have_mise() { command -v mise >/dev/null 2>&1; }

if ! have_mise; then
  echo "mise not installed; skipping global npm packages."
  exit 0
fi

mise use -g node@lts >/dev/null 2>&1 || true

echo "==> Installing global npm packages: ${PACKAGES[*]}"
# Run npm via mise to guarantee the runtime is present in PATH
mise exec node@lts -- npm install -g "${PACKAGES[@]}"

echo "✓ Global npm packages installed"
