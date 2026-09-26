#!/usr/bin/env bash
# apply-lan-bypass.sh — idempotently install a priority-5200 ip rule that
# steers 192.168.2.0/24 traffic to the main table, bypassing the Tailscale
# rule 5270 ("from all lookup 52") when stormx is physically on the workshop
# LAN. Lives in /usr/local/lib/mullvad-tailscale/ when deployed; called from
# mullvad-tailscale-exclusion.service ExecStart / ExecReload.
#
# Why priority 5200 and not lower: Mullvad's rules are 5208 (suppress
# prefix) and 5209 (mole table). Tailscale's rules are 5210/5230/5250/5270.
# 5200 sits below the built-ins (0/32766/32767) and ABOVE Mullvad — so 5200
# wins over the suppress-prefixlength check and the mole-table lookup.
#
# Why this rule is safe away from the workshop LAN: per iproute2(8), the
# RPDB scans rules in decreasing priority order. If the action's lookup
# yields no matching route, evaluation CONTINUES to the next rule. So at a
# coffee shop on 192.168.1.x, lookup main for 192.168.2.0/24 finds nothing
# (no home route on this iface), evaluation falls through to 5210/5230/
# 5250/5270, and Tailscale's table 52 (which DOES have 192.168.2.0/24 via
# tailscale0 from the OpenWrt subnet-route advertisement) wins. Self-
# disabling by construction.
#
# Why check-before-add: iproute2 has no `ip rule replace` (confirmed with
# iproute2-7.2.0: "Command 'replace' is unknown, try 'ip rule help'"). The
# `ip rule add` form is atomic with respect to priority — if another daemon
# owns that priority slot we detect it before clobbering. Alternative:
# `ip rule del priority 5200 && ip rule add …` — rejected because it
# removes an unintended rule at the same priority (Tailscale's "mullvad
# stole my rules" pattern, but in reverse).
#
# Idempotent: `ip rule list` + grep is cheap, runs on every ExecStart/Reload.
# Race window: between the grep and the add, another rule-table churn
# (Mullvad connect/disconnect) could land. The kernel returns EEXINVAL on
# duplicate priority; we treat that as success.
#
# Args (env vars, all optional):
#   LAN_PREFIX  default 192.168.2.0/24
#   RULE_PRIO   default 5200
#   TABLE       default main

set -euo pipefail

LAN_PREFIX="${LAN_PREFIX:-192.168.2.0/24}"
RULE_PRIO="${RULE_PRIO:-5200}"
TABLE="${TABLE:-main}"

log() { printf '[apply-lan-bypass] %s\n' "$*" >&2; }

# Preflight: skip entirely if tailscale0 isn't even around. Tailscale
# package installed but not yet logged in -> no rule 5270 exists -> our
# rule would do nothing useful but also nothing harmful. Bail quietly.
if ! ip -o link show tailscale0 &>/dev/null; then
    log "tailscale0 absent — nothing to bypass yet, exiting clean"
    exit 0
fi

# Preflight: if the kernel's rule database has zero rules mentioning
# table 52, Tailscale hasn't installed its routing yet. Our rule is still
# safe (RPDB fallthrough), but skip to keep the journal quiet.
if ! ip rule list | grep -qE '\blookup[[:space:]]+52\b'; then
    log "no rule references table 52 — Tailscale rules not yet installed, skipping"
    exit 0
fi

# Idempotent install.
# ERE pattern. Notes:
#   - bash variable expansion turns $LAN_PREFIX into 192.168.2.0/24
#   - we escape the slashes for grep (it warns on unescaped / inside charsets
#     but here it's outside, so harmless; the slash-escape is defensive)
#   - [[:space:]] matches both spaces and tabs (ip rule list uses tabs)
#   - \b in ERE is treated literally by GNU grep — but the match still works
#     because the literal "." and "lookup" boundaries exist in the line
PATTERN="^${RULE_PRIO}:[[:space:]]+from[[:space:]]+all[[:space:]]+to[[:space:]]+${LAN_PREFIX//\//\\/}[[:space:]]+lookup[[:space:]]+${TABLE}[[:space:]]*\$"
if ip rule list | grep -Eq "${PATTERN}"; then
    log "rule already present (priority ${RULE_PRIO} to ${LAN_PREFIX} lookup ${TABLE})"
    exit 0
fi

if ip rule add priority "${RULE_PRIO}" to "${LAN_PREFIX}" table "${TABLE}" 2>/tmp/lan-bypass.err; then
    log "added: priority ${RULE_PRIO} to ${LAN_PREFIX} lookup ${TABLE}"
    exit 0
fi

# Race: another actor inserted at this priority between our check and add.
# Treat as success — the slot is occupied, which is the desired end-state.
if grep -qi "file exists" /tmp/lan-bypass.err 2>/dev/null \
   || grep -qi "EEXIST" /tmp/lan-bypass.err 2>/dev/null; then
    log "priority ${RULE_PRIO} already occupied (race) — accepting current state"
    rm -f /tmp/lan-bypass.err
    exit 0
fi

log "ip rule add failed:"
cat /tmp/lan-bypass.err >&2 || true
rm -f /tmp/lan-bypass.err
exit 1
