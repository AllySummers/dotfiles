function files-in() {
  file="$1"

  if [[ -z "$file" ]]; then
    echo "Usage: files-in <file>"
    return 1
  fi
  if [[ ! -f "$file" ]]; then
    echo "Error: $file is not a file."
    return 1
  fi
  if [[ ! -r "$file" ]]; then
    echo "Error: $file is not readable."
    return 1
  fi

  cat "$file" | tr '\n' ' '
}

_files_in() {
  _arguments "1:filename:_files"
}

compdef _files_in files-in
