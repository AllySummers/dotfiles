# Casks that require binary, pkg, or preflight install artifacts and therefore
# cannot be installed by mise's brew-cask: backend. Installed via
# 'brew bundle --global' inside the [tasks.bootstrap] task (INSTALL_GUI=true).
#
# All brew formulae and app-only casks have moved to [bootstrap.packages] in
# mise.toml (managed by the brew: and brew-cask: backends respectively).

# Write, edit, and chat about your code with AI (app + CLI binary symlink)
cask "cursor"
# Command-line agent for Cursor (binary only, no .app bundle)
cask "cursor-cli"
# App to build and share containerised applications and microservices
# (app + many binary symlinks + completions + postflight script)
cask "docker-desktop"
# Web browser (preflight script + app + binary symlink)
cask "firefox"
# Cross-platform Git credential storage for multiple hosting providers (pkg installer)
cask "git-credential-manager"
# Open-source code editor (app + 'code' binary symlink)
cask "visual-studio-code"
# Insiders build of VS Code (app + 'code-insiders' binary symlink)
cask "visual-studio-code@insiders"
