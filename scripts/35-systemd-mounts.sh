#!/usr/bin/env bash
set -euo pipefail

# Install per-machine systemd mount/automount units from machines/$HOST/systemd
# - Place .mount and optional .automount files in machines/<HOST>/systemd
# - This script copies them into /etc/systemd/system and enables them

ROOT_DIR="$(cd -- "$(dirname "$0")/.." && pwd)"
HOSTNAME_SHORT="${HOSTNAME:-$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo unknown)}"
SRC_DIR="$ROOT_DIR/machines/$HOSTNAME_SHORT/systemd"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "(skip) No per-machine systemd mounts at $SRC_DIR"
  exit 0
fi

units=( $(find "$SRC_DIR" -maxdepth 1 -type f -name '*.mount' -o -name '*.automount' | sort) )
if [[ ${#units[@]} -eq 0 ]]; then
  echo "(skip) No .mount/.automount units in $SRC_DIR"
  exit 0
fi

echo "==> Installing systemd mount units for host: $HOSTNAME_SHORT"

need_sudo=1
command -v sudo >/dev/null 2>&1 || need_sudo=0

copy_cmd=(install -Dm644)
reload_cmd=(systemctl daemon-reload)
enable_cmd=(systemctl enable --now)
start_cmd=(systemctl start)

if [[ $need_sudo -eq 1 ]]; then
  copy_cmd=(sudo install -Dm644)
  reload_cmd=(sudo systemctl daemon-reload)
  enable_cmd=(sudo systemctl enable --now)
  start_cmd=(sudo systemctl start)
fi

# Ensure mount points exist based on Where= in .mount units
for m in "${units[@]}"; do
  if [[ "$m" == *.mount ]]; then
    where=$(awk -F= '/^Where=/{print $2}' "$m" | head -n1 || true)
    if [[ -n "${where:-}" ]]; then
      if [[ $need_sudo -eq 1 ]]; then sudo mkdir -p "$where"; else mkdir -p "$where"; fi
    fi
  fi
done

# Copy unit files
for u in "${units[@]}"; do
  dest="/etc/systemd/system/$(basename "$u")"
  echo "→ Installing $(basename "$u")"
  "${copy_cmd[@]}" "$u" "$dest"
done

"${reload_cmd[@]}"

# Enable automounts first (if present) for on-demand mounting
for a in "${units[@]}"; do
  if [[ "$a" == *.automount ]]; then
    echo "→ Enabling $(basename "$a")"
    "${enable_cmd[@]}" "$(basename "$a")"
  fi
done

# For mounts without automounts, enable/start them directly
for m in "${units[@]}"; do
  if [[ "$m" == *.mount ]]; then
    base=$(basename "$m" .mount)
    if [[ ! -f "/etc/systemd/system/$base.automount" ]]; then
      echo "→ Enabling and starting $(basename "$m")"
      "${enable_cmd[@]}" "$base.mount" || true
      "${start_cmd[@]}" "$base.mount" || true
    fi
  fi
done

echo "==> Systemd mount units installed. Current mounts/automounts:"
systemctl list-units --type=automount,mount --no-pager | sed -n '1,200p' || true

