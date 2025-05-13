#!/usr/bin/env fish

# get every directory, sorted
set dirs (find . -type d | sort)

for dir in $dirs
    # strip leading “./”
    set label (string replace -r '^./' '' -- $dir)
    if test $label = ''
        set label '.'
    end
    printf "%s:\n" $label

    for file in (find $dir -maxdepth 1 -type f | sort)
        printf "-> %s:\n" (basename $file)
        sed 's/^/   /' $file
    end

    echo
end

