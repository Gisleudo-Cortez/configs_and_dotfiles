#!/usr/bin/env bash
# Arch Linux post-install script (idempotent, supports --dry-run)
set -euo pipefail

LOCK="/var/lock/arch-postinstall.lock"
LOGGED_USER="$(logname)"
GITHUB_DIR="/home/${LOGGED_USER}/Downloads/github"
DRY_RUN=false
[[ ${1:-} == "--dry-run" ]] && DRY_RUN=true

run() { $DRY_RUN && echo "DRY-RUN: $*" || eval "$*"; }
msg() { echo -e "\e[1;34m[*]\e[0m $*"; }

[[ -e "$LOCK" ]] && { echo "Another run in progress." >&2; exit 1; }
echo $$ > "$LOCK"; trap 'rm -f "$LOCK"' EXIT

refresh_system() {
  msg "System upgrade"
  run "pacman -Syyu --noconfirm"
}

install_official() {
  msg "Installing official packages"
  local pkgs=(
    cargo go neovim vim alacritty fish dbeaver qalculate-gtk
    docker docker-buildx kdeconnect nodejs npm postgresql
    rclone brave thunderbird kate zen-browser-bin
    obsidian obs-studio ttf-jetbrains-mono
    ttf-nerd-fonts-symbols delve gopls 
  )
  run "pacman -S --needed --noconfirm ${pkgs[*]}"
}

enable_services() {
  msg "Enabling services"
  run "systemctl enable --now docker.service"
  run "systemctl enable --now libvirtd.service virtlogd.socket"
  run "systemctl enable --now postgresql.service"
  run "usermod -aG docker,libvirt $LOGGED_USER"
}

init_postgres() {
  msg "Initializing PostgreSQL database"
  run "sudo -iu postgres bash -c '[ -d /var/lib/postgres/base ] || initdb -D /var/lib/postgres'"
}

deploy_dotfiles() {
  msg "Deploying dotfiles"
  run "sudo -u $LOGGED_USER bash -c '
    mkdir -p \"$GITHUB_DIR\"
    git -C \"$GITHUB_DIR\" clone --depth=1 https://github.com/Gisleudo-Cortez/configs_and_dotfiles.git || true
    command -v rsync >/dev/null && {
      rsync -a \"$GITHUB_DIR/configs_and_dotfiles/nvim/\" \"/home/$LOGGED_USER/.config/nvim/\"
      rsync -a \"$GITHUB_DIR/configs_and_dotfiles/fish/\" \"/home/$LOGGED_USER/.config/fish/\"
    }
  '"
}

health_check() {
  $DRY_RUN && return
  msg "Health check"
  local bins=(cargo go nvim vim zen-browser-bin alacritty fish vscodium dbeaver tldr docker)
  for b in "${bins[@]}"; do
    command -v "$b" &>/dev/null || echo "Missing: $b"
  done
  systemctl --quiet is-active docker || echo "Docker inactive"
}

refresh_system
install_official
enable_services
init_postgres
deploy_dotfiles
health_check

msg "Finished — reboot recommended."
