#!/usr/bin/env bash
set -euo pipefail

# Requirements
for cmd in gh fzf git; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing $cmd"
    exit 1
  }
done

mkdir -p "$HOME/repos"

# Ensure GitHub CLI is authenticated
if ! gh auth status >/dev/null 2>&1; then
  echo "==> Logging in to GitHub CLI…"
  gh auth login -s 'repo,read:org' -w
fi

ME=$(gh api user -q .login)

ALL=0
while [[ $# -gt 0 ]]; do
  case "$1" in
  --all) ALL=1 ;;
  *)
    echo "Unknown flag: $1"
    exit 1
    ;;
  esac
  shift
done

echo "==> Gathering repositories…"

# TSV: name \t owner \t sshUrl \t visibility
gh repo list "$ME" --limit 1000 --json name,sshUrl,owner,visibility \
  --jq '.[] | [.name, .owner.login, .sshUrl, .visibility] | @tsv' \
  >/tmp/_gh_user.tsv

gh api user/orgs -q '.[].login' | while read -r ORG; do
  gh repo list "$ORG" --limit 1000 --json name,sshUrl,owner,visibility \
    --jq '.[] | [.name, .owner.login, .sshUrl, .visibility] | @tsv'
done >/tmp/_gh_org.tsv || true

# De-dup
cat /tmp/_gh_user.tsv /tmp/_gh_org.tsv 2>/dev/null | sort -u >/tmp/_gh_all.tsv || true
[[ -s /tmp/_gh_all.tsv ]] || {
  echo "No repositories found."
  exit 0
}

# Interactive multi-select (Space/Tab to mark, Enter to confirm)
if [[ $ALL -eq 1 ]]; then
  SEL=$(cat /tmp/_gh_all.tsv)
else
  SEL=$(fzf -m \
    --delimiter=$'\t' \
    --with-nth=1,2,4 \
    --prompt="Select repos (Space/Tab=mark, Enter=confirm) > " \
    </tmp/_gh_all.tsv) || {
    echo "No selection."
    exit 0
  }
fi

echo
echo "==> Cloning / fetching into ~/repos …"
echo

# Parse TSV exactly; NO pretty columns anywhere
while IFS=$'\t' read -r name owner url vis; do
  [[ -z "${name:-}" ]] && continue

  dest="$HOME/repos/$name"

  # If a repo with same name exists but points to a different remote, suffix with -owner
  if [[ -d "$dest/.git" ]]; then
    current_url=$(git -C "$dest" remote get-url origin 2>/dev/null || echo '')
    if [[ -n "$current_url" && "$current_url" != "$url" ]]; then
      dest="$HOME/repos/${name}-${owner}"
    fi
  elif [[ -e "$dest" ]]; then
    dest="$HOME/repos/${name}-${owner}"
  fi

  if [[ -d "$dest/.git" ]]; then
    echo "→ $owner/$name exists → fetch"
    git -C "$dest" remote set-url origin "$url" >/dev/null 2>&1 || true
    git -C "$dest" fetch --all --prune --tags
  else
    echo "→ Cloning $owner/$name → $dest"
    git clone "$url" "$dest"
  fi
done <<<"$SEL"

echo
echo "==> Done."
