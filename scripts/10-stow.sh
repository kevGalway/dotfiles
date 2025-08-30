#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.." # run from repo root

PKGS=(fish tmux alacritty starship)

read -rp "Apply these symlinks? [y/N] " ok
if [[ "$ok" =~ ^[Yy]$ ]]; then
  # Use --adopt to move existing files under the repo and replace with symlinks
  stow --adopt -v -t "$HOME" "${PKGS[@]}"
  echo "==> Stowed: ${PKGS[*]}"
  echo "==> Review and commit any adopted files:"
  echo "    git add -A && git commit -m 'adopt configs'"
else
  echo "Aborted."
fi
