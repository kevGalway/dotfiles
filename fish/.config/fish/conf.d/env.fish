set -x EDITOR nvim
set -x SUDO_EDITOR $EDITOR
set -x BAT_THEME ansi
fish_add_path -g ~/.local/bin ./bin

set -gx LESS -R
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
