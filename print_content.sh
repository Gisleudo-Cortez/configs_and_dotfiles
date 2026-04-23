#!/bin/bash

# Usage: ./print_contents.sh [directory]
# If no directory is specified, uses the current directory

DIR="${1:-.}"

if [[ ! -d "$DIR" ]]; then
    echo "Error: '$DIR' is not a valid directory" >&2
    exit 1
fi

find "$DIR" -type f | while read -r file; do
    if [[ -f "$file" && -r "$file" ]]; then
        # Skip binary files (optional)
        if file "$file" | grep -q "text\|empty"; then
            echo "$file"
            echo " - File content:"
            cat "$file"
            echo ""  # Add blank line between files
        else
            echo "$file"
            echo " - Binary file (skipped)"
            echo ""
        fi
    elif [[ ! -r "$file" ]]; then
        echo "$file"
        echo " - Permission denied"
        echo ""
    fi
done

