# Detect IDE-backed editors. Cursor inherits VS Code env (TERM_PROGRAM=vscode,
# VISUAL=code) so clear those before re-detecting from server install paths.
if [[ "${VISUAL:-}" == (code|code-insiders|cursor) ]]; then
  unset VISUAL
fi

_vscode_env="${VSCODE_GIT_ASKPASS_MAIN:-}${GIT_ASKPASS:-}${VSCODE_CWD:-}"

if [[ "${TERM_PROGRAM:l}" == cursor || "$_vscode_env" == *[Cc]ursor* ]]; then
  export VISUAL=cursor
elif [[ "${TERM_PROGRAM:l}" == vscode || "$_vscode_env" == *vscode-server* ]]; then
  if [[ "$_vscode_env" == *insiders* ]]; then
    export VISUAL=code-insiders
  else
    export VISUAL=code
  fi
fi

unset _vscode_env

export VISUAL="${VISUAL:-$EDITOR}"

case "${VISUAL:-}" in
  cursor|code|code-insiders)
    export GIT_EDITOR="$VISUAL --wait"
    ;;
  *)
    export GIT_EDITOR="$VISUAL"
    ;;
esac
