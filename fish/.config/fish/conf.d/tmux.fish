if status is-interactive; and status is-login; and not set -q TMUX
    tmux attach -t base 2>/dev/null; or tmux new -s base
end
