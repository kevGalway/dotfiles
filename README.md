## Setup
```bash
git clone git@github.com:kev/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles

# One-shot orchestrator (recommended)
./scripts/run-all.sh

# Or run steps manually
./scripts/00-bootstrap-arch.sh
./scripts/02-install-extra.sh        # installs from lists/packages.txt (official repos)
./scripts/05-prune-defaults.sh       # removes from lists/remove-packages.txt if installed
./scripts/10-stow.sh                 # symlink dotfiles (uses stow --adopt)
./scripts/15-git-setup.sh            # git name/email + SSH key
./scripts/20-clone-repos-gh.sh       # clone selected repos via gh
```
