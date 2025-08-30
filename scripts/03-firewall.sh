#!/usr/bin/env bash
set -euo pipefail

if ! command -v ufw >/dev/null 2>&1; then
  echo "==> Installing ufw"
  sudo pacman -S --needed --noconfirm ufw
fi

echo "==> Enabling ufw service"
sudo systemctl enable --now ufw

echo "==> Setting default rules"
sudo ufw default deny incoming
sudo ufw default allow outgoing

echo "==> Firewall status:"
sudo ufw status verbose
