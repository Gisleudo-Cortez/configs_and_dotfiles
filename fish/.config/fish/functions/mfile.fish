function mfile
    if test (count $argv) -eq 0
        echo "Usage: mfile /path/to/file"
        return 1
    end

    set filepath $argv[1]
    set dirpath (dirname $filepath)

    # Create the directory if missing
    mkdir -p $dirpath

    # Create the file if missing
    if not test -e $filepath
        touch $filepath
        echo "Created: $filepath"
    else
        echo "File already exists: $filepath"
    end
end
