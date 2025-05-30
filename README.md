# THIS CONFIG WORKS ONLY ON MY CURRENT SYSTEM
# USING THIS ON ANY OTHER INSTALL IS LIKELY TO BREAK IT
# I WILL FIX IT LATTER BUT IF YOU WANT TO TRY IT,,,

    INSTALL GARUDA HYPRLAND -> INSTALL HyDE Theme -> ./scripts/run-all.sh -> reboot/logout

**Note on Git Setup:**
The `10-git-setup.sh` script (run as part of `run-all.sh`) no longer prompts for Git user name and email. You will need to configure these manually after the scripts complete:
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
