# place in ~/.zshrc
function fzf_function_search() {
  setopt extended_glob

  # 1) literal names to drop
  local -a ignored_functions=(
    bash-ctrl-d
    fzf_function_search
    azure_prompt_info
    backward-extend-paste
    bashcompinit
    cd
    add-zsh-hook
    alias_value
    bman
    bracketed-paste-magic
    branch_prompt_info
    bzr_prompt_info
    chruby_prompt_info
    clipcopy
    clippaste
    colored
    colors
    compaudit
    compdef
    compdump
    compgen
    compinit
    compinstall
    complete
    conda_prompt_info
    copyfile
  )

  # 2) join names into (a|b|c)
  local ignore_names="${(j:|:)ignored_functions}"

  # 3) wildcard patterns + explicit names - THIS IS THE FIX
  local pattern="((_*)|(-*)|(zui*)|(/*)|(chroma*)|(.*)|(antidote-*)|($ignore_names))"

  # 4) remove anything matching $pattern
  local -a function_list=( ${(k)functions:#${~pattern}} )

  # 5) sort and fzf
  local selection
  selection=$(
    printf '%s\n' "${function_list[@]}" \
      | sort \
      | fzf --ansi --prompt="Select Function> " --tac --no-sort
  )

  # 6) push the choice into your command line buffer
  if [[ -n $selection ]]; then
     print -z -- "$selection "
  fi
}
