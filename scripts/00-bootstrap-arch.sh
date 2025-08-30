#!/usr/bin/env bash
set -euo pipefail

if ! sudo -v; then
  echo "This script needs sudo privileges." >&2
  exit 1
fi

if ! command -v pacman >/dev/null 2>&1 || [ ! -f /etc/arch-release ]; then
  echo "This bootstrap is for Arch/Omarchy only." >&2
  exit 1
fi

echo "Installing base packages"
sudo pacman -Syu --needed git stow tmux fish starship zoxide fzf ripgrep bat neovim reflector github-cli

echo "==> Refreshing mirrors with reflector"
sudo reflector --country --age 48 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || true

FISH_BIN="$(command -v fish)"
if ! grep -q "$FISH_BIN" /etc/shells; then
  echo "==> Adding $FISH_BIN to /etc/shells"
  echo "$FISH_BIN" | sudo tee -a /etc/shells >/dev/null
fi
if [ "${SHELL:-}" != "$FISH_BIN" ]; then
  echo "==> Setting default shell to fish"
  chsh -s "$FISH_BIN"
fi

# CapsLock -> Control
if command -v hyprctl >/dev/null 2>&1; then
  HYPR=~/.config/hypr/hyprland.conf
  mkdir -p "$(dirname "$HYPR")"
  grep -q 'kb_options = ctrl:nocaps' "$HYPR" 2>/dev/null || {
    printf "\ninput {\n    kb_options = ctrl:nocaps\n}\n" >>"$HYPR"
    echo "==> Set Caps as Ctrl in Hyprland config"
  }
fi

mkdir -p "$HOME/repos"

echo "==> Bootstrap complete. You may need to log out/in for default shell & keyboard changes."
