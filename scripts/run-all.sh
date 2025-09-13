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
  "55-npm-globals.sh"
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
    # Insert an interactive pause between 60 and 65 to allow 1Password desktop sign-in
    if [[ "$s" == "60-op-login.sh" ]]; then
      echo
      echo "==> Please sign in to 1Password Desktop now (if installed)."
      echo "    - Ensure 1Password SSH agent is enabled (Settings → Developer)."
      echo "    - CLI sign-in was attempted in the previous step."
      # Best-effort: launch desktop app if available
      if command -v 1password >/dev/null 2>&1; then
        1password >/dev/null 2>&1 &
      fi
      # Give the user control to continue
      read -r -p "Press Enter to continue once 1Password is signed in..." _
    fi
  else
    echo "(skip) $s (not found or not executable)"
  fi
done

echo
echo "==> All steps attempted. Review output for any actions required."
