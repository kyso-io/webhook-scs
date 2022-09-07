#!/bin/ash
set -euo pipefail
set -o errexit
set -o errtrace
# Check variables
if [ -z "$AWS_KEY" ] || [ -z "$AWS_SECRET_KEY" ] || [ -z "$S3_BUCKET" ] ||
  [ -z	"$KYSO_URL" ] || [ -z "$KYSO_USERNAME" ] || [ -z "$KYSO_TOKEN" ]; then
	[ "$AWS_KEY" ] || echo "Set the AWS_KEY environment variable"
	[ "$AWS_SECRET_KEY" ] || echo "Set the AWS_SECRET_KEY environment variable"
	[ "$S3_BUCKET" ] || echo "Set the S3_BUCKET environment variable"
	[ "$KYSO_URL" ] || echo "Set the KYSO_URL environment variable"
	[ "$KYSO_USERNAME" ] || echo "Set the KYSO_USERNAME environment variable"
	[ "$KYSO_TOKEN" ] || echo "Set the KYSO_TOKEN environment variable"
	exit 1
fi
if [ "$S3_REGION" ] && [ "$S3_REGION" != "us-east-1" ]; then
	EP_URL="endpoint=$S3_REGION,url=https://s3.$S3_REGION.amazonaws.com"
else
	EP_URL="endpoint=us-east-1"
fi
# Check moutpoint
MNT_POINT="${MNT_POINT:-/webhook/s3data}"
if [ ! -d "${MNT_POINT}" ]; then
	mkdir -p "${MNT_POINT}"
elif mountpoint "${MNT_POINT}"; then
	echo "There is already something mounted on '${MNT_POINT}', aborting!"
	exit 1
fi
# Create password file
touch "$HOME/.passwd-s3fs"
chmod 0400 "$HOME/.passwd-s3fs"
echo "${AWS_KEY}:${AWS_SECRET_KEY}" >"$HOME/.passwd-s3fs"
# Mount s3 bucket as a filesystem
/usr/bin/s3fs -o dbglevel=info,retries=5 -o "${EP_URL}" "${S3_BUCKET}" \
  "${MNT_POINT}"
echo "Mounted bucket '$S3_BUCKET' on '${MNT_POINT}'"
# Remove the password file, just in case
rm -f "$HOME/.passwd-s3fs"
# Check import path
MNT_POINT="${MNT_POINT:-/webhook/s3data}"
IMPORT_PATH="$MNT_POINT/$S3PATH"
if [ ! -d "${IMPORT_PATH}" ]; then
  echo "The S3PATH '$S3PATH' can't be found!"
  umount -f "${MNT_POINT}"
  echo "Called umount for '${MNT_POINT}'"
  exit 1
fi
# Call kyso login
ret="0"
kyso login -y "$KYSO_URL" -r "kyso" -u "$KYSO_USERNAME" -k "$KYSO_TOKEN" ||
  ret="$?"
if [ "$ret" -eq "0" ]; then
  # Prepare import arguments
  # shellcheck disable=SC2089
  IMPORT_ARGS="--path '$IMPORT_PATH'"
  if [ "$#" -gt "0" ]; then
    if [ "$1" = "true" ] || [ "$1" = "verbose" ]; then
      IMPORT_ARGS="$IMPORT_ARGS --verbose"
    fi
  fi
  [ "$ORGANIZATION" ] &&
    IMPORT_ARGS="$IMPORT_ARGS --organization '$ORGANIZATION'"
  [ "$CHANNEL" ] && IMPORT_ARGS="$IMPORT_ARGS --channel '$CHANNEL'"
  [ "$AUTHOR" ] && IMPORT_ARGS="$IMPORT_ARGS --author '$AUTHOR'"
  [ "$MAPPINGS" ] && IMPORT_ARGS="$IMPORT_ARGS --mappings '$MAPPINGS'"
  # Call the import function
  eval "kyso import $IMPORT_ARGS" || ret="$?"
fi
# Unmount the S3 bucket
umount -f "${MNT_POINT}"
echo "Called umount for '${MNT_POINT}'"
# Remove kyso auth data
rm -f "$HOME/.kyso/auth.json"
exit "$ret"
