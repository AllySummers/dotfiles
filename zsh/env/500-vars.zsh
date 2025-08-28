export TERMINFO="$HOMEBREW_OPT/ncurses/share/terminfo:/Applications/kitty.app/Contents/Resources/terminfo"

export EDITOR=hx
export VISUAL=$EDITOR

# if editor is cursor (determined by `VSCODE_GIT_ASKPASS_MAIN` containing `Cursor.app`)
if [[ "$VSCODE_GIT_ASKPASS_MAIN" == *"Cursor.app"* ]]; then
    VISUAL=cursor
elif [[ "$TERM_PROGRAM" == "vscode" ]]; then
    VISUAL=code-insiders
fi

export PAGER="bat"
export LESS="-R"
export BROWSER="open -a 'Google Chrome'"
export NED_DEFAULTS='-Ru --colors=always'
export CD_HISTORY="$HOME/.cd_history"
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob '"'"'!.git/'"'"
export KITTY_CONFIG_DIRECTORY="$HOME/.config/kitty"

GIT_EDITOR="hx"
# if [[ "$GIT_EDITOR" == "code-insiders" || "$GIT_EDITOR" == "code" ]]; then
    # GIT_EDITOR="'$VISUAL --wait'"
# fi
