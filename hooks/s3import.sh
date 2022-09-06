#!/bin/ash
set -euo pipefail
set -o errexit
set -o errtrace
# Check import path
MNT_POINT="${MNT_POINT:-/webhook/s3data}"
IMPORT_PATH="$MNT_POINT/$S3PATH"
if [ ! -d "${IMPORT_PATH}" ]; then
  echo "The S3PATH '$S3PATH' can't be found"
  echo "It does not exist or the S3 bucket is not mounted, aborting!"
  exit 1
fi
# Kyso login
URL="${KYSO_URL:-https://kyso.io}"
USER="$KYSO_USERNAME"
TOKEN="$KYSO_TOKEN"
if [ -z "$USER" ] || [ -z "$TOKEN" ]; then
  echo "Missing variables!!!"
  echo ""
  echo "Add 'KYSO_USERNAME' and 'KYSO_TOKEN' to the environment."
  exit 1
fi
kyso login -y "$URL" -r "kyso" -u "$USER" -k "$TOKEN"
# Call the import function
# shellcheck disable=SC2089
IMPORT_ARGS="--path '$IMPORT_PATH'"
[ "$ORGANIZATION" ] && IMPORT_ARGS="$IMPORT_ARGS --organization '$ORGANIZATION'"
[ "$CHANNEL" ] && IMPORT_ARGS="$IMPORT_ARGS --channel '$CHANNEL'"
[ "$AUTHOR" ] && IMPORT_ARGS="$IMPORT_ARGS --author '$AUTHOR'"
[ "$MAPPINGS" ] && IMPORT_ARGS="$IMPORT_ARGS --mappings '$MAPPINGS'"
eval "kyso import $IMPORT_ARGS"
