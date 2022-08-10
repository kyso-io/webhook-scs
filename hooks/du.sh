#!/bin/sh
set -e
# Script to print disk usage for organizations and teams (the script asumes
# that the working directory contains directories for each ORG and inside them
# we have a folder for each TEAM).

# ---------
# FUNCTIONS
# ---------
print_error() {
  if [ "$OUTPUT_FORMAT" = "json" ]; then
    echo "{\"error\":\"$*\"}"
  else
    echo "$*" >&2
  fi
  exit 1
}

usage() {
  if [ "$OUTPUT_FORMAT" = "json" ]; then
    echo "{\"error\":\"Pass arguments as '?org=XXX&team=YYY' (team optional)\"}"
  else
    echo "Usage: $(basename "$0") ORG [TEAM]" >&2
  fi
  exit 1
}
# ----
# MAIN
# ----
if [ "$1" ]; then
  ORG="$(find -L . -mindepth 1 -maxdepth 1 -type d -path "./$1")" \
    2>/dev/null || true
else
  usage
fi
if [ -z "$ORG" ]; then
  print_error "Organization '$1' not found."
fi
if [ "$2" ]; then
  TEAMS="$(find -L "$ORG" -mindepth 1 -maxdepth 1 -type d -path "$ORG/$2")" \
    2>/dev/null || true
  if [ -z "$TEAMS" ]; then
    print_error "Team '$2' not found in organization '$1'."
  fi
else
  TEAMS="$(find -L "$ORG" -mindepth 1 -maxdepth 1 -type d -path "$ORG/*")" \
    2>/dev/null || true
  if [ -z "$TEAMS" ]; then
    print_error "Organization '$1' has no teams."
  fi
fi
# Print disk usage in bytes for one or all the teams of the organization
OUTPUT="$(for team in $TEAMS; do du -b -s "${team#./}"; done)"
if [ "$OUTPUT_FORMAT" = "json" ]; then
  # Format output as {"name":"ORG","teams":[{"name":"TEAM1","bytes":"BYTES"}]}
  json_teams="$(
    echo "$OUTPUT" |
      sed -e "s%^\(.*\)\t.*/\(.*\)$%{\"name\":\"\2\",\"bytes\":\"\1\"},%" |
	  tr -d '\n'
  )"
  echo "{\"name\":\"${ORG#./}\",\"teams\":[${json_teams%,}]}"
else
  # Print du output as is
  echo "$OUTPUT"
fi
