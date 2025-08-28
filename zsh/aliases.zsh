alias zsh-bundle='antidote bundle <~/.zsh_plugins.txt >~/.zsh_plugins.zsh'

alias edit='${VISUAL:-${EDITOR:-nano}} '
alias e='edit '

alias nvm='fnm '

export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.7z=01;31:*.ace=01;31:*.alz=01;31:*.apk=01;31:*.arc=01;31:*.arj=01;31:*.bz=01;31:*.bz2=01;31:*.cab=01;31:*.cpio=01;31:*.crate=01;31:*.deb=01;31:*.drpm=01;31:*.dwm=01;31:*.dz=01;31:*.ear=01;31:*.egg=01;31:*.esd=01;31:*.gz=01;31:*.jar=01;31:*.lha=01;31:*.lrz=01;31:*.lz=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.lzo=01;31:*.pyz=01;31:*.rar=01;31:*.rpm=01;31:*.rz=01;31:*.sar=01;31:*.swm=01;31:*.t7z=01;31:*.tar=01;31:*.taz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tgz=01;31:*.tlz=01;31:*.txz=01;31:*.tz=01;31:*.tzo=01;31:*.tzst=01;31:*.udeb=01;31:*.war=01;31:*.whl=01;31:*.wim=01;31:*.xz=01;31:*.z=01;31:*.zip=01;31:*.zoo=01;31:*.zst=01;31:*.avif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:*~=00;90:*#=00;90:*.bak=00;90:*.crdownload=00;90:*.dpkg-dist=00;90:*.dpkg-new=00;90:*.dpkg-old=00;90:*.dpkg-tmp=00;90:*.old=00;90:*.orig=00;90:*.part=00;90:*.rej=00;90:*.rpmnew=00;90:*.rpmorig=00;90:*.rpmsave=00;90:*.swp=00;90:*.tmp=00;90:*.ucf-dist=00;90:*.ucf-new=00;90:*.ucf-old=00;90:'
export LSCOLORS="${LS_COLORS}"
alias ls="$HOMEBREW_PREFIX/bin/gls --color=tty --almost-all --literal"
alias l='ls -1'
alias lsperms="$HOMEBREW_PREFIX/bin/eza --color=auto --almost-all --long --sort=size --group-directories-first --no-quotes --octal-permissions --no-filesize --no-time --no-user"

alias h='history'
alias hg='history | rg'
alias hgi='history | rg -i'
alias mans='mans'
alias mansearch='mans'

alias copy='clipcopy'
alias -g C='| clipcopy'
alias -g E='| $EDITOR -'
alias -g V='| $VISUAL -'


# ▄▀  █ ▀█▀    ▄▀▄ █   █ ▄▀▄ ▄▀▀ ██▀ ▄▀▀
# ▀▄█ █  █     █▀█ █▄▄ █ █▀█ ▄█▀ █▄▄ ▄█▀

# git root dir
alias groot='git rev-parse --show-toplevel '
alias reporoot='git rev-parse --show-toplevel '
# git branch name
alias gbranch='git rev-parse --abbrev-ref HEAD '
# git repo name
alias gname='basename $(git rev-parse --show-toplevel) '
# git main branch name
alias grmain="git branch -a | rg 'HEAD -> origin/(.*)$' -or '$1' "
# git ls unstaged
alias glsunstaged='git --no-pager diff --name-only '
alias glsu='glsunstaged '

# git ls staged
alias glsstaged='git --no-pager diff --name-only --cached '
alias glss='glsstaged'

alias latest-head='git merge-base HEAD origin/master'

# git ls staged+unstaged
alias glsall='git --no-pager diff HEAD --name-only '
alias lsall='glsall '
alias lsa='glsall '
alias glsa='glsall '

# git unstaged
alias gunstage='git restore --staged '
# git add
alias gadd='git add '

# git (un)ignore locally
alias gignore='git update-index --skip-worktree '
alias gunignore='git update-index --no-skip-worktree '

# git pull master
alias gp-m='git pull origin master'
# git pull jira-stable
alias gp-js='git pull origin jira-stable'
# git pull head
alias gp='git pull origin '
alias gp-h='git pull origin $(git rev-parse --abbrev-ref HEAD) '


# git main branch
alias gb-main='git checkout $(gname) '
alias gbp-pain='gb-main; gp-h '

# git main branch
alias gb-main='git checkout master '
alias gbp-main='gb-main; gp-h '

# list commands in a brew cellar (package)
alias lsp="brew --cellar"
alias brewformulas="curl --silent https://formulae.brew.sh/api/formula.json | fx "
alias brewcasks="curl --silent https://formulae.brew.sh/api/cask.json | fx "

# node modules aliases
alias pnx='node_modules/.bin/nx '
alias ptsx='node_modules/.bin/tsx '
alias ptsc='node_modules/.bin/tsc '
alias pesbuild='node -r esbuild-register '
alias pesb='pesbuild '
alias peslint='node_modules/.bin/eslint '
alias pvitest='node_modules/.bin/vitest '

alias -s git="git clone"

alias jsonl2json="jq --slurp '.'"
alias ndjson2json="jq --slurp '.'"

alias timestamp='printf "%.4f" "$(echo "$(gdate +%s.%N) * 1000" | bc -l)"'

alias fixup='git log -n 10 --oneline --no-decorate --no-merges | fzf -0 --preview "git show --color=always --format=oneline {1}" | awk "{print $1}" | xargs -r git commit --fixup'
