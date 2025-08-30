#!/usr/bin/env bash
set -euo pipefail

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  echo "==> Generating SSH key (ed25519)"
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  ssh-keygen -t ed25519 -C "$GEMAIL" -f ~/.ssh/id_ed25519 -N ""
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add ~/.ssh/id_ed25519
  echo "==> Public key:"
  echo "------------------------------------------------------------"
  cat ~/.ssh/id_ed25519.pub
  echo "------------------------------------------------------------"
  echo "Add this key to GitHub/GitLab before cloning over SSH."
else
  echo "SSH key already present at ~/.ssh/id_ed25519"
fi
