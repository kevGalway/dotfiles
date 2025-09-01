#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname "$0")/.." && pwd)"

steps=(
  "00-bootstrap-arch.sh"
  "10-install-extra.sh"
  "20-firewall.sh"
  "30-prune-defaults.sh"
  "40-stow.sh"
  "50-mise.sh"
  "60-op-login.sh"
  "65-firefox-setup.sh"
  "70-ssh-1password.sh"
  "80-clone-repos-gh.sh"
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
