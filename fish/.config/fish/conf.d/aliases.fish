# eza views
alias ls="eza -lh --group-directories-first --icons=auto"
alias lsa="ls -a"
alias lt="eza --tree --level=3 --long --icons --git"
alias lta="lt -a"
alias vim="nvim"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ff='fzf --preview "bat --style=numbers --color=always {}"'
alias gst='git status'
alias gs='git status -sb'

# quick open
function open
    command xdg-open $argv >/dev/null 2>&1 &
end

# frequent short-hands as *abbr* (expand in editor)
abbr -a g git
abbr -a d docker
abbr -a r rails

function gcm
    git commit -m $argv
end
function gcam
    git commit -a -m $argv
end
function gcad
    git commit -a --amend $argv
end

function n
    if test (count $argv) -eq 0
        nvim .
    else
        nvim $argv
    end
end
