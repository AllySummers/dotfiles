function source_dirs() {
  # Define the directories containing the env scripts
  local dirs=("$@")

  local files=()

  for dir in "${dirs[@]}"; do
    if [[ -d "$dir" ]]; then
      # Append all .zsh files to the files array
      # Using globbing to match *.zsh files
      files+=("$dir"/*.zsh)
    else
      echo "Warning: Directory '$dir' does not exist."
    fi
  done

  # Remove any non-existing files (in case there are no matches)
  files=("${(@f)files}")

  # Check if there are any files to source
  if (( ${#files[@]} == 0 )); then
    echo "No environment scripts found to source."
    return 1
  fi

  # Sort the files based on the numeric prefix in their filenames
  # This ensures files like '0-base.zsh' come before '5-homebrew.zsh', etc.
  local sorted_files=($(printf "%s\n" "${files[@]}" | \
    awk -F/ '{
      filename = $NF
      if (match(filename, /^[0-9]+/)) {
        num = substr(filename, RSTART, RLENGTH)
      } else {
        num = 999999
      }
      print num " " $0
    }' | sort -n | cut -d' ' -f2-))

  # Iterate over the sorted files and source each one
  for file in "${sorted_files[@]}"; do
    if [[ -f "$file" ]]; then
      source "$file"
    else
      echo "Warning: File '$file' does not exist."
    fi
  done
}
