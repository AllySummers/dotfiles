#!/usr/bin/env bash
# Guest-side dotfiles installer. Runs INSIDE a VM or container.
#
# Installs Homebrew (macOS; which provides git), bootstraps mise (via mise.run), installs
# chezmoi through mise and applies the dotfiles, then runs `mise install` to
# materialise everything pinned in ~/.config/mise/config.toml (sheldon, etc.).
# Supports macOS, Arch, Ubuntu and Debian.
#
# Usage: ./setup.sh [--gui] [--repo <url>]
#
# Flags:
#   --gui          Also install GUI apps (macOS casks via ~/.Brewfile). Off by default.
#   --repo <url>   Dotfiles git repo to apply (default: the AllySummers/dotfiles repo).
#
# Environment:
#   DOTFILES_SOURCE   If set to a directory, chezmoi uses it as the source instead of
#                     cloning --repo. Lets you test *local* uncommitted changes.

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/AllySummers/dotfiles.git}"
DOTFILES_SOURCE="${DOTFILES_SOURCE:-}"
INSTALL_GUI=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --gui)   INSTALL_GUI=true; shift ;;
    --repo)  DOTFILES_REPO="$2"; shift 2 ;;
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
            *arch*)   PLATFORM="arch" ;;
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

# ── Install base prerequisites per platform ───────────────────────────────────
install_prereqs() {
  case "$PLATFORM" in
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        log "Installing Homebrew"
        NONINTERACTIVE=1 /bin/bash -c \
          "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      eval "$(/opt/homebrew/bin/brew shellenv)"
      ok "brew $(brew --version | head -1)"
      ;;
    arch)
      log "Installing base packages (pacman)"
      # Pacman 7's downloader runs in a seccomp + landlock sandbox that the kernel
      # can't apply inside Docker (and especially under QEMU/Rosetta emulation),
      # so pacman aborts with "restricting syscalls via seccomp" / landlock errors.
      # Disable it when running inside a container (/.dockerenv exists in Docker).
      pac_flags=()
      [ -f /.dockerenv ] && pac_flags+=(--disable-sandbox)
      $SUDO pacman -Sy --needed --noconfirm "${pac_flags[@]}" git curl zsh base-devel ca-certificates
      ;;
    ubuntu|debian)
      log "Installing base packages (apt)"
      $SUDO apt-get update -y
      DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y \
        git curl zsh build-essential ca-certificates
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

# ── Install chezmoi (via mise) ────────────────────────────────────────────────
install_chezmoi() {
  # chezmoi is managed by mise like everything else, but it has to exist BEFORE
  # the dotfiles — and therefore the full mise.toml — are applied. So install
  # just chezmoi up front and run it via `mise exec`. We deliberately avoid
  # `mise use -g chezmoi`, which would write chezmoi into the global mise config
  # that the dotfiles own and chezmoi itself lays down.
  log "Installing chezmoi (mise)"
  mise install chezmoi
  ok "chezmoi $(mise exec chezmoi -- chezmoi --version | head -1)"
}

# ── Apply dotfiles ─────────────────────────────────────────────────────────────
apply_dotfiles() {
  if [ -n "$DOTFILES_SOURCE" ] && [ -d "$DOTFILES_SOURCE" ]; then
    log "Applying dotfiles from local source: $DOTFILES_SOURCE"
    mise exec chezmoi -- chezmoi init --apply --source "$DOTFILES_SOURCE"
  else
    log "Applying dotfiles from repo: $DOTFILES_REPO"
    mise exec chezmoi -- chezmoi init --apply "$DOTFILES_REPO"
  fi
  ok "Dotfiles applied"
}

# ── Materialise pinned tools from the applied mise.toml (sheldon, etc.) ────────
install_tools() {
  log "Installing pinned tools via mise (this can take a while)"
  mise trust --yes "$HOME/.config/mise/config.toml" 2>/dev/null || true
  mise install --yes
  ok "Tools installed"
}

# ── GUI apps (opt-in, macOS only) ─────────────────────────────────────────────
install_gui() {
  if [ "$INSTALL_GUI" != true ]; then
    log "Skipping GUI apps (pass --gui to enable)"
    return
  fi
  if [ "$PLATFORM" != "macos" ]; then
    warn "GUI app install is only wired up for macOS — skipping on $PLATFORM"
    return
  fi
  if [ -f "$HOME/.Brewfile" ]; then
    log "Installing GUI apps from ~/.Brewfile"
    HOMEBREW_BUNDLE_NO_LOCK=1 brew bundle --global --no-upgrade
    ok "GUI apps installed"
  else
    warn "No ~/.Brewfile found — nothing to install"
  fi
}

install_prereqs
install_mise
install_chezmoi
apply_dotfiles
install_tools
install_gui

log "Done! Open a new zsh session to use the configured shell."
