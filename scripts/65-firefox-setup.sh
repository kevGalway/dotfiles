#!/usr/bin/env bash
set -euo pipefail

# --- config ---------------------------------------------------------------
ARKENFOX_BASE="https://raw.githubusercontent.com/arkenfox/user.js/master"
REPO_ROOT="$(cd -- "$(dirname "$0")/.." && pwd)"
POLICY_SRC="$REPO_ROOT/firefox/policies.json"        # optional: if present, we install it
OVERRIDES_SRC="$REPO_ROOT/firefox/user-overrides.js" # we copy this into profile (empty ok)
PROFILES_INI="$HOME/.mozilla/firefox/profiles.ini"

log() { printf '\033[1;36m==> %s\033[0m\n' "$*"; }
die() {
  echo "ERROR: $*" >&2
  exit 1
}

need() { command -v "$1" >/dev/null 2>&1 || die "Missing $1"; }

fetch() {
  local url="$1" dst="$2"
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$dst" "$url"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dst"
  else
    die "Need wget or curl"
  fi
}

# Resolve Firefox Dev Edition profile dir (Name=dev-edition-default preferred)
find_dev_profile() {
  local p
  if [[ -f "$PROFILES_INI" ]]; then
    # 1) exact Name=dev-edition-default
    p="$(awk -F= -v HOME="$HOME" '
      /^\[Profile[0-9]+\]$/ {in=1; name=path=rel=""; next}
      /^\[/ {in=0}
      in && $1=="Name" {name=$2}
      in && $1=="Path" {path=$2}
      in && $1=="IsRelative" {rel=$2}
      END { if (name=="dev-edition-default")
              print (rel=="1" ? HOME"/.mozilla/firefox/"path : path) }' "$PROFILES_INI")"
    [[ -n "${p:-}" && -d "$p" ]] && {
      echo "$p"
      return
    }

    # 2) any Name matching dev-edition-default
    p="$(awk -F= -v HOME="$HOME" '
      /^\[Profile[0-9]+\]$/ {in=1; name=path=rel=""; next}
      /^\[/ {in=0}
      in && $1=="Name" {name=$2}
      in && $1=="Path" {path=$2}
      in && $1=="IsRelative" {rel=$2}
      { if (in && name ~ /dev-edition-default/) {
          print (rel=="1" ? HOME"/.mozilla/firefox/"path : path); exit
        } }' "$PROFILES_INI")"
    [[ -n "${p:-}" && -d "$p" ]] && {
      echo "$p"
      return
    }
  fi

  # 3) glob fallback
  p="$(ls -d "$HOME"/.mozilla/firefox/*.dev-edition-default* 2>/dev/null | head -n1 || true)"
  [[ -n "${p:-}" && -d "$p" ]] && {
    echo "$p"
    return
  }

  return 1
}

install_policies_dev() {
  [[ -f "$POLICY_SRC" ]] || {
    log "No policies.json found (skip)"
    return 0
  }
  local distro_dir="/usr/lib/firefox-developer-edition/distribution"
  local dst="$distro_dir/policies.json"
  log "Installing policies.json → $dst"
  sudo mkdir -p "$distro_dir"
  sudo install -m 0644 "$POLICY_SRC" "$dst"
  echo "✓ policies.json installed. Verify in about:policies"
}

ensure_firefox_closed() {
  if pgrep -x firefox >/dev/null 2>&1; then
    die "Firefox is running. Please close it completely and re-run."
  fi
}

# --- main -----------------------------------------------------------------
main() {
  need awk
  need bash

  local profile
  if ! profile="$(find_dev_profile)"; then
    die "Could not find Firefox Dev Edition profile. Launch Dev Edition once, then re-run."
  fi
  log "Using Dev Edition profile: $profile"

  ensure_firefox_closed

  # Download official files straight into the profile
  log "Fetching arkenfox files"
  fetch "$ARKENFOX_BASE/user.js" "$profile/user.js"
  fetch "$ARKENFOX_BASE/updater.sh" "$profile/updater.sh"
  fetch "$ARKENFOX_BASE/prefsCleaner.sh" "$profile/prefsCleaner.sh"
  chmod +x "$profile/updater.sh" "$profile/prefsCleaner.sh"

  # Place your (empty) overrides file
  if [[ -f "$OVERRIDES_SRC" ]]; then
    install -m 0644 "$OVERRIDES_SRC" "$profile/user-overrides.js"
  else
    : >"$profile/user-overrides.js"
    chmod 0644 "$profile/user-overrides.js"
  fi

  # Backup any existing user.js once
  [[ -f "$profile/user.js" && ! -f "$profile/user.js.bak" ]] &&
    cp "$profile/user.js" "$profile/user.js.bak" || true

  # Run the official updater to append overrides, then tidy prefs
  log "Running updater.sh"
  (cd "$profile" && bash ./updater.sh)

  log "Running prefsCleaner.sh"
  (cd "$profile" && bash ./prefsCleaner.sh)

  install_policies_dev

  echo
  echo "✓ Arkenfox applied to: $profile"
  echo "   - Restart Firefox Developer Edition (fully quit, then open)."
  echo "   - Verify in about:policies (Active) and about:config (e.g. privacy.fingerprintingProtection = true)."
}

main "$@"
