#!/usr/bin/env bash
set -euo pipefail
LIST="$(dirname "$0")/../lists/packages.txt"

mapfile -t PKGS < <(grep -vE '^\s*#|^\s*$' "$LIST" || true)
[ "${#PKGS[@]}" -gt 0 ] || {
  echo "No packages listed in $LIST"
  exit 0
}

echo "==> Installing packages from official repos via pacman"

official=()
aur_missing=()
for p in "${PKGS[@]}"; do
  if pacman -Si "$p" >/dev/null 2>&1; then
    official+=("$p")
  else
    aur_missing+=("$p")
  fi
done

if [ ${#official[@]} -gt 0 ]; then
  echo "==> Installing official packages via pacman: ${official[*]}"
  sudo pacman -S --needed "${official[@]}"
fi

if [ ${#aur_missing[@]} -gt 0 ]; then
  echo "==> Skipping unavailable packages (not in official repos):"
  printf ' - %s\n' "${aur_missing[@]}"
fi
