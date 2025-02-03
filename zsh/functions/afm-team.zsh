#############################################
# afm-team
# Open a workspace package in your editor by package name
# Usage: afm-team <team-name>
# Example: afm-team 'JFP - Bedrock'
#############################################

Color_Off='\033[0m'       # Text Reset
IPurple='\033[0;95m'      # Purple
BICyan='\033[1;96m'       # Cyan

afm-team() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is not installed. Please install it to use afm-team." >&2
    return 1 2>/dev/null || exit 1
  fi

  SLACK_DOMAIN="atlassian.slack.com"

  if [[ $# -ne 1 ]]; then
  echo "Usage: afm-team <team-name>" >&2
  echo "Example: afm-team 'JFP - Bedrock'" >&2
  return 1
  fi

  local team="$1"

  local slack="$(jq -r '.["'"$team"'"].slack' teams.json)"
  slack="${slack#\#}"

  echo -e "${BICyan}Team: ${Color_Off}${team}"
  echo -e "${IPurple}Slack: ${Color_Off}https://${SLACK_DOMAIN}/channels/${slack} (#${slack})"
}

_afm_team() {
  local -a teams

  if [[ -f teams.json ]]; then
    local IFS=$'\n'
    teams=($(jq -r 'keys[]' teams.json))
  fi

  if (( ${#teams} )); then
    compadd -- "${teams[@]}"
  fi
}

compdef _afm_team afm-team
