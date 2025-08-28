#!/usr/bin/env zsh

gdu-with-ignore() {
	local -a target_dirs=()
	if [[ $# -eq 0 ]]; then
		target_dirs=("$PWD")
	else
		target_dirs=("$@")
	fi

    local -A gitignore_data=()
    local -a final_patterns=()

    local abs_target=$(realpath "$target_dir")
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)

    local -a gitignore_files=($(fd -H .gitignore $target_dirs))
	echo $gitignore_files

}
