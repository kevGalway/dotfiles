# System setup and Dotfiles

Goal: Quickly rebuild (and define) my Arch/Omarchy setup to work cross laptop. Be able to wipe a machine and fully re-provision in ~30 mins. No important state on machines. 

This is built for me and my setup. No guarantees that it will work for others. 

## What it does
- Arch base system
- Omarchy for the opinionated initial setup.
- Setups my tools (fish shell, tmux, nvim, custom config)
- Install my stuff, remove what I don't need that Omarchy installed. 
- Symlink these dotfiles via stow
- Install some dev tools via install-extra
- Setup 1password + get working with cli for ssh keys, api, aws etc. 
- Clone repos selectively.
- TODO: configure base browser plugins (uBlock Origin, Firefox Containers, Password manager)



## Setup
```bash
git clone git@github.com:kev/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
./scripts/run-all.sh
```


