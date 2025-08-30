function dumpproj --description 'Copy project text files to clipboard, respects .gitignore if in git repo'
    set -l max_kb 4096
    if test (count $argv) -ge 1
        set max_kb $argv[1]
    end

    set -l copier
    if type -q wl-copy
        set copier wl-copy
    else if type -q xclip
        set copier xclip -selection clipboard
    else
        echo "dumpproj: need wl-copy or xclip"
        return 1
    end

    set -l tmp (mktemp)

    if git rev-parse --is-inside-work-tree >/dev/null 2>&1
        git ls-files -z --cached --others --exclude-standard \
            | while read -z f
            test -z "$f"; and continue
            test -d "$f"; and continue
            set -l mime (file --mime-type -b -- "$f" 2>/dev/null)
            string match -rq '^text/' -- "$mime"; or continue
            set -l sz_kb (math (stat -c %s -- "$f") / 1024)
            if test "$sz_kb" -le "$max_kb"
                printf "\n=== %s ===\n" "$f" >>$tmp
                cat -- "$f" >>$tmp
            else
                printf "\n=== %s (skipped: %d KB > %d KB) ===\n" "$f" $sz_kb $max_kb >>$tmp
            end
        end
    else
        find . -type f -print0 | sort -z | while read -z f
            test -z "$f"; and continue
            test -d "$f"; and continue
            set -l mime (file --mime-type -b -- "$f" 2>/dev/null)
            string match -rq '^text/' -- "$mime"; or continue
            set -l sz_kb (math (stat -c %s -- "$f") / 1024)
            if test "$sz_kb" -le "$max_kb"
                printf "\n=== %s ===\n" "$f" >>$tmp
                cat -- "$f" >>$tmp
            else
                printf "\n=== %s (skipped: %d KB > %d KB) ===\n" "$f" $sz_kb $max_kb >>$tmp
            end
        end
    end

    $copier <$tmp
    set -l rc $status
    rm -f $tmp
    test $rc -eq 0; and echo "✓ Copied project text files to clipboard (≤ $max_kb KB each)."
end
