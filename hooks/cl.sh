#!/bin/sh
set -e
# Script to print a range of lines of a file, if no range is given the number
# of lines is printed, if only one value is given or the initial value is empty
# the range is assumed to start at 1
# ---------
# FUNCTIONS
# ---------
print_error() {
  echo "$*" >&2
  exit 1
}
usage() {
  echo "Usage: $(basename "$0") FILE [[BEG] END]" >&2
  exit 1
}
# ----
# MAIN
# ----
FILE="$1"
BEG="$2"
END="$3"
if [ -z "$FILE" ]; then
  usage
fi
if [ ! -f "$FILE" ]; then
  print_error "File '$FILE' not found!"
fi
if [ -z "$BEG" ]; then
  if [ -z "$END" ]; then
    # if no range was passed, print the number of lines
    sed -n '$=' "$FILE"
    exit 0
  else
    # if the initial value was empty, use 1
    BEG="1"
  fi
elif [ -z "$END" ]; then
  # If only beg was set, make it the end of the range and start at 1
  END="$BEG"
  BEG="1"
fi
case "$BEG" in
  *[!0-9]*) print_error "Initial line '$BEG' is not a number" ;;
esac
case "$END" in
  *[!0-9]*) print_error "Ending line '$END' is not a number" ;;
esac
if [ "$BEG" -gt "$END" ]; then
  print_error "Wrong range, '$BEG' must be smaller than '$END'"
fi
sed -n "${BEG},${END}p" "$FILE"
# vim: ts=2:sw=2:et:ai:sts=2
