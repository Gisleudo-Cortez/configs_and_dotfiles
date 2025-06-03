# Ansible PoC for Arch Linux Hyprland Setup

This Ansible playbook automates the setup of a Hyprland desktop environment on a fresh Arch Linux installation. It aims for a production-like, idempotent, and highly automated deployment with clear logging.

## Prerequisites

1.  **Fresh Arch Linux Installation:** This playbook is intended to run on a clean, minimal Arch Linux system (e.g., after `archinstall` with a base setup and a user).
2.  **Internet Connection:** Required for downloading packages and cloning repositories.
3.  **User with Sudo Privileges:** The user running the `install.sh` script must have `sudo` rights.
4.  **Git:** `git` should be installed to clone this repository if you're obtaining the playbook this way. If `git` is not present, the `install.sh` script will attempt to install it as part of Ansible's dependencies or initial package setup.

## Setup and Execution

1.  **Obtain the Playbook Files:**
    Clone the repository containing these files or otherwise copy the `ansible_arch_poc/` directory to your target Arch Linux machine (e.g., into your user's home directory).
    ```bash
    # Example if cloned:
    # git clone <your-repo-url-here> ansible_arch_poc
    # cd ansible_arch_poc
    ```

2.  **Review Variables (Optional but Recommended):**
    Before running, you might want to review and customize variables in `vars/main.yml`, especially:
    * `target_user`: Defaults to the user running the script.
    * `base_packages`, `hyprland_packages`: Review the package lists.
    * `dotfiles_repo_url`: Ensure this points to your dotfiles repository.
    * `stow_packages`: List of directories in your dotfiles repo to be "stowed".
    * `root_dotfiles_to_link`: List of individual files at the root of your dotfiles repo to be symlinked.
    * **IMPORTANT ASSUMPTIONS for Dotfiles:** The dotfiles deployment logic assumes your `stow_packages` directories are structured such that their internal paths mirror the desired target paths relative to `$HOME`. For example, for `stow_package_name: "hypr"`, a file like `dotfiles_repo/hypr/.config/hypr/hyprland.conf` will be symlinked to `~/.config/hypr/hyprland.conf`.

3.  **Make `install.sh` Executable:**
    ```bash
    chmod +x install.sh
    ```

4.  **Run the Installer Script:**
    ```bash
    ./install.sh
    ```
    * The script will check for Ansible. If not found, it will prompt to install it automatically via `pacman` (this requires `sudo`).
    * It will then execute the Ansible playbook (`playbook.yml`). You will be prompted for your `sudo` password once by Ansible for tasks that require privilege escalation (if not using passwordless sudo).
    * Detailed logs of the Ansible run will be saved to `ansible_playbook_run.log` in the same directory.

5.  **Reboot:**
    After the script completes successfully, it is **highly recommended to reboot your system**. This ensures all changes, especially the display manager (SDDM), user group memberships, and system services, take full effect. After rebooting, you should see SDDM as your login manager and be able to select the Hyprland session.

## Playbook Structure

* `install.sh`: Main execution wrapper script.
* `README.md`: This documentation file.
* `inventory.ini`: Ansible inventory, configured for `localhost`.
* `ansible.cfg`: Ansible configuration file (e.g., sets log path, roles path).
* `playbook.yml`: The main Ansible playbook that defines hosts and calls roles.
* `vars/main.yml`: Centralized variables for customizing package lists, user settings, repository URLs, etc.
* `roles/`: Directory containing Ansible roles for modular and reusable task definitions:
    * `base_system`: Handles base system setup, including enabling repositories (multilib, Chaotic-AUR) and installing core packages.
    * `desktop_env`: Installs and configures the Hyprland desktop environment and SDDM display manager.
    * `dotfiles`: Manages dotfiles deployment by cloning a Git repository and creating symlinks in a `stow`-like manner.

## Understanding Ansible Output

During playbook execution, Ansible provides colored output for each task:
* **Green (ok):** Task executed successfully, and no changes were made to the system (it was already in the desired state).
* **Yellow (changed):** Task executed successfully, and changes were made to the system to bring it to the desired state.
* **Red (failed):** Task failed to execute. The playbook will usually stop at this point. Check the error message provided by Ansible and the `ansible_playbook_run.log` for more details.
* **Blue (skipping):** Task was skipped due to a conditional check (e.g., a `when` condition was not met).

Review the output carefully to understand what actions Ansible performed.
