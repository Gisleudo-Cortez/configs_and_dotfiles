#!/usr/bin/env bash
# apply-lan-bypass.sh — idempotently install a priority-2500 ip rule that
# steers 192.168.2.0/24 traffic to the main table when stormx is PHYSICALLY
# on the workshop LAN, bypassing the Tailscale rule 5270 ("from all lookup
# 52") interception. Lives in /usr/local/lib/mullvad-tailscale/ when
# deployed; called from mullvad-tailscale-exclusion.service ExecStart/Reload.
#
# WHY FROM-SCOPED (lab-proven 2026-09-25, unshare netns two-scenario test):
#   An UNSCOPED rule ("to 192.168.2.0/24 lookup main") is DANGEROUS when
#   stormx is AWAY (e.g. shop LAN 192.168.1.x): lookup main matches the
#   DEFAULT ROUTE, so printer traffic exits the foreign gateway instead of
#   tailscale0 — the away-path silently breaks. The rule is NOT
#   self-disabling; the old "lookup fails away, falls through" reasoning
#   was wrong. The from-scope (source must ALSO be 192.168.2.0/24) makes it
#   self-disabling for real: away, sockets carry the away-LAN source, the
#   rule never matches, RPDB falls through to 5270 → table 52 → tailscale0.
#   Home, the Lychee-style bound-to-LAN-IP socket matches the from-scope →
#   lookup main → direct on the wire.
#
# WHY PRIORITY 2500 and not 5200: Tailscale's own KB (lan-traffic-
# overlapping-subnets, validated 2026-03) states Tailscale uses the priority
# range 5200–5500 for its rules (currently 5210/5230/5250/5270) and
# recommends installing ahead of them at 2500. A rule at 5200 sits inside
# the range a future tailscaled release may claim; 2500 is outside it.
# Mullvad's rules (5208/5209) sit above 2500, so LAN traffic still gets the
# RFC1918 bypass treatment Mullvad would give it — same outcome, earlier.
#
# WHY check-before-add: iproute2 has no `ip rule replace` ("Command
# 'replace' is unknown"). Idempotent: cheap grep on every ExecStart/Reload.
# Race: between grep and add, Mullvad rule churn could land — kernel
# returns File exists; we treat that as success.
#
# Args (env vars, all optional):
#   LAN_PREFIX  default 192.168.2.0/24
#   RULE_PRIO   default 2500
#   TABLE       default main

set -euo pipefail

LAN_PREFIX="${LAN_PREFIX:-192.168.2.0/24}"
RULE_PRIO="${RULE_PRIO:-2500}"
TABLE="${TABLE:-main}"

log() { printf '[apply-lan-bypass] %s\n' "$*" >&2; }

# Journal-quiet on happy paths. The safety-net timer runs this every 60s;
# a "rule already present" line per minute is ~500k journal lines/year of
# nothing. Under systemd there's no controlling TTY → silent no-ops. Manual
# runs from a terminal still speak. Failures log unconditionally — a failed
# install must always be loud.
tty_log() { [[ -t 2 ]] && log "$*"; }

# Preflight: skip entirely if tailscale0 isn't around. Nothing to bypass
# yet, nothing harmful either — bail quietly.
if ! ip -o link show tailscale0 &>/dev/null; then
    tty_log "tailscale0 absent — nothing to bypass yet, exiting clean"
    exit 0
fi

# Preflight: if no rule references table 52, Tailscale hasn't installed its
# routing yet. Our rule is still safe, but skip to keep the journal quiet.
if ! ip rule list | grep -qE 'lookup[[:space:]]+52\b'; then
    tty_log "no rule references table 52 — Tailscale rules not yet installed, skipping"
    exit 0
fi

# Idempotent install. Fixed-string grep — iproute2 prints the rule as
#   2500:	from 192.168.2.0/24 to 192.168.2.0/24 lookup main
# so a -F substring match is robust (no regex-escaping pitfalls).
NEEDLE="from ${LAN_PREFIX} to ${LAN_PREFIX} lookup ${TABLE}"
if ip rule list | grep -Fq "${NEEDLE}"; then
    tty_log "rule already present (from+to ${LAN_PREFIX} lookup ${TABLE})"
    exit 0
fi

# Error capture is IN-MEMORY (command substitution), never a scratch file.
# This runs as root from a system unit: a fixed path under /tmp is a bug
# class, not a convenience. fs.protected_regular=1 makes root's O_CREAT
# fail on a sticky-dir /tmp when a user-owned file of that name exists —
# the redirect dies BEFORE ip rule add even executes, and the stale file's
# contents get echoed as if they were live output (deployed 2026-09-26:
# exactly this failure, with a test-artifact file from the night before).
if err=$(ip rule add priority "${RULE_PRIO}" from "${LAN_PREFIX}" to "${LAN_PREFIX}" table "${TABLE}" 2>&1); then
    log "added: priority ${RULE_PRIO} from ${LAN_PREFIX} to ${LAN_PREFIX} lookup ${TABLE}"
    exit 0
fi

# Race: another actor inserted an equivalent rule between check and add.
if grep -qi "file exists" <<<"$err"; then
    log "equivalent rule appeared concurrently — accepting current state"
    exit 0
fi

log "ip rule add failed:"
printf '%s\n' "$err" >&2
exit 1