#!/usr/bin/env bash
# Guest-side dotfiles installer. Runs INSIDE a VM or container.
#
# 1. Installs git + curl + mise (minimum bootstrap prerequisites).
# 2. Clones the dotfiles repo to ~/.local/share/dotfiles and seeds a symlink
#    so the global mise config (~/.config/mise/config.toml) is readable.
# 3. Runs 'mise bootstrap --yes' from $HOME, which reads the global config
#    and handles the rest:
#      a. [bootstrap.packages]  — brew formulae, app-only casks, apt/pacman/dnf
#      b. [dotfiles] apply      — symlinks and Cursor settings template
#      c. [bootstrap.macos.*]   — macOS defaults
#      d. [bootstrap.user]      — login shell (chsh)
#      e. mise install [tools]  — tools from global config
#      f. [tasks.bootstrap]     — atuin hooks, GUI casks
#
# Usage: ./setup.sh [--repo <url>] [--branch <branch>]
#
# Flags:
#   --repo <url>      Dotfiles git repo (default: AllySummers/dotfiles).
#   --branch <branch> Branch to check out (default: repo's default branch).
#
# Environment:
#   DOTFILES_SOURCE   If set to an existing directory, symlinks it as the
#                     dotfiles root instead of cloning --repo. Lets you test
#                     local uncommitted changes inside a VM or container.

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/AllySummers/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)    DOTFILES_REPO="$2"; shift 2 ;;
    --branch)  DOTFILES_BRANCH="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

# ── Pretty logging (no zsh dependency; works in a bare container) ─────────────
if [ -t 1 ]; then
  C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BOLD=$'\033[1m'; C_RESET=$'\033[0m'
else
  C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_BOLD=''; C_RESET=''
fi
log()  { printf '%s==>%s %s%s%s\n' "$C_BLUE" "$C_RESET" "$C_BOLD" "$*" "$C_RESET"; }
ok()   { printf '%s ✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%s ⚠%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }

# ── sudo only when needed (containers usually run as root) ────────────────────
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

# ── Detect platform ───────────────────────────────────────────────────────────
PLATFORM=""
case "$(uname -s)" in
  Darwin) PLATFORM="macos" ;;
  Linux)
    # /etc/os-release is a symlink to /usr/lib/os-release on Arch; some
    # minimal containers only have the latter.
    _os_release=""
    [ -r /etc/os-release ]      && _os_release=/etc/os-release
    [ -z "$_os_release" ] && [ -r /usr/lib/os-release ] && _os_release=/usr/lib/os-release
    if [ -n "$_os_release" ]; then
      # shellcheck disable=SC1090
      . "$_os_release"
      case "${ID:-}" in
        arch)   PLATFORM="arch" ;;
        ubuntu) PLATFORM="ubuntu" ;;
        debian) PLATFORM="debian" ;;
        *)
          case " ${ID_LIKE:-} " in
            *arch*)            PLATFORM="arch" ;;
            *debian*|*ubuntu*) PLATFORM="debian" ;;
            *) echo "Unsupported Linux distro: ${ID:-unknown}" >&2; exit 1 ;;
          esac
          ;;
      esac
    else
      echo "Cannot detect Linux distro (no /etc/os-release)" >&2; exit 1
    fi
    ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
log "Detected platform: $PLATFORM"

# ── Ensure ~/.local/bin is on PATH for installers below ───────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── Install git + curl (minimum to bootstrap mise) ───────────────────────────
# The full package set is declared in [bootstrap.packages] in the global config
# and installed by 'mise bootstrap' after dotfiles are seeded.
install_prereqs() {
  case "$PLATFORM" in
    macos)
      # curl and git ship with macOS; nothing extra needed here.
      ;;
    arch)
      # Pacman 7's downloader runs in a seccomp + landlock sandbox that the kernel
      # can't apply inside Docker (especially under QEMU/Rosetta emulation).
      # Disable it when running inside a container (/.dockerenv exists in Docker).
      pac_flags=()
      [ -f /.dockerenv ] && pac_flags+=(--disable-sandbox)
      $SUDO pacman -Sy --needed --noconfirm "${pac_flags[@]}" git curl ca-certificates
      ;;
    ubuntu|debian)
      $SUDO apt-get update -y
      DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y git curl ca-certificates
      ;;
  esac
}

# ── Install mise ──────────────────────────────────────────────────────────────
install_mise() {
  if command -v mise >/dev/null 2>&1; then
    ok "mise already installed"
  else
    log "Installing mise (mise.run)"
    curl -fsSL https://mise.run | sh
  fi
  command -v mise >/dev/null 2>&1 && ok "mise $(mise --version)"
}

# ── Clone/link dotfiles repo ──────────────────────────────────────────────────
# Seeds ~/.dotfiles and copies the global mise config so that 'mise bootstrap'
# can read [bootstrap.*] and [dotfiles] in the next step. bootstrap's dotfiles
# apply step will then replace the copy with a proper symlink (content-identical
# regular files are converged to symlinks without --force since mise v2026.6.7).
apply_dotfiles() {
  DOTFILES_DIR="$HOME/.dotfiles"

  if [ -n "${DOTFILES_SOURCE:-}" ] && [ -d "$DOTFILES_SOURCE" ]; then
    log "Linking dotfiles from local source: $DOTFILES_SOURCE"
    ln -snf "$DOTFILES_SOURCE" "$DOTFILES_DIR"
  else
    if [ -d "$DOTFILES_DIR/.git" ]; then
      log "Updating dotfiles repo at $DOTFILES_DIR"
      git -C "$DOTFILES_DIR" pull --ff-only
    else
      log "Cloning dotfiles repo: $DOTFILES_REPO${DOTFILES_BRANCH:+ (branch: $DOTFILES_BRANCH)}"
      git clone ${DOTFILES_BRANCH:+--branch "$DOTFILES_BRANCH"} "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
  fi

  # Seed the global mise config so mise bootstrap can read it.
  mkdir -p "$HOME/.config/mise"
  cp "$DOTFILES_DIR/home/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
  mise trust --yes "$HOME/.config/mise/config.toml"
  ok "Dotfiles seeded"
}

install_prereqs
install_mise
apply_dotfiles

# ── Run bootstrap from $HOME ──────────────────────────────────────────────────
# Reads [bootstrap.*] and [dotfiles] from the now-seeded global config.
log "Running mise bootstrap"
cd ~
mise bootstrap --yes

log "Done! Open a new zsh session to use the configured shell."
