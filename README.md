# I Have forked the HyDE theme and will be using it as a base for my customization.

# THIS CONFIG WORKS ONLY ON MY CURRENT SYSTEM
# USING THIS ON ANY OTHER INSTALL IS LIKELY TO BREAK IT

**Note on Git Setup:**
The `10-git-setup.sh` script (run as part of `run-all.sh`) no longer prompts for Git user name and email. You will need to configure these manually after the scripts complete:
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
