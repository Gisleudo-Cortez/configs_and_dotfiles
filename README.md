# My Personal Dotfiles & Arch Linux Setup

This repository contains my personal dotfiles and a collection of scripts to automate the setup of a new Arch Linux system. The configuration is centered around the Hyprland window manager and a curated set of tools and applications.

> [!CAUTION]
> **FOR PERSONAL USE ONLY**
>
> These scripts and configurations are tailored to my specific hardware and workflow. Running them on a different system is **highly likely to cause issues or break your installation**. Proceed at your own risk.

## Overview

This setup automates the following:
- **System Configuration:** Enables necessary repositories, performs a full system upgrade, and installs drivers.
- **Package Installation:** Installs official packages via `pacman`, AUR packages via `paru`, and sets up Flatpak.
- **Application Setup:** Configures Docker, PostgreSQL, virtualization tools, gaming software, and Python development tools.
- **Dotfile Deployment:** Uses `stow` to symlink configuration files for various applications like Hyprland, Kitty, Neovim, Waybar, and more.

## Prerequisites

Before you begin, ensure you have:
1.  A fresh Arch Linux installation.
2.  The `git` and `stow` packages installed.
3.  A regular user account with `sudo` privileges.

## Installation

The entire setup process is orchestrated by a single script.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/your-dotfiles-repo.git
    cd your-dotfiles-repo
    ```

2.  **Run the main installation script:**
    The `run-all.sh` script must be executed with `sudo`. It will handle running scripts that require root privileges and will use `sudo -u` to run user-specific scripts as the original user.

    ```bash
    sudo ./scripts/run-all.sh
    ```

3.  **Dry Run:**
    To see what commands the script will execute without making any changes to your system, use the `--dry-run` flag:
    ```bash
    sudo ./scripts/run-all.sh --dry-run
    ```

## Script Breakdown

The `run-all.sh` script executes the following scripts in order.

| Script                      | Description                                                                                              | Runs as |
| --------------------------- | -------------------------------------------------------------------------------------------------------- | ------- |
| `00-enable-repos.sh`        | Enables the `[multilib]` and `[chaotic-aur]` repositories in `/etc/pacman.conf`.                           | `root`  |
| `01-system-upgrade.sh`      | Performs a full system upgrade using `pacman -Syu`.                                                      | `root`  |
| `02-official-packages.sh`   | Installs a list of official packages from `packages-official.txt` and configures services like Docker.     | `root`  |
| `04-flatpak-setup.sh`       | Installs `flatpak` and adds the Flathub remote repository.                                               | `root`  |
| `05-appimage-setup.sh`      | Installs `fuse2` to provide support for running AppImage files.                                          | `root`  |
| `06-printer-setup.sh`       | Installs and enables the CUPS printing service.                                                          | `root`  |
| `07-virt-setup.sh`          | Installs and configures QEMU/KVM and libvirt for virtualization.                                         | `root`  |
| `08-gaming-setup.sh`        | Auto-detects the GPU vendor (NVIDIA/AMD/Intel) and installs appropriate drivers and gaming tools like Steam. | `root`  |
| `02b-aur-packages.sh`       | Installs a list of AUR packages from `packages-aur.txt` using the `paru` helper.                         | `user`  |
| `09-python-tools.sh`        | Installs Python development tools (`uv`, `ruff`) into the user's home directory.                         | `user`  |
| `10-git-setup.sh`           | Sets placeholder Git credentials and provides guidance for setting up GPG signing.                       | `user`  |
| `11-deploy-dotfiles.sh`     | Uses `stow` to symlink the dotfiles from this repository into the user's home directory.                   | `user`  |

## Post-Installation Steps

After the `run-all.sh` script finishes, you will need to perform a few manual configuration steps:

1.  **Configure Git:**
    The script sets placeholder values for your Git user name and email. Configure them with your actual details:
    ```bash
    git config --global user.name "Your Name"
    git config --global user.email "you@example.com"
    ```

2.  **Update Shell PATH:**
    The `09-python-tools.sh` script installs tools to `~/.local/bin`. To make them accessible in all sessions, add the following line to your shell's startup file (e.g., `~/.zshrc` or `~/.config/fish/config.fish`):
    ```bash
    export PATH="$HOME/.local/bin:$PATH"
    ```

3.  **Re-login:**
    A reboot or re-login is required for group changes (e.g., `docker`, `libvirt`) to take effect.