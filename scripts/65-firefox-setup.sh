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
  local best="" any="" in=0 name="" path="" rel=""
  local ini="$PROFILES_INI"

  [[ -f "$ini" ]] || return 1

  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
    "[Profile"*[0-9]"]")
      # starting a new profile section — reset fields
      in=1
      name=""
      path=""
      rel=""
      ;;
    "["*"]")
      # leaving a profile section
      in=0
      ;;
    Name=*)
      [[ $in -eq 1 ]] && name="${line#Name=}"
      ;;
    Path=*)
      [[ $in -eq 1 ]] && path="${line#Path=}"
      ;;
    IsRelative=*)
      [[ $in -eq 1 ]] && rel="${line#IsRelative=}"
      ;;
    esac

    # As soon as we have name+path+rel inside a section, consider it
    if [[ $in -eq 1 && -n $name && -n $path && -n $rel ]]; then
      local full
      if [[ "$rel" == "1" ]]; then
        full="$HOME/.mozilla/firefox/$path"
      else
        full="$path"
      fi

      if [[ -d "$full" ]]; then
        # exact preferred match
        if [[ "$name" == "dev-edition-default" ]]; then
          best="$full"
          break
        fi
        # fallback: anything containing dev-edition-default
        if [[ -z "$any" && "$name" == *dev-edition-default* ]]; then
          any="$full"
        fi
      fi

      # reset so we don’t reuse for the next profile block
      name=""
      path=""
      rel=""
    fi
  done <"$ini"

  if [[ -n "$best" ]]; then
    printf '%s\n' "$best"
    return 0
  fi
  if [[ -n "$any" ]]; then
    printf '%s\n' "$any"
    return 0
  fi

  # final glob fallback
  local guess
  guess="$(ls -d "$HOME"/.mozilla/firefox/*.dev-edition-default* 2>/dev/null | head -n1 || true)"
  [[ -n "$guess" && -d "$guess" ]] && {
    printf '%s\n' "$guess"
    return 0
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

  TEMPLATE_CONTAINERS_JSON="$REPO_ROOT/firefox/containers.json"
  if [[ -f "$TEMPLATE_CONTAINERS_JSON" ]]; then
    log "Seeding containers.json"
    install -m 0644 "$TEMPLATE_CONTAINERS_JSON" "$profile/containers.json"
  fi

  echo
  echo "✓ Arkenfox applied to: $profile"
  echo "   - Restart Firefox Developer Edition (fully quit, then open)."
  echo "   - Verify in about:policies (Active) and about:config (e.g. privacy.fingerprintingProtection = true)."
}

main "$@"
