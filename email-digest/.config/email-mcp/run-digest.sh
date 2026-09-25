#!/bin/bash
# Email digest cron wrapper — sources Hermes env for Telegram, runs the digest script
# Called by crontab at 08:00 and 20:00

set -euo pipefail

# Source Hermes env for Telegram bot token
source ~/.hermes/.env

# Run the digest script with the MCP venv
cd ~/Documents/Estudos/07-tools-and-infrastructure/lms_mcp/email_management
uv run python ~/.config/email-mcp/daily_digest.py >> ~/.config/email-mcp/digest-cron.log 2>&1