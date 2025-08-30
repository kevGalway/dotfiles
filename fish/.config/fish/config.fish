if not status is-interactive
    exit
end

set -x SHELL (which fish)

# Quiet the default banner
set -g fish_greeting
