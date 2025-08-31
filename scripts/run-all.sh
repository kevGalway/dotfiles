#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname "$0")/.." && pwd)"

steps=(
  "00-bootstrap-arch.sh"
  "02-install-extra.sh"
  "03-firewall.sh"
  "05-prune-defaults.sh"
  "10-stow.sh"
  "12-mise.sh"
  "15-git-setup.sh"
  "18-op-login.sh"
  "20-clone-repos-gh.sh"
)

echo "==> Running provisioning steps from: $ROOT_DIR/scripts"
for s in "${steps[@]}"; do
  p="$ROOT_DIR/scripts/$s"
  if [[ -x "$p" ]]; then
    echo
    echo "==== $s ===="
    "$p"
  else
    echo "(skip) $s (not found or not executable)"
  fi
done

echo
echo "==> All steps attempted. Review output for any actions required."
