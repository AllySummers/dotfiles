#############################################
# yarn-open
# Open a workspace package in your editor by package name
# Usage: yarn-open <package-name>
# Example: yarn-open @atlassian/jira-issue-view
#############################################

yarn-open() {
  if ! command -v rg >/dev/null 2>&1; then
    echo "Error: ripgrep (rg) is not installed. Please install it to use yarn-open." >&2
    return 1 2>/dev/null || exit 1
  fi

  if [[ $# -ne 1 ]]; then
    echo "Usage: yarn-open <package-name>" >&2
    echo "Example: yarn-open @atlassian/jira-issue-view" >&2
    return 1
  fi

  local pkg="$1"

  declare -AU workspaces
  workspaces=($(rg 'resolution:\s*"(.*?)@workspace.*:(.*?)"' -Nor $'$1\t$2' yarn.lock))

  selected_pkg=$workspaces[$pkg]

  if [[ -z "$selected_pkg" ]]; then
    echo "Error: Package '$pkg' not found in yarn.lock." >&2
    return 1
  fi

  if [[ -d "$selected_pkg" ]]; then
    ${VISUAL:-${EDITOR:-vim}} "$selected_pkg/package.json"
  else
    echo "Error: package.json for package '$package' not found." >&2
    return 1
  fi
}

_yarn_open() {
  local -a workspaces

  if [[ -f yarn.lock ]]; then
    workspaces=($(rg 'resolution:\s*"(.*?)@workspace.*:(.*?)"' -Nor '$1' yarn.lock))
  fi

  if (( ${#workspaces} )); then
    compadd -- "${workspaces[@]}"
  fi
}

compdef _yarn_open yarn-open
