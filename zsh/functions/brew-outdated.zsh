function brew-outdated() {
  brew outdated --json=v2 2>/dev/null \
  | jq -r '
      # Color helpers
      def hdr(s):    "\u001b[1;95m" + s + "\u001b[0m";        # bright magenta
      def name(s):   "\u001b[1;96m" + s + "\u001b[0m";        # bright cyan
      def old(s):    "\u001b[0;33m"  + s + "\u001b[0m";        # yellow
      def arrow:     "\u001b[1;37m ➜ \u001b[0m";               # white arrow
      def new(s):    "\u001b[1;91m"  + s + "\u001b[0m";        # bright red

      # Collect items
      def fmt(item):
        name(item.name) + " " + old(item.installed) + arrow + new(item.current);

      # Build sections
      (
        # Formulae section
        if (.formulae | length) > 0 then
          hdr("Formulae:") ,
          (.formulae[]
            | {name: .name,
               installed: (.installed_versions | join(", ")),
               current: .current_version}
            | fmt(.)
          )
        else empty end
      ),
      (
        # Casks section
        if (.casks | length) > 0 then
          hdr("Casks:") ,
          (.casks[]
            | {name: .name,
               installed: (.installed_versions | join(", ")),
               current: .current_version}
            | fmt(.)
          )
        else empty end
      )
    '
}
