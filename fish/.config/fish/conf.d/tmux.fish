if status is-interactive
    and not set -q TMUX
    tmux attach -t base || tmux new -s base
end
