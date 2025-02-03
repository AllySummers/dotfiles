# 4x ctrl-d to exit ...
export IGNOREEOF=3

# bash like ctrl-d wrapper for IGNOREEOF
# requires:
# setopt ignore_eof
bash-ctrl-d() {
  if [[ $CURSOR == 0 && -z $BUFFER ]]
  then
    asciinema_cmd_out=$(ps aux | rg 'python' | rg 'asciinema')
    asciinema_running=$?

    [[ -z $IGNOREEOF || $IGNOREEOF == 0 || $asciinema_running == 0 ]] && exit
    if [[ "$LASTWIDGET" == "bash-ctrl-d" ]]
    then
      (( --__BASH_IGNORE_EOF <= 0 )) && exit
    else
      (( __BASH_IGNORE_EOF = IGNOREEOF ))
    fi
  fi
}

zle -N bash-ctrl-d
bindkey "^d" bash-ctrl-d
