#!/usr/bin/env bash

# Script to accept one or more paths relative to the home directory,
# then replicate each into a specific structure within the current directory.
# Example: if an input path is ".config/nvim" (referring to $HOME/.config/nvim),
# it will be copied to ./nvim/.config/nvim in the current working directory.

set -euo pipefail # Exit on error, undefined variable, or pipe failure

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <path1_relative_to_home> [path2_relative_to_home ...]"
    echo "Example: $0 .config/nvim .zshrc documents/another_dir"
    exit 1
fi

echo "Starting configuration backup for multiple paths..."
echo "================================================="
overall_success=true

for USER_PATH_ARG in "$@"; do
    echo ""
    echo "Processing path: '$USER_PATH_ARG'..."
    echo "--------------------------------------"

    # Normalize the input path: remove leading/trailing slashes
    USER_PATH_RELATIVE_TO_HOME=$(echo "$USER_PATH_ARG" | sed 's:^/*\(.*\)*/*$:\1:')

    if [[ -z "$USER_PATH_RELATIVE_TO_HOME" ]]; then
        echo "⚠ Warning: Skipped empty or invalid path derived from '$USER_PATH_ARG'."
        overall_success=false
        continue
    fi

    FULL_SOURCE_PATH="$HOME/$USER_PATH_RELATIVE_TO_HOME"

    if [[ ! -e "$FULL_SOURCE_PATH" ]]; then
        echo "⚠ Warning: Source path '$FULL_SOURCE_PATH' (from argument '$USER_PATH_ARG') does not exist. Skipping."
        overall_success=false
        continue
    fi

    # Determine the prefix directory for the destination based on the basename of the full source path.
    DEST_PREFIX_DIR=$(basename "$FULL_SOURCE_PATH")

    # The final destination path within the current directory.
    FINAL_DESTINATION_PATH_IN_PWD="./$DEST_PREFIX_DIR/$USER_PATH_RELATIVE_TO_HOME"

    echo "Source: $FULL_SOURCE_PATH"
    echo "Target location: $(pwd)/$DEST_PREFIX_DIR/$USER_PATH_RELATIVE_TO_HOME"

    # Create the necessary parent directories for the final destination path.
    DEST_PARENT_DIR=$(dirname "$FINAL_DESTINATION_PATH_IN_PWD")

    if [[ "$DEST_PARENT_DIR" != "." ]]; then # Avoid mkdir -p . which is harmless but unnecessary
        echo "Creating destination directory structure: $DEST_PARENT_DIR"
        if ! mkdir -p "$DEST_PARENT_DIR"; then
            echo "⚠ Error: Failed to create directory structure '$DEST_PARENT_DIR' for argument '$USER_PATH_ARG'. Skipping."
            overall_success=false
            continue
        fi
    else
        # This case handles when FINAL_DESTINATION_PATH_IN_PWD has no directory components other than the current dir.
        # e.g. if USER_PATH_RELATIVE_TO_HOME is "myfile.txt", then DEST_PREFIX_DIR is "myfile.txt",
        # FINAL_DESTINATION_PATH_IN_PWD is "./myfile.txt/myfile.txt", and DEST_PARENT_DIR is "./myfile.txt".
        # If USER_PATH_RELATIVE_TO_HOME is "single_dir", then DEST_PREFIX_DIR is "single_dir",
        # FINAL_DESTINATION_PATH_IN_PWD is "./single_dir/single_dir", and DEST_PARENT_DIR is "./single_dir".
        # If DEST_PARENT_DIR was simply ".", it means FINAL_DESTINATION_PATH_IN_PWD itself is a direct child of pwd,
        # which shouldn't happen with the "./$DEST_PREFIX_DIR/$USER_PATH_RELATIVE_TO_HOME" structure
        # unless USER_PATH_RELATIVE_TO_HOME was empty or complexly resolved to it, handled earlier.
        # This message is mostly for clarity if DEST_PARENT_DIR is just the DEST_PREFIX_DIR itself.
        echo "Destination structure starts directly under './$DEST_PREFIX_DIR/' or is the current directory for very short paths."
    fi

    # Perform the copy.
    echo "Copying '$FULL_SOURCE_PATH' to '$FINAL_DESTINATION_PATH_IN_PWD'..."
    if cp -rT "$FULL_SOURCE_PATH" "$FINAL_DESTINATION_PATH_IN_PWD"; then
        echo "✓ Successfully copied '$USER_PATH_ARG'."
    else
        echo "⚠ Error during copy from '$FULL_SOURCE_PATH' to '$FINAL_DESTINATION_PATH_IN_PWD' for argument '$USER_PATH_ARG'. Skipping."
        overall_success=false
        continue # Continue to the next path argument
    fi
done

echo ""
echo "========================================"
if [[ "$overall_success" = true ]]; then
    echo "All configuration backups completed successfully!"
    exit 0
else
    echo "Configuration backup completed with one or more warnings/errors."
    exit 1
fi
