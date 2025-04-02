n() {
  local cmd="$1"
  shift

  # Search upward for the binary in node_modules/.bin directories.
  local dir=$(pwd)
  while [[ "$dir" != "/" ]]; do
    if [[ -x "$dir/node_modules/.bin/$cmd" ]]; then
      "$dir/node_modules/.bin/$cmd" "$@"
      return $?
    fi
    dir=$(dirname "$dir")
  done

  echo "Command '$cmd' not found in any node_modules/.bin directory up the tree."
  return 127
}

_n() {
  # When completing the command name itself (n <TAB>):
  if (( CURRENT == 2 )); then
    local -a cmds
    local dir=$PWD
    while [[ "$dir" != "/" ]]; do
      if [[ -d "$dir/node_modules/.bin" ]]; then
        cmds+=( ${(f)"$(cd "$dir/node_modules/.bin" && echo *)"} )
      fi
      dir=$(dirname "$dir")
    done
    _describe 'node_modules/.bin commands' cmds && return
  fi

  # For completing the arguments of the chosen subcommand:
  # Temporarily replace the first word (n) with the subcommand name.
  local orig_cmd=${words[1]}
  words[1]=${words[2]}
  _normal
  # Restore the original command name.
  words[1]=$orig_cmd
}

compdef _n n
