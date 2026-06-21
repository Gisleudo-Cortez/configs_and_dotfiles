## Useful aliases

# Replace ls with eza
alias ls 'eza -al --color=always --group-directories-first --icons' # preferred listing
alias lsz 'eza -al --color=always --total-size --group-directories-first --icons' # include file size
alias la 'eza -a --color=always --group-directories-first --icons' # all files and dirs
alias ll 'eza -l --color=always --group-directories-first --icons' # long format
alias lt 'eza -aT --color=always --group-directories-first --icons' # tree listing
alias l. 'eza -ald --color=always --group-directories-first --icons .*' # show only dotfiles

# Replace some more things with better alternatives
alias cat 'bat --style header --style snip --style changes --style header'
if not test -x /usr/bin/yay && test -x /usr/bin/paru
    alias yay paru
end

# Common use — navigation aliases stay as aliases (not worth abbreviating)
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'
alias ...... 'cd ../../../../..'

# Replace grep family (shadow system commands)
alias grep 'ugrep --color=auto'
alias egrep 'ugrep -E --color=auto'
alias fgrep 'ugrep -F --color=auto'

## abbreviations — interactive shortcuts (expand on Space/Enter)

# System / package management
abbr big 'expac -H M "%m\t%n" | sort -h | nl'
abbr cls 'clear'
abbr dir 'dir --color=auto'
abbr fixpacman 'sudo rm /var/lib/pacman/db.lck'
abbr gitpkg 'pacman -Q | grep -i "\-git" | wc -l'
abbr hw 'hwinfo --short'
abbr ip 'ip -color'
abbr psmem 'ps auxf | sort -nr -k 4'
abbr psmem10 'ps auxf | sort -nr -k 4 | head -10'
abbr rmpkg 'sudo pacman -Rdd'
abbr tarnow 'tar -acf '
abbr untar 'tar -zxvf '
abbr upd_force 'sudo pacman -Syyu && paru -Syyu'

# Get fastest mirrors
abbr mirror 'sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist'
abbr mirrora 'sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist'
abbr mirrord 'sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist'
abbr mirrors 'sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist'

# Help people new to Arch
abbr tb 'nc termbin.com 9999'
abbr helpme 'echo "To print basic information about a command use tldr <command>"'

# Get the error messages from journalctl
abbr jctl 'journalctl -p 3 -xb'

# Recent installed packages
abbr rip 'expac --timefmt="%Y-%m-%d %T" "%l\t%n %v" | sort | tail -200 | nl'

# Custom aliases
abbr backup_all 'sudo bash $HOME/Documents/Estudos/07-tools-and-infrastructure/Bash_Scripts/mount_storage_backup.sh && bash $HOME/Documents/Estudos/07-tools-and-infrastructure/Bash_Scripts/backup_all.sh'
abbr source_fish 'source $HOME/Documents/configs_and_dotfiles/fish/.config/fish/config.fish'
abbr save_fish_config 'cp ~/.config/fish/config.fish $conf/fish/.config/fish/config.fish && cp ~/.config/fish/conf.d/aliases.fish $conf/fish/.config/fish/conf.d/aliases.fish'
abbr print_file 'lp -d EPSON_L3210_Series'
abbr rs 'rsync -avP'
abbr update 'sudo pacman -Syu && paru -Syu && flatpak update'

# Mullvad VPN region switching
abbr vpn-br 'mullvad relay set location br for'
abbr vpn-us 'mullvad relay set location us mia'
abbr vpn-jp 'mullvad relay set location jp tyo'
abbr vpn-eu 'mullvad relay set location de fra'

# tool calls
abbr nv 'nvim .'
abbr mk 'mkdir -p'
abbr mkdir 'mkdir -p' # just in case i type the full command :)

# Custom launch parameters
abbr anki_launch 'LIBGL_ALWAYS_SOFTWARE=1 anki'

# Quickshell reload
abbr qs-reload 'pkill quickshell 2>/dev/null; quickshell &'

## abbreviations — navigation / yazi
abbr yal "yazi ~/Documents/Lonam/"
abbr yag "yazi ~/Documents/GEG/"
abbr cff 'nvim ~/.config/fish/'
abbr cfq "nvim ~/.config/quickshell/"
abbr cfh "nvim ~/.config/hypr/"
abbr cfk "nvim ~/.config/kitty/"

## git
# --- Status & Diffing ---
abbr gs "git status"
abbr gd "git diff"
abbr gds "git diff --staged"
abbr gdc "git diff --cached"

# --- Staging & Committing ---
abbr ga "git add"
abbr gaa "git add ."
abbr gau "git add -u"
abbr gc "git commit -m"
abbr gca "git commit -a -m"
abbr gcam "git commit --amend -m"
abbr gcnm "git commit --amend --no-edit"
abbr gfix "git commit -a --amend -C HEAD"
abbr greset "git reset HEAD --"

# --- Branching ---
abbr gb "git branch"
abbr gba "git branch -a"
abbr gco "git checkout"
abbr gcb "git checkout -b"
abbr gbd "git branch -d"
abbr gbD "git branch -D"
abbr gbm "git branch -m"
abbr gbM "git branch -M"

# --- Remotes, Pushing & Pulling ---
abbr gph "git push"
abbr gpl "git pull"
abbr gpr "git pull --rebase"
abbr gpo "git push -u origin (git rev-parse --abbrev-ref HEAD)"
abbr gf "git fetch"
abbr gfa "git fetch --all --prune"
abbr grv "git remote -v"
abbr gra "git remote add"
abbr grr "git remote remove"
abbr grset "git remote set-url"

# --- Merging & Rebasing ---
abbr gm "git merge"
abbr gma "git merge --abort"
abbr gmc "git merge --continue"
abbr gr "git rebase"
abbr grba "git rebase --abort"
abbr grc "git rebase --continue"
abbr gri "git rebase -i"

# --- Logging & History ---
abbr gl "git log --oneline --graph --decorate --all"
abbr gll "git log --pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s' --date=short --graph"
abbr gls "git log --stat"
abbr gsh "git show"

# --- Stashing ---
abbr gst "git stash"
abbr gstp "git stash pop"
abbr gsta "git stash apply"
abbr gstd "git stash drop"
abbr gstl "git stash list"
abbr gsts "git stash show -p"

# --- Ignoring & Cleaning ---
abbr gcl "git clone"
abbr gignore "git update-index --assume-unchanged"
abbr gunignore "git update-index --no-assume-unchanged"
abbr gclean "git clean -fd"
abbr gcleani "git clean -fd -i"

# --- Configuration ---
abbr gcfgl "git config --local --list"
abbr gcfgg "git config --global --list"
abbr gcfgse "git config --global --edit"