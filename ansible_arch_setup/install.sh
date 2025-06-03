#!/usr/bin/env bash
set -euo pipefail

# Determine the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PREFIX="[PoC Install Script]"

# --- Logging Functions ---
log_info() {
    echo -e "\n${LOG_PREFIX} \033[1;34mINFO:\033[0m $1"
}

log_warn() {
    echo -e "${LOG_PREFIX} \033[1;33mWARN:\033[0m $1"
}

log_error() {
    echo -e "${LOG_PREFIX} \033[1;31mERROR:\033[0m $1" >&2
}

log_success() {
    echo -e "${LOG_PREFIX} \033[1;32mSUCCESS:\033[0m $1"
}

# --- Main Script ---
log_info "Starting Arch Linux Hyprland PoC Setup Script."
log_info "This script will set up your environment using Ansible."
log_info "Current directory: $(pwd)"
log_info "Script directory: ${SCRIPT_DIR}"

# 1. Check for essential commands (sudo, git, pacman)
for cmd in sudo git pacman; do
    if ! command -v $cmd &> /dev/null; then
        log_error "$cmd command not found. Please ensure it is installed and in your PATH."
        exit 1
    fi
done
log_success "Essential commands (sudo, git, pacman) found."

# 2. Check for Ansible
log_info "Checking for Ansible (ansible-playbook command)..."
if ! command -v ansible-playbook &> /dev/null; then
    log_warn "Ansible (ansible-playbook command) is not detected on your system."
    
    # Corrected read command syntax
    install_ansible_confirm="" # Initialize variable
    read -r -p "Attempt to install Ansible automatically using pacman? (requires sudo) [Y/n]: " install_ansible_confirm
    
    # Set default to Y if user just presses Enter
    if [[ -z "$install_ansible_confirm" ]]; then
        install_ansible_confirm="Y"
    fi

    if [[ "$install_ansible_confirm" =~ ^[Yy]$ ]]; then
        log_info "Attempting to install Ansible via pacman (sudo pacman -S --noconfirm --needed ansible)..."
        if sudo pacman -S --noconfirm --needed ansible; then
            log_success "Ansible installed successfully."
        else
            log_error "Failed to install Ansible automatically. Please install Ansible manually and re-run this script."
            log_error "You can typically install it with: sudo pacman -S ansible"
            exit 1
        fi
    else
        log_error "Ansible installation declined by user. Please install Ansible manually and re-run this script."
        exit 1
    fi
else
    log_success "Ansible is already installed."
fi

# 3. Navigate to the playbook directory if not already there
if [[ "$(pwd)" != "${SCRIPT_DIR}" ]]; then
    log_info "Changing to Ansible playbook directory: ${SCRIPT_DIR}"
    cd "${SCRIPT_DIR}" || { log_error "Failed to change directory to ${SCRIPT_DIR}."; exit 1; }
else
    log_info "Already in the correct playbook directory: ${SCRIPT_DIR}"
fi

# 4. Set Ansible log path (can also be set in ansible.cfg)
# ANSIBLE_LOG_PATH environment variable overrides ansible.cfg log_path
export ANSIBLE_LOG_PATH="${SCRIPT_DIR}/ansible_playbook_run.log"
log_info "Ansible execution logs will also be saved to: ${ANSIBLE_LOG_PATH}"
# Ensure the log file can be written by the user running ansible-playbook initially,
# though ansible itself (if using become) might create it as root if it doesn't exist.
# Touch it as current user.
touch "${ANSIBLE_LOG_PATH}" || log_warn "Could not touch log file ${ANSIBLE_LOG_PATH}. Permissions issue?"


# 5. Execute the Ansible playbook
log_info "Executing Ansible playbook: playbook.yml"
log_info "You will likely be prompted for your sudo password for Ansible's 'become' functionality (privilege escalation)."
log_info "This password is for 'become' (sudo) within Ansible tasks, not stored by this script."

# Using --ask-become-pass to prompt for sudo password for 'become'
# Python interpreter is often needed for Ansible on fresh systems.
# Explicitly setting it, although ansible_python_interpreter can also be in inventory.
if ansible-playbook -i inventory.ini playbook.yml --ask-become-pass --extra-vars "ansible_python_interpreter=/usr/bin/python3"; then
    log_success "Ansible playbook executed successfully."
    log_info "Review the Ansible output above and check the detailed log file: ${ANSIBLE_LOG_PATH}"
else
    log_error "Ansible playbook execution FAILED."
    log_error "Review the Ansible output above and check the detailed log file for errors: ${ANSIBLE_LOG_PATH}"
    exit 1
fi

log_success "PoC Hyprland setup script finished successfully."
echo -e "\n\033[1mIMPORTANT NEXT STEPS:\033[0m"
echo "- It is **highly recommended to REBOOT** your system for all changes (especially the display manager, user groups, and system services) to take full effect."
echo "- After rebooting, you should see SDDM as your login manager. Select the Hyprland session to log in."
echo "- Verify your dotfiles, Hyprland configuration, and overall system setup."

exit 0
