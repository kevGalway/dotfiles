function compress
    if test (count $argv) -ne 1
        echo "Usage: compress <file-or-directory>"
        return 1
    end

    set target $argv[1]

    if not test -e $target
        echo "compress: '$target' not found"
        return 1
    end

    set dir (dirname $target)
    set base (basename $target)

    tar -czf "$base.tar.gz" -C "$dir" "$base"
end
