#!/usr/bin/env bash
set -euo pipefail

# === SETTINGS ===============================================================
OP_SSH_ITEM="${OP_SSH_ITEM:-ssh_key_id_ed25519}"
GIT_EMAIL="${GIT_EMAIL:-$(git config --global user.email || true)}"
OP_SSH_SIGN="${OP_SSH_SIGN:-/opt/1Password/op-ssh-sign}"
# ============================================================================

need() { command -v "$1" >/dev/null 2>&1 || {
  echo "Missing $1"
  exit 1
}; }

need op
need jq
[ -S "$HOME/.1password/agent.sock" ] || {
  echo "1Password SSH agent socket not found at ~/.1password/agent.sock"
  echo "Enable it in 1Password → Settings → Developer → 'SSH Agent'."
}

# Ensure we're signed in
op whoami >/dev/null 2>&1 || op signin >/dev/null 2>&1

# Fetch the item JSON from 1Password
ITEM_JSON="$(op item get "$OP_SSH_ITEM" --format json)"

# Extract the public key (field label is typically "public key")
PUBKEY="$(echo "$ITEM_JSON" |
  jq -r '
      (.fields // [] + (.sections[]?.fields // []))
      | map(select((.label // .title // "") | ascii_downcase | test("public key")))
      | .[0].value // empty
    ')"

if [ -z "${PUBKEY:-}" ]; then
  echo "Could not find a 'public key' field in 1Password item: $OP_SSH_ITEM"
  echo "Make sure the item is an SSH Key item with a visible Public Key field."
  exit 1
fi

# Basic sanity check: should look like "ssh-ed25519 AAAA... comment"
if ! printf '%s' "$PUBKEY" | grep -qE '^ssh-(ed25519|rsa) [A-Za-z0-9+/=]+'; then
  echo "The extracted public key does not look valid:"
  echo "  $PUBKEY"
  exit 1
fi

# Ensure ~/.ssh bits
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# SSH config: point to 1Password agent
if ! grep -q 'IdentityAgent ~/.1password/agent\.sock' "$HOME/.ssh/config" 2>/dev/null; then
  {
    echo "Host *"
    echo "    IdentityAgent ~/.1password/agent.sock"
    echo
    echo "Host github.com"
    echo "    HostName github.com"
    echo "    User git"
    echo "    IdentitiesOnly yes"
  } >>"$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
  echo "Wrote ~/.ssh/config with 1Password IdentityAgent."
fi

# Allowed signers: principal (email) + key
if [ -z "${GIT_EMAIL:-}" ]; then
  echo "Git user.email is empty. Set it first, e.g.:"
  echo "  git config --global user.email 'you@example.com'"
  exit 1
fi

# Normalize line endings and write allowed_signers
printf '%s %s\n' "$GIT_EMAIL" "$PUBKEY" >"$HOME/.ssh/allowed_signers"
# Strip CRLF if any
sed -i 's/\r$//' "$HOME/.ssh/allowed_signers"
chmod 600 "$HOME/.ssh/allowed_signers"

# Git signing config (SSH)
git config --global gpg.format ssh
git config --global gpg.ssh.program "$OP_SSH_SIGN"
git config --global commit.gpgsign true
git config --global gpg.ssh.allowedSignersFile "$HOME/.ssh/allowed_signers"

# IMPORTANT: Set user.signingkey to the **public key** string (not a file path)
git config --global user.signingkey "$PUBKEY"

# Write public key for easy access (PUBLIC ONLY; no private key on disk)
echo "$PUBKEY" >"$HOME/.ssh/id_ed25519.pub"
chmod 644 "$HOME/.ssh/id_ed25519.pub"

# Pre-trust GitHub host key to avoid first-ssh prompt (idempotent)
touch "$HOME/.ssh/known_hosts"
chmod 600 "$HOME/.ssh/known_hosts"
ssh-keygen -F github.com -f "$HOME/.ssh/known_hosts" >/dev/null 2>&1 || {
  ssh-keyscan -t rsa,ed25519 github.com >>"$HOME/.ssh/known_hosts" 2>/dev/null || true
}
echo "✓ Configured git to sign with 1Password SSH key from item: $OP_SSH_ITEM"
echo "  Principal: $GIT_EMAIL"
echo "  Allowed signers: $HOME/.ssh/allowed_signers"
