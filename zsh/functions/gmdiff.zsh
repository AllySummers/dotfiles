# Function: gmdiff
# Usage:
#   gmdiff <source_branch>            # uses current branch as default for current_branch
#   gmdiff <current_branch> <source_branch>  # uses both provided branches
gmdiff() {
  if [ "$#" -eq 0 ] || [ "$#" -gt 2 ]; then
    echo "Usage: gmdiff [current_branch] <source_branch>"
    return 1
  fi

  if [ "$#" -eq 1 ]; then
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    local source_branch=$1
  else
    local current_branch=$1
    local source_branch=$2
  fi

  local merge_base
  merge_base=$(git merge-base "$current_branch" "$source_branch")
  if [ -z "$merge_base" ]; then
    echo "Error: Could not determine merge-base between '$current_branch' and '$source_branch'."
    return 1
  fi

  git diff "${merge_base}..${source_branch}"
}

# Zsh completion for gmdiff
# This provides tab-completion for local Git branch names.
_gmdiff_branches() {
  local -a branches
  branches=(${(f)"$(git for-each-ref --format='%(refname:short)' refs/heads)"})
  _describe 'branches' branches
}

# Attach the completion function to gmdiff
compdef _gmdiff_branches gmdiff
