find-up() {
  local cwd="$PWD"
  local all=0
  local file

  # parse options
  while [[ $# -gt 0 ]]; do
    case $1 in
      -d|--cwd)
        cwd="$2"
        shift 2
        ;;
      -a|--all)
        all=1
        shift
        ;;
      -*)
        echo "find_up: unknown option '$1'" >&2
        return 1
        ;;
      *)
        file="$1"
        shift
        ;;
    esac
  done

  # validate
  if [[ -z $file ]]; then
    echo "Usage: find_up [-d DIR] [-a] filename" >&2
    return 1
  fi

  # resolve starting directory
  local dir path results=()
  dir=$(cd "$cwd" 2>/dev/null && pwd) || { echo "find_up: cannot cd to '$cwd'" >&2; return 1 }

  # walk up
  while :; do
    path="$dir/$file"
    if [[ -e $path ]]; then
      results+=("$path")
      (( all == 0 )) && break
    fi
    [[ $dir == "/" ]] && break
    dir="${dir%/*}"
    [[ -z $dir ]] && dir="/"
  done

  # output
  if (( ${#results[@]} )); then
    printf '%s\n' "${results[@]}"
    return 0
  else
    return 1
  fi
}
