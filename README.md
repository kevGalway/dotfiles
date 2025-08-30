
## Setup
```bash
git clone git@github.com:kev/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
./scripts/00-bootstrap-arch.sh
./scripts/02-install-extra.sh
./scripts/05-prune-defaults.sh
./scripts/10-stow.sh
./scripts/15-git-setup.sh
./scripts/20-clone-repos-gh.sh
