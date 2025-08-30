#!/usr/bin/env bash
set -euo pipefail

LIST="$(dirname "$0")/../lists/remove-packages.txt"
[ -f "$LIST" ] || {
  echo "No remove list found: $LIST (skipping)"
  exit 0
}

mapfile -t PKGS < <(grep -vE '^\s*#|^\s*$' "$LIST" || true)
[ "${#PKGS[@]}" -gt 0 ] || {
  echo "No packages to remove."
  exit 0
}

echo "==> Packages requested for removal:"
printf ' - %s\n' "${PKGS[@]}"

# remove only if installed
TO_REMOVE=()
for p in "${PKGS[@]}"; do
  pacman -Qi "$p" >/dev/null 2>&1 && TO_REMOVE+=("$p")
done

if [ "${#TO_REMOVE[@]}" -eq 0 ]; then
  echo "Nothing to remove."
  exit 0
fi

read -rp "Remove these? [y/N] " ok
[[ "$ok" =~ ^[Yy]$ ]] || {
  echo "Aborted."
  exit 0
}

sudo pacman -Rns --noconfirm "${TO_REMOVE[@]}"
echo "==> Removed: ${TO_REMOVE[*]}"
