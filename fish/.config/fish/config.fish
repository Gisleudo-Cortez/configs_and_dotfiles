# Set values
# Hide welcome message & ensure we are reporting fish as shell
set fish_greeting
set VIRTUAL_ENV_DISABLE_PROMPT "1"
set -x SHELL /usr/bin/fish

# Use bat for man pages
set -xU MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -xU MANROFFOPT "-c"

# Hint to exit PKGBUILD review in Paru
set -x PARU_PAGER "less -P \"Press 'q' to exit the PKGBUILD review.\""

## Export variable need for qt-theme
if type "qtile" >> /dev/null 2>&1
   set -x QT_QPA_PLATFORMTHEME "qt5ct"
end

# Set settings for https://github.com/franciscolourenco/done
set -U __done_min_cmd_duration 10000
set -U __done_notification_urgency_level low

## Environment setup

# Apply .profile: use this to put fish compatible .profile stuff in
if test -f ~/.fish_profile
  source ~/.fish_profile
end

# Add ~/.local/bin to PATH
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end

# Add depot_tools to PATH
if test -d ~/Applications/depot_tools
    if not contains -- ~/Applications/depot_tools $PATH
        set -p PATH ~/Applications/depot_tools
    end
end

## Starship prompt
if status --is-interactive
   source ("/usr/bin/starship" init fish --print-full-init | psub)
end

## Advanced command-not-found hook
source /usr/share/doc/find-the-command/ftc.fish

## Functions
# Functions needed for !! and !$ https://github.com/oh-my-fish/plugin-bang-bang
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end

if [ "$fish_key_bindings" = fish_vi_key_bindings ];
  bind -Minsert ! __history_previous_command
  bind -Minsert '$' __history_previous_command_arguments
else
  bind ! __history_previous_command
  bind '$' __history_previous_command_arguments
end

# Fish command history
function history
    builtin history --show-time='%F %T '
end

function backup --argument filename
    cp $filename $filename.bak
end

# Copy DIR1 DIR2
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
	set from (echo $argv[1] | string trim --right --chars=/)
	set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

# Cleanup local orphaned packages
function cleanup
    while pacman -Qdtq
        sudo pacman -R (pacman -Qdtq)
        if test "$status" -eq 1
           break
        end
    end
end


## Run fastfetch if session is interactive
if status --is-interactive && type -q fastfetch
   fastfetch --config neofetch.jsonc
end



# Custom functions 
function unzip_all
    for file in *.zip
        set dir_name (basename "$file" .zip)
        mkdir -p "$dir_name"; and unzip -o "$file" -d "$dir_name"
    end
end

# Custom env vars
set -gx loja  $HOME/Documents/Lonam
set -gx estudos  $HOME/Documents/Estudos
set -gx ourodata  $HOME/Documents/ourodata
set -gx geg  $HOME/Documents/GEG
set -gx portfolio  $HOME/Documents/Portfolio
set -gx pessoal  $HOME/Documents/Pessoal
set -gx boot_dev $HOME/Documents/Estudos/boot_dev/
set -gx conf $HOME/Documents/configs_and_dotfiles/

# go env setup
export PATH="$PATH:$(go env GOBIN):$(go env GOPATH)/bin"

# protontricks env variables
set -gx WINE "/usr/bin/wine"
set -gx WINETRICKS "/usr/bin/winetricks"

# Add cargo to PATH
set -gx PATH $HOME/.cargo/bin $PATH

# change editor to nvim 
set -gx EDITOR /usr/bin/nvim

# Generated for envman. Do not edit.
test -s ~/.config/envman/load.fish; and source ~/.config/envman/load.fish

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/nero/.lmstudio/bin
# End of LM Studio CLI section

# Ollama performance settings
set -gx OLLAMA_FLASH_ATTENTION 1
set -gx OLLAMA_MAX_LOADED_MODELS 1
set -gx OLLAMA_KV_CACHE_TYPE q8_0
set -gx OLLAMA_NUM_PARALLEL 1
set -gx OLLAMA_NUM_CTX 35000

