#!/usr/bin/env bash
set -euo pipefail
LIST="$(dirname "$0")/../lists/packages.txt"

mapfile -t PKGS < <(grep -vE '^\s*#|^\s*$' "$LIST" || true)
[ "${#PKGS[@]}" -gt 0 ] || exit 0

echo "==> Installing extra packages"
sudo pacman -S --needed "${PKGS[@]}"
