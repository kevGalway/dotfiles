#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

PKGS=(fish tmux alacritty starship aws bin)

read -rp "Apply these symlinks? [y/N] " ok
if [[ "$ok" =~ ^[Yy]$ ]]; then
  stow --adopt -v -t "$HOME" "${PKGS[@]}"
  echo "==> Stowed: ${PKGS[*]}"
  echo "==> Review and commit any adopted files:"
  echo "    git add -A && git commit -m 'adopt configs'"
else
  echo "Aborted."
fi
