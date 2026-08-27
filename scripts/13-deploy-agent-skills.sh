#!/usr/bin/env bash
# 13-deploy-agent-skills.sh
#
# Deploys skills from the agent_skills/ source-of-truth to ~/.hermes/skills/
# via symlinks. The agent_skills/ directory is the canonical location for all
# user-maintained skills — all edits go there, this script propagates them.
#
# Usage:
#   ./13-deploy-agent-skills.sh           # Deploy (create/update symlinks)
#   ./13-deploy-agent-skills.sh --dry-run # Preview without changes
#   ./13-deploy-agent-skills.sh --verify  # Check existing symlinks
#
# Requires: skill-map.yaml in the agent_skills/ root directory.
# This script does NOT require root — all paths are under $HOME.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
AGENT_SKILLS_DIR="$HOME/Documents/Estudos/07-tools-and-infrastructure/agent_skills"
HERMES_SKILLS_DIR="$HOME/.hermes/skills"
MAP_FILE="$AGENT_SKILLS_DIR/skill-map.yaml"
DRY_RUN=false
VERIFY_ONLY=false
FORCE=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --verify)  VERIFY_ONLY=true ;;
        --force)   FORCE=true ;;
        --help|-h)
            echo "Usage: $0 [--dry-run] [--verify] [--force]"
            echo ""
            echo "Deploys agent_skills/ to ~/.hermes/skills/ via symlinks."
            echo "  --dry-run  Preview without making changes"
            echo "  --verify   Check existing symlinks point correctly"
            echo "  --force    Replace real directories with symlinks (Phase 2)"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

# --- Pre-flight checks ---

if [[ ! -d "$AGENT_SKILLS_DIR" ]]; then
    echo "ERROR: agent_skills directory not found: $AGENT_SKILLS_DIR"
    exit 1
fi

if [[ ! -f "$MAP_FILE" ]]; then
    echo "ERROR: skill-map.yaml not found: $MAP_FILE"
    echo "Create it with 'skill: category' lines (see existing file for format)."
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 is required to parse skill-map.yaml"
    exit 1
fi

# --- Parse skill-map.yaml and deploy ---

# Read the map file and process each line
# Format: "skill_name: category" or "skill_name: category/subcategory"
# Lines starting with # are comments, blank lines are skipped

deployed=0
skipped=0
conflicts=0
broken=0

# Use python to parse the YAML (simple key: value format, no complex YAML needed)
MAP_DATA=$(python3 -c "
import sys
with open('$MAP_FILE') as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if ':' in line:
            parts = line.split(':', 1)
            skill = parts[0].strip()
            category = parts[1].strip()
            print(f'{skill}|{category}')
")

while IFS='|' read -r skill_name category; do
    [[ -z "$skill_name" ]] && continue

    source_dir="$AGENT_SKILLS_DIR/$skill_name"

    # Verify source exists and has SKILL.md
    if [[ ! -d "$source_dir" ]]; then
        echo "  SKIP: $skill_name — source directory missing"
        skipped=$((skipped + 1))
        continue
    fi

    # Handle name mismatch (pptx → powerpoint)
    # If category contains a /, the last part is the target dir name
    if [[ "$category" == */* ]]; then
        target_subpath="${category}"
    else
        target_subpath="${category}/${skill_name}"
    fi

    # _top means the skill lives directly under ~/.hermes/skills/
    if [[ "$category" == "_top" ]]; then
        target_path="$HERMES_SKILLS_DIR/$skill_name"
    else
        target_path="$HERMES_SKILLS_DIR/$target_subpath"
    fi

    # Ensure parent directory exists
    target_parent="$(dirname "$target_path")"
    if [[ ! -d "$target_parent" ]] && [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$target_parent"
    fi

    # --- Verify mode: check existing symlinks ---
    if [[ "$VERIFY_ONLY" == true ]]; then
        if [[ -L "$target_path" ]]; then
            current_target=$(readlink "$target_path")
            if [[ "$current_target" == "$source_dir" ]]; then
                echo "  OK: $skill_name → $target_path"
            else
                echo "  WRONG TARGET: $skill_name → $current_target (expected $source_dir)"
                broken=$((broken + 1))
            fi
        elif [[ -d "$target_path" ]]; then
            echo "  REAL DIR (not symlink): $target_path"
            broken=$((broken + 1))
        else
            echo "  MISSING: $skill_name at $target_path"
            broken=$((broken + 1))
        fi
        continue
    fi

    # --- Deploy mode ---
    if [[ -L "$target_path" ]]; then
        current_target=$(readlink "$target_path")
        if [[ "$current_target" == "$source_dir" ]]; then
            # Already correct — skip
            deployed=$((deployed + 1))
            continue
        else
            # Symlink points to wrong place — fix it
            if [[ "$DRY_RUN" == true ]]; then
                echo "  DRY-RUN: would update symlink $skill_name: $current_target → $source_dir"
            else
                ln -sfn "$source_dir" "$target_path"
                echo "  UPDATED: $skill_name → $source_dir"
            fi
            deployed=$((deployed + 1))
            continue
        fi
    fi

    if [[ -d "$target_path" ]] && [[ "$FORCE" == true ]]; then
        # Force mode: back up real dir, replace with symlink
        backup_path="${target_path}.pre-symlink.$(date +%Y%m%d-%H%M%S)"
        if [[ "$DRY_RUN" == true ]]; then
            echo "  DRY-RUN: would backup $target_path → $backup_path, then symlink"
        else
            mv "$target_path" "$backup_path"
            ln -s "$source_dir" "$target_path"
            echo "  REPLACED: $skill_name (backup at $(basename "$backup_path"))"
        fi
        deployed=$((deployed + 1))
        continue
    fi

    if [[ -d "$target_path" ]]; then
        # Real directory exists and no force — conflict
        echo "  CONFLICT: $skill_name — real directory exists at $target_path"
        echo "           Use --force to replace with symlink (backs up real dir first)"
        conflicts=$((conflicts + 1))
        continue
    fi

    # No conflict — create symlink
    if [[ "$DRY_RUN" == true ]]; then
        echo "  DRY-RUN: would link $skill_name → $target_path"
    else
        ln -s "$source_dir" "$target_path"
        echo "  LINKED: $skill_name → $target_path"
    fi
    deployed=$((deployed + 1))

done <<< "$MAP_DATA"

# --- Summary ---
echo ""
echo "=== SUMMARY ==="
if [[ "$VERIFY_ONLY" == true ]]; then
    echo "  Verified: $deployed"
    echo "  Broken/missing: $broken"
else
    echo "  Deployed/updated: $deployed"
    echo "  Skipped: $skipped"
    echo "  Conflicts (real dir exists): $conflicts"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  (dry-run mode — no changes made)"
    fi
fi

if [[ "$conflicts" -gt 0 ]]; then
    echo ""
    echo "WARNING: $conflicts conflict(s) found. Real directories exist at target paths."
    echo "To resolve: move the real directory contents to agent_skills/, then re-run."
    exit 1
fi