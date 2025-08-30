# Only define if zoxide is available
type -q z; and begin
    functions -q cd; and functions -c cd cd_bak
    function cd --wraps=cd
        if test (count $argv) -eq 0
            builtin cd ~
        else if test -d "$argv[1]"
            builtin cd "$argv[1]"
        else
            z $argv; and begin
                printf "\uf7a9 "
                pwd
            end; or echo "Directory not found"
        end
    end
end
