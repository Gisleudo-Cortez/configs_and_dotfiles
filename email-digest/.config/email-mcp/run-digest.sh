#!/bin/bash
# Email digest timer wrapper — sources Hermes env for Telegram, runs the digest
# Called by email-digest.timer (systemd user unit) at 08:00 and 20:00

set -euo pipefail

# Source Hermes env for Telegram bot token
source ~/.hermes/.env

# Run the digest script from the MCP repo (accounts/state stay in ~/.config/email-mcp)
cd ~/Documents/Estudos/07-tools-and-infrastructure/lms_mcp/email_management
uv run python daily_digest.py >> ~/.config/email-mcp/digest-cron.log 2>&1