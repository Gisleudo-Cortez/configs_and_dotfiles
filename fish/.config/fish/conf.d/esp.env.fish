## ESP Rust toolchain environment (espup)
# espup generates ~/export-esp.sh in POSIX syntax after install/update; fish
# cannot source it. Parse it here instead, so `espup update` regenerations
# (which bump the versioned toolchain paths) are picked up automatically.
# Sets: LIBCLANG_PATH (Xtensa clang libs) and prepends the xtensa-esp-elf
# GCC linker bin dir to PATH.

if test -f $HOME/export-esp.sh
    for line in (string split \n < $HOME/export-esp.sh)
        if string match -q 'export LIBCLANG_PATH=*' -- $line
            set -gx LIBCLANG_PATH (string replace -r '^export LIBCLANG_PATH="?([^"]*)"?$' '$1' -- $line)
        else if string match -q 'export PATH=*' -- $line
            set -gx PATH (string replace -r '^export PATH="?([^"]+):\$PATH"?$' '$1' -- $line) $PATH
        end
    end
end
