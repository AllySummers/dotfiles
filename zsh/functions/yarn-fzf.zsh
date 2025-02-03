function yarn-fzf() {
  if ! command -v rg >/dev/null 2>&1; then
    echo "Error: ripgrep (rg) is not installed. Please install it to use yarn-fzf." >&2
    return 1 2>/dev/null || exit 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    echo "Error: fzf is not installed. Please install it to use yarn-fzf." >&2
    return 1 2>/dev/null || exit 1
  fi

  if ! command -v bat >/dev/null 2>&1; then
    echo "Error: bat is not installed. Please install it to use yarn-fzf." >&2
    return 1 2>/dev/null || exit 1
  fi

  t_cols="${$(tput cols):-80}"
  preview_cols=$(( t_cols * 30 / 100 ))
  main_cols=$(( t_cols - preview_cols ))
  name_width=$(( main_cols * 40 / 100 ))

  rg 'resolution:\s*"(.*?)@workspace.*:(.*?)"' \
  -Nor $'$1\t$2' yarn.lock \
  | awk -F'\t' -v nW="$name_width" '
    ##################################################################
    # Left-align, truncate if too long, else pad with spaces (right)
    ##################################################################
    function left_align(str, width,   slen, out, i) {
    slen = length(str)
    if (slen > width) {
      out = substr(str, 1, width)
    } else {
      out = str
      for (i = slen + 1; i <= width; i++) {
      out = out " "
      }
    }
    return out
    }

    {
    rawName     = $1
    rawLocation = $2

    # 1) Do raw truncation/padding
    truncName = left_align(rawName, nW)

    # 2) Apply color AFTER truncation
    greenStart  = "\033[32m"
    greyStart   = "\033[90m"
    yellowStart = "\033[33m"
    reset       = "\033[0m"

    coloredName = greenStart truncName reset
    coloredSep  = greyStart "│" reset
    coloredLoc  = yellowStart rawLocation reset

    # 3) Print the color-coded row for fzf, plus hidden fields
    print coloredName "  " coloredSep "  " coloredLoc \
        "\t" rawName "\t" rawLocation
    }
  ' \
  | fzf \
    --ansi \
    --height=100% \
    --border \
    --delimiter='\t' \
    --with-nth=1 \
    --preview 'bat --color=always {3}/package.json' \
    --preview-window 'right:30%' \
    --bind 'enter:execute(${VISUAL:-${EDITOR:-nano}} {3}/package.json)+abort'
}

