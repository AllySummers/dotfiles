fzfo() {
  local file="$(fzf)"

  if [[ -n "$file" ]]; then
    ${VISUAL:-${EDITOR:-nano}} "$file"
  fi
}
