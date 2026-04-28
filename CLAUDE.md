# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles and system-setup scripts for an Arch Linux + Hyprland + Kitty + Fish desktop. Configs are managed with GNU Stow — each top-level directory mirrors `$HOME` and is stowed directly into it.

## Deploying dotfiles

```bash
# Deploy all configured stow packages (run as regular user, from repo root)
bash scripts/11-deploy-dotfiles.sh

# Preview without making changes
bash scripts/11-deploy-dotfiles.sh --dry-run
```

The stow packages currently deployed are: `fish`, `nvim`, `starship`, `hypr`, `kitty`, `waybar`. Each must contain the directory tree as it should appear under `$HOME` (e.g. `fish/.config/fish/config.fish` → `~/.config/fish/config.fish`).

## System setup scripts

Scripts in `scripts/` are numbered and meant to be run in order on a fresh Arch install. The orchestrator is:

```bash
# Run as root (drops to user for user-level scripts automatically)
sudo bash scripts/run-all.sh

# Dry-run to see what would happen
sudo bash scripts/run-all.sh --dry-run
```

Individual scripts that require root use `need_root`; scripts meant for a regular user use `need_user`. All scripts source `scripts/helpers.sh` for `run_cmd` / `run_cmd_user` helpers that respect `DRY_RUN`.

Package lists live in `scripts/packages-official.txt` (pacman) and `scripts/packages-aur.txt` (paru/yay).

## Architecture

### Stow layout

Each package directory maps to `$HOME`. Stow creates symlinks from `~/<path>` → `<repo>/<package>/<path>`. Adding files to a package: place them at the correct relative path under the package dir, then re-run `stow -Svt "$HOME" --adopt <package>`.

### Config structure

| Directory | Target | Notes |
|-----------|--------|-------|
| `fish/` | `~/.config/fish/` | Shell config, aliases, functions, plugin conf.d |
| `nvim/` | `~/.config/nvim/` | Neovim — see `nvim/.config/nvim/CLAUDE.md` for details |
| `hypr/` | `~/.config/hypr/` | Hyprland WM, hypridle, hyprlock, hyprpaper |
| `kitty/` | `~/.config/kitty/` | Terminal emulator |
| `waybar/` | `~/.config/waybar/` | Status bar + shell scripts |
| `starship/` | `~/.config/` | Starship prompt (`starship.toml`) |
| `rofi/` | `~/.config/rofi/` | App launcher |
| `mako/` | `~/.config/mako/` | Notification daemon |
| `wlogout/` | `~/.config/wlogout/` | Logout menu |

### Hyprland config structure

`hypr/.config/hypr/hyprland.conf` is the entry point; it sources modular files:
- `monitors_positioning.conf` — monitor layout
- `keybindings.conf` / `keybinds.conf` — input bindings
- `animations/` — swappable animation presets (active one sourced via `theme.conf`)
- `workflows/` — per-context window rules (default, editing, gaming, powersaver, snappy)
- `themes/` — color variables and wallbash integration

### Fish shell structure

- `config.fish` — env vars, PATH, functions, Starship init
- `conf.d/aliases.fish` — all aliases and abbreviations (git, system, navigation)
- `conf.d/` — plugin integrations (nvm, autopair, done notifications, mocha theme)
- `functions/` — named functions including VR launch helpers

### Neovim

Full details are in `nvim/.config/nvim/CLAUDE.md`. Key point: there is no build step — plugin changes require `:Lazy sync`, LSP changes `:LspRestart`.

## Searxng

Self-hosted search via Docker Compose:

```bash
cd searxng
docker compose up -d
```

Config lives in `searxng/core-config/`.
