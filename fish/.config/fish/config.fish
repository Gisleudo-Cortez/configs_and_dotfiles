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

# Start ssh-agent only if not running
if not set -q SSH_AGENT_PID
    eval (ssh-agent -c)
end

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

## Useful aliases

# Replace ls with eza
alias ls 'eza -al --color=always --group-directories-first --icons' # preferred listing
alias lsz 'eza -al --color=always --total-size --group-directories-first --icons' # include file size
alias la 'eza -a --color=always --group-directories-first --icons'  # all files and dirs
alias ll 'eza -l --color=always --group-directories-first --icons'  # long format
alias lt 'eza -aT --color=always --group-directories-first --icons' # tree listing
alias l. 'eza -ald --color=always --group-directories-first --icons .*' # show only dotfiles

# Replace some more things with better alternatives
alias cat 'bat --style header --style snip --style changes --style header'
if not test -x /usr/bin/yay; and test -x /usr/bin/paru
    alias yay 'paru'
end


# Common use
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'
alias ...... 'cd ../../../../..'
alias big 'expac -H M "%m\t%n" | sort -h | nl'     # Sort installed packages according to size in MB (expac must be installed)
alias dir 'dir --color=auto'
alias fixpacman 'sudo rm /var/lib/pacman/db.lck'
alias gitpkg 'pacman -Q | grep -i "\-git" | wc -l' # List amount of -git packages
alias grep 'ugrep --color=auto'
alias egrep 'ugrep -E --color=auto'
alias fgrep 'ugrep -F --color=auto'
alias grubup 'sudo update-grub'
alias hw 'hwinfo --short'                          # Hardware Info
alias ip 'ip -color'
alias psmem 'ps auxf | sort -nr -k 4'
alias psmem10 'ps auxf | sort -nr -k 4 | head -10'
alias rmpkg 'sudo pacman -Rdd'
alias tarnow 'tar -acf '
alias untar 'tar -zxvf '
alias upd '/usr/bin/garuda-update'
alias vdir 'vdir --color=auto'
alias wget 'wget -c '

# Get fastest mirrors
alias mirror 'sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist'
alias mirrora 'sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist'
alias mirrord 'sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist'
alias mirrors 'sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist'

# Help people new to Arch
alias apt 'man pacman'
alias apt-get 'man pacman'
alias please 'sudo'
alias tb 'nc termbin.com 9999'
alias helpme 'echo "To print basic information about a command use tldr <command>"'
alias pacdiff 'sudo -H DIFFPROG=meld pacdiff'

# Get the error messages from journalctl
alias jctl 'journalctl -p 3 -xb'

# Recent installed packages
alias rip 'expac --timefmt="%Y-%m-%d %T" "%l\t%n %v" | sort | tail -200 | nl'

## Run fastfetch if session is interactive
if status --is-interactive && type -q fastfetch
   fastfetch --config neofetch.jsonc
end

# Custom aliases
alias cls='clear'
alias config_fish='nvim ~/.config/fish/config.fish'
alias backup_all='bash /home/nero/Documents/Estudos/Bash_Scripts/backup_all.sh'
alias backup_loja='bash /home/nero/Documents/Estudos/Bash_Scripts/back_up_loja.sh'
alias backup_pessoal='bash /home/nero/Documents/Estudos/Bash_Scripts/back_up_pessoal.sh'
alias backup_estudos='bash /home/nero/Documents/Estudos/Bash_Scripts/backup_estudos.sh'
alias backup='sudo bash /home/nero/Documents/Estudos/Bash_Scripts/mount_storage_backup.sh && backup_all'
alias source_fish='source ~/.config/fish/config.fish'
alias create_dc_folder='bash /home/nero/Documents/Estudos/Bash_Scripts/create_dc_folder.sh'
alias print_file='lp -d EPSON_L3210_Series'
alias save_fish_config='cp ~/.config/fish/config.fish $pessoal/dotfiles/config.fish'
alias estudos_env='source $estudos/estudos/bin/activate.fish'
alias ollama_update_models='bash /home/nero/Documents/Estudos/Bash_Scripts/ollama_update_models.sh'
alias ds "dust -d 2"
alias dua "dua interactive"
## abbreviations
abbr ya yazi
abbr sfl "sftp -r lonam:Documents/LONAM/"
abbr sfg "sftp -r lonam:Documents/GEG/"
abbr gtal "./gather_data.sh .config/nvim .zshrc .config/fish .config/hypr .config/kitty .config/waybar .config/starship .config/starship.toml .config/starship_cat.toml"

## git 
# --- Status & Diffing ---
alias gs "git status"
alias gd "git diff"                             # Show unstaged changes
alias gds "git diff --staged"                   # Show staged changes (same as gdc)
alias gdc "git diff --cached"                   # Show staged changes (alternative to gds)

# --- Staging & Committing ---
alias ga "git add"
alias gaa "git add ."                           # Add all changes in current directory
alias gau "git add -u"                          # Add all tracked files (update)
alias gc "git commit -m"
alias gca "git commit -a -m"                    # Add all tracked files and commit
alias gcam "git commit --amend -m"              # Amend last commit with a new message
alias gcnm "git commit --amend --no-edit"       # Amend last commit, keep existing message
alias gfix "git commit -a --amend -C HEAD"      # Add to last commit without changing message (stages all tracked files)
alias greset "git reset HEAD --"                # Unstage a file

# --- Branching ---
alias gb "git branch"
alias gba "git branch -a"                       # Show all branches (local and remote)
alias gco "git checkout"
alias gcb "git checkout -b"                     # Create and switch to a new branch
alias gbd "git branch -d"                       # Delete a local branch (safer: only if merged)
alias gbD "git branch -D"                       # Force delete a local branch
alias gbm "git branch -m"                       # Rename current local branch
alias gbM "git branch -M"                       # Force rename current local branch (even if new name exists)

# --- Remotes, Pushing & Pulling ---
alias gph "git push"
alias gpl "git pull"
alias gpr "git pull --rebase"                   # Pull and rebase
alias gpo "git push -u origin (git rev-parse --abbrev-ref HEAD)" # Push current branch to origin and set upstream
alias gf "git fetch"
alias gfa "git fetch --all --prune"             # Fetch all remotes and remove stale remote-tracking branches
alias grv "git remote -v"                       # List remotes
alias gra "git remote add"
alias grr "git remote remove"
alias grset "git remote set-url"

# --- Merging & Rebasing ---
alias gm "git merge"
alias gma "git merge --abort"                   # Abort a merge in progress
alias gmc "git merge --continue"                # Continue a merge in progress
alias gr "git rebase"
alias gra "git rebase --abort"                  # Abort a rebase in progress
alias grc "git rebase --continue"               # Continue a rebase in progress
alias gri "git rebase -i"                       # Interactive rebase

# --- Logging & History ---
alias gl "git log --oneline --graph --decorate --all" # Concise log of all branches
alias gll "git log --pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s' --date=short --graph" # Detailed, pretty log
alias gls "git log --stat"                      # Log with stats (files changed)
alias gsh "git show"                            # Show various types of objects (last commit by default)

# --- Stashing ---
alias gst "git stash"
alias gstp "git stash pop"
alias gsta "git stash apply"
alias gstd "git stash drop"
alias gstl "git stash list"
alias gsts "git stash show -p"                  # Show changes in latest stash as a patch

# --- Ignoring & Cleaning ---
alias gcl "git clone"
alias gignore "git update-index --assume-unchanged" # Ignore tracking changes to a file (locally)
alias gunignore "git update-index --no-assume-unchanged" # Resume tracking changes to a file (locally)
alias gclean "git clean -fd"                    # Remove untracked files and directories (USE WITH CAUTION!)
alias gcleani "git clean -fd -i"                # Remove untracked files and directories interactively (safer)

# --- Configuration ---
alias gcfgl "git config --local --list"         # List local git config
alias gcfgg "git config --global --list"        # List global git config
alias gcfgse "git config --global --edit"       # Edit global git config

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

# go env setup
export PATH="$PATH:$(go env GOBIN):$(go env GOPATH)/bin"

# protontricks env variables
set -gx WINE "/usr/bin/wine"
set -gx WINETRICKS "/usr/bin/winetricks"

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# change editor to nvim 
set -gx EDITOR /usr/bin/nvim
