path=(
    "$HOME/.bin"
    "$HOME/.cargo/bin"
    "$DENO_INSTALL/bin"
    "$FNM_PATH"
    "$HOME/.ts-cli/bin"
    "$BUN_INSTALL/bin"
    "$HOME/.local/bin"
    "$AFM_DIR/afm-tools/path"
    # Jenv Shims
    "$JENV_ROOT/shims"
    # Pyenv Shims
    "$PYENV_ROOT/shims"
    "$PYENV_ROOT/bin"
    # Homebrew
    "$HOMEBREW_PREFIX/bin"
    "$HOMEBREW_PREFIX/sbin"
    "$HOMEBREW_PREFIX/opt/util-linux/sbin"
    "$HOMEBREW_PREFIX/opt/util-linux/bin"
    "$PNPM_HOME"
    "/opt/local/bin"
    "/opt/local/sbin"
    $path
    "$HOME/.micromamba/bin"
    "$HOME/micromamba/bin"
    "$HOME/.orbit/bin"
    "$BUN_INSTALL/bin"
)

# github copilot chat adds a space to the path and breaks some stuff
path=( ${path[@]:#*copilot-chat/debugCommand*} )
