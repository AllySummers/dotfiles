function fzf_alias_search() {
    local -a ignored_aliases
    ignored_aliases=(
        '_' # sudo
        '-' # cd -
    )

    local -a alias_names
    alias_names=($(
        # `${(k)aliases}` expands to the keys of the associative array `aliases`
        # and `j:\n:` joins them with newlines
        echo ${(j:\n:)${(k)aliases}} \
            | sort -g -r
    ))

    # # Build a tab-separated list of aliases and their definitions
    local alias_list=""
    for name in "${alias_names[@]}"; do
        # only add to list if it's not in the ignored_aliases array
        if [[ ${ignored_aliases[(ie)$name]} -gt ${#ignored_aliases} ]]; then
            alias_list+="$name\t${aliases[$name]}\n"
        fi
    done

    # local selection
    local selection=$(
        echo -e "$alias_list" \
            | column -t -s $'\t' \
            | fzf --ansi --prompt "Select Alias> " --tac --no-sort
    )

    if [[ -n $selection ]]; then
        # Extract the alias name from the selection
        local selected_alias=${selection%%[[:space:]]*}
        # Execute the alias
        eval "${aliases[$selected_alias]}"
    fi
}
