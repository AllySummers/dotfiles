#!/usr/bin/env bash
# Shared host-side helpers for the VM/container test tasks.
# This file is meant to be *sourced*, not executed, and is intentionally
# left non-executable so mise does not treat it as a task.

# ── Logging ───────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  _C_BLUE=$'\033[34m'; _C_GREEN=$'\033[32m'; _C_YELLOW=$'\033[33m'
  _C_RED=$'\033[31m';  _C_BOLD=$'\033[1m';   _C_RESET=$'\033[0m'
else
  _C_BLUE=''; _C_GREEN=''; _C_YELLOW=''; _C_RED=''; _C_BOLD=''; _C_RESET=''
fi

log()  { printf '%s[setup-vm]%s %s%s%s\n' "$_C_BLUE" "$_C_RESET" "$_C_BOLD" "$*" "$_C_RESET"; }
ok()   { printf '%s[setup-vm] ✓%s %s\n' "$_C_GREEN" "$_C_RESET" "$*"; }
warn() { printf '%s[setup-vm] ⚠%s %s\n' "$_C_YELLOW" "$_C_RESET" "$*"; }
err()  { printf '%s[setup-vm] ✗%s %s\n' "$_C_RED" "$_C_RESET" "$*" >&2; }

# require_cmd <command> <install hint>
require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "'$1' not found. ${2:-}"
    exit 1
  fi
}

# Repo root = two levels up from this lib file (tasks/lib/common.sh -> repo).
repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}
